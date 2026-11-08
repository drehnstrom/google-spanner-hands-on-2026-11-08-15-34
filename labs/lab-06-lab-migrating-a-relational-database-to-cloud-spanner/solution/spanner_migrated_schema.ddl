-- Refactored Cloud Spanner GoogleSQL Schema
-- Addresses relational migration anti-patterns:
-- 1. Bit-reversed positive sequences eliminate monotonic key write hotspots
-- 2. Collocated interleaved table hierarchy eliminates distributed 2PC locks across splits
-- 3. ANSI data types mapped to Spanner GoogleSQL types (NUMERIC, INT64, STRING, TIMESTAMP)
-- 4. Secondary indexes deferred until post-bulk-load to prevent mutation amplification
-- 5. Change Stream created for zero-downtime cutover and reverse replication

-- Sequence for Customers primary key
CREATE SEQUENCE CustomerIdSeq OPTIONS (
  sequence_kind = 'bit_reversed_positive'
);

-- Sequence for Orders primary key
CREATE SEQUENCE OrderIdSeq OPTIONS (
  sequence_kind = 'bit_reversed_positive'
);

-- Parent Table: Customers
CREATE TABLE Customers (
  CustomerId INT64 DEFAULT (GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerIdSeq)),
  FirstName STRING(50) NOT NULL,
  LastName STRING(50) NOT NULL,
  Email STRING(100) NOT NULL,
  AccountBalance NUMERIC NOT NULL,
  CreatedAt TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true)
) PRIMARY KEY (CustomerId);

-- Child Table: Orders (interleaved under Customers)
CREATE TABLE Orders (
  CustomerId INT64 NOT NULL,
  OrderId INT64 DEFAULT (GET_NEXT_SEQUENCE_VALUE(SEQUENCE OrderIdSeq)),
  OrderDate TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
  TotalAmount NUMERIC NOT NULL,
  OrderStatus STRING(30) NOT NULL
) PRIMARY KEY (CustomerId, OrderId),
  INTERLEAVE IN PARENT Customers ON DELETE CASCADE;

-- Grandchild Table: OrderItems (interleaved under Orders)
CREATE TABLE OrderItems (
  CustomerId INT64 NOT NULL,
  OrderId INT64 NOT NULL,
  ItemId INT64 NOT NULL,
  ProductSku STRING(64) NOT NULL,
  Quantity INT64 NOT NULL,
  UnitPrice NUMERIC NOT NULL,
  LineTotal NUMERIC NOT NULL
) PRIMARY KEY (CustomerId, OrderId, ItemId),
  INTERLEAVE IN PARENT Orders ON DELETE CASCADE;

-- Deferred Secondary Index (Created post-load to optimize bulk ingestion)
-- CREATE INDEX idx_orders_customer_date ON Orders (CustomerId, OrderDate DESC);

-- Change Stream for cutover reverse-replication and rollback safety
CREATE CHANGE STREAM RetailCutoverStream
FOR ALL
OPTIONS (
  retention_period = '7d'
);
