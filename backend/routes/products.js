const express = require('express');
const router = express.Router();
const { body, query, validationResult } = require('express-validator');
const fs = require('fs');
const db = require('../config/database');
const { authenticate, isAdmin, isAdminOrStaff } = require('../middleware/auth');
const { upload, handleUploadError } = require('../middleware/upload');
const { uploadImage, deleteImage } = require('../config/cloudinary');

// Validation rules
const productValidation = [
    body('name').trim().notEmpty().withMessage('Product name is required'),
    body('nameKm').optional().trim(),
    body('description').optional().trim(),
    body('categoryId').optional().isUUID().withMessage('Invalid category ID'),
    body('costPrice').isFloat({ min: 0 }).withMessage('Cost price must be a positive number'),
    body('sellingPrice').isFloat({ min: 0 }).withMessage('Selling price must be a positive number'),
    body('costCurrency').optional().isIn(['USD', 'KHR']).withMessage('Invalid cost currency'),
    body('sellingCurrency').optional().isIn(['USD', 'KHR']).withMessage('Invalid selling currency'),
    body('quantityInStock').isInt({ min: 0 }).withMessage('Quantity must be a non-negative integer'),
    body('lowStockThreshold').optional().isInt({ min: 0 }).withMessage('Threshold must be a non-negative integer'),
    body('sku').optional().trim()
];

const stockUpdateValidation = [
    body('quantity').isInt().withMessage('Quantity must be an integer'),
    body('type').isIn(['set', 'add', 'subtract']).withMessage('Type must be set, add, or subtract'),
    body('notes').optional().trim()
];

