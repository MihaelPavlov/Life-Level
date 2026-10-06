# Plan — Life Level waitlist: landing page on GitHub Pages + email collection

## Context
Page 1 of the "Life Level Launch Pages" canvas (dark "Level 0" page with glitch intro, XP bar, Web-Audio sound toggle) is approved. It must go live and actually store the emails people enter. User decisions:
- **No emails are sent** (no provider, no confirmation). Just store each address.
- **Spam protection: built-in only** (no CAPTCHA account).
- **Host on GitHub Pages**, replacing the current root page at `https://mihaelpavlov.github.io/Life-Level/` (Pages serves `main:/docs`). The old page moves to `/about/`; `/privacy/` stays.
- Storage = the existing ASP.NET Core API on Render (`https://life-level-api-latest-1779363121.onrender.com/api`) + Supabase Postgres, so every signup is a DB row we can count and export.

## 1. Backend — new `LifeLevel.Modules.Waitlist` module
Follow the Streak module layout (`modules/LifeLevel.Modules.Streak/…`, `StreakModule.cs`).

- `Domain/Entities/WaitlistSignup.cs`
  - `Id` (Guid), `Email` (normalized: trimmed, lower-case, ≤254), `CreatedAt`, `LastSubmittedAt`, `SubmitCount`
  - Tracking: `Source` (e.g. `landing`), `UtmSource`, `UtmMedium`, `UtmCampaign`, `Referrer` (≤500), `Locale`, `UserAgent` (≤300)
  - `IpHash` (SHA-256 of IP + server salt from config `Waitlist:IpSalt`; never the raw IP)
- `Infrastructure/Persistence/Configurations/WaitlistSignupConfiguration.cs`: table `WaitlistSignups`, unique index on `Email`, index on `CreatedAt`, max lengths.
- `Application/DTOs/WaitlistDtos.cs`: `JoinWaitlistRequest { Email, Website (honeypot), ElapsedMs, Source, UtmSource, UtmMedium, UtmCampaign, Referrer, Locale }`; admin list/stats DTOs.
- `Application/UseCases/WaitlistService.cs`
  - `JoinAsync(req, ip, userAgent)`:
    1. Honeypot `Website` non-empty, or `ElapsedMs < 2500` → return success **without saving** (bots learn nothing).
    2. Validate with `System.Net.Mail.MailAddress` + regex (`local@domain.tld`, no spaces, ≤254); invalid → 400 `{error:"invalid_email"}`.
    3. Reject disposable domains from a small static list (`DisposableDomains.cs`: mailinator.com, 10minutemail.com, guerrillamail.com, tempmail…, yopmail.com, etc.) → same 400.
    4. Per-IP-hash cap: >20 new signups from one IP hash in 24 h → silently accept, don't save.
    5. Upsert: existing email → `SubmitCount++`, `LastSubmittedAt` (no duplicate row); else insert.
    6. Always the same 200 response (`{ok:true}`) for new and existing emails, so the endpoint can't be used to check who signed up.
  - `GetStatsAsync()` (total, today, last 7 days, top UTM sources), `ListAsync(page, size)`, `ExportCsvAsync()`.
- `Infrastructure/WaitlistModule.cs` → `AddWaitlistModule()`; reference in `LifeLevel.Api.csproj` + `LifeLevel.slnx`; `ApplyConfigurationsFromAssembly(typeof(WaitlistModule).Assembly)` + `DbSet` in `AppDbContext.cs`; `builder.Services.AddWaitlistModule()` in `Program.cs`.
- Controllers:
  - `Controllers/WaitlistController.cs`: `POST /api/waitlist` `[AllowAnonymous]`, `[EnableRateLimiting("waitlist")]`.
  - `Controllers/Admin/AdminWaitlistController.cs` `[Authorize(Policy="Admin")]`: `GET /api/admin/waitlist/stats`, `GET /api/admin/waitlist?page=&size=`, `GET /api/admin/waitlist/export` (CSV download).
