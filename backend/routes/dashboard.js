const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticate } = require('../middleware/auth');

// @route   GET /api/dashboard/stats
// @desc    Get dashboard statistics
// @access  Private (Admin gets full data, Staff gets limited data)
router.get('/stats', authenticate, async (req, res) => {
    try {
        const isAdminUser = req.user.role === 'admin';

        // Get total products count
        const totalProductsResult = await db.query(
            'SELECT COUNT(*) as count FROM products WHERE is_active = true'
        );
        const totalProducts = parseInt(totalProductsResult.rows[0].count);

        // Get total items in stock
        const totalItemsResult = await db.query(
            'SELECT COALESCE(SUM(quantity_in_stock), 0) as total FROM products WHERE is_active = true'
        );
        const totalItemsInStock = parseInt(totalItemsResult.rows[0].total);

        // Get low stock products count
        const lowStockResult = await db.query(
            `SELECT COUNT(*) as count FROM products 
       WHERE is_active = true 
       AND quantity_in_stock > 0 
       AND quantity_in_stock <= low_stock_threshold`
        );
        const lowStockCount = parseInt(lowStockResult.rows[0].count);

        // Get out of stock products count
        const outOfStockResult = await db.query(
            'SELECT COUNT(*) as count FROM products WHERE is_active = true AND quantity_in_stock = 0'
        );
        const outOfStockCount = parseInt(outOfStockResult.rows[0].count);

        // Get category breakdown
        const categoryBreakdownResult = await db.query(
            `SELECT c.id, c.name, COUNT(p.id) as product_count, 
              COALESCE(SUM(p.quantity_in_stock), 0) as total_items
       FROM categories c
       LEFT JOIN products p ON c.id = p.category_id AND p.is_active = true
       GROUP BY c.id, c.name
       ORDER BY c.display_order ASC`
        );

        // Base response for both admin and staff
        let response = {
            success: true,
            data: {
                totalProducts,
                totalItemsInStock,
                lowStockCount,
                outOfStockCount,
                categoryBreakdown: categoryBreakdownResult.rows
            }
        };

        // Admin-only data: cost value, selling value, profit margins
        if (isAdminUser) {
            // Get inventory value summary
            const valueResult = await db.query(
                `SELECT 
           COALESCE(SUM(quantity_in_stock * cost_price), 0) as total_cost_value,
           COALESCE(SUM(quantity_in_stock * selling_price), 0) as total_selling_value,
           COALESCE(SUM(quantity_in_stock * (selling_price - cost_price)), 0) as potential_profit
         FROM products 
         WHERE is_active = true`
            );

            const valueData = valueResult.rows[0];

            // Get top 5 low stock products
            const lowStockProductsResult = await db.query(
                `SELECT p.id, p.name, p.quantity_in_stock, p.low_stock_threshold, p.sku,
                c.name as category_name
         FROM products p
         LEFT JOIN categories c ON p.category_id = c.id
         WHERE p.is_active = true 
         AND p.quantity_in_stock <= p.low_stock_threshold
         ORDER BY p.quantity_in_stock ASC
         LIMIT 5`
            );

            // Get top 5 most profitable products
            const topProfitableResult = await db.query(
                `SELECT p.id, p.name, p.cost_price, p.selling_price,
                (p.selling_price - p.cost_price) as profit_per_unit,
                CASE WHEN p.cost_price > 0 
                     THEN ROUND(((p.selling_price - p.cost_price) / p.cost_price * 100)::numeric, 2)
                     ELSE 0 
                END as profit_percentage
         FROM products p
         WHERE p.is_active = true AND p.quantity_in_stock > 0
         ORDER BY profit_per_unit DESC
         LIMIT 5`
            );

            // Get recent stock movements
            const recentMovementsResult = await db.query(
                `SELECT sm.id, sm.change_type, sm.quantity_change, sm.new_quantity, sm.created_at,
                p.name as product_name, u.name as user_name
         FROM stock_movements sm
         JOIN products p ON sm.product_id = p.id
         LEFT JOIN users u ON sm.user_id = u.id
         ORDER BY sm.created_at DESC
         LIMIT 10`
            );

            response.data = {
                ...response.data,
                totalCostValue: parseFloat(valueData.total_cost_value),
                totalSellingValue: parseFloat(valueData.total_selling_value),
                potentialProfit: parseFloat(valueData.potential_profit),
                lowStockProducts: lowStockProductsResult.rows,
                topProfitableProducts: topProfitableResult.rows,
                recentStockMovements: recentMovementsResult.rows
            };
        }

        res.json(response);
    } catch (error) {
        console.error('Dashboard stats error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// @route   GET /api/dashboard/low-stock
// @desc    Get all low stock and out of stock products
// @access  Private
router.get('/low-stock', authenticate, async (req, res) => {
    try {
        const isAdminUser = req.user.role === 'admin';

        const selectFields = isAdminUser
            ? `p.id, p.name, p.quantity_in_stock, p.low_stock_threshold, p.sku, 
         p.cost_price, p.selling_price, p.image_url, c.name as category_name`
            : `p.id, p.name, p.quantity_in_stock, p.low_stock_threshold, p.sku, 
         p.selling_price, p.image_url, c.name as category_name`;

        const result = await db.query(
            `SELECT ${selectFields}
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.is_active = true 
       AND p.quantity_in_stock <= p.low_stock_threshold
       ORDER BY p.quantity_in_stock ASC`
        );

        // Add stock status
        const products = result.rows.map(product => ({
            ...product,
            stockStatus: product.quantity_in_stock === 0 ? 'out_of_stock' : 'low_stock'
        }));

        res.json({
            success: true,
            data: products,
            count: products.length
        });
    } catch (error) {
        console.error('Low stock error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// @route   GET /api/dashboard/profit-calculator
// @desc    Get profit breakdown for all products (Admin only)
// @access  Private (Admin)
router.get('/profit-calculator', authenticate, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admin privileges required.'
            });
        }

        const result = await db.query(
            `SELECT 
         p.id, p.name, p.sku, p.cost_price, p.selling_price, p.quantity_in_stock,
         (p.selling_price - p.cost_price) as profit_per_unit,
         (p.quantity_in_stock * (p.selling_price - p.cost_price)) as total_potential_profit,
         CASE WHEN p.cost_price > 0 
              THEN ROUND(((p.selling_price - p.cost_price) / p.cost_price * 100)::numeric, 2)
              ELSE 0 
         END as profit_percentage,
         c.name as category_name
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.is_active = true
       ORDER BY total_potential_profit DESC`
        );

        // Calculate summary
        const summary = result.rows.reduce((acc, product) => {
            acc.totalCostValue += parseFloat(product.cost_price) * product.quantity_in_stock;
            acc.totalSellingValue += parseFloat(product.selling_price) * product.quantity_in_stock;
            acc.totalPotentialProfit += parseFloat(product.total_potential_profit);
            return acc;
        }, { totalCostValue: 0, totalSellingValue: 0, totalPotentialProfit: 0 });

        res.json({
            success: true,
            data: {
                products: result.rows,
                summary: {
                    ...summary,
                    overallProfitMargin: summary.totalCostValue > 0
                        ? Math.round((summary.totalPotentialProfit / summary.totalCostValue) * 10000) / 100
                        : 0
                }
            }
        });
    } catch (error) {
        console.error('Profit calculator error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

module.exports = router;
