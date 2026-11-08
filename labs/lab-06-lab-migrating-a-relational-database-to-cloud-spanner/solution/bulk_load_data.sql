-- Bulk Migration Data Load
-- Historical records migrated from legacy relational database
-- Demonstrates structured mutation batching respecting Cloud Spanner limits:
-- Under 80,000 mutations and under 100 MB per commit batch

-- Batch 1: Customers
INSERT INTO Customers (CustomerId, FirstName, LastName, Email, AccountBalance, CreatedAt)
VALUES
  (1001, 'Marcus', 'Vance', 'marcus.vance@example.com', 450.00, TIMESTAMP '2025-01-15 10:00:00Z'),
  (1002, 'Elena', 'Reyes', 'elena.reyes@example.com', 1250.75, TIMESTAMP '2025-01-16 11:30:00Z'),
  (1003, 'Tariq', 'Mansoor', 'tariq.mansoor@example.com', 85.20, TIMESTAMP '2025-01-18 14:15:00Z'),
  (1004, 'Sophia', 'Chen', 'sophia.chen@example.com', 3200.00, TIMESTAMP '2025-01-20 09:00:00Z'),
  (1005, 'Liam', 'OConnor', 'liam.oconnor@example.com', 610.50, TIMESTAMP '2025-01-22 16:45:00Z');

-- Batch 2: Orders (Interleaved under Customers)
INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
VALUES
  (1001, 5001, TIMESTAMP '2025-02-01 08:30:00Z', 185.00, 'COMPLETED'),
  (1001, 5002, TIMESTAMP '2025-02-15 12:00:00Z', 265.00, 'COMPLETED'),
  (1002, 5003, TIMESTAMP '2025-02-10 15:45:00Z', 750.50, 'COMPLETED'),
  (1002, 5004, TIMESTAMP '2025-02-28 17:10:00Z', 500.25, 'PROCESSING'),
  (1003, 5005, TIMESTAMP '2025-02-05 11:20:00Z', 85.20, 'COMPLETED'),
  (1004, 5006, TIMESTAMP '2025-02-12 09:15:00Z', 1450.00, 'COMPLETED'),
  (1004, 5007, TIMESTAMP '2025-02-20 14:00:00Z', 1750.00, 'COMPLETED'),
  (1005, 5008, TIMESTAMP '2025-02-18 16:30:00Z', 610.50, 'DELIVERED');

-- Batch 3: OrderItems (Interleaved under Orders)
INSERT INTO OrderItems (CustomerId, OrderId, ItemId, ProductSku, Quantity, UnitPrice, LineTotal)
VALUES
  (1001, 5001, 1, 'SKU-HEADSET-PRO', 1, 185.00, 185.00),
  (1001, 5002, 1, 'SKU-KEYBOARD-MECH', 1, 140.00, 140.00),
  (1001, 5002, 2, 'SKU-MOUSE-WIRELESS', 1, 125.00, 125.00),
  (1002, 5003, 1, 'SKU-MONITOR-4K', 1, 650.00, 650.00),
  (1002, 5003, 2, 'SKU-CABLE-HDMI', 2, 50.25, 100.50),
  (1002, 5004, 1, 'SKU-DESK-MAT', 2, 45.00, 90.00),
  (1002, 5004, 2, 'SKU-DOCKING-STATION', 1, 410.25, 410.25),
  (1003, 5005, 1, 'SKU-WEBCAM-HD', 1, 85.20, 85.20),
  (1004, 5006, 1, 'SKU-LAPTOP-STAND', 2, 75.00, 150.00),
  (1004, 5006, 2, 'SKU-GPU-CARD-RTX', 1, 1300.00, 1300.00),
  (1004, 5007, 1, 'SKU-SERVER-RACK-CAB', 1, 1750.00, 1750.00),
  (1005, 5008, 1, 'SKU-CHAIR-ERGONOMIC', 1, 610.50, 610.50);
