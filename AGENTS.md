# LLM Engineering Rules

## Monorepo Scope
This repository contains four active applications:
- `backend/`
- `user_app/`
- `vendor_app/`
- `admin_app/`

Any API, auth, shared business-rule, or contract change must be checked across all impacted apps and backend in the same change set.

## Mandatory Cross-App Update Rule
If a change affects any of the following, update all impacted consumers in the same PR:
- API routes or prefixes
- request and response payloads
- field names and status codes
- auth, RBAC, session, or token behavior
- order, menu, vendor, or user business logic
- validation rules or enum values

## Mandatory Documentation Update Rule
For any code, API, UI/UX, config, workflow, or test change, update all related documentation in the same PR.
This includes (when applicable):
- `README.md`
- `API_REFERENCE.md`
- `DEVELOPER_GUIDE.md`
- sprint and planning docs (`sprints_master.md`, `sprints_kanban.md`)
- runbooks, setup steps, and architecture notes

Do not merge changes with stale docs. Documentation updates are a required acceptance criterion.

## Mandatory Feature Test Rule
If any new feature is added or existing feature behavior is changed:
- Add or update automated tests that validate the feature behavior.
- Cover the happy path and key edge/error paths relevant to the feature.
- Do not merge unless all impacted tests pass locally/CI.

Feature work without corresponding tests is incomplete and must not be merged.

## Required Verification
Before merge, run:

```powershell
cd c:\project\food\backend
npm test

cd c:\project\food\user_app
flutter analyze
flutter test

cd c:\project\food\vendor_app
flutter analyze
flutter test

cd c:\project\food\admin_app
flutter analyze
flutter test
```

## Admin App Rule
If backend changes affect admin operations, update:
- `backend/`
- `admin_app/`
- tests for both

If shared business logic changes, verify:
- `backend/`
- `user_app/`
- `vendor_app/`
- `admin_app/`