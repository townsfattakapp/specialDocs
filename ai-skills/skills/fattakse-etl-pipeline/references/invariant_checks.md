# Database Migration Invariant SQL Checks Reference

Run these SQL queries after any ETL migration stage (local, rehearsal, or cutover) to mathematically prove data integrity.

## Invariant 1: Zero Orphaned Order Items
Check that every migrated order item references a valid order and item:
```sql
SELECT COUNT(*) AS orphaned_items_count
FROM fattakse_order.order_items oi
LEFT JOIN fattakse_order.orders o ON oi.order_id = o.id
WHERE o.id IS NULL;
-- Expected Result: 0
```

## Invariant 2: Total Item Subtotal Matches Order Amount
```sql
SELECT o.id, o.order_amount_paise, SUM(oi.price_paise * oi.quantity) AS computed_items_paise
FROM fattakse_order.orders o
JOIN fattakse_order.order_items oi ON o.id = oi.order_id
GROUP BY o.id, o.order_amount_paise, o.delivery_charge_paise, o.coupon_discount_paise
HAVING o.order_amount_paise != (SUM(oi.price_paise * oi.quantity) + o.delivery_charge_paise - o.coupon_discount_paise);
-- Expected Result: 0 rows returned
```

## Invariant 3: Single-Writer Boundary Audit
Ensure no legacy POS tables were imported into target databases:
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema LIKE 'fattakse_%'
  AND (table_name LIKE 'pos_%' OR table_name LIKE 'hyper_pos_%');
-- Expected Result: 0 rows returned
```

## Invariant 4: No Negative Inventory Balances
```sql
SELECT * FROM fattakse_inventory.stock_balances
WHERE available_qty < 0 OR reserved_qty < 0;
-- Expected Result: 0 rows returned
```
