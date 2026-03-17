# Feature Matrix

This matrix reflects the implementation currently present in the repository as of 2026-03-17.

Status legend:

- `Real`: backed by Spring Boot service logic and used by the client
- `Partial`: some parts are real, but related actions still rely on local state or demo flow
- `Demo`: present in UI only or mostly hard-coded

| Domain | Flow | Backend | Flutter | React | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Auth | Login with role selection | Yes | Yes | Yes | Real | Flutter and React both map backend auth errors to controlled messages |
| Auth | Password reset via OTP | Yes | Yes | Yes | Real | Request OTP, verify OTP, complete reset are implemented |
| Auth | Change password | Yes | Yes | No | Partial | Available in backend and Flutter account flow |
| Auth | Resident list/create/delete/activate | Yes | Yes | No | Real | React resident page is still mock |
| Auth | Staff list/create/update/delete/activate | Yes | Yes | No | Real | React staff page is still mock |
| Auth | Google sign-in | Partial | Partial | Partial | Partial | Flutter has Google Sign-In integration with fallback role mapping; React only has a dev helper endpoint in `server.ts` |
| Billing | Billing overview | Yes | Yes | Yes | Real | Real API on backend and both clients |
| Billing | Invoice create/update/status/deactivate | Yes | Yes | Partial | Partial | React billing page supports main billing actions; Flutter admin screen is more complete |
| Billing | Invoice email | Yes | Yes | Yes | Real | SMTP config must still be valid in environment |
| Billing | Direct mark-as-paid | Yes | Yes | No | Real | Backend pay endpoint exists and Flutter uses it |
| Billing | PayOS checkout + webhook | Yes | Yes | No | Real | Checkout URL comes from billing-service |
| Billing | Apartment administration CRUD/status | Yes | Yes | No | Real | Implemented in billing-service and Flutter admin apartment screen |
| Billing | Export/import/track/monitor/generate helpers | No | Yes | No | Partial | These dialogs and CSV helpers remain Flutter-local |
| Facilities | Facility list | Yes | Yes | No | Real | Backend returns facilities, logs, and announcements bundle |
| Facilities | Facility create/update/status/deactivate | Yes | Yes | No | Real | Admin Flutter screen now persists these actions |
| Facilities | Maintenance logs | Yes | Yes | No | Real | Log creation persists in backend |
| Facilities | Resident bookings for shared facilities | Yes | Yes | No | Real | Pool, gym, lounge bookings are real in backend + Flutter |
| Facilities | Paid in-unit services | Yes | Yes | No | Real | Housekeeping, home repair, AC cleaning |
| Facilities | Car parking subscription | Yes | Yes | No | Real | Car-only parking, monthly/yearly pricing, 30 slots `A1..E6` |
| Facilities | Assign facility work to staff | Yes | Yes | No | Real | Uses `operations-service` task creation |
| Facilities | Schedule/notify/export/import/track/monitor/generate | No | Yes | No | Partial | Visible in Flutter but not persisted as backend workflows |
| Security | Incident overview | Yes | Yes | No | Real | Overview metrics and incident data come from backend |
| Security | Incident create/update/status/deactivate | Yes | Yes | No | Real | Admin Flutter screen persists these changes |
| Security | SOS trigger | Yes | Yes | No | Real | Resident emergency flow calls backend |
| Security | Resident/staff history | Yes | Yes | No | Real | History endpoints exist and are used in Flutter |
| Security | Assign incident to staff | Yes | Yes | No | Real | Admin selects real staff and creates operations task |
| Security | Schedule/notify/export/import/track/monitor/generate | No | Yes | No | Partial | Still UI helpers in Flutter |
| Operations | Activity feed | Yes | Yes | No | Real | Admin activity screen uses backend |
| Operations | Staff task queue | Yes | Yes | No | Real | Staff facilities screen loads assigned tasks only |
| Resident UX | Resident dashboard summary | Partial | Yes | Yes | Partial | Flutter loads real supporting data; React dashboard is mock-heavy |
| Resident UX | Resident bills page | Yes | Yes | No | Real | Flutter resident bills uses backend |
| Resident UX | Resident bookings page | Yes | Yes | No | Real | Includes services and parking subscription flow |
| Resident UX | Resident account/settings | Partial | Yes | Yes | Partial | Flutter supports real account fetch/change password; React account page is mostly static |
| Admin UX | Resident management assign/notify/export/import/track/monitor/generate | No | Yes | No | Partial | CRUD is real, but helper workflows are not persisted |
| Admin UX | Staff settings pricing/config import-export | No | Yes | No | Demo | Local utility screen only |
| React portal | Admin dashboards and module pages outside billing | No | No | Yes | Demo | Mostly static arrays and UI showcase pages |

## Summary

The current project should be understood as:

- backend: real for the core business flows listed above
- Flutter: primary real client, with some admin helper actions still local-only
- React: secondary/demo portal with only auth reset and billing significantly connected to backend
