-- Cloud Spanner GoogleSQL Schema Definition
-- Retail Order Management System with Interleaved Tables

CREATE SEQUENCE CustomerSeq OPTIONS (
  sequence_kind = 'bit_reversed_positive'
);

CREATE TABLE Customers (
  CustomerId INT64 DEFAULT (GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq)),
  FullName STRING(128) NOT NULL,
  Email STRING(256) NOT NULL,
  Balance NUMERIC,
  Metadata JSON,
  CreatedAt TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
  CustomerTier STRING(32) AS (JSON_VALUE(Metadata, '$.loyalty.tier')) STORED,
  CONSTRAINT chk_customer_balance CHECK (Balance >= 0),
  CONSTRAINT chk_customer_tier CHECK (CustomerTier IS NULL OR CustomerTier IN ('BRONZE', 'SILVER', 'GOLD', 'PLATINUM'))
) PRIMARY KEY (CustomerId);

CREATE TABLE Orders (
  CustomerId INT64 NOT NULL,
  OrderId STRING(36) NOT NULL DEFAULT (GENERATE_UUID()),
  OrderDate TIMESTAMP NOT NULL,
  TotalAmount NUMERIC NOT NULL,
  OrderStatus STRING(32) NOT NULL,
  CONSTRAINT chk_order_total CHECK (TotalAmount >= 0),
  CONSTRAINT chk_order_status CHECK (OrderStatus IN ('PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'))
) PRIMARY KEY (CustomerId, OrderId),
  INTERLEAVE IN PARENT Customers ON DELETE CASCADE;

CREATE TABLE OrderItems (
  CustomerId INT64 NOT NULL,
  OrderId STRING(36) NOT NULL,
  LineItem INT64 NOT NULL,
  ProductId STRING(36) NOT NULL,
  Quantity INT64 NOT NULL,
  UnitPrice NUMERIC NOT NULL,
  CONSTRAINT chk_quantity CHECK (Quantity > 0),
  CONSTRAINT chk_unit_price CHECK (UnitPrice >= 0)
) PRIMARY KEY (CustomerId, OrderId, LineItem),
  INTERLEAVE IN PARENT Orders ON DELETE CASCADE;

CREATE INDEX idx_orders_date_covering
ON Orders (OrderDate)
STORING (TotalAmount, OrderStatus);

CREATE INDEX idx_orders_customer_status
ON Orders (CustomerId, OrderStatus),
INTERLEAVE IN Customers;

CREATE INDEX idx_customers_tier
ON Customers (CustomerTier);
