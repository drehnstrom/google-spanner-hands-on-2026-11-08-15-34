-- Fine-Grained Access Control (FGAC) Database Roles and Privilege Grants
-- Dialect: GoogleSQL

-- Role: reporting_analyst
-- Has full read access to Customers, and column-restricted read access to Orders
CREATE ROLE reporting_analyst;

GRANT SELECT ON TABLE Customers TO ROLE reporting_analyst;

GRANT SELECT (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus) ON TABLE Orders TO ROLE reporting_analyst;

-- Role: order_manager
-- Has read, insert, and update privileges on Orders
CREATE ROLE order_manager;

GRANT SELECT, INSERT, UPDATE ON TABLE Orders TO ROLE order_manager;
