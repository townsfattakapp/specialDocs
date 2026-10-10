# Fattakse Modernization: Engineering Team Task Prompt Playbook

**Organization:** Evolw Technologies Private Limited (Tirora, Maharashtra)  
**Project:** Parallel Greenfield Microservices Modernization & Production Replacement  
**Duration:** 5 Months (November 2026 – March 2027 / 20 Weeks)  
**Team Pod:** 8 Dedicated FTE Engineers  

---

## 1. How to Use This Prompt Playbook

This directory contains **ready-to-execute, copy-pasteable prompts** for every single task across all 5 months of the modernization project. 

Each prompt is self-contained and engineered specifically for:
1. **AI Coding Assistants & Autonomous Agents** (e.g., Antigravity, Claude Code, Cursor, Copilot).
2. **Human Software Engineers** looking for unambiguous technical specifications, file targets, and acceptance criteria.

### Standard Prompt Execution Workflow
1. Locate the current week and your assigned role (`ARCH`, `BE-1`, `BE-2`, `BE-3`, `FE-1`, `FE-2`, `DATA`, `QA`).
2. Copy the exact text block under the task header.
3. Paste it directly into your AI coding tool or terminal agent.
4. Execute the implementation and run the automated verification commands specified in the **Verification & Definition of Done** section.

---

## 2. Global Context & Architectural Invariants

Every prompt inherits these non-negotiable architectural rules:
- **Reference Monolith is Ground Truth:** The existing Laravel monolith (`towns_fattakse_in`) is the executable specification for all business rules, calculations, and database structures. Live production on VPS `145.223.19.105` is strictly **READ-ONLY**.
- **Frozen Mobile Clients:** Flutter Customer (`1.0.18`), Vendor (`1.0.5`), and Rider (`1.0.1`) apps are compiled and frozen. The new API Gateway must emulate legacy Laravel response formats (`{ errors: [{ code, message }] }`, stringified pagination `limit`/`offset`, and Passport RSA JWT claims).
- **Dual-Channel Strategy:** Flutter mobile apps are **100% tobacco-free** for App Store safety. The modernized React User Web Storefront (`user-web` at `fattakse.in`) is a **full-catalog storefront** selling groceries, dark store essentials, restaurant food, and Paan Corner / tobacco products with COTPA 2003 age verification.
- **Hybrid Messaging Backbone:** Use **Redpanda / Kafka** (`kafkajs`) for domain event streaming (`fattakse.orders.lifecycle`, `fattakse.riders.telemetry`, `fattakse.inventory.adjustments`, `fattakse.finance.transactions`) with transactional outbox. Use **Redis 7.2 BullMQ** strictly for delayed timers (3-minute restaurant SLA, 10-minute OTP expiry).
- **Zero POS / Offline Retail:** Hyper POS is permanently retired. All dark-store operations use the native digital Pick & Pack queue in `vendor-react`.
- **Mandatory Engineering Toolchain & Platform Stack:**
  1. **GitHub + GitHub Actions:** Monorepo management, CI/CD automated test & build workflows.
  2. **GitHub Projects:** Sprint planning, weekly Kanban boards for 8 FTE roles.
  3. **SonarQube Community Build:** Static code analysis, maintainability, and Quality Gate (> 80% coverage).
  4. **Gitleaks:** Secret and API key detection in pre-commit and CI.
  5. **Trivy:** Container image and npm dependency vulnerability scans.
  6. **OWASP ZAP (Zed Attack Proxy):** Automated DAST penetration testing against Gateway and portals.
  7. **Testcontainers:** Disposable Docker containers (MySQL, Redis, Redpanda) inside Vitest integration tests.
  8. **Playwright:** E2E headless browser testing across Admin, Vendor, and User-Web.
  9. **Bruno:** Automated git-friendly API test collections (`.bru` files) covering all 431 routes.
  10. **OpenAPI 3.1:** API contracts (Swagger UI / ReDoc) generated from Fastify decorators.
  11. **MySQL 8.4 LTS & Docker:** Multi-stage container builds and isolated relational databases.
  12. **Nginx:** Reverse proxy, TLS 1.3 termination, rate limiting, and 60-second cutover switching.
  13. **Redis 7.2 & BullMQ:** Distributed caching, session store, and delayed timers (3m SLA, 10m OTP).
  14. **Typesense 28.0:** Sub-50ms typo-tolerant catalog search and change-data-capture indexing.
  15. **Prometheus + Grafana:** Real-time metrics collection, SLI/SLO dashboards, and alerts.
  16. **Grafana Loki:** Centralized container log aggregation from structured Pino JSON.
  17. **OpenTelemetry:** Distributed tracing across Gateway, microservices, and Kafka.
  18. **Sentry:** Full-stack application error and exception tracking with release health.
  19. **Uptime Kuma:** Synthetic monitoring and public status page at `status.fattakse.in`.
  20. **Restic + Off-site Storage:** Encrypted, automated database snapshots shipped to Wasabi / S3 Glacier.
  21. **k6:** Load, stress, and concurrency performance benchmarking (1,500 req/s).
  22. **Renovate:** Automated dependency update PRs with security patches.
  23. **MkDocs Material:** Searchable engineering documentation site.

---

## 3. Playbook Directory Index

| File | Scope | Theme |
|---|---|---|
| [`Month-1-Task-Prompts.md`](Month-1-Task-Prompts.md) | Weeks 1–4 | Discovery, Monorepo Scaffolding, Contracts, Dev Infra & Stage 1 ETL |
| [`Month-2-Task-Prompts.md`](Month-2-Task-Prompts.md) | Weeks 5–8 | Core Foundations, IAM, Store Zones, Catalog, Typesense CDC, Cart & GST |
| [`Month-3-Task-Prompts.md`](Month-3-Task-Prompts.md) | Weeks 9–12 | Transactions, Multi-Owner Inventory, Pick/Pack, Fleet, Finance, Web SPAs |
| [`Month-4-Task-Prompts.md`](Month-4-Task-Prompts.md) | Weeks 13–16 | Contract Diffing, Rehearsals 1 & 2, Load & Streaming Chaos, Hardening |
| [`Month-5-Task-Prompts.md`](Month-5-Task-Prompts.md) | Weeks 17–20 | Production Provisioning, Rehearsal 3, Cutover Night (02:00 AM IST), Hypercare |
