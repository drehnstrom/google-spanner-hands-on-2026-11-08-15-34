-- Sample Data Insertion Script for Testing Schema and Integrity Constraints

-- 1. Insert Parent Records (Customers)
-- Note: CustomerId is automatically populated from CustomerSeq (bit-reversed positive integer)
INSERT INTO Customers (CustomerId, FullName, Email, Balance, Metadata, CreatedAt)
VALUES (
  GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq),
  'Alice Chen',
  'alice.chen@example.com',
  450.00,
  JSON '{"loyalty": {"tier": "PLATINUM", "points": 1420}, "preferences": {"notifications": true}}',
  PENDING_COMMIT_TIMESTAMP()
);

INSERT INTO Customers (CustomerId, FullName, Email, Balance, Metadata, CreatedAt)
VALUES (
  GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq),
  'Marcus Vance',
  'marcus.vance@example.com',
  125.50,
  JSON '{"loyalty": {"tier": "GOLD", "points": 880}, "preferences": {"notifications": false}}',
  PENDING_COMMIT_TIMESTAMP()
);

-- 2. Insert Interleaved Child Records (Orders)
-- Uses Alice's CustomerId
INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
SELECT
  CustomerId,
  'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
  CURRENT_TIMESTAMP(),
  180.00,
  'PROCESSING'
FROM Customers
WHERE Email = 'alice.chen@example.com';

-- 3. Insert Interleaved Grandchild Records (OrderItems)
INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
  1,
  'prod-sku-98124',
  2,
  45.00
FROM Customers
WHERE Email = 'alice.chen@example.com';

INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
  2,
  'prod-sku-34109',
  1,
  90.00
FROM Customers
WHERE Email = 'alice.chen@example.com';
