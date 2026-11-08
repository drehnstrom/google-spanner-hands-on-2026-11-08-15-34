-- PostgreSQL Dialect Schema and Sample Data for Cloud Spanner
-- Database: inventory-pg-db

CREATE TABLE inventory_items (
  item_id character varying(36) NOT NULL PRIMARY KEY,
  item_name character varying(128) NOT NULL,
  category character varying(64) NOT NULL,
  attributes jsonb,
  stock_count bigint NOT NULL
);

INSERT INTO inventory_items (item_id, item_name, category, attributes, stock_count)
VALUES
  ('prod-sku-98124', 'Wireless Noise-Canceling Headphones', 'Electronics', '{"brand": "AuraSound", "model": "NC-500", "specs": {"color": "black", "bluetooth": "5.3"}}', 150),
  ('prod-sku-34109', 'Ergonomic Mechanical Keyboard', 'Peripherals', '{"brand": "KeyCraft", "model": "Pro-Tenkeyless", "specs": {"switch": "tactile", "backlight": "RGB"}}', 85),
  ('prod-sku-10293', 'Ultra-Wide 4K Gaming Monitor', 'Displays', '{"brand": "VisionMax", "model": "VX-34", "specs": {"refresh_rate_hz": 144, "curved": true}}', 30),
  ('prod-sku-55412', 'Braided USB-C Fast Charging Cable', 'Accessories', '{"brand": "CableSync", "model": "ToughFlex-2m", "specs": {"length_meters": 2, "wattage": 100}}', 500),
  ('prod-sku-88219', 'Smart Home Ambient Light Bar', 'Smart Home', '{"brand": "Lumina", "model": "Bar-RGBW", "specs": {"matter_support": true, "voltage": 120}}', 110);
