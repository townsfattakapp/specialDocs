---
name: fattakse-kafka-streaming
description: >-
  Provides end-to-end patterns, schemas, and verification steps for Apache Kafka / Redpanda
  event streaming, Transactional Outbox publishing, and idempotent consumer workers.
  Use whenever publishing domain events, implementing Kafka consumers, or handling asynchronous order/rider/inventory workflows.
---

# Fattakse Kafka & Event Streaming Skill

This skill guides engineers and agents in implementing resilient, replayable event streaming across microservice boundaries using Redpanda / Apache Kafka and `kafkajs`.

## 1. Core Event Streaming Principles

1. **Transactional Outbox for Event Publishing:**
   Never publish directly to Kafka inside an active database transaction. Instead, persist the event to `outbox_events` in the same transaction:
   ```typescript
   // Inside Prisma transaction
   await prisma.outboxEvent.create({
     data: {
       id: uuidv7(),
       topic: 'fattakse.orders.lifecycle',
       eventKey: order.id.toString(),
       eventType: 'OrderCreated',
       payload: JSON.stringify(orderPayload),
       status: 'PENDING',
     },
   });
   ```
   A dedicated `KafkaOutboxService` polls `PENDING` outbox events and dispatches them to Kafka using `producer.send()`.

2. **Consumer Idempotency:**
   Every event payload includes a unique `eventId` (UUIDv7). Consumers MUST check and register this ID before taking business action:
   ```typescript
   await prisma.$transaction(async (tx) => {
     const alreadyProcessed = await tx.processedEvent.findUnique({
       where: { eventId },
     });
     if (alreadyProcessed) return; // Skip duplicate safely

     // Execute domain state change here...

     await tx.processedEvent.create({
       data: { eventId, topic, consumerGroup, processedAt: new Date() },
     });
   });
   ```

3. **Partition Key Routing:**
   Always assign an explicit `eventKey`:
   - `fattakse.orders.lifecycle` -> `order_id` (preserves sequence: Created -> Accepted -> Packed -> Delivered)
   - `fattakse.riders.telemetry` -> `rider_id`
   - `fattakse.inventory.adjustments` -> `${store_id}:${item_id}`
   - `fattakse.finance.transactions` -> `transaction_id`

## 2. Topic Schema Validation

Before publishing or consuming, validate payloads with Zod schemas.
See [`references/topic_event_schemas.md`](./references/topic_event_schemas.md) for complete payload specifications.

## 3. Local Cluster Verification

Verify local Redpanda / Kafka readiness using the helper script:
```bash
bash .agents/skills/fattakse-kafka-streaming/scripts/check-kafka-health.sh
```
