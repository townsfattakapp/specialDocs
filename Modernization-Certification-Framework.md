# Fattakse Modernization: Launch-Gate Certification Framework & Protocol

**Operating Company:** Evolw Technologies Private Limited  
**Flagship Hub:** Tirora, Maharashtra  
**Project:** Greenfield Microservices Modernization & Monolith Production Replacement  
**Standard:** Strict Launch-Gate Certification Protocol (Derived from Fattakse Food Module Certification Standards)  
**Status:** Canonical Release Governance Standard  

---

## 1. Executive Certification Standard

At Evolw Technologies / Fattakse, no release, milestone gate, or production cutover may occur without a **formal, test-driven Launch-Gate Certification Report**. 

A milestone or cutover is either:
```text
CERTIFIED FOR PRODUCTION / NEXT STAGE
```
or
```text
NOT CERTIFIED — DO NOT LAUNCH / DO NOT CUTOVER
```

There are no conditional approvals. Certification is **withheld** if even a single P0/P1 defect remains open, if a single paisa is missing from financial reconciliation, if any frozen mobile app crashes, or if any restricted tobacco item leaks to mobile clients.

---

## 2. The 5 Milestone Certification Gates

| Gate ID | Target Timeline | Milestone Scope | Mandatory Certification Evidence |
|---|---|---|---|
| **GATE-M1-CERT** | Month 1 (Week 4) | **Foundation, Monorepo & API Contracts** | All 8 services compile cleanly; Fastify Gateway routes 100% of `/api/v1/*` mocks; Redpanda & Redis clusters healthy; Stage 1 ETL migration succeeds on test DB. |
| **GATE-M2-CERT** | Month 2 (Week 8) | **Core Domain, Catalog & GST Pricing** | Passport RSA JWT verification works with zero re-logins; Typesense CDC indexing latency < 500ms; Tirora GST pricing engine achieves 100% mathematical parity with legacy Laravel. |
| **GATE-M3-CERT** | Month 3 (Week 12) | **Transactions & Fulfillment Lifecycle** | Full multi-persona order journey passes (Customer -> Vendor Pick/Pack -> Rider Proximity Dispatch -> OTP Delivery); Multi-owner dark store stock ledger balances cleanly; Kafka topics stream without loss. |
| **GATE-M4-CERT** | Month 4 (Week 16) | **Integration, Compatibility & Chaos Resilience** | Frozen Flutter Customer (`1.0.18`), Vendor (`1.0.5`), and Rider (`1.0.1`) pass complete regression suite without app updates; Kafka broker failover loses zero events; Load test achieves 1,500 req/s with p95 < 180ms. |
| **GATE-M5-FINAL-CERT** | Month 5 (Week 19) | **Cutover Night Launch-Gate Certification** | Scheduled 15-minute maintenance window at 02:00 AM IST; Delta ETL sync completes in < 10 minutes; Zero paisa financial variance across all accounts; Live smoke test order delivered in < 90 seconds. |

---

## 3. Mandatory Certification Report Structure

Every monthly certification gate must produce a signed markdown report saved in `docs/modernization/certification-evidence/` using this exact standard template:

### 3.1 Status & Verdict Block
```text
================================================================================
STATUS: CERTIFIED FOR PRODUCTION CUTOVER  [or: NOT CERTIFIED — DO NOT LAUNCH]
================================================================================
Gate ID: GATE-M5-FINAL-CERT
Date & Time: 2027-03-15 02:14:00 IST
Lead SRE: [Lead Engineer Name]
Principal Architect: [Architect Name]
Target Environment: Production (Hostinger VPS 145.223.19.105)
```

