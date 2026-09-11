# NileSky — Get It Live (corrected runbook)

This reflects what is actually in your repo, verified file by file — not the
example URLs in the old `DEPLOY.md`, several of which were wrong.

**Already applied to your working copy:** `render.yaml`, `.gitignore`,
`customer_app/lib/services/api_service.dart`,
`admin_panel/lib/services/admin_api_service.dart`.
Originals saved as `render.yaml.bak` and `gitignore.bak`.

---

## Why the URL 404s

Your repo has **no git remote**. Nothing was ever pushed to GitHub, so Render
was never connected and no service exists at that hostname.
`nilesky-api.onrender.com` was only an example in `DEPLOY.md`.

---

## 0. Security — do this first

`backend/.env.production` holds **real JWT secrets** and was **not** ignored
(the old `.gitignore` only covered `.env`, `.env.local`, `.env.*.local` — none
match `.env.production`). One push to a public repo and they were out.

- The new `.gitignore` excludes all `.env*`.
- The new `render.yaml` uses `generateValue: true`, so Render mints fresh
  secrets. Treat the ones in that file as burned; don't reuse them.
- The APK (60 MB) and Windows zip (13 MB) are now ignored too — GitHub warns
  above 50 MB and rejects at 100 MB, so the push would have failed. Ship those
  through GitHub **Releases**.

---

## 1 + 2 + 3. One command, then one click

From the repo root:

```powershell
.\go-live.ps1
```

(Defaults to GitHub user `engkemo1`. The repo will be created at
<https://github.com/engkemo1/nilesky>, private.)

That script re-applies the ignore rules, **refuses to continue** if any `.env`
or file over 50 MB is staged, builds the backend locally so you find compile
errors before Render does, creates a **private** GitHub repo (via `gh`, if you
have it), pushes, and opens Render's deploy page.

In the Render tab: sign in, click **Apply**. Nothing to paste — the blueprint
now provisions the Postgres database *and* the API, and wires `DATABASE_URL`
between them automatically.

> **The free Postgres instance expires after 30 days.** For something
> permanent, create a free-forever database at neon.tech and replace
> `DATABASE_URL` in the Render dashboard with its connection string. No code
> change needed: `app.module.ts` already handles `DATABASE_URL` with
> `ssl: { rejectUnauthorized: false }` under `NODE_ENV=production`, which is
> what Neon wants. All 13 tables are created and seeded on first boot, and
> `SeedService` is idempotent (`if (usersCount > 0) return`), so restarts won't
> duplicate data.

## What changed in render.yaml

First build takes 3–6 min (`bcrypt` compiles natively).

| Was | Now | Why |
|---|---|---|
| `name: nilesky-backend` | `name: nilesky-api` | Gives you `nilesky-api.onrender.com`, matching every doc and both apps' new default. |
| `version: "1"` | *(removed)* | Not a valid blueprint key. |
| `env: node` | `runtime: node` | `env:` is the deprecated spelling. |
| `healthCheckPath: /weather/luxor` | `healthCheckPath: /` | `GET /` is `AppController.getHello()` — no DB, no auth, instant. A health check that touches the DB flaps during database cold starts. |
| `PORT=10000` | *(removed)* | Render injects `PORT`; `main.ts` already reads it and binds `0.0.0.0`. Hardcoding conflicts. |
| — | `NODE_VERSION: 20.18.0` | Unpinned, Render picks a Node that `bcrypt@6` may have no prebuild for — a confusing native-compile failure. |
| — | `branch: main`, `autoDeploy: true` | Pushes redeploy automatically. |
| no database | `databases:` block + `fromDatabase` | The blueprint now creates Postgres itself and injects `DATABASE_URL`, so there is no connection string to copy by hand. |
| 2 Flutter static services | *(removed)* | They published `build/web`, which `.gitignore` excluded, with `buildCommand: echo` — they'd have deployed **empty**. Render's image has no Flutter SDK, so it can't build them either. See step 5. |

---

## 4. Verify

```
https://nilesky-api.onrender.com/           -> "Hello World!"
https://nilesky-api.onrender.com/api/docs   -> Swagger UI, 14 tag groups
https://nilesky-api.onrender.com/weather/luxor
```

If `/api/docs` loads, the app booted **and** TypeORM connected — Nest won't
start if the DB connection fails.

**Free-tier caveat:** the service sleeps after 15 min idle; the next request
takes 30–60 s. First-time users will think the app is broken. Either add a
generous loading state (the customer app currently uses a **10-second HTTP
timeout**, which is shorter than a cold start — it will time out on first
launch) or take Render's $7/mo Starter plan, which never sleeps.

---

## 5. Front-ends

Build locally — Render can't:

```powershell
cd admin_panel   ; flutter build web --release
cd ..\customer_app ; flutter build web --release
```

Then drag each `build/web` folder onto **app.netlify.com/drop**, or
`npx vercel --prod` from inside it. (Or commit `*/build/web` — the new
`.gitignore` already has the un-ignore rules — and use a Render Static Site
with a `/*` → `/index.html` rewrite.)

---

## 6. Rebuild the Android APK — required

**Your existing `NileSky_Customer_App.apk` will never work.** `DEPLOY.md`
claims both apps default to `https://nilesky-api.onrender.com`. They did not:

- `customer_app` defaulted to **`http://localhost:3000`** — on a phone that's
  the phone itself. It would also be blocked outright, since Android 9+ forbids
  cleartext HTTP by default.
- `admin_panel` defaulted to **`https://node-mongo-dn.onrender.com`** — a
  leftover URL from an unrelated project.

I've corrected both defaults. Rebuild and redistribute:

```powershell
cd customer_app
flutter build apk --release --dart-define=API_URL=https://nilesky-api.onrender.com
```

---

## 7. Known gaps that will show up in production

Not blockers for going live, but you'll hit them:

- **File uploads don't persist.** `UploadService` doesn't write anywhere — it
  returns a made-up URL at `https://images.nilesky.com/uploads/...`, a domain
  that doesn't exist. Every uploaded image will 404. Needs real S3/Cloudinary
  before users upload anything.
- **Weather is hardcoded.** `WeatherService` returns a fixed Luxor forecast
  (28°C, sunny) regardless of the actual day. Fine for a demo, wrong on screen.
- **JWT fallback secret.** `jwt.strategy.ts` falls back to
  `'super-secret-key-change-me-in-production'` if `JWT_SECRET` is unset. The
  blueprint always sets it, but that default should be a hard startup failure.
- **Seeded credentials are public.** `admin@nilesky.com / Admin@123456` and
  `operator@nilesky.com / Operator@123456` are in `DEPLOY.md`, which will be in
  your public repo. Change them the moment the API is up.

---

## Pre-flight checks I ran

- All 89 backend TypeScript files: **0 unresolved imports**.
- Every external package imported is declared in `package.json` — no missing
  dependency will break the Render build.
- `main.ts` binds `0.0.0.0` and reads `process.env.PORT`. Correct for Render.
- I could not run a full `npm install && npm run build` — this sandbox has no
  access to the npm registry. The static checks above cover the common causes
  of a failed Render build, but the compile itself is unverified. Run
  `cd backend ; npm run build` locally before pushing if you want certainty.
