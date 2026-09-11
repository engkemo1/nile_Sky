# NileSky — Get It Live (corrected runbook)

Everything below reflects what's actually in your repo today, not the example
URLs in the old `DEPLOY.md`.

---

## 0. Do this first — security

`backend/.env.production` contains **real JWT secrets** and is **not** covered by
your current `.gitignore` (it only ignores `.env`, `.env.local`, `.env.*.local`).
The moment you push to a public GitHub repo, those secrets are public.

1. Replace `.gitignore` with the corrected one in this folder (it ignores
   **all** `.env*` files).
2. Treat the current `JWT_SECRET` / `JWT_REFRESH_SECRET` as burned — the
   corrected `render.yaml` uses `generateValue: true`, so Render will mint fresh
   strong secrets for you. Don't reuse the ones in the file.
3. Also add the two large binaries (`NileSky_Customer_App.apk` — 60 MB,
   `NileSky_Admin_Windows.zip` — 13 MB) to `.gitignore`. GitHub warns above
   50 MB and hard-rejects at 100 MB; the APK would make your push fail.
   The corrected `.gitignore` already excludes `*.apk` and `*.zip` — publish
   those through GitHub **Releases** instead.

---

## 1. Database — Neon (free)

1. neon.tech → sign up → **Create Project**
   - Name `nilesky`, Postgres 16, region **Frankfurt (eu-central-1)**
     (match the Render region so latency is low)
2. Copy the pooled connection string. Keep it for step 3.

Your `app.module.ts` uses `synchronize: true` and `ssl: { rejectUnauthorized: false }`
when `NODE_ENV=production`, so Neon works with no code changes — all 13 tables
are created and seeded on first boot.

---

## 2. Push to GitHub

Your repo has **no remote** — nothing has ever been pushed, which is the actual
reason `nilesky-api.onrender.com` 404s.

```bash
cd C:\Users\kemoe\.gemini\antigravity-ide\scratch\nilesky
# copy the corrected .gitignore and render.yaml into place FIRST
git rm -r --cached . && git add .        # re-apply the new ignore rules
git commit -m "Fix Render blueprint, ignore env files and binaries"
git remote add origin https://github.com/<your-username>/nilesky.git
git branch -M main
git push -u origin main
```

Before pushing, confirm nothing sensitive is staged:

```bash
git ls-files | grep -E "\.env|\.apk|\.zip"   # must print nothing
```

---

## 3. Deploy the API — Render

1. render.com → **New +** → **Blueprint** → pick the `nilesky` repo.
2. Render reads the corrected `render.yaml` and proposes one service:
   **nilesky-api**.
3. It will prompt for `DATABASE_URL` — paste the Neon string.
4. **Apply**. First build takes 3–6 min (`bcrypt` compiles natively).

### What I changed in `render.yaml` and why

| Was | Now | Why |
|---|---|---|
| `name: nilesky-backend` | `name: nilesky-api` | Both Flutter apps hardcode `https://nilesky-api.onrender.com` as the default `API_URL`. The old name would have given you `nilesky-backend.onrender.com` and every app call would 404. |
| `version: "1"` | *(removed)* | Not a valid Render blueprint key. |
| `env: node` | `runtime: node` | `env:` is the deprecated spelling. |
| `healthCheckPath: /weather/luxor` | `healthCheckPath: /` | `GET /` is `AppController.getHello()` — no DB, no auth, always fast. A health check that touches the DB will flap your service during Neon cold starts. |
| `PORT=10000` | *(removed)* | Render injects `PORT`; `main.ts` already reads `process.env.PORT` and binds `0.0.0.0`. Hardcoding it can conflict. |
| — | `NODE_VERSION: 20.18.0` | Pinned. Unpinned, Render picks a newer Node that `bcrypt@6` may have no prebuild for — a classic silent build failure. |
| — | `branch: main`, `autoDeploy: true` | Explicit, and pushes redeploy automatically. |
| 2 Flutter static services | *(removed)* | They had `buildCommand: echo "Built via Flutter"` pointing at `build/web`, which your `.gitignore` excluded — they would have deployed **empty**. Render's build image has no Flutter SDK, so it cannot build them either. See step 5. |

---

## 4. Verify

```
https://nilesky-api.onrender.com/           -> "Hello World!"-style string
https://nilesky-api.onrender.com/api/docs   -> Swagger UI, 14 tag groups
https://nilesky-api.onrender.com/weather/luxor
```

If `/api/docs` loads, the app booted **and** TypeORM connected — Nest won't
start if the DB connection fails.

**Free-tier caveat:** the service sleeps after 15 min idle. The next request
takes 30–60 s to wake it. Your apps will look broken to a first-time user.
Mitigations: add a splash/loading state with a long timeout, or upgrade to
Render's $7/mo Starter plan which never sleeps.

---

## 5. Front-ends

Build locally (you have Flutter; Render does not):

```bash
cd admin_panel  && flutter build web --release
cd ../customer_app && flutter build web --release
```

Then either:

- **Render Static Site** — commit `*/build/web` (the corrected `.gitignore` has
  the un-ignore rules ready), then New + → Static Site → publish directory
  `admin_panel/build/web`, with a rewrite `/*` → `/index.html`.
- **Netlify Drop / Vercel** (faster) — drag the `build/web` folder onto
  app.netlify.com/drop, or `npx vercel --prod` from inside it.

No rebuild is needed to point them at the API: `API_URL` defaults to
`https://nilesky-api.onrender.com`, which is exactly what step 3 creates. The
APK you already built will also just start working.

---

## 6. Immediately after go-live

Change the seeded credentials — `admin@nilesky.com / Admin@123456` and
`operator@nilesky.com / Operator@123456` are in `DEPLOY.md`, which will be
public in your GitHub repo, and `SeedService` creates those accounts on every
fresh database.
