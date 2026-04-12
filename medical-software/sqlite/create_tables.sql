-- 创建医疗器械管理系统SQLite数据库表结构
-- 基于今天从云服务器导出的5个表

-- 1. 业务合作伙伴表
CREATE TABLE IF NOT EXISTS business_partner (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    partner_code TEXT NOT NULL UNIQUE,
    partner_name TEXT NOT NULL,
    partner_type TEXT CHECK(partner_type IN ('supplier', 'customer', 'distributor')),
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    tax_id TEXT,
    credit_limit REAL DEFAULT 0.0,
    current_balance REAL DEFAULT 0.0,
    status TEXT DEFAULT 'active' CHECK(status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 产品目录表
CREATE TABLE IF NOT EXISTS product_catalog (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_code TEXT NOT NULL UNIQUE,
    product_name TEXT NOT NULL,
    product_type TEXT CHECK(product_type IN ('medical_device', 'consumable', 'equipment', 'software')),
    category TEXT,
    manufacturer TEXT,
    model TEXT,
    specification TEXT,
    unit_price REAL NOT NULL DEFAULT 0.0,
    unit_cost REAL DEFAULT 0.0,
    unit_of_measure TEXT DEFAULT 'piece',
    min_stock_level INTEGER DEFAULT 10,
    max_stock_level INTEGER DEFAULT 100,
    shelf_life_months INTEGER,
    storage_condition TEXT,
    regulatory_certification TEXT,
    status TEXT DEFAULT 'active' CHECK(status IN ('active', 'discontinued', 'pending')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. 库存表
CREATE TABLE IF NOT EXISTS inventory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    batch_number TEXT NOT NULL,
    warehouse_location TEXT,
    quantity_on_hand INTEGER NOT NULL DEFAULT 0,
    quantity_reserved INTEGER DEFAULT 0,
    quantity_available INTEGER GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) VIRTUAL,
    production_date DATE,
    expiration_date DATE,
    purchase_price REAL,
    current_value REAL GENERATED ALWAYS AS (quantity_on_hand * purchase_price) VIRTUAL,
    storage_condition TEXT,
    quality_status TEXT DEFAULT 'good' CHECK(quality_status IN ('good', 'damaged', 'expired', 'quarantine')),
    last_count_date DATE,
    next_count_date DATE,
    notes TEXT,
    FOREIGN KEY (product_id) REFERENCES product_catalog(id) ON DELETE CASCADE
);

-- 4. 采购验收表
CREATE TABLE IF NOT EXISTS purchase_acceptance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    po_number TEXT NOT NULL UNIQUE,
    supplier_id INTEGER NOT NULL,
    acceptance_date DATE NOT NULL,
    total_items INTEGER NOT NULL,
    total_value REAL NOT NULL,
    inspector TEXT,
    acceptance_status TEXT DEFAULT 'pending' CHECK(acceptance_status IN ('pending', 'accepted', 'rejected', 'partial')),
    rejection_reason TEXT,
    quality_check_passed BOOLEAN DEFAULT 1,
    documentation_complete BOOLEAN DEFAULT 1,
    storage_location TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES business_partner(id)
);

-- 5. 销售交付表
CREATE TABLE IF NOT EXISTS sales_delivery (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    delivery_number TEXT NOT NULL UNIQUE,
    customer_id INTEGER NOT NULL,
    delivery_date DATE NOT NULL,
    total_items INTEGER NOT NULL,
    total_value REAL NOT NULL,
    delivery_method TEXT CHECK(delivery_method IN ('pickup', 'delivery', 'express')),
    delivery_status TEXT DEFAULT 'pending' CHECK(delivery_status IN ('pending', 'in_transit', 'delivered', 'cancelled')),
    tracking_number TEXT,
    recipient_name TEXT,
    recipient_phone TEXT,
    delivery_address TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES business_partner(id)
);

-- 创建索引以提高查询性能
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_batch ON inventory(batch_number);
CREATE INDEX idx_inventory_expiry ON inventory(expiration_date);
CREATE INDEX idx_purchase_supplier ON purchase_acceptance(supplier_id);
CREATE INDEX idx_sales_customer ON sales_delivery(customer_id);
CREATE INDEX idx_product_code ON product_catalog(product_code);
CREATE INDEX idx_partner_code ON business_partner(partner_code);

-- 创建视图便于查询
CREATE VIEW IF NOT EXISTS v_inventory_summary AS
SELECT 
    p.product_code,
    p.product_name,
    p.category,
    SUM(i.quantity_on_hand) as total_quantity,
    SUM(i.quantity_reserved) as total_reserved,
    SUM(i.quantity_available) as total_available,
    AVG(i.purchase_price) as avg_cost,
    SUM(i.current_value) as total_value
FROM product_catalog p
LEFT JOIN inventory i ON p.id = i.product_id
GROUP BY p.id, p.product_code, p.product_name, p.category;

-- 插入一些测试数据（可选）
INSERT OR IGNORE INTO business_partner (partner_code, partner_name, partner_type, contact_person, phone, email) VALUES
('SUP001', '医疗设备供应商A', 'supplier', '张经理', '13800138001', 'supplier_a@example.com'),
('CUST001', '人民医院', 'customer', '王主任', '13900139001', 'hospital@example.com');

INSERT OR IGNORE INTO product_catalog (product_code, product_name, product_type, category, manufacturer, unit_price) VALUES
('PD001', '电子血压计', 'medical_device', '监测设备', '医疗科技公司', 299.00),
('PD002', '医用口罩', 'consumable', '防护用品', '防护用品厂', 2.50);

-- 更新检查脚本
PRAGMA foreign_keys = ON;
SELECT '数据库创建完成，表结构已就绪' as status;