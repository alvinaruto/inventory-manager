-- =============================================
-- Inventory Management System - Database Schema
-- PostgreSQL Database for Religious Offerings Shop
-- =============================================

-- Enable UUID extension for generating unique IDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- Users Table
-- Stores admin and staff accounts
-- =============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'staff' CHECK (role IN ('admin', 'staff')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster email lookups during login
CREATE INDEX idx_users_email ON users(email);

-- =============================================
-- Categories Table
-- Product categories (Spirit Houses, Incense, etc.)
-- =============================================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Products Table
-- Main inventory items
-- =============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    image_url TEXT,
    cost_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    cost_currency VARCHAR(3) DEFAULT 'USD',
    selling_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    selling_currency VARCHAR(3) DEFAULT 'USD',
    quantity_in_stock INTEGER NOT NULL DEFAULT 0,
    low_stock_threshold INTEGER NOT NULL DEFAULT 5,
    sku VARCHAR(100) UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for common queries
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_stock ON products(quantity_in_stock);

-- =============================================
-- Stock Movement History Table (Optional but recommended)
-- Track stock changes for auditing
-- =============================================
CREATE TABLE stock_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    change_type VARCHAR(50) NOT NULL CHECK (change_type IN ('addition', 'subtraction', 'adjustment', 'sale')),
    quantity_change INTEGER NOT NULL,
    previous_quantity INTEGER NOT NULL,
    new_quantity INTEGER NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX idx_stock_movements_date ON stock_movements(created_at);

-- =============================================
-- Function to auto-update 'updated_at' column
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to users table
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to categories table
CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to products table
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- Seed Data - Default Categories
-- =============================================
INSERT INTO categories (name, description, icon, display_order) VALUES
    ('Spirit Houses', 'Traditional Khmer spirit houses and shrines', 'temple_buddhist', 1),
    ('Statues', 'Buddha statues, deity figures, and religious sculptures', 'self_improvement', 2),
    ('Incense', 'Incense sticks, cones, and holders', 'local_fire_department', 3),
    ('Candles', 'Offering candles and ceremonial lights', 'emoji_objects', 4),
    ('Decorations', 'Religious decorations and ornaments', 'celebration', 5),
    ('Offerings', 'Food offerings, flowers, and ceremonial items', 'spa', 6),
    ('Accessories', 'Prayer beads, bells, and ritual accessories', 'diamond', 7);

-- =============================================
-- Seed Data - Default Admin User
-- Password: admin123 (bcrypt hashed)
-- IMPORTANT: Change this password in production!
-- =============================================
INSERT INTO users (email, password_hash, name, role) VALUES
    ('admin@shop.com', '$2a$10$rQnM1k6YhZTKvJvHvpHE0.fhnJAMD3T3xKJZvP0LdRhPxjKCm6G.e', 'Shop Admin', 'admin');

-- =============================================
-- Sample Products (Optional - for testing)
-- =============================================
INSERT INTO products (name, description, category_id, cost_price, selling_price, quantity_in_stock, low_stock_threshold, sku) VALUES
    (
        'Teak Wood Spirit House - Large',
        'Handcrafted large teak wood spirit house with intricate traditional Khmer carvings. Perfect for outdoor placement.',
        (SELECT id FROM categories WHERE name = 'Spirit Houses'),
        150.00,
        299.99,
        5,
        2,
        'SH-TK-LG-001'
    ),
    (
        'Golden Buddha Statue - Medium',
        'Beautiful gold-painted Buddha statue in meditation pose. Height: 30cm.',
        (SELECT id FROM categories WHERE name = 'Statues'),
        45.00,
        89.99,
        12,
        3,
        'ST-BD-MD-001'
    ),
    (
        'Sandalwood Incense Bundle (100 sticks)',
        'Premium sandalwood incense sticks. Long-lasting fragrance for meditation and offerings.',
        (SELECT id FROM categories WHERE name = 'Incense'),
        3.50,
        8.99,
        50,
        10,
        'IN-SW-100-001'
    ),
    (
        'Lotus Flower Candle Set',
        'Set of 5 lotus-shaped floating candles. Perfect for water offerings.',
        (SELECT id FROM categories WHERE name = 'Candles'),
        5.00,
        12.99,
        25,
        5,
        'CN-LT-SET-001'
    ),
    (
        'Ceramic Incense Holder - Dragon',
        'Decorative dragon-shaped ceramic incense holder with ash catcher.',
        (SELECT id FROM categories WHERE name = 'Accessories'),
        8.00,
        19.99,
        15,
        4,
        'AC-IH-DG-001'
    );

-- =============================================
-- Helpful Views
-- =============================================

-- View for low stock products
CREATE VIEW low_stock_products AS
SELECT 
    p.id,
    p.name,
    p.quantity_in_stock,
    p.low_stock_threshold,
    c.name as category_name
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.quantity_in_stock <= p.low_stock_threshold
AND p.is_active = true;

-- View for inventory value summary (Admin only view)
CREATE VIEW inventory_summary AS
SELECT 
    COUNT(*) as total_products,
    SUM(quantity_in_stock) as total_items_in_stock,
    SUM(quantity_in_stock * cost_price) as total_cost_value,
    SUM(quantity_in_stock * selling_price) as total_selling_value,
    SUM(quantity_in_stock * (selling_price - cost_price)) as potential_profit
FROM products
WHERE is_active = true;
