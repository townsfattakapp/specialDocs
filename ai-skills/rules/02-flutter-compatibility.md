# Flutter Backward Compatibility Rule

This rule governs all interactions with consumer, vendor, and rider mobile applications.

## 1. Frozen Mobile Client Invariant
- The production Flutter mobile apps are compiled, signed, and frozen in production:
  * **Customer App:** Version `1.0.18` (`townsfattakappin_ios_android_user`)
  * **Vendor App:** Version `1.0.5` (`townsfattakappin_ios_android_vendor`)
  * **Rider App:** Version `1.0.1` (`townsfattakappin_ios_android_delivery_man`)
- **Zero App Store Updates:** Modernization must NOT require forcing users to download an app update.
- The new `api-gateway` must intercept all `/api/v1/*` traffic and emulate legacy Laravel monolith behavior with 100% fidelity.

## 2. Response Envelope Standards
- **Errors:** All error responses must return the exact legacy Laravel error envelope:
  ```json
  {
    "errors": [
      {
        "code": "auth-001",
        "message": "Unauthorized access"
      }
    ]
  }
  ```
- **Pagination Shape:** Paginated endpoints must match legacy shape:
  ```json
  {
    "total_size": 150,
    "limit": "20",
    "offset": "0",
    "products": [...]
  }
  ```
  Note: `limit` and `offset` in responses are frequently stringified integers in legacy Laravel. Gateway must preserve this exact format.

## 3. Header Normalization
- Flutter apps send geolocation and zone headers via custom headers:
  * `zoneId`: JSON string array (e.g., `"[1,2]"`) or integer.
  * `latitude` / `longitude`: Sent as headers or query parameters.
  * `moduleId`: Sent as header or query parameter.
- The `api-gateway` must parse, sanitize, and normalize these headers into standardized internal context before forwarding to downstream microservices.

## 4. Passport RSA JWT Token Emulation
- Existing logged-in mobile users authenticate via Laravel Passport OAuth tokens signed with a 4096-bit RSA private key (`oauth-private.key`).
- Gateway and `iam-service` must mount `oauth-public.key` to verify legacy JWT claims (`sub`, `scopes`, `exp`) without forcing user re-logins during or after cutover.
