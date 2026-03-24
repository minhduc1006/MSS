# API Overview

This file lists the HTTP endpoints that exist in the current Spring Boot services.

## Services And Ports

| Service | Port | Base Mapping |
| --- | --- | --- |
| `auth-service` | `8081` | `/api` |
| `billing-service` | `8082` | `/api` |
| `facility-service` | `8083` | `/api` |
| `security-service` | `8084` | `/api/security` |
| `operations-service` | `8085` | `/api/operations` |

## auth-service

Base URL: `http://localhost:8081/api`

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/auth/login` | Login with email, password, and target role |
| `POST` | `/auth/reset-password/request-otp` | Send reset OTP |
| `POST` | `/auth/reset-password/verify-otp` | Verify OTP and return reset token |
| `POST` | `/auth/reset-password/complete` | Complete password reset |
| `GET` | `/users/residents` | List residents |
| `POST` | `/users/residents` | Create resident |
| `DELETE` | `/users/residents/{id}` | Deactivate resident |
| `POST` | `/users/residents/{id}/activate` | Reactivate resident |
| `GET` | `/users/staff` | List staff |
| `POST` | `/users/staff` | Create staff |
| `PUT` | `/users/staff/{id}` | Update staff |
| `DELETE` | `/users/staff/{id}` | Deactivate staff |
| `POST` | `/users/staff/{id}/activate` | Reactivate staff |
| `GET` | `/users/{id}` | Get user by id |
| `GET` | `/users/by-email` | Get user by email |
| `GET` | `/users/{id}/account` | Account profile |
| `GET` | `/users/{id}/settings` | Account settings payload |
| `POST` | `/users/{id}/change-password` | Change password |

## billing-service

Base URL: `http://localhost:8082/api`

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/billing/overview` | Billing summary and invoice list |
| `GET` | `/billing/resident/{residentId}` | Resident invoice list |
| `POST` | `/billing/invoices` | Create invoice |
| `PUT` | `/billing/invoices/{invoiceId}` | Update invoice |
| `POST` | `/billing/invoices/{invoiceId}/status` | Update invoice status |
| `DELETE` | `/billing/invoices/{invoiceId}` | Deactivate invoice |
| `POST` | `/billing/{invoiceId}/send-email` | Send invoice email |
| `POST` | `/billing/{invoiceId}/pay` | Mark invoice as paid |
| `POST` | `/billing/{invoiceId}/checkout` | Create PayOS checkout session |
| `POST` | `/billing/payos/webhook` | Receive PayOS webhook |
| `GET` | `/billing/payos/return` | Browser return page |
| `GET` | `/billing/payos/cancel` | Browser cancel page |
| `GET` | `/apartments` | Apartment unit stats and list |
| `POST` | `/apartments` | Create apartment unit |
| `PUT` | `/apartments/{unitId}` | Update apartment unit |
| `POST` | `/apartments/{unitId}/status` | Update apartment unit status |
| `DELETE` | `/apartments/{unitId}` | Deactivate apartment unit |
| `GET` | `/tenancies` | Lease portfolio overview and records |
| `POST` | `/tenancies` | Create tenancy / lease record |
| `PUT` | `/tenancies/{tenancyId}` | Update tenancy / lease record |
| `POST` | `/tenancies/{tenancyId}/status` | Update tenancy status |
| `GET` | `/utilities/meters` | Utility meter overview and submissions |
| `POST` | `/utilities/meters` | Create utility meter submission |
| `PUT` | `/utilities/meters/{meterId}` | Update utility meter submission |
| `POST` | `/utilities/meters/{meterId}/status` | Update utility meter status |
| `POST` | `/utilities/meters/{meterId}/generate-invoice` | Generate utility invoice from a meter reading |

## facility-service

Base URL: `http://localhost:8083/api`

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/facilities` | Facilities bundle with logs and announcements |
| `POST` | `/facilities` | Create facility or service |
| `PUT` | `/facilities/{facilityId}` | Update facility or service |
| `POST` | `/facilities/{facilityId}/status` | Update facility status |
| `DELETE` | `/facilities/{facilityId}` | Deactivate facility |
| `POST` | `/facilities/{facilityId}/logs` | Add maintenance log |
| `GET` | `/bookings/resident/{residentId}` | Resident bookings |
| `POST` | `/bookings/resident/{residentId}` | Create resident booking |
| `GET` | `/announcements` | Building announcements |

Current seeded service groups include:

- free shared facilities: pool, gym, lounge
- operations facility examples: elevator, lobby lighting
- paid in-unit services: housekeeping, home repair, AC cleaning
- paid car parking subscription with 30 slots `A1..E6`

## security-service

Base URL: `http://localhost:8084/api/security`

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/overview` | Security overview dashboard data |
| `POST` | `/incidents` | Create incident |
| `PUT` | `/incidents/{incidentId}` | Update incident |
| `POST` | `/incidents/{incidentId}/status` | Update incident status |
| `DELETE` | `/incidents/{incidentId}` | Deactivate incident |
| `POST` | `/sos` | Trigger SOS incident |
| `GET` | `/history?userId={id}&audience={role}` | Get history by query params |
| `GET` | `/history/{audience}/{userId}` | Get history by path params |

## operations-service

Base URL: `http://localhost:8085/api/operations`

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/activity` | Admin activity feed |
| `GET` | `/staff/{staffId}/tasks` | Task bundle for a staff member |
| `POST` | `/tasks` | Create staff task |
| `GET` | `/packages` | Package desk and lost-found queue |
| `GET` | `/packages/resident/{residentId}` | Resident package / lost-found history |
| `POST` | `/packages` | Create parcel or lost-found record |
| `POST` | `/packages/{packageId}/status` | Update parcel or lost-found status |
| `GET` | `/complaints` | Complaint / feedback ticket queue |
| `GET` | `/complaints/resident/{residentId}` | Resident complaint history |
| `GET` | `/complaints/staff/{staffId}` | Staff complaint assignment queue |
| `POST` | `/complaints` | Create complaint or feedback ticket |
| `POST` | `/complaints/{complaintId}/assign` | Assign complaint to staff |
| `POST` | `/complaints/{complaintId}/status` | Update complaint status / response |
| `POST` | `/complaints/{complaintId}/rating` | Save resident service rating after resolution |
| `GET` | `/shifts` | Full shift roster |
| `GET` | `/shifts/staff/{staffId}` | Shift roster for one staff member |
| `POST` | `/shifts` | Create duty roster entry |
| `POST` | `/shifts/{shiftId}` | Update duty roster entry |

## Client Usage Notes

Flutter API host resolution:

- default host is derived inside `AppApiService`
- each service can be overridden independently with Dart defines

React API usage:

- `VITE_AUTH_API_BASE` defaults to `http://localhost:8081/api`
- `VITE_BILLING_API_BASE` defaults to `http://localhost:8082/api`
- most React pages do not yet consume the backend APIs listed here
