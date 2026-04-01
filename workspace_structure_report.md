# Workspace Folder Structure Report

## Root Directory
- admin_app/: Flutter app for admins
- admin_features.md: Admin features documentation
- AGENTS.md: LLM engineering rules and agent instructions
- API_REFERENCE.md: API reference documentation
- apps/: APK builds for all apps
- backend/: Node.js backend API server
- build-app.ps1: Build script
- BUILD_APP_GUIDE.md: Build instructions
- docs_archive/: Archived documentation
- llm.md: LLM notes
- README.md: Main project readme
- supabase/: Database schema and migrations
- user_app/: Flutter app for end users
- user_features.md: User features documentation
- vendor_app/: Flutter app for vendors
- vendor_features.md: Vendor features documentation

---

## admin_app/
- .dart_tool/, .idea/, .flutter-plugins-dependencies, .metadata: Flutter build/config files
- admin_app.iml: IntelliJ project file
- analysis_options.yaml: Dart analysis config
- android/: Android project files
- assets/: App assets
- build/: Build outputs
- lib/: App source code
  - app.dart, main.dart: Entry points
  - core/, features/, shared/: App modules
- pubspec.lock, pubspec.yaml: Flutter dependencies
- README.md: App-specific readme
- test/: Tests
  - core/, providers/, smoke/, widgets/: Test modules
  - widget_test.dart: Widget test
- web/: Web build files

---

## apps/
- admin_app.apk, user_app.apk, vendor_app.apk: Built APKs for each app

---

## backend/
- .env, .env .production, .env.example: Environment configs
- admin_responses.txt, backend_response.txt, backend_responses.txt, user_responses.txt, vendor_responses.txt: Response logs
- api/: API entry (index.ts)
- api_test.log: API test log
- campus_food_images/: Image assets
- current_menu_items.json: Menu data
- demo-credentials.json: Demo credentials
- dist/: Build outputs
- IndianFoodDataset.csv: Dataset
- jest.config.js: Jest test config
- node_modules/: Node dependencies
- package-lock.json, package.json: Node dependencies
- reports/: API reports
- scripts/: Utility scripts
- src/: Source code
  - app.ts: Main app
  - config/, contracts/, controllers/, middleware/, models/, modules/, routes/, services/, utils/: Backend modules
  - index.ts: Entry point
  - test-db.ts, test-e2e.ts: Test scripts
- tests/: Test code
  - api/, mocks/, unit/: Test modules
- test_food.jpg, test_medhu_vada.jpg: Test images
- test_output.log: Test output
- test_startup.js: Startup test
- tsconfig.json: TypeScript config
- vercel.json: Vercel deployment config

---

## docs_archive/
- FEATURES_AND_GAPS.md: Features and gaps documentation
- system_features.md: System features documentation

---

## supabase/
- migrations/: SQL migration scripts
  - 2026-03-24T-chat-support.sql, 20260324_media_items_tracking.sql, ...: Migration files
- schema.sql: Main DB schema
- tests/: DB tests

---

## user_app/
- .dart_tool/, .idea/, .flutter-plugins-dependencies, .metadata: Flutter build/config files
- analysis_errors.txt, analysis_output.txt, build_log.txt: Analysis/build logs
- analysis_options.yaml: Dart analysis config
- android/: Android project files
- assets/: App assets
- build/: Build outputs
- ios/: iOS project files
- lib/: App source code
  - core/, features/, models/, providers/, screens/, services/, theme/, utils/, widgets/: App modules
  - main.dart: Entry point
- mobile_app.iml: IntelliJ project file
- pubspec.lock, pubspec.yaml: Flutter dependencies
- README.md: App-specific readme
- test/: Tests
  - core/, mocks/, models/, providers/, screens/, services/, widgets/: Test modules
  - widget_test.dart: Widget test

---

## vendor_app/
- .dart_tool/, .idea/, .flutter-plugins-dependencies, .metadata: Flutter build/config files
- analysis_options.yaml: Dart analysis config
- android/: Android project files
- assets/: App assets
- build/: Build outputs
- ios/, linux/, macos/, web/, windows/: Platform-specific files
- lib/: App source code
  - auth/, core/, providers/, widgets/: App modules
  - features/, main.dart: Features and entry point
- pubspec.lock, pubspec.yaml: Flutter dependencies
- README.md: App-specific readme
- test/: Tests
  - widget_test.dart: Widget test

---

This report summarizes the folder structure and main files of the workspace. For more details, see the README.md or app-specific documentation.
