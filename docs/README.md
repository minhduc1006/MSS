# MSS Project Documentation

This folder is the source-of-truth documentation for the current codebase in `be_microservices`, `flutter_apartment`, and `fe_react`.

The previous `Feature List.xlsx` file was removed on 2026-03-17 because it contained generic placeholder rows such as `Create/Update/Delete/Search/...` for every module and did not match the real API surface, screen set, or implementation status of the project.

## System Overview

The project is an apartment management system built as Spring Boot microservices with two clients:

| Module | Type | Default Port | Current Role |
| --- | --- | --- | --- |
| `be_microservices/gateway-service` | Spring Boot Gateway | `8080` | API gateway routing auth, billing, facility, security, and operations APIs through one entry point |
| `be_microservices/auth-service` | Spring Boot | `8081` | Login, password reset, resident/staff management, account lookup |
| `be_microservices/billing-service` | Spring Boot | `8082` | Billing overview, invoice CRUD, PayOS, apartment admin, tenancy, utility meters |
| `be_microservices/facility-service` | Spring Boot | `8083` | Facilities, maintenance logs, resident bookings, announcements, resident services |
| `be_microservices/security-service` | Spring Boot | `8084` | Incident management, SOS trigger, history |
| `be_microservices/operations-service` | Spring Boot | `8085` | Activity feed, staff tasks, package desk, complaints, resident ratings, shift roster |
| `flutter_apartment` | Flutter app | N/A | Primary client, most complete and most aligned with backend |
| `fe_react` | React + Vite + Express dev server | `3000` in dev | Secondary portal, only partly connected to backend |

## Current Product State

### Backend

The backend exposes real endpoints for:

- authentication and password reset
- resident CRUD and staff CRUD
- billing overview, invoice create/update/status/deactivate, invoice email, PayOS checkout/webhook
- apartment unit create/update/status/deactivate
- tenancy / lease portfolio
- utility meter submission and utility invoice generation
- facility create/update/status/deactivate and maintenance logs
- resident bookings and announcements
- security incident create/update/status/deactivate, SOS, and history
- operations activity, staff task creation, package/lost-found, complaint tickets, resident service ratings, and shift roster

### Flutter app

`flutter_apartment` is the main working client. The route map in `lib/main.dart` covers:

- admin: dashboard, activity, residents, staff, billing, facilities, apartment, security
- admin: leasing & utilities, operations hub
- resident: dashboard, bills, bookings, security, account, support desk
- staff: dashboard, facilities, security, settings, roster
- login and reset-password flow

Important implemented flows in Flutter:

- login with sanitized user-facing error messages
- password reset flow
- resident, staff, billing, apartment, facility, and security admin screens
- resident service booking and resident announcements
- admin-to-staff assignment flow through `operations-service`
- staff facilities queue showing assigned work only
- admin lease portfolio and utility meter workspace
- admin operations hub for package desk, complaints, and shift roster
- resident support desk for package tracking, complaints, and service rating
- staff roster view with complaint status updates

### React portal

`fe_react` is only partially production-aligned.

Real API-backed pages:

- `/`
- `/login`
- `/reset-password`
- `/reset-password/new`
- `/admin/billing`
- `/admin/leasing`
- `/admin/ops`
- `/resident/bills`

Pages that still use hard-coded or local-only data:

- most dashboards
- most resident pages outside bills
- staff pages
- resident/staff/security/facility/apartment admin views outside the billing page

The new `/` landing page is public-facing and intended for prospective renters to review live building metrics, availability, and amenity health before entering the portal.

The React admin portal now also includes:

- lease portfolio and utility meter submissions
- parcel / lost & found desk
- complaint assignment and resolution
- resident service rating visibility
- staff shift and duty roster

The Google auth helper route `/api/auth/url` exists only in `fe_react/server.ts`, so it works in the Express dev server flow and is not part of the static Vite build by itself.

## Business Rules Already Present In Code

- Shared/community facilities such as pool, gym, and lounge are seeded as free services.
- In-unit resident services are charged:
  - `Housekeeping Service`: `250000`
  - `Home Repair Service`: `350000`
  - `AC Cleaning Service`: `180000`
- Car parking is a paid resident subscription:
  - monthly: `800000`
  - yearly: `8400000`
- Parking layout is seeded as car-only with 30 slots in a `5 x 6` grid: `A1..E6`.
- Admin assignment is handled by selecting a real staff member, then creating an operations task.
- Staff only see their assigned tasks from `operations-service`.

## Known Gaps And Limitations

- Authentication is not yet a full production auth stack. There is still no JWT-based authorization layer across services.
- The current auth flow still relies on direct user lookup and client-side stored session objects.
- Many secondary admin actions in Flutter are still local-only helpers rather than persisted backend workflows:
  - schedule
  - notify
  - export/import packs
  - track/monitor/generate dialogs
- Some resident/staff management helper actions are still UI-level only.
- The React portal is not feature-complete relative to Flutter.
- Email sending now reads the correct `SPRING_MAIL_*` variables, but real delivery still depends on valid SMTP credentials.

## Environment Notes

Common backend configuration:

- PostgreSQL per service with `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`
- schema mode with `SPRING_JPA_HIBERNATE_DDL_AUTO`

Mail-related environment variables used by auth and billing:

- `SPRING_MAIL_HOST`
- `SPRING_MAIL_PORT`
- `SPRING_MAIL_USERNAME`
- `SPRING_MAIL_PASSWORD`
- `SPRING_MAIL_PROPERTIES_MAIL_SMTP_AUTH`
- `SPRING_MAIL_PROPERTIES_MAIL_SMTP_STARTTLS_ENABLE`

Billing payment integration:

- `PAYOS_CLIENT_ID`
- `PAYOS_API_KEY`
- `PAYOS_CHECKSUM_KEY`
- `PAYOS_RETURN_URL`
- `PAYOS_CANCEL_URL`

Flutter compile-time overrides:

- `API_HOST`
- `AUTH_API_URL`
- `BILLING_API_URL`
- `FACILITY_API_URL`
- `SECURITY_API_URL`
- `OPERATIONS_API_URL`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`

React environment variables:

- `VITE_API_BASE`
- `VITE_AUTH_API_BASE`
- `VITE_BILLING_API_BASE`

## Docs In This Folder

- `README.md`: project status and structure
- `feature-matrix.md`: what is real, partial, or still demo
- `api-overview.md`: actual endpoints exposed by the microservices
