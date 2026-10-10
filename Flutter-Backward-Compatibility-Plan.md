# Fattakse — Flutter Client Backward Compatibility Plan

**Document Version:** 2.0.0  
**Scope:** Customer App (`1.0.18`), Vendor App (`1.0.5`), Rider App (`1.0.1`)  
**Architecture:** API Gateway Compatibility Facade -> Node.js Microservices  
**Status:** Mandatory Safety Specification (Zero Mobile Client Rewrites)  
**Author:** Principal Mobile & API Architect  

---

## 1. Frozen Mobile Client Baseline

The three Flutter mobile applications are currently published or in release staging on Google Play Store and Apple TestFlight. The mobile apps **cannot be forced to update simultaneously** when the backend transitions to the new microservices platform.

```
+---------------------------------------+---------------------------------------+---------------------------------------+
|          CUSTOMER APP                 |             VENDOR APP                |            DELIVERY APP               |
+---------------------------------------+---------------------------------------+---------------------------------------+
| Repo: townsfattakappin_ios_android_   | Repo: townsfattakappin_ios_android_   | Repo: townsfattakappin_ios_android_   |
|       user                            |       vendor                          |       delivery_man                    |
| Version: 1.0.18+28                    | Version: 1.0.5+14                     | Version: 1.0.1+14                     |
| Architecture: GetX / MVC              | Architecture: GetX / MVC              | Architecture: GetX / MVC              |
| API Contract: /api/v1/*               | API Contract: /api/v1/vendor/*        | API Contract: /api/v1/delivery-man/*  |
+---------------------------------------+---------------------------------------+---------------------------------------+
```

---

## 2. Mandatory Protocol & Payload Invariants

The **API Gateway / Edge Router** implements a dedicated **Flutter Compatibility Facade** that enforces exact wire-level compatibility before delegating to downstream microservices.

### 2.1 Request Header Normalization
The Gateway normalizes the following client headers identical to Laravel middleware:
- `zoneId`: Can arrive as a raw integer (`1`) or a JSON-encoded array string (`"[1]"`). The Gateway normalizes both formats seamlessly.
- `moduleId`: Integer representing the active vertical (`1` = Quick Grocery, `2` = Food Restaurant).
- `latitude` & `longitude`: Float values passed in headers for hyperlocal zone resolution.
- `X-Software-Id`: App client identifier.
- `Authorization`: `Bearer <token>` (OAuth2 JWT).

### 2.2 Error Response Format Standard
Under no circumstances may the default microservice error payload (`{ statusCode: 400, message: "...", error: "Bad Request" }`) reach Flutter clients. Flutter GetX repositories parse errors strictly using:

```json
{
  "errors": [
    {
      "code": "auth-001",
      "message": "Invalid OTP or OTP has expired."
    }
  ]
}
```

A custom NestJS global filter (`FlutterExceptionFilter`) on the Gateway intercepts all exceptions and serializes them into this exact schema.

### 2.3 Pagination Schema Standard
List endpoints must strictly preserve the pagination envelope:

```json
{
  "total_size": 154,
  "limit": "10",
  "offset": "1",
  "products": [ ... ]
}
```
*(Note: `limit` and `offset` in legacy Laravel responses are stringified numbers; the Gateway serializer preserves these exact primitive types).*

### 2.4 Order Fulfilment Stage Emulation
As discovered in `app/Models/Order.php`, the Flutter apps render real-time progress using the appended `fulfilment_stage` object:

```json
{
  "id": 10042,
  "order_status": "processing",
  "fulfilment_stage": {
    "code": "picking",
    "label": "Picking your items",
    "step": 2
  }
}
```
Even with Hyper POS excluded, the native dark-store order engine (`order-service`) emits this exact structure during the dark-store pick-and-pack workflow so customer animations and status steppers continue to function without alteration.

---

## 3. Seamless Authentication & Passport JWT Emulation

### 3.1 The Problem
Existing logged-in mobile users hold Laravel Passport OAuth2 tokens generated with an RSA private key. If the new `iam-service` rejects these tokens, thousands of active customers and delivery riders will be logged out simultaneously on cutover night.

### 3.2 The Solution: RSA Public Key Passport Verifier
1. Export the existing `storage/oauth-public.key` from the Laravel deployment.
2. In `iam-service`, implement a custom JWT Passport Strategy using `jsonwebtoken` / `jose` configured with the RSA public key.
3. Verify claims (`sub` = user_id, `scopes` = user/vendor/delivery_man).
4. New tokens issued by `iam-service` use the same RSA private key pair, ensuring seamless token validity across cutover night.

---

## 4. Contract Verification Pipeline (Month 4 Integration)

Before cutover authorization in Month 5:
1. **Automated Schema Diffing:** An automated test runner replays production API request samples against both the reference Laravel instance and the staging Microservices API Gateway, asserting:
   - Field key equivalence.
   - Primitive type matches (string vs integer vs boolean).
   - Nullability consistency.
   - Array structure compliance.
2. **Flutter Integration Smoke Tests:** Automated headless Flutter integration tests execute the core user journey (Login -> Select Address -> Add to Cart -> Checkout -> Track Order) against the Staging API Gateway.

---

## 5. App Store Policy Safety & Regulated Tobacco Firewall

### 5.1 Google Play & Apple App Store Compliance Mandate
- Google Play Developer Policy (*Restricted Content > Tobacco*) and Apple App Store Review Guidelines (*Guideline 1.4.3*) strictly prohibit mobile apps from selling, facilitating, or promoting tobacco, cigarettes, and smoking accessories.
- Listing any tobacco or smoking product inside the Flutter Customer App (`townsfattakappin_ios_android_user`) would cause immediate app delisting or permanent developer account ban.

### 5.2 API Gateway Regulated Category Firewall
1. **Client Identity Inspection:** The API Gateway inspects incoming request headers (`X-Software-Id`, `User-Agent`). Requests identified as originating from the Flutter Customer App are assigned a context flag: `is_app_store_client: true`.
2. **Category & Store Exclusion:** For all app store client requests, the Gateway automatically injects exclusion filters into downstream `catalog-service` and `store-service` queries:
   - Excludes all items with `category_id` corresponding to tobacco, cigarettes, beedis, or smoking supplies.
   - Excludes stores with `store_type = 'paan_corner'` or `is_tobacco_vendor = true`.
3. **Full-Catalog Web Storefront (Unrestricted):** The React User Web Storefront (`user-web` at `fattakse.in`) receives the complete catalog including tobacco and Paan Corner products — because it runs in a mobile browser, it is exempt from App Store content restrictions. Tobacco category pages on the web enforce COTPA 2003 age-gating (18+ interstitial with DOB) and mandatory statutory health warnings. This dual-channel approach shields Flutter mobile apps while maximizing web storefront AOV by offering a one-stop shop experience.

