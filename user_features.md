# User App Features

## ✅ Existing Features

### Core Ordering Flow
- **Home Feed**: Mood-to-meal intent chips (Comfort, Quick, Sweet, Light, All) filtering recommendations by category/keywords
- **Vendor Discovery**: Browsable vendor list with open/closed status and ratings
- **Menu System**: Category-based vendor menus with inline quantity steppers on menu item cards
- **Cart Management**: Multi-vendor-aware cart with local caching, synced via `PATCH /api/v1/cart`, item quantity controls
- **Address Book**: Saved delivery addresses with default selection, add/edit/delete operations via `/api/v1/addresses` endpoints
- **Order Creation**: Full order metadata including `delivery_mode` (standard|class), `delivery_building_id`, `delivery_room`, `delivery_zone_id`, scheduled delivery slots via `GET /api/v1/orders/slots`

### Payment & Checkout
- **Payment Methods**: Razorpay integration for card/wallet payments; pay-on-pickup option
- **Promo Codes**: Validation via `POST /api/v1/promos/validate`; active promo list via `GET /api/v1/promos/active`
- **Scheduled Delivery**: Time slot picker for deferred order fulfillment

### Order Management
- **Order Tracking**: Real-time order status with live map view via `orderTrackingProvider` (Supabase Realtime stream)
- **Order History**: List view with filterable order timeline, access to past orders via `GET /api/v1/orders/me`
- **Order Cancellation**: Cancel orders before preparation via `PATCH /api/v1/orders/:id/cancel` (shows ETA confidence bands)
- **Order Review**: Submit ratings and text reviews via `/reviews` endpoint (ReviewService)

### Campus & Delivery Features
- **Class Delivery Integration**: Room/building selection with class session management via `POST /api/v1/class-sessions`, schedule sync
- **Campus Geofence**: Buildings list via `GET /api/v1/public/buildings`, zones via `GET /api/v1/public/zones` for location-aware delivery
- **Handoff Code**: Generated for class deliveries to coordinate pickup timing
- **Quiet Mode**: Toggle for "no calls" delivery preference

### Discovery & Personalization
- **Global Search**: Full-text search across menus and vendors via `GET /api/v1/public/search`, debounced 320ms input handling
- **Recommendations Feed**: Backend-ranked items via `GET /api/v1/public/recommendations` with recommendation scores
- **Reorder Studio**: One-tap repeat order card on home screen (extracts items from latest order)
- **Favorites System**: Vendor heart-toggle with local persistence (StateNotifier-based)

### Notifications & Communication
- **Notification Feed**: List view with order-linked notifications via `GET /api/v1/notifications`, mark-as-read via `PATCH /api/v1/notifications/:id/read`
- **Push Registration**: Device token registration for iOS/Android via `POST /api/v1/notifications/device`
- **ETA Trust Band**: Order responses include `eta.min_minutes`, `eta.max_minutes`, `eta.confidence` (low|medium|high)

### User Account
- **Authentication**: Email/password signup and login via Supabase and backend session endpoints
- **Profile Management**: Edit name, email, phone via `updateProfile()` (AuthService)
- **Session Posture**: Auth state tracking with current user available in providers
- **Legal & Help**: Terms of Service, Privacy Policy, Help & Support screens (currently static)

## ❌ Missing Features

### Loyalty & Rewards
- **Wallet/Account Credit System**: No wallet top-up, credit balance, or credit-based ordering UI (model exists with `walletBalance` field but no corresponding endpoints)
- **Referral Program**: No referral code generation, sharing, or referral bonus UI
- **Loyalty Tiers**: No tier progression, points accumulation, or tier-based perks
- **Achievement System**: No milestones, badges, or gamified engagement rewards

### Messaging & Support
- **In-App Chat**: Support screen shows placeholder UI for "Chat with Support" but no real chat implementation or WebSocket/messaging endpoints
- **Courier Communication**: No direct messaging with delivery personnel (only ETA and status updates)
- **Order-Scoped Support Tickets**: No ability to create help requests tied to specific orders

