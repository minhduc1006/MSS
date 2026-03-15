# MSS Microservices

Each domain runs as an independent Spring Boot service with its own PostgreSQL database.

## Services

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
cd be_microservices/auth-service && mvn spring-boot:run
cd be_microservices/billing-service && mvn spring-boot:run
cd be_microservices/facility-service && mvn spring-boot:run
cd be_microservices/security-service && mvn spring-boot:run
cd be_microservices/operations-service && mvn spring-boot:run
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
