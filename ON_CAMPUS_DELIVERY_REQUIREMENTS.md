# On-Campus Delivery to Class — Requirements
Date: 2026-03-19

## Scope
Enable food delivery directly to classrooms during active class sessions with reliable scheduling, location clarity, and quiet handoff workflows.

## Core Goals
- Deliver within class time windows without disruption.
- Provide clear location and access instructions to couriers.
- Reduce failed handoffs and late deliveries.
- Support peak campus traffic with slotting and throttling.

## User App (Students)
Must-have
- Class schedule import or manual class picker (building, room, time)
- “Deliver to class” mode with arrival window and delivery notes
- Real-time courier location and ETA
- Quiet delivery options (no calls, silent handoff)
- Handoff confirmation (name/code/QR)
- Push notifications for arrival and delivery

Nice-to-have
- Automatic fallback to pickup if class ends early
- Campus map with delivery zones and building entrances
- Group order to class

## Courier/Runner (Delivery Ops)
Must-have
- Route optimization by building priority
- Building access rules and delivery points
- “Arrived at building” and “Arrived at class” status
- Secure handoff flow (code/QR)
- Exception handling (student late, class moved)

Nice-to-have
- Crowd-aware routing during peak times
- Batch delivery support across nearby classrooms

## Vendor App
Must-have
- Scheduled delivery slots and cutoff times
- Prep-time pacing for class-time orders
- Order priority tags for class deliveries

Nice-to-have
- Batch-ready view for upcoming class deliveries

## Admin / Ops
Must-have
- Delivery zones per building and time window
- Admin campus management UI for buildings and zones
- Slot caps and throttling by time of day
- Runner staffing and shift management
- Incident handling workflow
- SLA tracking (late/missed deliveries)

Nice-to-have
- Fraud/abuse detection (fake orders, no-shows)
- On-campus policy compliance logs

## Backend / Infrastructure
Must-have
- Scheduling engine with time window validation
- Geofence validation for delivery zones using last courier location
- Proof-of-delivery capture for delivered/failed handoffs
- Notification fanout (in-app + push)
- Audit logs for handoff and disputes

Nice-to-have
- Predictive ETA modeling
- Campus event-aware throttling

## Phased Delivery
Phase 1 (MVP)
- Class-time scheduling with building + room
- Slot-based ordering and cutoff enforcement
- Courier ETA + arrival notifications
- Quiet delivery mode

Phase 2
- Handoff verification (QR/code)
- Zone-based throttling
- Runner staffing tools

Phase 3
- Predictive ETA + peak traffic routing
- Incident automation and analytics dashboards

## Open Questions
- How will class schedule import be authorized (SIS integration vs manual)?
- Are couriers allowed to enter buildings, or must deliver to a designated point?
- What are acceptable SLA targets for class-time delivery?

## Data Model (Draft)
- `campus_buildings`: canonical campus locations with lat/lng and delivery notes.
- `delivery_zones`: geojson boundaries for delivery eligibility and throttling.
- `class_sessions`: user-saved class blocks (building, room, time window).
- `orders` new fields:
  - `delivery_mode` (`standard` | `class`)
  - `delivery_instructions`, `delivery_location_label`, `delivery_building_id`, `delivery_room`
  - `delivery_zone_id`, `quiet_mode`
  - `handoff_code`, `handoff_status`, `handoff_proof_url`
  - `class_start_at`, `class_end_at`

