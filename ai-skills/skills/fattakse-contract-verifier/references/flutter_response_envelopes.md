# Flutter Client Response Envelopes Reference

This reference documents the exact JSON responses expected by frozen Flutter clients (`Customer 1.0.18`, `Vendor 1.0.5`, `Rider 1.0.1`).

## 1. Authentication Responses (`/api/v1/auth/login`)

```json
{
  "token": "eyJhbGciOiJSUzI1NiIs...",
  "is_phone_verified": 1,
  "phone_verify_end_url": "",
  "user": {
    "id": 42,
    "f_name": "Ramesh",
    "l_name": "Patil",
    "phone": "+919876543210",
    "email": "ramesh@example.com",
    "image": "profile/ramesh.jpg",
    "is_phone_verified": 1,
    "email_verified_at": null,
    "created_at": "2026-03-15T10:00:00.000000Z",
    "updated_at": "2026-03-15T10:00:00.000000Z",
    "order_count": 5,
    "wallet_balance": 150.00,
    "loyalty_point": 25
  }
}
```

## 2. Config Endpoint (`/api/v1/config`)

The Flutter customer app validates configuration parameters at startup:

```json
{
  "business_name": "Fattakse",
  "logo": "logo.png",
  "currency_symbol": "₹",
  "currency_symbol_direction": "left",
  "app_minimum_version_android": 1018,
  "app_minimum_version_ios": 1018,
  "maintenance_mode": false,
  "country": "IN",
  "default_location": {
    "lat": "21.3060",
    "lng": "79.9922"
  },
  "customer_verification": {
    "status": 1,
    "phone": 1,
    "email": 0,
    "firebase": 0
  },
  "modules": [
    {
      "id": 1,
      "module_name": "Grocery",
      "module_type": "grocery",
      "status": "1"
    },
    {
      "id": 2,
      "module_name": "Food",
      "module_type": "food",
      "status": "1"
    }
  ]
}
```
*Note:* Module 4 (Paan Corner) must be omitted when `X-Client-Type: flutter-mobile`.

## 3. Standard Error Envelope (HTTP 400/401/403/404/422/500)

```json
{
  "errors": [
    {
      "code": "l_name",
      "message": "The last name field is required."
    }
  ]
}
```
Never return `{ "status": false, "message": "error" }` or NestJS default `{ "statusCode": 400, "message": [...] }` directly to mobile clients. The Gateway exception filter must map all errors to `{ "errors": [ { "code", "message" } ] }`.
