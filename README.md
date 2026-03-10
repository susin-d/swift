# Swift
A comprehensive, real-time logistics and food delivery platform connecting students with premium vendors.

## 🌟 Platform Components

1. **User Mobile App (Flutter)**: Allows students and staff to browse vendors, order food, and track deliveries in real-time.
2. **Vendor Dashboard (React/Vite)**: A tablet-optimized web dashboard for canteens to manage their menus and process live orders.
3. **Admin Dashboard (React/Vite)**: A control panel for campus management to oversee vendor approvals and platform analytics.
4. **Backend API (Node.js/Fastify)**: The central brain handling authentication, order processing, and RBAC security.
5. **Database (Supabase PostgreSQL)**: A strictly secured database using Row Level Security (RLS) with Realtime WebSockets built-in.

## 🚀 Getting Started

### Prerequisites
- Node.js (v18+)
- Flutter SDK (v3.10+)
- A Supabase Project (Free Tier works)

### Local Setup

1. **Supabase**
   - Head to [Supabase](https://supabase.com) and create a project.
   - Run the SQL script found in `supabase/schema.sql` in the Supabase SQL Editor.
   - Grab your Project URL and anon/service keys.

2. **Backend Services**
   ```bash
   cd backend
   npm install
   cp .env.example .env
   # Add your Supabase keys to .env
   npm run dev
   ```

3. **Vendor Dashboard**
   ```bash
   cd vendor-dashboard
   npm install
   npm run dev
   ```

4. **User Mobile App**
   ```bash
   cd mobile_app
   flutter pub get
   flutter run
   ```

## 🔒 Tech Stack
- **Flutter** & **Dart**
- **React.js** (Vite), **Tailwind CSS**
- **Node.js**, **Fastify**, **TypeScript**
- **Supabase** (PostgreSQL, Auth, Realtime)

## 🤝 Contributing
Please read the internal developer guides before pushing changes to the `main` branch. Ensure your code passes all lint checks.
