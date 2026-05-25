# Tutorial: Fixing 2 CI Tests After Schema & Default Changes

## The Problem

Two tests broke after we introduced the ProductCache migration (schema bump) and changed the default backend URL from localhost to Render.

### Test 1: `test/core/drift/app_database_test.dart`

**Failure**: `Expected: <1> Actual: <2>` on line 26.

**Why**: We bumped `schemaVersion` from 1 to 2 in `AppDatabase` to support the migration that creates the `ProductCache` table. The test was still asserting the old schema version.

**Fix**: Changed `expect(db.schemaVersion, 1)` → `expect(db.schemaVersion, 2)`.

### Test 2: `test/core/config/app_config_test.dart`

**Failure**: `Expected: 'http://localhost:8080/api/v1' Actual: 'https://mundo-limpio-backend.onrender.com/api/v1'` on line 15.

**Why**: We changed the default `baseUrl` in `AppConfig` to point to our Render deployment. The test description and assertion both still referenced localhost.

**Fix**: Updated the assertion to match the new default, and updated the test description from `"localhost:8080"` to `"Render backend"`.

## Lesson

When you change **defaults** (config values, schema versions, timeouts) or **public constants**, **always** grep for existing tests that assert those values. CI will catch them either way, but finding them proactively saves a feedback cycle.

Common change types that break tests:
- Schema version bumps
- Default URL/endpoint changes
- Timeout adjustments
- Environment variable default changes
- Enum value renames

**Rule of thumb**: If a constant or default changes, assume a test asserts it somewhere. `grep` for the old value first.
