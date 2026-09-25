# NileSky — what's live

## Your links

| What | Address |
|---|---|
| **Admin panel** | https://nilesky-admin.vercel.app |
| **API** | https://nile-sky.vercel.app |
| **API docs (Swagger)** | https://nile-sky.vercel.app/api/docs |
| Database | Neon — free, never expires |
| Code | https://github.com/engkemo1/nile_Sky |

## Admin login

```
admin@nilesky.com
```

The password is **not written down here any more**. Both passwords this project
has used — `Admin@123456` and the one that replaced it — were committed to a
public repository, so both must be treated as burned.

To set a new one: sign in to the admin panel, click the key icon next to your
name at the bottom of the sidebar, and change it there. The new password is
never stored in the repo. Removing it from these files does not remove it from
git history, so rotating it is the only thing that actually helps.

## Cost

Everything is on free tiers and **no credit card was used anywhere**.
Render was abandoned because it now demands card verification even on its
free plan; Koyeb was abandoned because it shut its deploy dashboard down.

The database is Neon rather than Render's free Postgres, which is deleted
after 30 days. Neon's free tier has no expiry.

## Still to do — the Android app

The APK has to be built on your own PC, because it needs the Android SDK.
Double-click **BUILD-APK.bat**, or run:

```
cd customer_app
flutter build apk --release --dart-define=API_URL=https://nile-sky.vercel.app
```

It lands in `customer_app\build\app\outputs\flutter-apk\app-release.apk`.

**Your old APK will never work** — it was built before the INTERNET
permission was added, so it had no network access at all.

## Known gaps (not blockers)

- **File uploads don't persist.** `UploadService` returns an invented URL at
  `images.nilesky.com`, a domain that does not exist, so every uploaded image
  will 404. Needs S3 or Cloudinary before users upload anything.
- **Weather is hardcoded** to a fixed Luxor forecast (28°C, sunny) whatever
  the real conditions.
- **Payments are simulated.** The booking screen offers Card / Apple Pay /
  Cash but nothing is charged; bookings are marked paid immediately.
- **Sessions are lost on refresh.** Neither app stores its token, so closing
  the app or pressing F5 returns you to the login screen.
- **First request after idle is slow.** Serverless functions sleep; the first
  call wakes them. Timeouts are set to 60s to absorb this.

## Environment variables

Nothing has to be set for the API to run: the token signing keys are derived
from `DATABASE_URL`, which is already there.

Worth setting later, none of them urgent:

| Variable | What it does |
|---|---|
| `JWT_SECRET` / `JWT_REFRESH_SECRET` | Pins the signing keys. Without them the keys follow the database password, so rotating that password signs everyone out. |
| `PAYMENT_WEBHOOK_SECRET` | Required before payment-gateway webhooks will be accepted at all. |
| `CORS_ORIGINS` | Comma-separated allowlist. Left unset, the API answers any origin. |
| `ENABLE_SWAGGER` | `true` republishes the API docs, which are off in production. |
| `DB_SYNCHRONIZE` | `false` stops TypeORM rewriting the schema on boot. Leave it on until the schema stops changing. |
