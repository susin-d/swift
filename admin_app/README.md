# admin_app

Flutter admin operations console for Campus Pulse.

## Core Features

- Secure admin authentication with session posture checks
- Dashboard overview for operational health
- Vendor, user, order, promo, finance, campus, settings, and audit modules
- Shared AppShell for compact and desktop admin navigation
- Governance workflows with reason capture on sensitive actions

## Production Readiness (Current)

- Compact mode bottom navigation with desktop sidebar parity
- Trust posture banner and trusted-device action flow
- Accessibility semantics on shell-level actions (search affordance + sign-out control)
- Test-covered provider and screen flows for orders, vendors, users, finance, settings, and audit

## Development Commands

Run from `admin_app/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Monorepo Verification Policy

When admin behavior changes due to backend or shared contract updates, validate impacted backend/app suites as required by repository governance docs.
