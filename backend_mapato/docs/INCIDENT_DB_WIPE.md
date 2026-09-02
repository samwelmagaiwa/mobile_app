# Incident: shared dev database wiped, 2026-09-02

## What happened

While comparing the inventory backend against a second, independently-built
"BDMS" implementation found in the repo, I ran that implementation's own test
suite (`php artisan test --filter=BdmsFeatureTest`) to check whether it
actually passed. That test uses Laravel's `RefreshDatabase` trait, which is
meant to run against an isolated database and rebuild it from migrations for
every run.

`phpunit.xml` correctly declares `DB_CONNECTION=sqlite` / `DB_DATABASE=:memory:`
for tests. But the app container's `docker-compose.yml` had `env_file: .env`
on the `app` service. That makes every value in `.env` — including
`DB_CONNECTION=mysql` and `DB_DATABASE=boda_db` — into **real container
environment variables**, visible to every process before Laravel or PHPUnit
ever runs. Laravel's Dotenv loader never overrides a variable that already
exists in the real environment, so `phpunit.xml`'s `sqlite`/`:memory:`
settings were silently powerless the entire time. Every test in this
container, run by anyone, was always going to hit the live `boda_db`
connection.

`RefreshDatabase` did exactly what it is supposed to do — dropped every table
and re-ran every migration from zero — except it did it against the shared
development database, not a throwaway one. It then hit an unrelated,
pre-existing bug (`2024_01_15_000001_create_receipts_table` referencing
`payments`, `drivers` and `users`, all of which are created by *later*
migrations) and aborted partway through, leaving only two tables:
`migrations` (empty) and `payment_receipts`.

## Impact

Every table in `boda_db` was lost: all `users` (13 accounts), all rental
data, all payments/drivers/receipts, and every inventory table. No backup was
available. The schema was fully rebuilt from the app's migrations (see
below), but real data — accounts, manually-entered records, anything not
reconstructible from migration seeds — could not be recovered.

## Fixes applied

1. **Root cause**: removed `env_file: .env` from `docker-compose.yml`'s `app`
   service, and added `.env.testing` (sqlite, in-memory). Laravel's own
   Dotenv loader reads `.env` / `.env.testing` itself — baking `.env` into the
   container's real OS environment was never necessary and is what made
   `.env.testing` unable to take effect.
2. **Guard rail**: `tests/Feature/TestEnvironmentSafetyTest.php` asserts the
   default connection is `sqlite` and the app environment is `testing`. If
   this test ever fails, treat it as a stop-everything signal — do not run
   any `RefreshDatabase`-based test until it passes again.
3. **The pre-existing migration bug** that made the rebuild abort partway
   through: `2024_01_15_000001_create_receipts_table.php` was superseded by
   `2025_10_13_083551_recreate_payments_and_payment_receipts_tables.php` and
   is now a documented no-op.
4. **A second, more serious bug this incident surfaced**: `users.id` is a
   UUID (`char(36)`), but every "who did this" column added across the
   inventory backend (`created_by`, `user_id`, `approved_by`, etc.) was typed
   `unsignedBigInteger`, and several service methods type-hinted the
   parameter as `?int`. Under MySQL's default leniency this was silently
   tolerated; the first time a *real* authenticated user (not `null`) reached
   one of these paths, it would have thrown a hard `TypeError`. Fixed with
   `2026_09_02_130000_fix_user_reference_column_types.php` (columns) and
   widened `int|string|null` parameter types (`StockLedger`,
   `CrateLedgerService`, `ProductUnitController`). This bug predates this
   incident and existed in three pre-inventory tables too
   (`inventory_products.created_by`, `inventory_sales.created_by`,
   `inventory_stock_movements.user_id`) — all corrected in the same migration.

## Verification

- `php artisan migrate --force` completes cleanly from an empty database:
  every base-app, rental, and inventory migration runs in order.
- Full test suite passes: 32 tests, 97 assertions, including HTTP-level tests
  authenticated as a real Sanctum user (which is what caught the UUID bug).
- `docs/INVENTORY_DEPOT_ROADMAP.md` records the current state of the
  inventory backend independent of this incident.

## What this should change going forward

- Never run a `RefreshDatabase`-based test without first confirming
  `TestEnvironmentSafetyTest` passes.
- Treat `env_file:` in any `docker-compose.yml` for this app as suspect —
  prefer the `environment:` block for the few values a container genuinely
  needs to override, and let Laravel's own `.env` handling do the rest.
- Any column meant to hold `$request->user()->id` must be typed to match
  `users.id` (UUID), not assumed to be a bigint.
