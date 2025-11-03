# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Repository overview
- backend_mapato: Laravel 12 backend API with Sanctum auth, Vite/Tailwind assets, queue jobs, and scheduled tasks.
- boda_mapato: Flutter mobile app (Provider state management, HTTP client, PDF/printing, charts, shared_preferences).

Common commands

Backend (Laravel) — run in backend_mapato/
- Install deps: composer install; npm install
- Initialize env: copy .env.example .env; php artisan key:generate; php artisan migrate
- Dev server (API, queue, logs, Vite): composer run dev
- Build assets: npm run build
- Tests (all): composer test
- Tests (single): php artisan test --filter <TestClassOrMethod> [tests/Feature/SomeTest.php]
- Lint/format (PHP): vendor/bin/pint -v
- Migrations: php artisan migrate; rollback: php artisan migrate:rollback; fresh: php artisan migrate:fresh --seed

Mobile app (Flutter) — run in boda_mapato/
- Install deps: flutter pub get
- Run app: flutter run [-d <device_id>]
- Tests (all): flutter test
- Tests (single file): flutter test test/<path_to_test>.dart
- Tests (by name): flutter test -n "<pattern>"
- Lint: flutter analyze
- Format: dart format .
- Build APK: flutter build apk

High-level architecture

Backend (backend_mapato)
- Routing: routes/api.php defines REST endpoints under /api with auth:sanctum. Admin-only routes use role:admin middleware; driver-facing routes use role:driver. Payments have a dedicated group (see api.php and api_payments.php). Web routes (routes/web.php) expose a minimal admin dashboard behind Sanctum.
- Auth & security: Laravel Sanctum tokens; password/OTP flows under /api/auth/*.
- Domain model: app/Models covers Users, Drivers, Devices, Transactions, Payments/PaymentReceipts, Debts/Reminders, Agreements, Communications, DriverTrips/Performance/StatusHistory, Prediction cache.
- Services & helpers: app/Services/ReportService plus app/Helpers for number/response utilities; app/Enums/PaymentStatus.
- Jobs & scheduling: app/Jobs/PredictDriverCompletionJob scheduled nightly via routes/console.php; queue listener used during dev (composer run dev).
- Providers: custom providers (NumberServiceProvider, MySQL57ServiceProvider) and database connection shim (app/Database/MySqlConnection57.php).
- PDFs & exports: dompdf is required; receipt/report generation endpoints live under payment-receipts and reports groups.
- Testing: phpunit.xml runs tests with in-memory sqlite and sensible defaults (Feature and Unit suites). Use php artisan test or vendor/bin/phpunit.

Mobile app (boda_mapato)
- Dependencies: provider (state), http (REST), shared_preferences (local storage), fl_chart (charts), pdf/printing (export), file_picker/path_provider (files), flutter_localizations and intl (i18n), custom fonts via assets/fonts/.
- Linting rules: analysis_options.yaml extends flutter_lints and adds many strict rules; run flutter analyze to apply.
- Platforms: Android/iOS/Windows scaffolding present; Android appId currently com.example.boda_mapato.
- Typical integration: App consumes the backend’s REST API (auth via token, data dashboards, payments, receipts, reports). Adjust API base URL in app code as needed when running locally.

Repo conventions and tips for Warp
- Operate from the correct subdirectory when running commands (backend_mapato/ vs boda_mapato/).
- For API exploration or endpoint discovery, consult routes/api.php and related controllers; health check is GET /api/health.
- When running backend locally, keep the queue worker active (composer run dev handles server, queue:listen, logs, and Vite concurrently).
- PHPUnit tests don’t require a real DB due to in-memory sqlite config; migrations aren’t needed for test runs unless a test overrides config.
