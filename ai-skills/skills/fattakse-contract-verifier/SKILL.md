---
name: fattakse-contract-verifier
description: >-
  Verifies that API Gateway endpoints strictly match the legacy Laravel 12 `/api/v1/*`
  contracts and frozen Flutter client Dart models (Customer 1.0.18, Vendor 1.0.5, Rider 1.0.1).
  Use whenever implementing or modifying API Gateway routes, request transformers, or response serializers.
---

# Fattakse Contract Verifier Skill

This skill ensures 100% backward compatibility with frozen Flutter mobile clients by inspecting legacy contracts and testing API response envelopes.

## Workflow: How to Verify an API Contract

### Step 1: Locate the Canonical Reference in Legacy Monolith
1. Open the legacy route file:
   [`towns_fattakse_in/routes/api.php`](file:///home/vishwas/Pictures/fattakseInLocal/towns_fattakse_in/routes/api.php)
2. Locate the controller handling the route (e.g., `ProductController.php`, `OrderController.php`, `ConfigController.php`).
3. Note:
   - Request parameter validation rules.
   - Headers inspected (`zoneId`, `latitude`, `longitude`, `moduleId`).
   - JSON structure returned by the controller or API resource.

### Step 2: Inspect Frozen Flutter Dart Model
Check the corresponding Flutter repository to verify expected field types and nullability:
- **Customer App:** [`townsfattakappin_ios_android_user/lib/features/`](file:///home/vishwas/Pictures/fattakseInLocal/townsfattakappin_ios_android_user/lib/features/)
- **Vendor App:** [`townsfattakappin_ios_android_vendor/lib/features/`](file:///home/vishwas/Pictures/fattakseInLocal/townsfattakappin_ios_android_vendor/lib/features/)
- **Rider App:** [`townsfattakappin_ios_android_delivery_man/lib/features/`](file:///home/vishwas/Pictures/fattakseInLocal/townsfattakappin_ios_android_delivery_man/lib/features/)

Verify if `id` is integer or string, and check whether numeric prices are returned as doubles or strings.

### Step 3: Enforce Gateway Response Envelopes
Ensure the Fastify Gateway serializer outputs:
1. **Error format (HTTP 4xx/5xx):**
   ```json
   {
     "errors": [
       {
         "code": "<error_code>",
         "message": "<human_readable_message>"
       }
     ]
   }
   ```
2. **Paginated lists:**
   ```json
   {
     "total_size": 100,
     "limit": "20",
     "offset": "0",
     "products": [...]
   }
   ```

### Step 4: Run Automated Verification Script
Run the helper contract test script:
```bash
bash .agents/skills/fattakse-contract-verifier/scripts/verify-contract.sh <ENDPOINT_PATH>
```

For detailed schema structures, refer to [`references/flutter_response_envelopes.md`](./references/flutter_response_envelopes.md).
