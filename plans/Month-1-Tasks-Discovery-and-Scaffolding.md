# Month 1: Discovery, Architecture, Scaffolding & Dev Environments (Weeks 1–4)

**Objective:** Establish the parallel greenfield development environment, scaffold the 8 microservices and 2 React SPAs, freeze Flutter API contracts, and build Stage 1 of the ETL data pipeline.  
**Acceptance Gate 1:** All 8 microservice skeletons, API Gateway, and 2 React frontends running cleanly in an isolated local Docker Compose cluster with automated CI checks passing.

---

## Week 1: Monorepo Scaffolding & Core Architecture Standards

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M1-W1-ARCH-01` Scaffold pnpm Monorepo Workspace:**
  - **Files:** `/pnpm-workspace.yaml`, `/package.json`, `/.npmrc`, `/tsconfig.base.json`, `/.eslintrc.js`.
  - **Technical Spec:** Configure workspace packages: `apps/*` (`api-gateway`, `iam-service`, `store-service`, `catalog-service`, `inventory-service`, `order-service`, `fleet-service`, `finance-service`, `notify-service`, `admin-react`, `vendor-react`), and `packages/*` (`common`, `types`, `kysely-db`, `eslint-config`).
  - **ESLint Boundaries:** Configure `eslint-plugin-boundaries` prohibiting any microservice from importing another microservice's internal code. Only shared contracts from `@fattakse/common` and `@fattakse/types` are permitted.
  - **DoD:** `pnpm install` resolves dependencies across all 11 packages in < 45 seconds with zero hoisting conflicts.

- **`M1-W1-ARCH-02` Shared Core Library (`@fattakse/common`):**
  - **Files:** `packages/common/src/bootstrap.ts`, `packages/common/src/filters/flutter-exception.filter.ts`, `packages/common/src/logger/pino.logger.ts`, `packages/common/src/dto/pagination.dto.ts`.
  - **Fastify Bootstrap:** Standardize `@nestjs/platform-fastify` bootstrap with gzip compression, helmet security headers, and CORS configured for mobile and admin origins.
  - **Exception Filter:** Implement `FlutterExceptionFilter` intercepting all exceptions and serializing `{ errors: [{ code: string, message: string }] }`.
  - **DoD:** Unit tests assert that standard NestJS exceptions (`NotFoundException`, `BadRequestException`) emit exact Laravel error arrays.

- **`M1-W1-ARCH-03` Edge Router & API Gateway Specification:**
  - **Files:** `apps/api-gateway/src/gateway.module.ts`, `apps/api-gateway/src/proxy.service.ts`.
  - **Technical Spec:** Fastify proxy routes `/api/v1/auth/*` -> `iam-service:3001`, `/api/v1/stores/*` -> `store-service:3002`, `/api/v1/items/*` -> `catalog-service:3003`, `/api/v1/cart/*` & `/order/*` -> `order-service:3005`, `/api/v1/delivery-man/*` -> `fleet-service:3006`, `/api/v1/payment/*` -> `finance-service:3007`.
- **`M1-W1-ARCH-04` Event Streaming Contracts & Schemas (`@fattakse/event-contracts`):**
  - **Files:** `packages/event-contracts/src/events/*.ts`, `packages/event-contracts/src/topics.ts`.
  - **Technical Spec:** Strongly typed event schemas for `OrderLifecycleEvent`, `RiderTelemetryPing`, `InventoryAdjustmentEvent`, and `FinanceTransactionEvent`. Define standard topic constants and partition key resolvers.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M1-W1-BE1-01` Scaffold `iam-service` Skeleton:**
  - **Files:** `apps/iam-service/src/main.ts`, `apps/iam-service/src/iam.module.ts`, `apps/iam-service/src/health/health.controller.ts`.
  - **Technical Spec:** Configure port `3001`, register Kysely module pointing to `fattakse_iam`. Add Terminus health checks for DB and Redis connectivity.
  - **DoD:** `GET /health` returns `{ status: "ok", info: { db: { status: "up" }, redis: { status: "up" } } }`.

- **`M1-W1-BE1-02` Scaffold `store-service` Skeleton:**
  - **Files:** `apps/store-service/src/main.ts`, `apps/store-service/src/store.module.ts`.
  - **Technical Spec:** Configure port `3002`, register Kysely module pointing to `fattakse_store`. Module structure: `stores`, `zones`, `configs`.
  - **DoD:** Boots on Fastify with `/health` endpoint responding in < 10ms.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M1-W1-BE2-01` Scaffold `catalog-service` Skeleton:**
  - **Files:** `apps/catalog-service/src/main.ts`, `apps/catalog-service/src/catalog.module.ts`.
  - **Technical Spec:** Configure port `3003`, register Kysely module pointing to `fattakse_catalog`. Module structure: `items`, `categories`, `brands`, `variants`, `search`.
- **`M1-W1-BE2-02` Setup Typesense Client SDK (`@fattakse/typesense`):**
  - **Files:** `packages/typesense/src/client.ts`, `packages/typesense/src/schemas/product.schema.ts`.
  - **Technical Spec:** Wrapper around `typesense` npm package with exponential retry backoff, health ping, and schema definition matching 28.0 cluster.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Core)
- **`M1-W1-BE3-01` Scaffold `order-service` Skeleton:**
  - **Files:** `apps/order-service/src/main.ts`, `apps/order-service/src/order.module.ts`. Configure port `3005`, pointing to `fattakse_order`.
- **`M1-W1-BE3-02` Scaffold `inventory-service` Skeleton:**
  - **Files:** `apps/inventory-service/src/main.ts`, `apps/inventory-service/src/inventory.module.ts`. Configure port `3004`, pointing to `fattakse_inventory`.
- **`M1-W1-BE3-03` Scaffold `fleet-service`, `finance-service` & `notify-service` Skeletons:**
  - **Files:** Skeletons for ports `3006`, `3007`, and `3008`.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M1-W1-FE1-01` Scaffold `admin-react` Shell:**
  - **Files:** `apps/admin-react/vite.config.ts`, `apps/admin-react/src/App.tsx`, `apps/admin-react/src/routes.tsx`.
  - **Technical Spec:** Vite 6 + React 19 + TypeScript. Tailwind CSS v4 + shadcn/ui. Responsive dashboard layout with sidebar navigation, breadcrumbs, header with user avatar, and dark mode toggle.
  - **DoD:** `pnpm dev` starts in < 300ms on port `5173`.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Dark Store)
- **`M1-W1-FE2-01` Scaffold `vendor-react` Shell:**
  - **Files:** `apps/vendor-react/vite.config.ts`, `apps/vendor-react/src/App.tsx`.
  - **Technical Spec:** Vite 6 + React 19 + TypeScript. Tablet/mobile-optimized layouts for Dark Store Picker queue and Kitchen Display Screen (KDS).
  - **Audio Engine:** Setup Howler.js / Web Audio API wrapper with pre-loaded high-contrast chime sounds.

#### DATA (Database Architect & ETL Data Engineer)
- **`M1-W1-DATA-01` Scaffold 8 Logical Schemas in MySQL 8.0:**
  - **Files:** `packages/kysely-db/src/schemas/*.sql`.
  - **Technical Spec:** Create 8 database schemas: `fattakse_iam`, `fattakse_store`, `fattakse_catalog`, `fattakse_inventory`, `fattakse_order`, `fattakse_fleet`, `fattakse_finance`, `fattakse_notify`.
  - **User Isolation:** Create isolated MySQL users (`iam_user`, `catalog_user`, `order_user`, etc.) with permissions strictly confined to their own schema.
  - **DoD:** `CREATE USER` and `GRANT` scripts execute cleanly; cross-schema queries trigger MySQL Error 1142 (command denied).

#### QA (SDET / Automation Engineer)
- **`M1-W1-QA-01` Setup Monorepo Testing Pipeline:**
  - Configure Vitest workspaces and Supertest across all packages. Configure GitHub Actions workflow running tests and verifying > 85% branch coverage.

---

## Week 2: Isolated Development Environment & Infrastructure

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M1-W2-ARCH-01` Root Docker Compose Infrastructure (`docker-compose.dev.yml`):**
  - **Services:** MySQL 8.0 (8 logical databases), Redis 7.2.4 (persistence enabled), Redpanda / Kafka (v24.2.x C++ broker on port 9092 + Redpanda Console on port 8080), Typesense 28.0 (mounted volume), MailHog (SMTP mock).
  - **DoD:** `docker compose -f docker-compose.dev.yml up -d` boots all infra healthy in < 30 seconds with Redpanda broker ready.
- **`M1-W2-ARCH-02` Environment Variable Standards & Enforcement:**
  - Define `.env.example` templates across all packages with `dotenv-safe` validation preventing boot on missing variables.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M1-W2-BE1-01` Connect IAM & Store Services to Isolated Schemas:**
  - Configure Kysely connection pool (min: 2, max: 10 connections) pointing to `fattakse_iam` and `fattakse_store`.
  - Implement health ping routes in both services verifying database read latency < 5ms.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M1-W2-BE2-01` Connect Catalog Service to Typesense & Redis:**
  - Wire Redis BullMQ connection to `redis:6379`.
  - Test index creation in Typesense 28.0 (`product_catalog_v1`) with fuzzy search schema definitions.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Core)
- **`M1-W2-BE3-01` Configure Kafka Client & Redis Task Queues:**
  - Setup `@nestjs/microservices` Kafka client wrapper in `packages/common/kafka` with `kafkajs`.
  - Initialize core topics with partition configs: `fattakse.orders.lifecycle` (3 partitions), `fattakse.riders.telemetry` (3 partitions), `fattakse.inventory.adjustments` (3 partitions), `fattakse.finance.transactions` (3 partitions).
  - Setup BullMQ queue definitions for delayed timers: `kitchen-sla-timer-queue`, `otp-expiry-queue`, `webhook-retry-queue`.
  - Verify Kysely connection pool to `fattakse_order` and `fattakse_inventory`.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M1-W2-FE1-01` Configure TanStack Query v5 in `admin-react`:**
  - Setup `QueryClient` with 5-minute stale time, global retry logic, and toast notifications on HTTP 4xx/5xx errors.
  - Configure Mock Service Worker (MSW) for offline frontend development.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Dark Store)
- **`M1-W2-FE2-01` Configure TanStack Query v5 in `vendor-react`:**
  - Configure polling intervals for KDS orders (5-second polling fallback if WebSockets disconnect).
  - Build responsive viewport switcher testing tablet landscape (1024x768) and mobile portrait (375x812).

#### DATA (Database Architect & ETL Data Engineer)
- **`M1-W2-DATA-01` Develop Idempotent Seed Scripts:**
  - **Files:** `packages/kysely-db/src/seeds/dev_seed.ts`.
  - **Seed Scope:** 1 Super Admin, 1 Tirora Dark Store Manager, 3 Local Tirora Merchants, 5 Delivery Riders, 20 Grocery Categories, 100 Sample Products with barcodes, and 1 Tirora Spatial Delivery Zone polygon.

#### QA (SDET / Automation Engineer)
- **`M1-W2-QA-01` Automated Stack Liveness Verification:**
  - Write bash validation script (`scripts/verify-dev-stack.sh`) testing HTTP health endpoints across all 8 microservices, Redis, Typesense, and MySQL.

---

## Week 3: API Contract Freezing & CI/CD Pipelines

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M1-W3-ARCH-01` Authoritative OpenAPI 3.1 Contract Generation:**
  - **Files:** `packages/types/openapi/fattakse-v1.yaml`.
  - Generate complete OpenAPI 3.1 document covering all 431 legacy `/api/v1/*` routes with request headers, parameters, DTO schemas, and response examples.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M1-W3-BE1-01` Gateway Header Normalization Interceptor:**
  - **Files:** `apps/api-gateway/src/interceptors/header-normalizer.interceptor.ts`.
  - Normalizes `zoneId`: if passed as `"[1]"`, parses JSON string to integer array `[1]`; if passed as `1`, wraps into `[1]`. Normalizes `latitude` and `longitude` to float numbers.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M1-W3-BE2-01` Gateway Pagination Envelope Transformer:**
  - **Files:** `apps/api-gateway/src/interceptors/pagination.interceptor.ts`.
  - Ensures all paginated responses serialize `{ total_size: number, limit: string, offset: string, products: Array }` with stringified limits/offsets matching legacy behavior.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Core)
- **`M1-W3-BE3-01` Redis Idempotency Middleware:**
  - **Files:** `apps/api-gateway/src/middleware/idempotency.middleware.ts`.
  - Checks `X-Idempotency-Key` on `POST` requests; caches response for 24 hours in Redis; rejects concurrent duplicate requests with HTTP 409 Conflict.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M1-W3-FE1-01` Generate Typed API Hooks for Admin:**
  - Run `openapi-typescript` generating full TypeScript type interfaces from `fattakse-v1.yaml` for `admin-react`.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Dark Store)
- **`M1-W3-FE2-01` Generate Typed API Hooks for Vendor:**
  - Generate typed client hooks from `fattakse-v1.yaml` for `vendor-react`.

#### DATA (Database Architect & ETL Data Engineer)
- **`M1-W3-DATA-01` Automated Schema Mapping Dictionary:**
  - **Files:** `etl/mappings/table_column_map.json`.
  - Detail table-by-table column transformations from monolithic schema to 8 domain schemas (e.g. `items.unit_id` -> `units.id`).

#### QA (SDET / Automation Engineer)
- **`M1-W3-QA-01` Automated Schema Diffing Test Suite:**
  - **Files:** `qa/contract_diff_runner.ts`.
  - Tool queries reference Laravel instance, queries Node.js Gateway instance, and diffs JSON response ASTs asserting zero structural variance.

---

## Week 4: Stage 1 ETL Data Pipeline & React Shells

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M1-W4-ARCH-01` GitHub Actions Quality Gate CI:**
  - Configure GitHub Actions pipeline: `pnpm lint`, `pnpm typecheck`, `pnpm test`, and Docker image builds on every pull request.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M1-W4-BE1-01` Gateway Route Delegation:**
  - Wire actual HTTP proxying from `api-gateway` to downstream microservices using internal Docker network DNS.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M1-W4-BE2-01` Mock Catalog Responses on Gateway:**
  - Ensure `/api/v1/items/*` and `/api/v1/categories/*` return mock responses matching Flutter contracts.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Core)
- **`M1-W4-BE3-01` Mock Order & Checkout Responses:**
  - Ensure `/api/v1/order/*` and `/api/v1/cart/*` return mock responses matching Flutter contracts.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M1-W4-FE1-01` Deliver `admin-react` Base Pages:**
  - Implement complete login view, dashboard layout skeleton, breadcrumb navigation, and responsive sidebar.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Dark Store)
- **`M1-W4-FE2-01` Deliver `vendor-react` Base Pages:**
  - Implement dark store picker queue layout and KDS order card components. Test audio chime trigger on mock WebSocket events.

#### DATA (Database Architect & ETL Data Engineer)
- **`M1-W4-DATA-01` Stage 1 Base ETL Extraction Engine:**
  - **Files:** `etl/stage1_extract_and_load.py`, `etl/transformers/*.py`.
  - Python script using `pymysql` and `sqlalchemy` reading from a sanitized production SQL dump. Chunks extraction into 2,000-row batches, transforms columns, and bulk-inserts into target domain databases.
- **`M1-W4-DATA-02` PII Anonymization Layer:**
  - Replace real phone numbers with `+919999000000` + sequential ID. Replace emails with `user_{id}@fattakse.local`. Re-hash passwords with standard Bcrypt cost 10.
- **`M1-W4-DATA-03` ETL Data Integrity Verification Script:**
  - Assert that record counts match between source and target for users, categories, products, and zones.

#### QA (SDET / Automation Engineer)
- **`M1-W4-QA-01` Execute Gate 1 Acceptance Certification:**
  - Verify all 8 microservices, API Gateway, 2 React frontends, and dev databases boot cleanly.
  - Run Stage 1 ETL script on sanitized dump; verify 100% data ingestion with zero errors.

---

## Gate 1 Acceptance Verification Sign-Off
- [ ] Monorepo bootstrapped with strict pnpm workspace boundaries.
- [ ] Docker Compose boots all 8 Node.js microservices, MySQL 8.0 (8 schemas), Redis 7.2, and Typesense 28.0.
- [ ] OpenAPI 3.1 specifications frozen for all 431 legacy routes.
- [ ] Stage 1 ETL script successfully loads sanitized data into target schemas.
- [ ] CI pipeline 100% green with > 85% branch coverage on shared libraries.