- `Program.cs`:
  - Rate limiter policy `waitlist`: fixed window 5 requests / 10 min per client IP.
  - **Real client IP behind Render's proxy:** add `UseForwardedHeaders` (XForwardedFor, KnownNetworks/Proxies cleared) before the rate limiter. Today `RemoteIpAddress` is Render's proxy, so every visitor shares one bucket — this also fixes the existing `auth` limiter.
  - CORS already allows any origin (`AllowAll`); no change needed.
- EF migration `AddWaitlist` (`dotnet ef migrations add AddWaitlist --project src/LifeLevel.Api`); check it only contains the new table.
- Config: `Waitlist:IpSalt` in `appsettings.example.json` + Render env var `Waitlist__IpSalt`.

## 2. Landing page — `docs/index.html`
- `git mv docs/index.html docs/about/index.html` (fix its relative asset paths: `assets/…` → `../assets/…`).
- New `docs/index.html`: plain static HTML exported from canvas artboard `Main.dc.html` (https://claude.ai/artifact/89WyUUE7HwfeT6cPtxwE8d), same markup/CSS/animations; the DCLogic class becomes a small inline `<script>`:
  - `const API = 'https://life-level-api-latest-1779363121.onrender.com/api';`
  - On load: `fetch(API.replace('/api','/health'))` to wake the Render instance (free tier sleeps), record `loadedAt`.
  - Hidden honeypot `<input name="website" tabindex="-1" autocomplete="off">` inside an off-screen wrapper.
  - Submit: client-side email check → POST JSON `{email, website, elapsedMs, source:'landing', utm_* from location.search, referrer: document.referrer, locale: navigator.language}`; button shows "Joining…" and is disabled; 30 s timeout with a "Server is waking up, try again" message; 400 → inline "That email doesn't look right"; 200 → success state + chime.
  - Sound toggle + Web Audio code carried over as-is.
- Logo: copy `life-level-logo-instragram.jpg` to `docs/assets/logo-ll.jpg`.
- Add `<meta name="description">`, Open Graph/Twitter tags (title, description, image) and a favicon from the logo; a "Privacy" link in the footer to `privacy/`.
- Small consent line under the form: "We'll only use your email to tell you when Life Level launches. Privacy" (link).

## 3. Privacy page — `docs/privacy/index.html`
Add a "Launch waitlist" section: what we store (email, signup time, campaign/referrer info, hashed IP for abuse prevention), why (one launch announcement), retention (deleted after launch announcement or on request), how to remove (email m.pavlov1405@gmail.com).

## 4. Seeing the signups
- Admin endpoints above (stats / list / CSV export) using the existing Admin JWT.
- Optional quick view: Supabase table editor on `WaitlistSignups`.
- Launch day: export CSV → import into any email tool.

## Out of scope (noted for the user)
- Sending any email (welcome/confirmation/launch).
- `AdminConfigController` (`GET /api/admin/config`) returns the admin email/password to anyone without auth — security issue to fix separately.

## Verification
- `dotnet build`; unit tests in `backend/tests/LifeLevel.Api.Tests/WaitlistServiceTests.cs` (in-memory DB like `PendingActivityServiceTests`): new email saved; duplicate (different case/spaces) increments `SubmitCount` and keeps one row; honeypot / too-fast → 200 and nothing saved; invalid + disposable → 400; IP cap; responses identical for new vs existing.
- `dotnet test backend/tests/LifeLevel.Api.Tests`.
- Local run: `curl -X POST localhost:5128/api/waitlist -H 'Content-Type: application/json' -d '{"email":"a@b.co","elapsedMs":5000}'` → 200 and a row; 6th call in 10 min → 429.
- Open `docs/index.html` locally with `API` pointed at localhost: intro, sound, submit, success, invalid email message.
- After pushing `main` + applying migration + deploying the API to Render: submit on https://mihaelpavlov.github.io/Life-Level/, check `/api/admin/waitlist/stats`; check `/Life-Level/about/` and `/Life-Level/privacy/` still load.
- No commit/push/deploy/migration apply without the user's OK.
