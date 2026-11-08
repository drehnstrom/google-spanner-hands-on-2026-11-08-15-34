-- Sample Data Population Script for Lab 3
-- Populates multi-tier retail data across Customers, Orders, and OrderItems

-- 1. Insert Additional Customers across different tiers
INSERT INTO Customers (CustomerId, FullName, Email, Balance, Metadata, CreatedAt)
VALUES (
  GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq),
  'Sophia Rodriguez',
  'sophia.rodriguez@example.com',
  750.25,
  JSON '{"loyalty": {"tier": "PLATINUM", "points": 3200}, "preferences": {"notifications": true, "channel": "email"}}',
  PENDING_COMMIT_TIMESTAMP()
);

INSERT INTO Customers (CustomerId, FullName, Email, Balance, Metadata, CreatedAt)
VALUES (
  GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq),
  'Devon Park',
  'devon.park@example.com',
  42.00,
  JSON '{"loyalty": {"tier": "SILVER", "points": 450}, "preferences": {"notifications": false, "channel": "sms"}}',
  PENDING_COMMIT_TIMESTAMP()
);

INSERT INTO Customers (CustomerId, FullName, Email, Balance, Metadata, CreatedAt)
VALUES (
  GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq),
  'Amina Idris',
  'amina.idris@example.com',
  0.00,
  JSON '{"loyalty": {"tier": "BRONZE", "points": 80}, "preferences": {"notifications": true, "channel": "email"}}',
  PENDING_COMMIT_TIMESTAMP()
);

-- 2. Insert Orders for Sophia Rodriguez (Multiple orders across dates and statuses)
INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
SELECT
  CustomerId,
  'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e',
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY),
  340.00,
  'DELIVERED'
FROM Customers
WHERE Email = 'sophia.rodriguez@example.com';

INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
SELECT
  CustomerId,
  'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f',
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY),
  410.25,
  'PROCESSING'
FROM Customers
WHERE Email = 'sophia.rodriguez@example.com';

-- 3. Insert Orders for Devon Park
INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
SELECT
  CustomerId,
  'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a',
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 25 DAY),
  42.00,
  'SHIPPED'
FROM Customers
WHERE Email = 'devon.park@example.com';

-- 4. Insert Orders for Marcus Vance (inserted in Lab 2)
INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
SELECT
  CustomerId,
  'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b',
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 DAY),
  125.50,
  'DELIVERED'
FROM Customers
WHERE Email = 'marcus.vance@example.com';

-- 5. Insert Interleaved OrderItems for Sophia's Orders
INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e',
  1,
  'prod-sku-10293',
  2,
  120.00
FROM Customers
WHERE Email = 'sophia.rodriguez@example.com';

INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e',
  2,
  'prod-sku-55412',
  1,
  100.00
FROM Customers
WHERE Email = 'sophia.rodriguez@example.com';

INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f',
  1,
  'prod-sku-88219',
  3,
  136.75
FROM Customers
WHERE Email = 'sophia.rodriguez@example.com';

-- 6. Insert OrderItems for Devon's Order
INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a',
  1,
  'prod-sku-34109',
  1,
  42.00
FROM Customers
WHERE Email = 'devon.park@example.com';

-- 7. Insert OrderItems for Marcus's Order
INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b',
  1,
  'prod-sku-98124',
  1,
  125.50
FROM Customers
WHERE Email = 'marcus.vance@example.com';
