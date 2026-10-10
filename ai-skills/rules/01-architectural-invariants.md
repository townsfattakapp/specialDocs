# Architectural Invariants Rule

This rule is ALWAYS active for any agent or engineer operating in the Fattakse codebase.

## 1. Production Integrity
- **Live Production VPS (`145.223.19.105`) is strictly READ-ONLY.**
- Never execute write operations, schema migrations, or destructive commands directly against production databases or servers.
- The existing PHP 8.2 / Laravel 12 monolith (`towns_fattakse_in`) is the **executable reference specification** for all business rules, tax formulas, and legacy contracts.

## 2. Microservice Boundaries & Single-Writer Rule
- The greenfield target architecture consists of 8 isolated services:
  `iam`, `store`, `catalog`, `inventory`, `order`, `fleet`, `finance`, `notify`, fronted by `api-gateway`.
- **Single-Writer Rule:** Each service owns its dedicated logical database (`fattakse_iam`, `fattakse_catalog`, etc.).
- **Zero Cross-Service Joins:** Direct cross-database SQL queries or table joins between microservices are strictly prohibited.
- Communication between services must occur via **gRPC / internal HTTP APIs** (synchronous queries) or **Redpanda / Kafka event streams** (asynchronous state changes).

## 3. Technology Stack Constraints
- **Backend Services:** Node.js 22 LTS, TypeScript 5.6+, NestJS 11 or Fastify 5.
- **Relational Databases:** MySQL 8.4 LTS with isolated single-writer schemas.
- **Containerization & Ingress:** Docker (multi-stage builds) and Nginx (reverse proxy, TLS 1.3, rate limiting).
- **ORM / Query Builder:** Prisma or Kysely with strict type-safety.
- **Portals:** React 19, TypeScript, TailwindCSS, Zustand / TanStack Query.
- **Event Streaming:** Redpanda / Apache Kafka (`kafkajs`) with Transactional Outbox.
- **Delayed Timers & Caching:** Redis 7.2 BullMQ (3-min SLA, 10-min OTP).
- **Search & Filtering:** Typesense 28.0 (sub-50ms typo-tolerant search).

## 4. Hyper POS Retirement (ADR-0004)
- Offline walk-in counter retail POS is permanently decommissioned.
- Never resurrect `pos_*` or `hyper_pos_*` tables or routes in target microservices.
- All dark store warehouse operations use native digital **Pick & Pack** queues in `vendor-react`.

## 5. Standard Engineering Toolchain & Platform Stack
- **Code & CI/CD:** GitHub + GitHub Actions (automated test, build, lint, scan), GitHub Projects (sprint Kanban).
- **Quality & Security:** SonarQube Community Build (Quality Gate), Gitleaks (pre-commit secrets scan), Trivy (CVE scans), OWASP ZAP (DAST penetration testing).
- **Testing:** Testcontainers (disposable Docker containers in Vitest), Playwright (browser E2E for Admin/Vendor/Web), Bruno (git-friendly API collections), k6 (load/concurrency).
- **Observability & Error Tracking:** Prometheus + Grafana (metrics & alerts), Grafana Loki (logs), OpenTelemetry (tracing), Sentry (crash monitoring), Uptime Kuma (heartbeat & public status).
- **Disaster Recovery & Hygiene:** Restic + Off-site Storage (Wasabi / S3 Glacier), Renovate (dependency updates), OpenAPI 3.1 (contracts), MkDocs Material (documentation site).

