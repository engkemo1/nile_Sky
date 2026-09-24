# 🚀 NileSky — Live Free Deployment Guide

This guide walks you through deploying the complete NileSky platform to **free hosting services** in under 10 minutes:
1. **Database**: PostgreSQL on **[Neon.tech](https://neon.tech)** (100% Free Forever tier)
2. **Backend API**: NestJS on **[Render.com](https://render.com)** (Free Web Service tier)
3. **Admin Panel**: Flutter Web on **[Render.com](https://render.com)** or **[Vercel](https://vercel.com)** (Free Static Hosting)
4. **Customer App**: Flutter Web & Mobile APK/IPA (Free Static Hosting & Release Build)

---

## 📋 Architecture & URLs Overview

| Component | Technology | Free Host | Production URL (Example) |
|---|---|---|---|
| **Database** | PostgreSQL 16 (UUID, PostGIS) | **Neon.tech** | `postgresql://user:pass@ep-xyz.eu-central-1.aws.neon.tech/nilesky?sslmode=require` |
| **Backend API** | NestJS + TypeORM + Swagger | **Render.com** | `https://nilesky-api.onrender.com` |
| **Swagger API Docs** | OpenAPI 3.0 | **Render.com** | `https://nilesky-api.onrender.com/api/docs` |
| **Admin Panel** | Flutter Web | **Render / Vercel** | `https://nilesky-admin.onrender.com` |
| **Customer App** | Flutter Web / Android / iOS | **Render / Vercel** | `https://nilesky-app.onrender.com` |

---

## Step 1: Deploy Free PostgreSQL Database (Neon.tech)

1. Go to **[https://neon.tech](https://neon.tech)** and sign up (free with GitHub or Google).
2. Click **Create Project**:
   - **Project Name**: `nilesky`
   - **Postgres Version**: `16`
   - **Region**: Choose closest (e.g. Frankfurt `eu-central-1` or Oregon `us-west-2`)
3. Neon will immediately display your **Connection Details**:
   - Select **Connection string** format.
   - Copy the string. It will look like:
     ```
     postgresql://nilesky_owner:npg_AbCdEf123@ep-cool-cloud-123456.eu-central-1.aws.neon.tech/nilesky?sslmode=require
     ```
   *(Keep this string for Step 2)*.

> [!NOTE]
> The NestJS backend uses `synchronize: true` on startup, which will **automatically generate all 14 tables, relations, and enums** on Neon upon first connect, and seed initial test operators, flights, coupons, and an admin account (`admin@nilesky.com`). Its password comes from the `SEED_PASSWORD` environment variable and the API refuses to seed without one in production.

---

## Step 2: Deploy Backend API (Render.com)

### Option A: Using Render Blueprint (One-Click)

1. Push this project to your GitHub account:
   ```bash
   git add .
   git commit -m "NileSky complete production release"
   git remote add origin https://github.com/<your-username>/nilesky.git
   git push -u origin main
   ```
2. Log into **[Render.com](https://render.com)**.
3. Click **New +** → **Blueprint**.
4. Select your `nilesky` repository.
5. Render reads `render.yaml` and sets up the services automatically!
6. In the Environment Variables prompt, paste your Neon `DATABASE_URL`.
7. Click **Apply**.

---

### Option B: Manual Web Service Setup on Render

1. On Render, click **New +** → **Web Service**.
2. Connect your GitHub repository.
3. Configure the settings:
   - **Name**: `nilesky-api`
   - **Root Directory**: `backend`
   - **Environment**: `Node`
   - **Region**: Same region as Neon (e.g. Frankfurt)
   - **Branch**: `main`
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm run start:prod`
   - **Plan**: `Free`
4. Add **Environment Variables**:
   | Key | Value |
   |---|---|
   | `NODE_ENV` | `production` |
   | `PORT` | `10000` |
   | `DATABASE_URL` | *Your Neon connection string from Step 1* |
   | `JWT_SECRET` | *Any strong random 32+ character string* |
   | `JWT_REFRESH_SECRET` | *Another strong random 32+ character string* |
   | `JWT_EXPIRES_IN` | `24h` |
   | `JWT_REFRESH_EXPIRES_IN` | `30d` |
5. Click **Create Web Service**.
6. Once deployed (~2-3 minutes), Render will assign you a live HTTPS URL, e.g.:
   `https://nilesky-api.onrender.com`
7. Test the health check in your browser:
   `https://nilesky-api.onrender.com/weather/luxor`
8. Browse the interactive Swagger docs:
   `https://nilesky-api.onrender.com/api/docs`

---

## Step 3: Configure Apps with the Live Backend URL

You can connect both Flutter apps to your live Render backend in **3 easy ways**:

### Way 1: In-App Dynamic Switcher (Zero rebuilding required!)
Both apps now include a built-in server switcher:
- **Customer App**: Go to **Profile** → **Live Backend Server URL** → tap the edit icon, paste your Render URL, or select the **🌐 Live Render** preset!
- **Admin Panel**: On the **Login Screen**, click the **Backend: ...** badge at the bottom to switch between Live Render and Localhost!

### Way 2: Compile-time define (for production builds)
When building for Web or APK, pass the live URL directly:
```bash
# Admin Panel Web build
cd admin_panel
flutter build web --release --dart-define=API_URL=https://your-backend.onrender.com

# Customer App Web build
cd customer_app
flutter build web --release --dart-define=API_URL=https://your-backend.onrender.com

# Customer App Android APK
flutter build apk --release --dart-define=API_URL=https://your-backend.onrender.com
```

### Way 3: Default Code Constant
The default URL in both `customer_app/lib/services/api_service.dart` and `admin_panel/lib/services/admin_api_service.dart` is pre-set to:
```dart
static String baseUrl = const String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://nilesky-api.onrender.com',
);
```

---

## Step 4: Deploy Admin Panel & Customer App to Web (Free)

### Deploying to Vercel (Fastest)

1. Build both web projects:
   ```bash
   cd admin_panel && flutter build web --release
   cd ../customer_app && flutter build web --release
   ```
2. Deploy Admin Panel with Vercel CLI:
   ```bash
   cd admin_panel/build/web
   npx vercel --prod
   ```
3. Deploy Customer App with Vercel CLI:
   ```bash
   cd ../../../customer_app/build/web
   npx vercel --prod
   ```

### Deploying to Render Static Sites

1. In Render, click **New +** → **Static Site**.
2. Select your repository.
3. For Admin Panel:
   - **Publish directory**: `admin_panel/build/web`
4. For Customer App:
   - **Publish directory**: `customer_app/build/web`

---

## 🔐 Default Credentials

- **Admin Email**: `admin@nilesky.com`
- **Admin Password**: whatever you set in `SEED_PASSWORD`; change it from the admin panel after the first sign-in. Never commit it.
- **Role**: `platform_admin`
- **Operator Admin Email**: `operator@nilesky.com`
- **Operator Admin Password**: not seeded. Create operator admins from the Users screen in the admin panel.
