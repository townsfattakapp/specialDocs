# Month 1 Task Prompts: Discovery, Scaffolding & Dev Environments (Weeks 1–4)

This document contains production-grade, copy-pasteable execution prompts for each task in Month 1.

---

## Table of Contents
- [Week 1 Prompts](#week-1-monorepo-scaffolding--core-architecture-standards)
- [Week 2 Prompts](#week-2-isolated-development-environment--infrastructure)
- [Week 3 Prompts](#week-3-api-contract-freezing--cicd-pipelines)
- [Week 4 Prompts](#week-4-stage-1-etl-data-pipeline--react-shells)

---

## Week 1: Monorepo Scaffolding & Core Architecture Standards

### `[M1-W1-ARCH-01]` Scaffold pnpm Monorepo Workspace
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `/pnpm-workspace.yaml`, `/package.json`, `/.npmrc`, `/tsconfig.base.json`, `/.eslintrc.js`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization (Evolw Technologies Private Limited).

TASK: M1-W1-ARCH-01 - Scaffold pnpm Monorepo Workspace

CONTEXT:
We are migrating from a PHP 8.2 Laravel monolith to a high-performance Node.js 22 + TypeScript 5.6+ microservices architecture. All services must live in a single monorepo with strict architectural boundaries.

REQUIREMENTS:
1. Initialize a pnpm monorepo workspace in the root directory.
2. Configure pnpm-workspace.yaml with:
   - apps/*: api-gateway, iam-service, store-service, catalog-service, inventory-service, order-service, fleet-service, finance-service, notify-service, admin-react, vendor-react, user-web.
   - packages/*: common, types, kysely-db, event-contracts, eslint-config.
3. Configure .npmrc with strict settings:
   - auto-install-peers=true
   - shamefully-hoist=false
   - strict-peer-dependencies=false
4. Create tsconfig.base.json:
   - Target: ES2023, Module: NodeNext, moduleResolution: NodeNext, strict: true, noImplicitAny: true.
5. Setup .eslintrc.js with eslint-plugin-boundaries:
   - Explicitly forbid apps/* from importing directly from any sibling app.
   - Microservices can only import from @fattakse/common, @fattakse/types, @fattakse/kysely-db, and @fattakse/event-contracts.
6. Initialize GitHub Projects board with columns (Backlog, This Sprint, In Progress, Verification/Review, Done) and custom fields (Role: ARCH/BE1/BE2/BE3/FE1/FE2/DATA/QA, Sprint: W1-W20).
7. Configure MkDocs Material (mkdocs.yml) in root linking all docs/modernization/*.md specifications.
8. Verify dependency resolution with pnpm install.

DEFINITION OF DONE:
- Root pnpm install runs cleanly in < 45 seconds.
- An illegal import between apps triggers an immediate ESLint error.
- MkDocs Material site builds and serves locally on port 8000.
- GitHub Projects board is active with 8 FTE roles mapped.
```

---

### `[M1-W1-ARCH-02]` Shared Core Library (`@fattakse/common`)
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `packages/common/src/bootstrap.ts`, `packages/common/src/filters/flutter-exception.filter.ts`, `packages/common/src/logger/pino.logger.ts`, `packages/common/src/dto/pagination.dto.ts`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization.

TASK: M1-W1-ARCH-02 - Shared Core Library (@fattakse/common)

CONTEXT:
The existing Flutter mobile apps (Customer v1.0.18, Vendor v1.0.5, Rider v1.0.1) are frozen in production and cannot be recompiled. They expect all API errors to strictly adhere to the legacy Laravel exception payload: { "errors": [{ "code": string, "message": string }] }.

REQUIREMENTS:
1. Create packages/common/src/filters/flutter-exception.filter.ts:
   - Implement NestJS ExceptionFilter.
   - Catch HttpException, validation errors, and uncaught 500 errors.
   - Transform standard NestJS error payloads into { errors: [{ code: string, message: string }] }.
   - If error is validation error (class-validator), extract each field validation error into the errors array.
2. Create packages/common/src/bootstrap.ts:
   - Standardize Fastify bootstrap wrapper (@nestjs/platform-fastify).
   - Configure fastify helmet, compression (brotli/gzip), and CORS policy allowing *.fattakse.in, localhost:5173, and mobile apps.
3. Create packages/common/src/logger/pino.logger.ts:
   - Structured JSON logging using pino-http.
   - Redact sensitive PII fields: password, otp, token, card_number, fcm_token.
4. Create packages/common/src/dto/pagination.dto.ts:
   - Ensure pagination helper emits legacy Laravel format: { total_size: number, limit: string, offset: string, data: T[] }.
5. Write Vitest unit tests in packages/common/test/flutter-exception.filter.spec.ts asserting that HttpException(404, 'Item not found') serializes exact Laravel error array.

DEFINITION OF DONE:
- All unit tests pass with > 85% branch coverage.
- Package builds cleanly via tsup / tsc.
```

---

### `[M1-W1-ARCH-03]` Edge Router & API Gateway Specification
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `apps/api-gateway/src/gateway.module.ts`, `apps/api-gateway/src/proxy.service.ts`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization.

TASK: M1-W1-ARCH-03 - Edge Router & API Gateway Specification

CONTEXT:
The API Gateway is the central ingress proxy facing mobile apps and web frontends. It must reverse-proxy legacy /api/v1/* routes to the 8 downstream NestJS microservices while normalizing headers and isolating services.

REQUIREMENTS:
1. Scaffold apps/api-gateway using NestJS 11+ and Fastify HTTP engine.
2. Implement proxy route mapping table in proxy.service.ts:
   - /api/v1/auth/* -> iam-service (port 3001)
   - /api/v1/stores/* & /api/v1/zone/* -> store-service (port 3002)
   - /api/v1/items/* & /api/v1/categories/* -> catalog-service (port 3003)
   - /api/v1/cart/* & /api/v1/order/* & /api/v1/customer/order/* -> order-service (port 3005)
   - /api/v1/delivery-man/* -> fleet-service (port 3006)
   - /api/v1/payment/* & /api/v1/wallet/* -> finance-service (port 3007)
   - /api/v1/notifications/* -> notify-service (port 3008)
3. Implement Fastify proxy handler using @fastify/http-proxy with connection pooling, keep-alive, and a 500ms connection timeout.
4. Add /health check endpoint returning status of gateway and reachable downstream microservices.

DEFINITION OF DONE:
- Gateway starts on port 3000.
- Forwarded requests preserve query strings, headers, and authorization bearer tokens.
```

---

### `[M1-W1-ARCH-04]` Event Streaming Contracts & Schemas (`@fattakse/event-contracts`)
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `packages/event-contracts/src/events/*.ts`, `packages/event-contracts/src/topics.ts`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization.

TASK: M1-W1-ARCH-04 - Event Streaming Contracts & Schemas (@fattakse/event-contracts)

CONTEXT:
We use a hybrid event streaming backbone: Redpanda / Apache Kafka for high-throughput replayable domain events and Redis BullMQ for delayed timers (ADR-0010). We need strongly-typed event schemas shared across all microservices.

REQUIREMENTS:
1. Scaffold packages/event-contracts package.
2. Define Kafka topic constants in packages/event-contracts/src/topics.ts:
   - TOPIC_ORDERS_LIFECYCLE = 'fattakse.orders.lifecycle'
   - TOPIC_RIDERS_TELEMETRY = 'fattakse.riders.telemetry'
   - TOPIC_INVENTORY_ADJUSTMENTS = 'fattakse.inventory.adjustments'
   - TOPIC_FINANCE_TRANSACTIONS = 'fattakse.finance.transactions'
   - TOPIC_CATALOG_EVENTS = 'fattakse.catalog.events'
3. Create TypeScript interfaces and Zod validation schemas in packages/event-contracts/src/events/:
   - OrderLifecycleEvent: eventId, eventType (ORDER_CREATED, ORDER_CONFIRMED, ORDER_PICKED, ORDER_DISPATCHED, ORDER_DELIVERED, ORDER_CANCELLED), orderId, storeId, zoneId, totalAmount, paymentStatus, timestamp.
   - RiderTelemetryPing: riderId, latitude, longitude, speed, batteryPercentage, isOnline, activeOrderId, timestamp.
   - InventoryAdjustmentEvent: itemId, storeId, ownerType (evolw | seller), changeQty, newAvailableQty, reason, timestamp.
   - FinanceTransactionEvent: transactionId, orderId, debitAccount, creditAccount, amountPaisa, reference, timestamp.
4. Export partition key helper functions ensuring:
   - Order events partition by orderId.
   - Rider telemetry partitions by riderId.
   - Inventory events partition by itemId.

DEFINITION OF DONE:
- All event contracts compile cleanly to TypeScript declaration files (.d.ts).
- Zod schema parse tests pass for all event structures.
```

---

### `[M1-W1-BE1-01]` Scaffold `iam-service` Skeleton
**Assignee:** BE-1 (Senior Backend Engineer 1 — Auth & Edge)  
**Target Files:** `apps/iam-service/src/main.ts`, `apps/iam-service/src/iam.module.ts`, `apps/iam-service/src/health/health.controller.ts`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M1-W1-BE1-01 - Scaffold iam-service Skeleton

CONTEXT:
iam-service is responsible for customer phone OTP login, merchant/rider authentication, employee RBAC, and emulating Laravel Passport RSA JWT tokens.

REQUIREMENTS:
1. Scaffold apps/iam-service using NestJS 11+ and Fastify.
2. Set service port to 3001 via environment variable PORT.
3. Import @fattakse/common bootstrap and register FlutterExceptionFilter globally.
4. Setup Terminus health check controller at GET /health:
   - Verifies MySQL connectivity to database fattakse_iam.
   - Verifies Redis connectivity.
5. Create module structure:
   - src/auth/ (Customer OTP & Staff Login)
   - src/users/ (Profile management)
   - src/passport/ (Passport token emulator)
   - src/health/

DEFINITION OF DONE:
- pnpm --filter iam-service dev starts in < 1 second on port 3001.
- GET http://localhost:3001/health returns HTTP 200 with { status: "ok" }.
```

---

### `[M1-W1-BE1-02]` Scaffold `store-service` Skeleton
**Assignee:** BE-1 (Senior Backend Engineer 1 — Auth & Edge)  
**Target Files:** `apps/store-service/src/main.ts`, `apps/store-service/src/store.module.ts`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M1-W1-BE1-02 - Scaffold store-service Skeleton

CONTEXT:
store-service manages store profiles (dark stores, supermarkets, restaurants, paan corners), KYC approvals, operating hours, and MySQL spatial GIS delivery zones.

REQUIREMENTS:
1. Scaffold apps/store-service on port 3002 with Fastify.
2. Configure Kysely database connection pointing to schema fattakse_store.
3. Create modules:
   - src/stores/ (store CRUD and metadata)
   - src/zones/ (spatial polygon GIS operations)
   - src/health/
4. Implement Terminus health check.

DEFINITION OF DONE:
- Service boots on port 3002.
- GET http://localhost:3002/health returns HTTP 200.
```

---

### `[M1-W1-BE2-01]` Scaffold `catalog-service` Skeleton
**Assignee:** BE-2 (Senior Backend Engineer 2 — Catalog & Search)  
**Target Files:** `apps/catalog-service/src/main.ts`, `apps/catalog-service/src/catalog.module.ts`

```text
You are acting as Senior Backend Engineer 2 (BE-2) for the Fattakse platform modernization.

TASK: M1-W1-BE2-01 - Scaffold catalog-service Skeleton

CONTEXT:
catalog-service owns master items, categories, brands, variants, barcodes, nutrition badges, and integration with Typesense 28.0.

REQUIREMENTS:
1. Scaffold apps/catalog-service on port 3003 with Fastify.
2. Configure Kysely connection pointing to schema fattakse_catalog.
3. Scaffold domain modules:
   - src/items/
   - src/categories/
   - src/variants/
   - src/search/
4. Add health check endpoint verifying MySQL and Typesense availability.

DEFINITION OF DONE:
- Service boots on port 3003.
- GET http://localhost:3003/health returns HTTP 200.
```

---

### `[M1-W1-BE2-02]` Setup Typesense Client SDK (`@fattakse/typesense`)
**Assignee:** BE-2 (Senior Backend Engineer 2 — Catalog & Search)  
**Target Files:** `packages/typesense/src/client.ts`, `packages/typesense/src/schemas/product.schema.ts`

```text
You are acting as Senior Backend Engineer 2 (BE-2) for the Fattakse platform modernization.

TASK: M1-W1-BE2-02 - Setup Typesense Client SDK (@fattakse/typesense)

CONTEXT:
Typesense 28.0 is the real-time search engine for Fattakse's catalog search, supporting typo-tolerance and instant geopoint filtering.

REQUIREMENTS:
1. Create packages/typesense workspace package wrapping the official typesense npm client.
2. Define the product_catalog_v1 schema in schemas/product.schema.ts:
   - Fields: id (string), name (string), description (string), store_id (int32, facet: true), zone_ids (int32[]), category_id (int32, facet: true), price (float), discount_price (float), in_stock (bool), rating (float), barcode (string, optional).
   - Default sorting field: rating:desc.
3. Implement connection factory with retry backoff and health check.
4. Write integration test verifying connection to local Typesense cluster (localhost:8108).

DEFINITION OF DONE:
- Client creates collection schema without error.
- Health check returns HTTP 200.
```

---

### `[M1-W1-BE3-01]` Scaffold `order-service` Skeleton
**Assignee:** BE-3 (Senior Backend Engineer 3 — Commerce & Core)  
**Target Files:** `apps/order-service/src/main.ts`, `apps/order-service/src/order.module.ts`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M1-W1-BE3-01 - Scaffold order-service Skeleton

CONTEXT:
order-service is the core transactional engine for carts, quotations, order placement, order state machine, and picking/packing fulfillment.

REQUIREMENTS:
1. Scaffold apps/order-service on port 3005 with Fastify.
2. Configure Kysely connection pointing to schema fattakse_order.
3. Structure modules:
   - src/cart/
   - src/checkout/
   - src/orders/ (lifecycle state machine)
   - src/outbox/ (transactional outbox relay)
4. Add health check verifying DB and Kafka/Redpanda connection.

DEFINITION OF DONE:
- Service boots on port 3005.
- GET http://localhost:3005/health returns HTTP 200.
```

---

### `[M1-W1-BE3-02]` Scaffold `inventory-service` Skeleton
**Assignee:** BE-3 (Senior Backend Engineer 3 — Commerce & Core)  
**Target Files:** `apps/inventory-service/src/main.ts`, `apps/inventory-service/src/inventory.module.ts`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M1-W1-BE3-02 - Scaffold inventory-service Skeleton

CONTEXT:
inventory-service manages Tirora dark store inventory, atomic pessimistic locking (SELECT ... FOR UPDATE), and multi-owner stock ledgers (Evolw-owned vs. Seller-deposited).

REQUIREMENTS:
1. Scaffold apps/inventory-service on port 3004 with Fastify.
2. Configure Kysely connection pointing to schema fattakse_inventory.
3. Structure modules:
   - src/stock/ (reservations & decrements)
   - src/owners/ (Evolw vs Seller inventory tracking)
   - src/bins/ (rack and bin warehouse locations)
4. Add health check endpoint.

DEFINITION OF DONE:
- Service boots on port 3004.
- GET http://localhost:3004/health returns HTTP 200.
```

---

### `[M1-W1-BE3-03]` Scaffold `fleet-service`, `finance-service` & `notify-service` Skeletons
**Assignee:** BE-3 (Senior Backend Engineer 3 — Commerce & Core)  
**Target Files:** `apps/fleet-service/src/main.ts`, `apps/finance-service/src/main.ts`, `apps/notify-service/src/main.ts`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M1-W1-BE3-03 - Scaffold fleet-service, finance-service & notify-service Skeletons

CONTEXT:
fleet-service (port 3006, fattakse_fleet) handles rider dispatch and GPS telemetry.
finance-service (port 3007, fattakse_finance) handles Razorpay webhooks, COD ledgers, and payouts.
notify-service (port 3008, fattakse_notify) handles FCM push and MSG91 SMS OTPs.

REQUIREMENTS:
1. Scaffold all three NestJS Fastify microservices with isolated ports:
   - fleet-service -> 3006
   - finance-service -> 3007
   - notify-service -> 3008
2. Wire each to its dedicated Kysely database schema.
3. Add /health check endpoint to each service.

DEFINITION OF DONE:
- All three services boot cleanly and respond to /health in < 10ms.
```

---

### `[M1-W1-FE1-01]` Scaffold `admin-react` Shell
**Assignee:** FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)  
**Target Files:** `apps/admin-react/vite.config.ts`, `apps/admin-react/src/App.tsx`, `apps/admin-react/src/routes.tsx`

```text
You are acting as Senior Frontend Engineer 1 (FE-1) for the Fattakse platform modernization.

TASK: M1-W1-FE1-01 - Scaffold admin-react Shell

CONTEXT:
admin-react replaces 1,419 legacy Laravel Blade admin views with a modern, high-performance React 19 SPA for operations, dispatch oversight, and financials.

REQUIREMENTS:
1. Initialize apps/admin-react using Vite 6 + React 19 + TypeScript.
2. Install and configure Tailwind CSS v4, Lucide React icons, and shadcn/ui component primitives.
3. Build the core application layout:
   - Collapsible sidebar with navigation groups: Dashboard, Live Dispatch, Catalog, Stores, Fleet, Finance & Town P&L, Settings.
   - Header with active Tirora zone selector, dark/light theme toggle, and admin user avatar dropdown.
   - Main content area with breadcrumb header.
4. Setup React Router v7 with routes: /login, /dashboard, /orders, /catalog/items, /stores, /fleet/riders, /finance/ledger, /settings.

DEFINITION OF DONE:
- pnpm --filter admin-react dev starts in < 300ms on port 5173.
- Responsive layout navigates smoothly without console errors.
```

---

### `[M1-W1-FE2-01]` Scaffold `vendor-react` Shell
**Assignee:** FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)  
**Target Files:** `apps/vendor-react/vite.config.ts`, `apps/vendor-react/src/App.tsx`

```text
You are acting as Senior Frontend Engineer 2 (FE-2) for the Fattakse platform modernization.

TASK: M1-W1-FE2-01 - Scaffold vendor-react Shell

CONTEXT:
vendor-react is used by Tirora dark store pickers and restaurant kitchen staff on tablets and mobile devices. It must have high-contrast UI, loud audio alerts, and instant touch feedback.

REQUIREMENTS:
1. Scaffold apps/vendor-react using Vite 6 + React 19 + TypeScript + Tailwind CSS.
2. Build tablet-optimized layouts for:
   - Dark Store Picker Queue (/picker/queue).
   - Restaurant Kitchen Display Screen (/kitchen/live-orders).
3. Setup Web Audio API / Howler.js wrapper to preload and play loud order arrival chimes with volume override.
4. Add viewport tester allowing toggling between tablet landscape (1024x768) and mobile portrait (375x812).

DEFINITION OF DONE:
- App starts on port 5174.
- Audio bell button plays clear audio alert without CORS or browser permission blocking.
```

---

### `[M1-W1-DATA-01]` Scaffold 8 Logical Schemas in MySQL 8.0
**Assignee:** DATA (Database Architect & ETL Data Engineer)  
**Target Files:** `packages/kysely-db/src/schemas/*.sql`

```text
You are acting as the Database Architect (DATA) for the Fattakse platform modernization.

TASK: M1-W1-DATA-01 - Scaffold 8 Logical Schemas in MySQL 8.0

CONTEXT:
We are decomposing the monolithic MySQL database (264 tables) into 8 strictly isolated domain schemas to enforce microservice boundary autonomy (ADR-0005).

REQUIREMENTS:
1. Write idempotent DDL initialization scripts creating 8 schemas:
   - fattakse_iam
   - fattakse_store
   - fattakse_catalog
   - fattakse_inventory
   - fattakse_order
   - fattakse_fleet
   - fattakse_finance
   - fattakse_notify
2. Create dedicated MySQL application users with strict privileges:
   - CREATE USER 'iam_user'@'%' IDENTIFIED BY 'iam_secret'; GRANT ALL ON fattakse_iam.* TO 'iam_user'@'%';
   - Repeat for all 8 services.
3. Exclude all Hyper POS tables permanently (pos_*, hyper_pos_*).
4. Verify cross-schema boundary enforcement: executing SELECT * FROM fattakse_store.stores using iam_user must throw MySQL Error 1142 (command denied).

DEFINITION OF DONE:
- DDL scripts run cleanly on fresh MySQL 8.0 instance.
- Cross-schema queries are blocked by MySQL permissions.
```

---

### `[M1-W1-QA-01]` Setup Monorepo Testing, DevSecOps & CI/CD Pipeline
**Assignee:** QA (SDET / Automation Engineer)  
**Target Files:** `vitest.workspace.ts`, `.github/workflows/ci.yml`, `.gitleaks.toml`, `renovate.json`, `sonar-project.properties`

```text
You are acting as the SDET / Automation Engineer (QA) for the Fattakse platform modernization.

TASK: M1-W1-QA-01 - Setup Monorepo Testing, DevSecOps & CI/CD Pipeline

CONTEXT:
We require strict automated testing and security gates across all monorepo packages. Code cannot be merged without passing SonarQube, Gitleaks, and Trivy scans.

REQUIREMENTS:
1. Configure Vitest workspace in root vitest.workspace.ts orchestrating unit and integration tests across apps/* and packages/*.
2. Setup Gitleaks configuration (.gitleaks.toml) and pre-commit hook to block secret leaks.
3. Setup Renovate configuration (renovate.json) for automated, grouped dependency update PRs.
4. Configure SonarQube Community Build (sonar-project.properties) with Quality Gate requiring > 80% branch coverage and 0 security hotspots.
5. Configure GitHub Actions workflow (.github/workflows/ci.yml):
   - Step 1: Run Gitleaks secret scan.
   - Step 2: Run pnpm lint and pnpm typecheck.
   - Step 3: Run Vitest with coverage report.
   - Step 4: Run SonarQube analysis and Quality Gate check.
   - Step 5: Run Trivy vulnerability scan against Docker build files and dependencies (exit code 1 on CRITICAL/HIGH).

DEFINITION OF DONE:
- pnpm test runs across all workspace packages and generates HTML/LCOV coverage reports.
- CI pipeline in GitHub Actions triggers and executes all 5 steps in < 3.5 minutes.
- Gitleaks and Trivy pass cleanly.
```

---

## Week 2: Isolated Development Environment & Infrastructure

### `[M1-W2-ARCH-01]` Root Docker Compose Infrastructure (`docker-compose.dev.yml`)
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `docker-compose.dev.yml`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization.

TASK: M1-W2-ARCH-01 - Root Docker Compose Infrastructure (docker-compose.dev.yml)

CONTEXT:
Developers need a complete, self-contained local environment running all backend infrastructure and microservices with one command.

REQUIREMENTS:
1. Author docker-compose.dev.yml defining:
   - mysql: MySQL 8.0, custom my.cnf tuning buffer pools, mounting packages/kysely-db/src/schemas/*.sql in /docker-entrypoint-initdb.d.
   - redis: Redis 7.2.4 with appendonly yes on port 6379.
   - redpanda: vectorized/redpanda:v24.2.4 in single-node dev mode on port 9092, zero JVM, zero ZooKeeper.
   - redpanda-console: vectorized/console:v2.5.2 on port 8080.
   - typesense: typesense/typesense:28.0 on port 8108 with persistent data volume.
   - mailhog: mailhog/mailhog on port 1025 (SMTP) and 8025 (Web UI).
2. Configure Docker network fattakse-dev-net with healthchecks on every service.
3. Test startup time: docker compose -f docker-compose.dev.yml up -d.

DEFINITION OF DONE:
- All containers become healthy within 30 seconds.
- Redpanda console accessible at http://localhost:8080 and Typesense responds to /health.
```

---

### `[M1-W2-BE3-01]` Configure Kafka Client & Redis Task Queues
**Assignee:** BE-3 (Senior Backend Engineer 3 — Commerce & Core)  
**Target Files:** `packages/common/src/kafka/`, `packages/common/src/bullmq/`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M1-W2-BE3-01 - Configure Kafka Client & Redis Task Queues

CONTEXT:
We implement ADR-0010: Hybrid Asynchronous Architecture using Redpanda/Kafka for domain event streaming and Redis BullMQ for delayed timers.

REQUIREMENTS:
1. In packages/common/src/kafka/:
   - Implement NestJS KafkaModule wrapper using kafkajs.
   - Provide KafkaProducerService with automatic message serialization and partition key resolution.
   - Provide base KafkaConsumerController decorator for consumer groups.
2. In packages/common/src/bullmq/:
   - Setup @nestjs/bullmq connection wrapper pointing to redis:6379.
   - Define queues: kitchen-sla-timer-queue, otp-expiry-queue, webhook-retry-queue.
3. Write test publishing an OrderLifecycleEvent to Redpanda and verifying receipt in a test consumer.

DEFINITION OF DONE:
- Integration test successfully produces and consumes Kafka messages on local Redpanda container.
- Delayed BullMQ job triggers accurately after specified millisecond delay.
```

---

### `[M1-W2-DATA-01]` Develop Idempotent Seed Scripts
**Assignee:** DATA (Database Architect & ETL Data Engineer)  
**Target Files:** `packages/kysely-db/src/seeds/dev_seed.ts`

```text
You are acting as the Database Architect (DATA) for the Fattakse platform modernization.

TASK: M1-W2-DATA-01 - Develop Idempotent Seed Scripts

CONTEXT:
Developers need realistic seed data reflecting Tirora, Maharashtra operations to test IAM, store zones, and catalog search.

REQUIREMENTS:
1. Create packages/kysely-db/src/seeds/dev_seed.ts.
2. Seed the following entities across domain schemas:
   - fattakse_iam: 1 Super Admin, 1 Tirora Dark Store Manager, 3 Local Merchants, 5 Delivery Riders. Passwords hashed with Bcrypt (secret123).
   - fattakse_store: 1 Tirora Central Dark Store (zone 1), 2 Local Restaurants, 1 Local Paan Corner. Store spatial delivery zone polygon covering Tirora town coordinates (21.4089° N, 79.9322° E).
   - fattakse_catalog: 20 grocery categories, 100 sample items with realistic MRP, sale price, HSN codes, and EAN-13 barcodes.
3. Make script strictly idempotent: can be run 5 times without duplicating records or violating unique constraints.

DEFINITION OF DONE:
- pnpm --filter kysely-db db:seed executes without error.
- Record counts in MySQL match expected seed fixtures.
```

---

## Week 3: API Contract Freezing & CI/CD Pipelines

### `[M1-W3-ARCH-01]` Authoritative OpenAPI 3.1 Contract Generation
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `packages/types/openapi/fattakse-v1.yaml`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization.

TASK: M1-W3-ARCH-01 - Authoritative OpenAPI 3.1 Contract Generation

CONTEXT:
All 431 legacy /api/v1/* routes must be captured into a single canonical OpenAPI 3.1 contract to prevent contract drift against the frozen Flutter apps.

REQUIREMENTS:
1. Analyze docs/modernization/API-Contract-Inventory.md and legacy Laravel route files.
2. Generate packages/types/openapi/fattakse-v1.yaml covering:
   - Headers: zoneId, latitude, longitude, Authorization.
   - Error schemas: { errors: [{ code: string, message: string }] }.
   - Routes: All 431 active routes mapped to target microservices.
   - Request bodies, query parameters, and 200 OK response structures.
3. Exclude all 27 retired POS endpoints.
4. Run spectral lint to validate OpenAPI 3.1 compliance.

DEFINITION OF DONE:
- OpenAPI spec passes Spectral lint with 0 errors.
- openapi-typescript generates complete TypeScript interfaces from the spec.
```

---

### `[M1-W3-BE1-01]` Gateway Header Normalization Interceptor
**Assignee:** BE-1 (Senior Backend Engineer 1 — Auth & Edge)  
**Target Files:** `apps/api-gateway/src/interceptors/header-normalizer.interceptor.ts`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M1-W3-BE1-01 - Gateway Header Normalization Interceptor

CONTEXT:
Frozen Flutter apps send zoneId unpredictably as either an integer 1, an array [1], or a stringified JSON array "[1]". Downstream microservices expect clean, strongly-typed headers.

REQUIREMENTS:
1. Create apps/api-gateway/src/interceptors/header-normalizer.interceptor.ts.
2. Intercept incoming requests:
   - If header zoneId is "[1]", parse JSON to number[] [1].
   - If header zoneId is "1", parse to [1].
   - If header latitude or longitude is string, cast to float.
   - Inject normalized x-fattakse-zone-ids and x-fattakse-geo-lat/lng headers for downstream microservices.
3. Write unit tests for all variations of malformed mobile headers.

DEFINITION OF DONE:
- Unit tests pass for string, array, and malformed zoneId inputs.
```

---

### `[M1-W3-QA-01]` Bruno API Test Collections & Automated Schema Diffing
**Assignee:** QA (SDET / Automation Engineer)  
**Target Files:** `qa/bruno/collection.bru`, `qa/bruno/**/*.bru`, `qa/contract_diff_runner.ts`

```text
You are acting as the SDET / Automation Engineer (QA) for the Fattakse platform modernization.

TASK: M1-W3-QA-01 - Bruno API Test Collections & Automated Schema Diffing

CONTEXT:
To ensure 100% backward compatibility, we use Bruno git-friendly API test collections (.bru files) alongside an automated AST diffing runner to compare live Laravel monolith responses against the new Node.js Gateway.

REQUIREMENTS:
1. Initialize Bruno collection in qa/bruno/ with environments:
   - laravel-reference: http://145.223.19.105:8000
   - nodejs-gateway: http://localhost:3000
2. Author Bruno requests (.bru files) covering foundational endpoints:
   - /api/v1/config
   - /api/v1/auth/login (mock)
   - /api/v1/zone/list
   - /api/v1/categories
   - /api/v1/items/popular
3. Author qa/contract_diff_runner.ts:
   - Execute Bruno requests against both targets.
   - Diff JSON response ASTs (key existence, data types, nullability, array structures).
   - Assert legacy error format { errors: [{ code, message }] } matches on 4xx status codes.
4. Integrate Bruno CLI into test scripts: `npx @usebruno/cli run qa/bruno --env nodejs-gateway`.
5. Generate diff report in qa/reports/diff_week3.json.

DEFINITION OF DONE:
- Bruno collection contains > 50 endpoint tests.
- `bru run` executes cleanly via CLI.
- AST diff report generated with 0 unexpected schema discrepancies.
```

---

## Week 4: Stage 1 ETL Data Pipeline & React Shells

### `[M1-W4-DATA-01]` Stage 1 Base ETL Extraction Engine
**Assignee:** DATA (Database Architect & ETL Data Engineer)  
**Target Files:** `etl/stage1_extract_and_load.py`, `etl/transformers/*.py`

```text
You are acting as the Database Architect (DATA) for the Fattakse platform modernization.

TASK: M1-W4-DATA-01 - Stage 1 Base ETL Extraction Engine

CONTEXT:
We must extract data from the legacy MySQL database (264 tables) and load it into the 8 new microservice domain schemas without losing data.

REQUIREMENTS:
1. Write Python ETL engine in etl/stage1_extract_and_load.py using sqlalchemy and pymysql.
2. Read table-column mapping from etl/mappings/table_column_map.json.
3. Extract in chunks of 2,000 rows to prevent memory exhaustion.
4. Transform and load:
   - users, delivery_men, vendors -> fattakse_iam.users.
   - stores, zones -> fattakse_store.stores, fattakse_store.zones.
   - items, categories -> fattakse_catalog.items, fattakse_catalog.categories.
5. Filter out all POS tables (pos_*, hyper_pos_*).
6. Log elapsed time, extracted row counts, and transformation errors.

DEFINITION OF DONE:
- Script extracts and loads 10,000 rows in < 60 seconds on local dump.
- Target tables contain clean, foreign-key compliant data.
```

---

### `[M1-W4-DATA-02]` PII Anonymization Layer
**Assignee:** DATA (Database Architect & ETL Data Engineer)  
**Target Files:** `etl/transformers/anonymizer.py`

```text
You are acting as the Database Architect (DATA) for the Fattakse platform modernization.

TASK: M1-W4-DATA-02 - PII Anonymization Layer

CONTEXT:
Local development and staging environments must never store real customer phone numbers, addresses, or plaintext customer names.

REQUIREMENTS:
1. Implement PII anonymization transformer in etl/transformers/anonymizer.py.
2. Rules:
   - Phone numbers: Replace with +919999000000 + sequential user ID.
   - Names: Replace with Test Customer {id} or Test Vendor {id}.
   - Emails: Replace with user_{id}@fattakse.local.
   - Addresses: Retain latitude/longitude within Tirora delivery boundaries, but mask street address to "Plot {id}, Main Road, Tirora".
   - Passwords: Hash static password 'secret123' with Bcrypt (cost 10).
3. Ensure referral codes and store slugs remain unique.

DEFINITION OF DONE:
- Anonymized database contains zero real customer phone numbers or emails.
- Seed users can log in with password 'secret123'.
```

---

### `[M1-W4-QA-01]` Execute Gate 1 Acceptance Certification
**Assignee:** QA (SDET / Automation Engineer)  
**Target Files:** `scripts/gate1_verify.sh`

```text
You are acting as the SDET / Automation Engineer (QA) for the Fattakse platform modernization.

TASK: M1-W4-QA-01 - Execute Gate 1 Acceptance Certification

CONTEXT:
Month 1 concludes with Gate 1: confirming all microservice skeletons, gateway, dev databases, and CI checks pass cleanly before starting domain logic in Month 2.

REQUIREMENTS:
1. Author automated verification script scripts/gate1_verify.sh.
2. Test sequence:
   - Run docker compose -f docker-compose.dev.yml up -d and verify all services healthy.
   - Run pnpm install and pnpm build across all workspace packages.
   - Run pnpm test: verify > 85% coverage on shared packages.
   - Execute Stage 1 ETL test against sanitized dump.
   - Hit GET http://localhost:3000/health on API Gateway and verify HTTP 200.
3. Emit formal Gate 1 Sign-Off report to docs/modernization/reports/gate1_signoff.md.

DEFINITION OF DONE:
- Script executes end-to-end with exit code 0.
- Gate 1 checklist is 100% verified.
```