### Analytics & Insights
- **Spending Dashboard**: No monthly/weekly spending summaries or expense tracking
- **Order Statistics**: No personal order analytics (frequency, favorite vendors, most ordered items)
- **Dietary Preferences**: No filtering by allergies, dietary restrictions, or cuisine preferences

### Account Management
- **Subscription Options**: No subscription plans for recurring orders or discounted bulk purchases
- **Payment Method Management**: No saved card list or payment method editing UI (only Razorpay selection at checkout)
- **Account Deletion**: No self-service account/data deletion flow

### Advanced Ordering
- **Bulk/Group Orders**: No group ordering or split payment features
- **Custom Dietary Requests**: No per-item special instructions beyond delivery instructions
- **Vendor Notifications**: No ability to follow/watch vendors for new menu items or status changes

## 🚀 Suggested Enhancements

### Retention & Engagement
1. **Wallet System**: Implement wallet top-up UI with balance display in profile. Backend needs `PATCH /api/v1/wallet/topup` and `GET /api/v1/wallet/balance` endpoints
2. **Referral Program**: Add referral share button on profile screen; generate unique referral code; backend needs `POST /api/v1/referrals/generate` and tracking endpoints
3. **Subscription Options**: Offer "Order 5 get 1 free" or monthly discount passes; requires new subscription state in cart and backend subscription endpoints
4. **Spending Insights**: Dashboard card on home showing "You've saved ₹240 this month with promos" and trending vendors/dishes

### Marketing & Discovery
5. **Personalized Feed Ranking**: Enhance `GET /api/v1/public/recommendations` to include user's order history, favorites, and inferred preferences
6. **Seasonal/Trending Section**: "This Week's Hits" section pulling trending vendors or limited-time items
7. **Smart Notifications**: Alert users 1-2 weeks after an order if they haven't reordered ("Your Comfort Meal is ready again")
8. **Push Notifications for Discounts**: Notify on newly active promo codes matching user's favorite vendors

### User Experience
9. **In-App Support Chat**: Replace static support screen with WebSocket-based agent chat or Intercom integration; backend needs chat endpoints
10. **Delivery Feedback Survey**: Post-delivery micro-survey (1-5 stars, optional comment) to improve ETA confidence and quality signals
11. **Order Comparison View**: "Last time you ordered biryani from Vendor X in 18 min for ₹350. Similar options today..." to encourage repeat patterns
12. **Smart Reorder Suggestions**: "You ordered from Cafe Mocha 3 times. Ready to order again?" with quick-add button
13. **Cuisine Filters on Home**: Persistent chips or filter menu for "Vegetarian Only", "Under ₹300", "Ready in <15min"
14. **Vendor Loyalty Badges**: "5+ orders" or "Regular" badges to highlight high-performing vendors user trusts
15. **Offline Mode**: Cache recently viewed vendors and menu items so search works in low connectivity

### Class Delivery Enhancement
16. **Calendar Integration**: Sync class schedule with calendar app (iOS Calendar, Google Calendar); auto-fill delivery time based on class end time
17. **Classroom Map**: Visual classroom picker instead of text input for campus buildings (if building layouts available)
18. **Early Warning for Class Delivery**: Notify if order ETA extends past class end time; suggest alternative delivery mode

### Account & Analytics
19. **Food Spending Dashboard**: Monthly/weekly breakdown by vendor, cuisine, or category; personal spending limits/alerts
20. **Favorites Sync**: Auto-categorize favorited vendors (e.g., "Breakfast", "Late Night Snacks") for smarter feed ranking
21. **Account Deletion API**: Self-service data deletion via `DELETE /api/v1/users/me` with 7-day confirmation window (required for GDPR/data privacy)

## ⚠️ UX Issues

