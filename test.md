# Swift Monorepo Test Documentation

This file centralizes test and verification commands for all active apps in this repository.

## Scope

- backend (Node.js/Fastify)
- user_app (Flutter)
- vendor_app (Flutter)
- admin_app (Flutter)

## Quick Full Verification

Run these commands from the repository root:

```powershell
cd c:\project\swift\backend
npm test

cd c:\project\swift\user_app
flutter analyze
flutter test

cd c:\project\swift\vendor_app
flutter analyze
flutter test

cd c:\project\swift\admin_app
flutter analyze
flutter test
```

## App-by-App Test Guide

### backend

Run from `backend/`:

```bash
npm test
```

Optional API sweeps:

```bash
npm run test:api
npm run test:api:live
npm run test:api:live:flow
```

Pass criteria:

- `npm test` completes with no failing tests.
- Optional API sweeps complete without contract failures.

### user_app

Run from `user_app/`:

```bash
flutter analyze
flutter test
```

Pass criteria:

- `flutter analyze` reports no errors.
- `flutter test` completes with all tests passing.

### vendor_app

Run from `vendor_app/`:

```bash
flutter analyze
flutter test
```

Pass criteria:

- `flutter analyze` reports no errors.
- `flutter test` completes with all tests passing.

### admin_app

Run from `admin_app/`:

```bash
flutter analyze
flutter test
```

Pass criteria:

- `flutter analyze` reports no errors.
- `flutter test` completes with all tests passing.

## Notes

- For backend, install dependencies first with `npm install` if needed.
- For Flutter apps, run `flutter pub get` before test execution when dependencies change.
- If backend contracts, auth, payloads, or enums change, re-run impacted app test suites in the same change cycle.
