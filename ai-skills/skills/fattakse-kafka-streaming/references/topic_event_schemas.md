# Kafka Topic Event Schemas Reference

All domain events published to Kafka must strictly conform to these JSON schema payloads.

## Common Event Envelope (All Topics)

```json
{
  "eventId": "0192e21b-839e-7164-9df9-34ba7d3a8264",
  "eventType": "OrderCreated",
  "topic": "fattakse.orders.lifecycle",
  "occurredAt": "2026-11-15T14:30:00.000Z",
  "producerService": "order-service",
  "version": 1,
  "payload": {}
}
```

---

## 1. Topic: `fattakse.orders.lifecycle`

### Event: `OrderCreated`
```json
{
  "orderId": 10245,
  "orderUid": "FTK-20261115-001",
  "customerId": 842,
  "storeId": 12,
  "zoneId": 1,
  "moduleType": "grocery",
  "orderAmountPaise": 48500,
  "deliveryChargePaise": 2500,
  "paymentMethod": "digital",
  "paymentStatus": "paid",
  "isTobaccoIncluded": false,
  "requiresDoorstepAgeCheck": false,
  "items": [
    {
      "itemId": 401,
      "variationId": null,
      "quantity": 2,
      "pricePaise": 23000
    }
  ]
}
```

### Event: `OrderPacked`
```json
{
  "orderId": 10245,
  "storeId": 12,
  "packerId": 55,
  "packedAt": "2026-11-15T14:36:20.000Z",
  "packageBagsCount": 1,
  "otp": "4892"
}
```

---

## 2. Topic: `fattakse.riders.telemetry`

### Event: `RiderLocationUpdated`
```json
{
  "riderId": 18,
  "latitude": 21.3060,
  "longitude": 79.9922,
  "headingDegrees": 180.5,
  "batteryPercentage": 82,
  "isOnline": true,
  "activeOrderId": 10245,
  "updatedAt": "2026-11-15T14:38:00.000Z"
}
```

---

## 3. Topic: `fattakse.inventory.adjustments`

### Event: `StockReserved`
```json
{
  "reservationId": "res_8492019",
  "orderId": 10245,
  "storeId": 12,
  "itemId": 401,
  "ownerType": "EVOLW_OWNED",
  "vendorId": null,
  "quantity": 2,
  "reservedAt": "2026-11-15T14:30:02.000Z"
}
```

---

## 4. Topic: `fattakse.finance.transactions`

### Event: `PaymentCaptured`
```json
{
  "transactionId": "txn_8923019",
  "orderId": 10245,
  "gatewayName": "razorpay",
  "gatewayPaymentId": "pay_O29dKsl290",
  "grossAmountPaise": 48500,
  "vendorSharePaise": 41225,
  "riderSharePaise": 3500,
  "platformCommissionPaise": 3775,
  "capturedAt": "2026-11-15T14:30:00.000Z"
}
```