### High Priority
1. **Support Screen Non-Functional**: "Chat with Support", "Email Us", "Call Us" buttons have empty `onTap` handlers (`() {}`). Implement real support routing (email client, chat SDK, phone dialer)
2. **Cart Height Overflow**: Cart checkout summary referenced as "height-capped with internal scrolling" in README, but on small screens (iPhone SE, Android <5"), address + promo + schedule sections may still overflow; verify horizontal scrolling/collapsible sections
3. **Payment Error Feedback**: No error recovery UX if Razorpay fails mid-flow; missing retry button or fallback to pay-on-pickup option
4. **Missing Wallet Balance Display**: User model has `walletBalance` field but no UI component shows it on profile; users unaware of available credit

### Medium Priority
5. **Notification Metadata Fragility**: Notifications linked to orders via `metadata['order_id']` string-to-UUID conversion; missing validation causes silent route-to-home failures
6. **Search Debounce Timing**: 320ms debounce may be too aggressive on slow networks; no "no results" state distinguishes between empty results and still-loading
7. **Promo Code Copy-Paste**: No copy-to-clipboard button on active promo list; users must manually type codes (friction point)
8. **Address Label Confusion**: Address labels ("Home", "Work") not highlighted on cart flow; users may select wrong address mid-checkout without visual feedback
9. **Favorites Persistence**: Favorites stored locally (StateNotifier) without backend sync; lost if user uninstalls app or switches devices
10. **ETA Confidence Bands Unclear**: "Low|Medium|High" confidence labels not explained to users; no contextual help on why ETA varies (e.g., "High = <5 min variance")

### Low Priority
11. **Class Schedule Screen Minimal**: `ClassScheduleScreen` shows saved sessions but no edit/delete UI; users must navigate to address book or cart to manage classes
12. **Review Text Limit Not Enforced**: Review submission via `ReviewService` has no character limit UI; backend may reject long text silently
13. **Order History Filtering**: No filter/sort options (status, vendor, date range) on `OrderHistoryScreen`; all orders shown in single list
14. **Vendor Card Rating Display**: Floating rating badge not distinguishing between "no reviews" (0.0) and "poor rating" (1.5); no review count shown
15. **Loading States Inconsistent**: Home feed uses shimmer loaders; notifications and address book use centered spinners; unify for consistent brand feel
16. **Profile Avatar Generic**: Initials-based avatar unaccounting for Unicode/emoji names; no image upload option

## 🔗 API Gaps

### User Management
1. **Missing**: Wallet endpoints (`GET /api/v1/wallet/balance`, `PATCH /api/v1/wallet/topup`, `GET /api/v1/wallet/transactions`)
2. **Missing**: User preferences endpoint (allergies, dietary restrictions, cuisine blacklist)
3. **Missing**: Account deletion endpoint (`DELETE /api/v1/users/me`)

### Loyalty & Engagement
4. **Missing**: Referral endpoints (`POST /api/v1/referrals/generate`, `GET /api/v1/referrals/code/:code`, `POST /api/v1/referrals/redeem`)
5. **Missing**: Loyalty tier endpoints (`GET /api/v1/loyalty/tier`, `POST /api/v1/loyalty/points`)
6. **Missing**: Subscription endpoints (`GET /api/v1/subscriptions`, `POST /api/v1/subscriptions/create`)

### Communication
7. **Missing**: Chat/messaging endpoints (e.g., `POST /api/v1/messages`, `GET /api/v1/conversations/:conversationId/messages`)
8. **Missing**: In-app support ticket endpoints (`POST /api/v1/support/tickets`, `GET /api/v1/support/tickets/me`)
9. **Missing**: Delivery person contact endpoint (name, phone, estimated ETA precision)

### Advanced Features
10. **Missing**: Order sharing/group ordering endpoints (`POST /api/v1/orders/group`, `PATCH /api/v1/orders/:id/split`)
11. **Missing**: Spending analytics endpoints (`GET /api/v1/analytics/spending`, `GET /api/v1/analytics/vendors`)
12. **Missing**: Refund request endpoints (`POST /api/v1/orders/:id/refund`, `GET /api/v1/refunds/me`)
13. **Missing**: Vendor-specific alerts endpoint (`POST /api/v1/vendors/:id/watch`, `DELETE /api/v1/vendors/:id/watch`)

### Data & Sync
14. **Missing**: Full user deletion with confirmation flow (`DELETE /api/v1/users/me` endpoint may exist but no 7-day confirmation pre-requisite in contracts)
15. **Incomplete**: `cart.get` endpoint response schema lacks `cart.expires_at` or cache TTL; unclear if cart persists server-side or is client-only
