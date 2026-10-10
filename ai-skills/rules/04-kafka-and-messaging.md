# Kafka & Hybrid Messaging Architecture Rule

This rule defines the asynchronous messaging topology and streaming standards.

## 1. Hybrid Messaging Model
- **Event Streaming Backbone:** Redpanda / Apache Kafka (using `kafkajs`).
  * Used for persistent, replayable domain events across service boundaries.
  * Guarantees immutable audit trail and multi-consumer pub/sub.
- **Delayed Timers & Transient Queues:** Redis 7.2 BullMQ.
  * Used strictly for scheduled countdowns (e.g. 3-minute restaurant acceptance timeout, 10-minute OTP expiration, push notification retries).

## 2. Standard Kafka Topics
1. `fattakse.orders.lifecycle`:
   - Key: `order_id` (guarantees in-order delivery per order partition).
   - Events: `OrderCreated`, `OrderPaid`, `OrderAcceptedByVendor`, `OrderPacked`, `OrderPickedUp`, `OrderDelivered`, `OrderCancelled`.
2. `fattakse.riders.telemetry`:
   - Key: `rider_id`.
   - Events: `RiderLocationUpdated`, `RiderShiftStarted`, `RiderShiftEnded`, `RiderAssigned`.
3. `fattakse.inventory.adjustments`:
   - Key: `store_id:item_id`.
   - Events: `StockReserved`, `StockReleased`, `StockDeducted`, `StockDeposited`, `StockWithdrawn`.
4. `fattakse.finance.transactions`:
   - Key: `transaction_id`.
   - Events: `PaymentCaptured`, `VendorDisbursed`, `RiderPayoutCredited`, `RefundIssued`.

## 3. Transactional Outbox Pattern
- Microservices MUST NOT publish directly to Kafka within an active database transaction.
- Instead, services write the event to a local `outbox_events` table in the same database transaction.
- A background worker (`KafkaOutboxService`) polls `outbox_events` or reads DB change streams to publish to Kafka with at-least-once delivery semantics.

## 4. Consumer Idempotency
- All Kafka consumers must be idempotent.
- Every incoming event has a unique `eventId` (UUIDv7).
- Consumers must check and write to a `processed_events` table inside their local database transaction to prevent duplicate processing during consumer rebalances or redeliveries.