### 3.2 Exact Software Release & Image SHAs
```text
Backend Monorepo Commit:   c3593ce71839... (origin/main)
API Gateway Image SHA:      sha256:4a8f912e...
IAM Service Image SHA:      sha256:8b22e11a...
Order Service Image SHA:    sha256:7c99201f...
Customer Flutter App:       1.0.18 (versionCode 5802) — FROZEN PRODUCTION BUILD
Vendor Flutter App:         1.0.5 (versionCode 105)   — FROZEN PRODUCTION BUILD
Rider Flutter App:          1.0.1 (versionCode 101)   — FROZEN PRODUCTION BUILD
Admin React Portal:         apps/admin-react commit d82910...
Vendor React Portal:        apps/vendor-react commit e19940...
Consumer Web Storefront:    apps/user-web commit f02931...
```

### 3.3 Full Category & Persona Coverage Matrix
Every product category operating in Tirora must be validated end-to-end across all personas:

| Category ID | Category Name | Items Count | Variation Types | Add-ons | GST Rate | Flutter Mobile (Tobacco Free) | Web Storefront (18+ Gate) | Cart & Quote | Pick & Pack | Rider Delivery | Double-Entry Ledger |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Grocery Essentials | 450 | Simple | N/A | 0% / 5% | PASS | PASS | PASS | PASS | PASS | PASS |
| 2 | Dairy & Bakery | 120 | Simple | N/A | 0% / 5% | PASS | PASS | PASS | PASS | PASS | PASS |
| 3 | Fresh Produce | 85 | Simple | N/A | 0% | PASS | PASS | PASS | PASS | PASS | PASS |
| 4 | Packaged Foods | 310 | Multi-group | N/A | 12% / 18% | PASS | PASS | PASS | PASS | PASS | PASS |
| 5 | Restaurant Food | 105 | Variations | 9 add-ons | 5% | PASS | PASS | PASS | PASS | PASS | PASS |
| 6 | Beverages | 60 | Simple | N/A | 18% / 28% | PASS | PASS | PASS | PASS | PASS | PASS |
| 7 | Paan Corner / Tobacco | 45 | Simple | N/A | 28% + Cess | MASKED (100% Hidden) | PASS (18+ Verified) | PASS | PASS | PASS (ID Checked) | PASS |

### 3.4 Automated Toolchain Quality Gates & Security Evidence
Every monthly certification report must embed execution outputs from the standard toolchain:

| Tool | Verification Gate Requirement | Output Evidence Required | Target Standard |
|---|---|---|---|
| **SonarQube Community** | Quality Gate Status | `sonar-report.json` | Status: `PASSED` (> 80% coverage, 0 Vulnerabilities, 0 Security Hotspots, Maintainability: A) |
| **Gitleaks** | Secret & API Key Scan | `gitleaks-report.json` | 0 leaks detected across all branches and commits |
| **Trivy** | Container & Dependency Vulnerabilities | `trivy-results.json` | 0 CRITICAL, 0 HIGH vulnerabilities in production Docker images |
| **Bruno** | Automated API Collection Run | `bruno-cli-results.json` | 100% pass across all 431 `/api/v1/*` endpoints; 0 schema drifts |
| **Playwright** | E2E Browser Testing | `playwright-report/` | 100% pass across Admin Control Plane, Vendor KDS/Picker, and User-Web Storefront |
| **OpenAPI** | Contract Schema Validation | `openapi-spec-diff.json` | 0 undocumented routes, 100% DTO typing equivalence |
| **Testcontainers** | Real Container Integration Tests | `testcontainers-summary.json`| 100% pass on disposable MySQL 8.4, Redis 7.2, and Redpanda containers |
| **OWASP ZAP (DAST)**| Dynamic Penetration Security Scan | `zap-scan-report.html` | 0 HIGH, 0 CRITICAL security vulnerabilities across Gateway and portals |
| **k6** | Load & Performance Baseline | `k6-summary.json` | 1,500 req/s sustained for 30m; p95 < 180ms; 0% 5xx errors |
| **OpenTelemetry (OTel)**| Distributed Tracing Verification | `trace-audit-sample.json` | Validated `x-correlation-id` propagation across Gateway -> Microservice -> Kafka -> Consumer |
| **Sentry** | Error Monitoring & Crash Free Rate | `sentry-issue-audit.json` | > 99.9% crash-free sessions; 0 unresolved P0/P1 exceptions |
| **Grafana Loki** | Centralized Logging Audit | `loki-query-audit.log` | Structured JSON Pino logs aggregated with zero unhandled exceptions |
| **Prometheus + Grafana**| Alerting & Dashboard Check | `alerts-rules-active.json` | Prometheus scraping healthy; Grafana SLI/SLO dashboards active; PagerDuty/Slack alerts operational |
| **Uptime Kuma** | Service Heartbeat & Synthetic Check | `uptime-kuma-status.json` | 100% availability over 72h continuous synthetic pinging at `status.fattakse.in` |
| **Restic + Off-Site**| Backup & Disaster Recovery Drill | `restic-restore-drill.log` | Automated encrypted snapshot and test restore from Wasabi / S3 Glacier with zero data loss |
| **Renovate** | Automated Dependency Hygiene | `renovate-audit.json` | 0 unpatched security vulnerabilities in npm/pnpm packages |
| **MkDocs Material** | Engineering Documentation Build | `site/index.html` | Clean documentation build with 0 broken internal links |

