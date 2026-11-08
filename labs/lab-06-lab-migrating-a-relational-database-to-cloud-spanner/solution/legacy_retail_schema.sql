-- Legacy Relational Schema (MySQL 8.0 Dialect)
-- Demonstrates traditional monolithic relational database patterns:
-- 1. Sequential AUTO_INCREMENT integer primary keys (hotspot anti-pattern on Spanner)
-- 2. Non-interleaved foreign key constraints requiring distributed cross-split locking
-- 3. Stored procedural triggers not supported on Cloud Spanner
-- 4. Unbounded or engine-specific data types

CREATE DATABASE IF NOT EXISTS legacy_retail;
USE legacy_retail;

-- Parent Table: Customers
CREATE TABLE customers (
    customer_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    account_balance DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Child Table: Orders (1:N with customers)
CREATE TABLE orders (
    order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(12, 2) NOT NULL,
    order_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Secondary index on legacy orders (amplifies write mutations if active during bulk load)
CREATE INDEX idx_legacy_orders_date ON orders (order_date);

-- Grandchild Table: Order Items (1:N with orders)
CREATE TABLE order_items (
    item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_sku VARCHAR(64) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    line_total DECIMAL(12, 2) NOT NULL,
    CONSTRAINT fk_items_order FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- Legacy procedural trigger (Spanner feature gap: must be moved to application code)
DELIMITER //
CREATE TRIGGER trg_after_order_insert
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    UPDATE customers
    SET account_balance = account_balance - NEW.total_amount
    WHERE customer_id = NEW.customer_id;
END;
//
DELIMITER ;
