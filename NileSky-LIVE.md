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
IG8dH1lihIbdRc2d@Ns1
```

The old password `Admin@123456` is written in DEPLOY.md inside your **public**
repo, so it was replaced. Change this one after you sign in, and consider
making the repository private.

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