---

## 4. Mathematical Financial & Invariant Reconciliation

Certification requires mathematical proof down to the exact paisa (0.00 INR tolerance):

```text
1. Customer Wallet Balances Proof:
   Legacy MySQL Total: ₹14,250.00 (1,425,000 paise)
   Target PostgreSQL Total: ₹14,250.00 (1,425,000 paise)
   Delta Variance: ₹0.00 [PASS]

2. Rider Cash in Hand (Collected COD):
   Legacy MySQL Total: ₹8,920.00 (892,000 paise)
   Target PostgreSQL Total: ₹8,920.00 (892,000 paise)
   Delta Variance: ₹0.00 [PASS]

3. Merchant Pending Settlement Balances:
   Legacy MySQL Total: ₹62,410.00 (6,241,000 paise)
   Target PostgreSQL Total: ₹62,410.00 (6,241,000 paise)
   Delta Variance: ₹0.00 [PASS]

4. Microservice Double-Entry Ledger Balance:
   Total Debits: ₹85,580.00
   Total Credits: ₹85,580.00
   Accounting Discrepancy: ₹0.00 [PASS]
```

---

## 5. Defect Classification & Triage Rules

| Severity | Definition | Launch Impact |
|---|---|---|
| **P0 (Blocker)** | Any crash in frozen Flutter apps, data loss, money calculation drift (> ₹0.00), order loss, tobacco leaking to mobile clients, or auth lockout. | **AUTOMATIC BLOCK:** Zero exceptions. Verdict must be `NOT CERTIFIED`. |
| **P1 (Critical)** | Core workflow degradation (e.g., rider dispatch delay > 30s, search latency > 1s, missing push notifications). | **AUTOMATIC BLOCK:** Must be resolved before certification sign-off. |
| **P2 (Major)** | Non-blocking admin dashboard UI misalignment, non-critical filter issue in vendor portal. | Can be accepted with explicit written mitigation plan. |
| **P3 (Minor)** | Minor styling glitch, translation string typo in secondary screens. | Non-blocking. Post-launch backlog. |

---

## 6. Cutover Night Final Go/No-Go Decision Tree

```
                      [02:00 AM IST Maintenance Start]
                                      │
                         [Final Delta ETL Migration]
                                      │
                         [Financial Invariant Script]
                                      │
                   Is Variance Delta == ₹0.00 INR?
                             │               │
                            YES              NO ──> [ABORT CUTOVER]
                             │                      [Rollback in < 60s]
                 [Gateway DNS Switch & Ingress]
                             │
              [Execute Production Smoke Test Order]
                             │
                  Did Live Order Succeed in < 90s?
                             │               │
                            YES              NO ──> [TRIGGER EMERGENCY ROLLBACK]
                             │                      [Reverse-Delta ETL Sync]
               =======================================
               VERDICT: CERTIFIED FOR PRODUCTION LAUNCH
               =======================================
               [Release Public Traffic - 02:15 AM IST]
```