// @route   GET /api/products
// @desc    Get all products with filtering and search
// @access  Private
router.get('/', authenticate, [
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('search').optional().trim(),
    query('categoryId').optional().isUUID(),
    query('stockStatus').optional().isIn(['all', 'in_stock', 'low_stock', 'out_of_stock'])
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const offset = (page - 1) * limit;
        const { search, categoryId, stockStatus } = req.query;
        const isAdminUser = req.user.role === 'admin';

        // Build query
        let whereClause = 'WHERE p.is_active = true';
        const params = [];
        let paramIndex = 1;

        if (search) {
            whereClause += ` AND (LOWER(p.name) LIKE LOWER($${paramIndex}) OR LOWER(p.sku) LIKE LOWER($${paramIndex}) OR LOWER(p.name_km) LIKE LOWER($${paramIndex}))`;
            params.push(`%${search}%`);
            paramIndex++;
        }

        if (categoryId) {
            whereClause += ` AND p.category_id = $${paramIndex}`;
            params.push(categoryId);
            paramIndex++;
        }

        if (stockStatus && stockStatus !== 'all') {
            if (stockStatus === 'out_of_stock') {
                whereClause += ' AND p.quantity_in_stock = 0';
            } else if (stockStatus === 'low_stock') {
                whereClause += ' AND p.quantity_in_stock > 0 AND p.quantity_in_stock <= p.low_stock_threshold';
            } else if (stockStatus === 'in_stock') {
                whereClause += ' AND p.quantity_in_stock > p.low_stock_threshold';
            }
        }

        // Select fields based on user role (hide cost_price for staff)
        const selectFields = isAdminUser
            ? `p.id, p.name, p.name_km, p.description, p.category_id, p.image_url, 
         p.cost_price, p.cost_currency, p.selling_price, p.selling_currency, p.quantity_in_stock, 
         p.low_stock_threshold, p.sku, p.created_at, p.updated_at,
         c.name as category_name,
         (p.selling_price - p.cost_price) as profit_margin`
            : `p.id, p.name, p.name_km, p.description, p.category_id, p.image_url, 
         p.selling_price, p.selling_currency, p.quantity_in_stock, 
         p.low_stock_threshold, p.sku, p.created_at, p.updated_at,
         c.name as category_name`;

        // Get total count
        const countResult = await db.query(
            `SELECT COUNT(*) FROM products p ${whereClause}`,
            params
        );
        const totalItems = parseInt(countResult.rows[0].count);
        const totalPages = Math.ceil(totalItems / limit);

        // Get products
        const result = await db.query(
            `SELECT ${selectFields}
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       ${whereClause}
       ORDER BY p.created_at DESC
       LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
            [...params, limit, offset]
        );

        // Add stock status to each product
        const products = result.rows.map(product => ({
            ...product,
            stockStatus: product.quantity_in_stock === 0
                ? 'out_of_stock'
                : product.quantity_in_stock <= product.low_stock_threshold
                    ? 'low_stock'
                    : 'in_stock'
        }));

        res.json({
            success: true,
            data: products,
            pagination: {
                currentPage: page,
                totalPages,
                totalItems,
                itemsPerPage: limit,
                hasNextPage: page < totalPages,
                hasPrevPage: page > 1
            }
        });
    } catch (error) {
        console.error('Get products error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// @route   GET /api/products/:id
// @desc    Get single product
// @access  Private
router.get('/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        const isAdminUser = req.user.role === 'admin';

        const selectFields = isAdminUser
            ? `p.*, c.name as category_name, (p.selling_price - p.cost_price) as profit_margin`
            : `p.id, p.name, p.name_km, p.description, p.category_id, p.image_url, 
         p.selling_price, p.selling_currency, p.quantity_in_stock, p.low_stock_threshold, p.sku, 
         p.created_at, p.updated_at, c.name as category_name`;

        const result = await db.query(
            `SELECT ${selectFields}
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.id = $1 AND p.is_active = true`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Product not found' });
        }

        const product = {
            ...result.rows[0],
            stockStatus: result.rows[0].quantity_in_stock === 0
                ? 'out_of_stock'
                : result.rows[0].quantity_in_stock <= result.rows[0].low_stock_threshold
                    ? 'low_stock'
                    : 'in_stock'
        };

        res.json({ success: true, data: product });
    } catch (error) {
        console.error('Get product error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// @route   POST /api/products
// @desc    Create a new product
// @access  Private (Admin only)
router.post('/', authenticate, isAdmin, upload.single('image'), handleUploadError, productValidation, async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { name, nameKm, description, categoryId, costPrice, sellingPrice, quantityInStock, lowStockThreshold, sku, costCurrency, sellingCurrency } = req.body;

        // Check for duplicate SKU if provided
        if (sku) {
            const existingSku = await db.query(
                'SELECT id FROM products WHERE sku = $1 AND is_active = true',
                [sku]
            );
            if (existingSku.rows.length > 0) {
                return res.status(400).json({ success: false, message: 'SKU already exists' });
            }
        }

        // Upload image if provided
        let imageUrl = null;
        if (req.file) {
            try {
                const uploadResult = await uploadImage(req.file.path, 'inventory/products');
                imageUrl = uploadResult.url;
                // Clean up temp file
                fs.unlinkSync(req.file.path);
            } catch (uploadError) {
                console.error('Image upload error:', uploadError);
            }
        }

        const result = await db.query(
            `INSERT INTO products (name, name_km, description, category_id, image_url, cost_price, selling_price, quantity_in_stock, low_stock_threshold, sku, cost_currency, selling_currency)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       RETURNING *`,
            [name, nameKm || null, description || null, categoryId || null, imageUrl, costPrice, sellingPrice, quantityInStock || 0, lowStockThreshold || 5, sku || null, costCurrency || 'USD', sellingCurrency || 'USD']
        );

        res.status(201).json({
            success: true,
            message: 'Product created successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Create product error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// @route   PUT /api/products/:id
// @desc    Update a product
// @access  Private (Admin only)
router.put('/:id', authenticate, isAdmin, upload.single('image'), handleUploadError, productValidation, async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { id } = req.params;
        const { name, nameKm, description, categoryId, costPrice, sellingPrice, quantityInStock, lowStockThreshold, sku, costCurrency, sellingCurrency } = req.body;

        // Check if product exists
        const existing = await db.query(
            'SELECT id, image_url FROM products WHERE id = $1 AND is_active = true',
            [id]
        );

        if (existing.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Product not found' });
        }

        // Check for duplicate SKU if provided
        if (sku) {
            const existingSku = await db.query(
                'SELECT id FROM products WHERE sku = $1 AND id != $2 AND is_active = true',
                [sku, id]
            );
            if (existingSku.rows.length > 0) {
                return res.status(400).json({ success: false, message: 'SKU already exists' });
            }
        }

        // Upload new image if provided
        let imageUrl = existing.rows[0].image_url;
        if (req.file) {
            try {
                const uploadResult = await uploadImage(req.file.path, 'inventory/products');
                imageUrl = uploadResult.url;
                fs.unlinkSync(req.file.path);
            } catch (uploadError) {
                console.error('Image upload error:', uploadError);
            }
        }

        const result = await db.query(
            `UPDATE products 
       SET name = $1, name_km = $2, description = $3, category_id = $4, image_url = $5, 
           cost_price = $6, selling_price = $7, quantity_in_stock = $8, 
           low_stock_threshold = $9, sku = $10, cost_currency = $11, selling_currency = $12
       WHERE id = $13
       RETURNING *`,
            [name, nameKm || null, description || null, categoryId || null, imageUrl, costPrice, sellingPrice, quantityInStock || 0, lowStockThreshold || 5, sku || null, costCurrency || 'USD', sellingCurrency || 'USD', id]
        );

        res.json({
            success: true,
            message: 'Product updated successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Update product error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// @route   PATCH /api/products/:id/stock
// @desc    Update product stock quantity (Admin or Staff)
// @access  Private
router.patch('/:id/stock', authenticate, isAdminOrStaff, stockUpdateValidation, async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { id } = req.params;
        const { quantity, type, notes } = req.body;

        // Get current product
        const existing = await db.query(
            'SELECT id, quantity_in_stock FROM products WHERE id = $1 AND is_active = true',
            [id]
        );

        if (existing.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Product not found' });
        }

        const currentQuantity = existing.rows[0].quantity_in_stock;
        let newQuantity;

        if (type === 'set') {
            newQuantity = quantity;
        } else if (type === 'add') {
            newQuantity = currentQuantity + quantity;
        } else if (type === 'subtract') {
            newQuantity = currentQuantity - quantity;
        }

        if (newQuantity < 0) {
            return res.status(400).json({
                success: false,
                message: 'Stock cannot be negative'
            });
        }

        // Update product stock
        const result = await db.query(
            'UPDATE products SET quantity_in_stock = $1 WHERE id = $2 RETURNING *',
            [newQuantity, id]
        );

        // Record stock movement
        await db.query(
            `INSERT INTO stock_movements (product_id, user_id, change_type, quantity_change, previous_quantity, new_quantity, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [id, req.user.id, type === 'add' ? 'addition' : type === 'subtract' ? 'subtraction' : 'adjustment',
                type === 'set' ? newQuantity - currentQuantity : quantity, currentQuantity, newQuantity, notes || null]
        );

        res.json({
            success: true,
            message: 'Stock updated successfully',
            data: {
                previousQuantity: currentQuantity,
                newQuantity: newQuantity,
                product: result.rows[0]
            }
        });
    } catch (error) {
        console.error('Update stock error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// @route   DELETE /api/products/:id
// @desc    Soft delete a product
// @access  Private (Admin only)
router.delete('/:id', authenticate, isAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        const existing = await db.query(
            'SELECT id FROM products WHERE id = $1 AND is_active = true',
            [id]
        );

        if (existing.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Product not found' });
        }

        // Soft delete
        await db.query(
            'UPDATE products SET is_active = false WHERE id = $1',
            [id]
        );

        res.json({
            success: true,
            message: 'Product deleted successfully'
        });
    } catch (error) {
        console.error('Delete product error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

module.exports = router;
