# Website Delivery Plan (2 Runs)

## Objective
Launch a production-ready marketing website for the Swift platform that supports three role-based conversion paths:
- User app install
- Vendor onboarding lead
- Admin demo request

## Run 1: Foundation Launch

### Scope
- Build and ship a complete public marketing site shell.
- Publish all core content and conversion paths.
- Keep integrations lightweight to reduce launch risk.

### Deliverables
1. New website workspace under `site/` with:
   - `index.html` (landing page)
   - `features.html` (role-based product features)
   - `how-it-works.html` (user/vendor/admin flow)
   - `contact.html` (static contact and CTA section)
   - shared assets folder for branding and screenshots
2. Responsive design system:
   - Typography scale, spacing tokens, and color variables
   - Mobile-first layout with tablet and desktop breakpoints
3. Conversion surfaces:
   - Primary CTA: Install App
   - Secondary CTA: Become a Vendor
   - Tertiary CTA: Request Admin Demo
4. SEO and discoverability baseline:
   - Page titles, meta descriptions, Open Graph tags
   - `sitemap.xml` and `robots.txt`
5. Performance baseline:
   - Image compression and lazy loading for media
   - Lighthouse target: Performance >= 85, Accessibility >= 90, SEO >= 90

### Exit Criteria
- All core pages are live and navigable.
- CTA buttons route to correct destinations.
- No critical accessibility errors.
- Site works on current mobile and desktop browsers.

## Run 2: Production Hardening and Growth

### Scope
- Add operational capabilities and tracking.
- Improve trust, reliability, and maintainability.
- Prepare for ongoing content and campaign updates.

### Deliverables
1. Real contact and lead flow:
   - Contact form with validation
   - Backend endpoint or external form provider integration
   - Success/failure states and spam mitigation (captcha or honeypot)
2. Analytics and funnel tracking:
   - Pageview and CTA event tracking
   - Role-specific conversion events (user install, vendor lead, admin demo)
3. Trust and compliance pages:
   - Privacy policy
   - Terms of service
   - Data usage and support commitments
4. Content operations:
   - Reusable content blocks for updates
   - Screenshot refresh process and release checklist
5. Release hardening:
   - Smoke tests for navigation and forms
   - Broken link checks and metadata checks
   - Deployment checklist and rollback notes

### Exit Criteria
- End-to-end lead capture works in production.
- Analytics events are visible and verified.
- Legal and support pages are published.
- Release checklist is repeatable by any team member.

## Implementation Sequence
1. Week 1: Run 1 build and first deployment.
2. Week 2: Run 2 integrations and hardening.

## Ownership
- Product: messaging and conversion targets
- Design: visual system and responsive quality
- Engineering: implementation, deployment, and QA
- Ops: analytics validation and support workflow

## Validation Commands (Post-Implementation)
Use these once website implementation is complete.

```powershell
# backend regression check
cd c:\project\food\backend
npm test

# app-level checks
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