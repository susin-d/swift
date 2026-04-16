# Swift Admin Web

Admin portal for the Swift food delivery platform.

## Backend Connection

Set `VITE_BACKEND_API_URL` to the backend API base URL. For local development, use `http://localhost:3000/api/v1`.

The admin portal authenticates against backend `/auth/session` and loads dashboard, users, vendors, orders, finance, audit, support, notifications broadcast, and settings data from the backend admin routes.
