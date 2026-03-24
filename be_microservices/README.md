# MSS Microservices

Each domain runs as an independent Spring Boot service with its own PostgreSQL database.

## Services

- `gateway-service` on `8080`
- `auth-service` on `8081`
- `billing-service` on `8082`
- `facility-service` on `8083`
- `security-service` on `8084`
- `operations-service` on `8085`

## IntelliJ / Maven Import

Open the backend workspace from [pom.xml](/d:/FULearning/Spring2026/MSS/MSS_Project/project/be_microservices/pom.xml) at the `be_microservices` root so IntelliJ imports all services as Maven modules and resolves shared dependencies correctly.

## Databases

All services share the same PostgreSQL server:

- username: `postgres`
- password: `postgres`

Each service uses a separate database:

- `mss_auth`
- `mss_billing`
- `mss_facility`
- `mss_security`
- `mss_operations`

## Gateway

`gateway-service` is a Spring Cloud Gateway entrypoint that proxies all current APIs through a single port:

- auth: `/api/auth/**`, `/api/users/**`
- billing: `/api/billing/**`, `/api/apartments/**`, `/api/tenancies/**`, `/api/utilities/**`
- facility: `/api/facilities/**`, `/api/bookings/**`, `/api/announcements/**`
- security: `/api/security/**`
- operations: `/api/operations/**`

Default gateway URL:

```bash
http://localhost:8080
```

Health endpoint:

```bash
http://localhost:8080/actuator/health
```

## Run Everything With Docker

```bash
cd be_microservices
docker compose up --build
```

Run in background:

```bash
cd be_microservices
docker compose up -d --build
```

Stop everything:

```bash
cd be_microservices
docker compose down
```

Stop everything and remove the PostgreSQL volume:

```bash
cd be_microservices
docker compose down -v
```

## Run Only PostgreSQL With Docker

```bash
cd be_microservices
docker compose up -d postgres
```

## Run Services Locally

You can still run the Spring Boot services on your machine. In that case, start PostgreSQL first and let the apps use their default `localhost:5432` datasource values.

```bash
cd be_microservices/gateway-service && mvn spring-boot:run
cd be_microservices/auth-service && mvn spring-boot:run
cd be_microservices/billing-service && mvn spring-boot:run
cd be_microservices/facility-service && mvn spring-boot:run
cd be_microservices/security-service && mvn spring-boot:run
cd be_microservices/operations-service && mvn spring-boot:run
```

## Point Frontends To Gateway

React env example:

```env
VITE_AUTH_API_BASE=http://localhost:8080/api
VITE_BILLING_API_BASE=http://localhost:8080/api
VITE_FACILITY_API_BASE=http://localhost:8080/api
VITE_SECURITY_API_BASE=http://localhost:8080/api/security
VITE_OPERATIONS_API_BASE=http://localhost:8080/api/operations
```

Flutter run example:

```bash
flutter run --dart-define=AUTH_API_URL=http://127.0.0.1:8080 --dart-define=BILLING_API_URL=http://127.0.0.1:8080 --dart-define=FACILITY_API_URL=http://127.0.0.1:8080 --dart-define=SECURITY_API_URL=http://127.0.0.1:8080 --dart-define=OPERATIONS_API_URL=http://127.0.0.1:8080
```

## PayOS

`billing-service` reads PayOS credentials from `be_microservices/.env` via Docker Compose:

```env
PAYOS_CLIENT_ID=...
PAYOS_API_KEY=...
PAYOS_CHECKSUM_KEY=...
PAYOS_RETURN_URL=
PAYOS_CANCEL_URL=
```

Notes:

- `PAYOS_RETURN_URL` and `PAYOS_CANCEL_URL` can stay empty for the current Flutter Android emulator flow because the app sends them dynamically.
- The PayOS webhook must point to a public URL that can reach `POST /api/billing/payos/webhook`. A local `localhost` or `10.0.2.2` URL will not be reachable by PayOS.
- For local end-to-end payment confirmation, expose `billing-service` with a tunnel such as `ngrok` or `cloudflared`, then configure the public webhook URL in the PayOS dashboard.
