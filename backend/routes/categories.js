const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const db = require('../config/database');
const { authenticate, isAdmin } = require('../middleware/auth');

// Validation rules
const categoryValidation = [
    body('name').trim().notEmpty().withMessage('Category name is required'),
    body('description').optional().trim(),
    body('icon').optional().trim(),
    body('displayOrder').optional().isInt({ min: 0 }).withMessage('Display order must be a positive integer')
];

// @route   GET /api/categories
// @desc    Get all categories
// @access  Private
router.get('/', authenticate, async (req, res) => {
    try {
        const result = await db.query(
            `SELECT id, name, description, icon, display_order, created_at 
       FROM categories 
       ORDER BY display_order ASC, name ASC`
        );

        res.json({
            success: true,
            data: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        console.error('Get categories error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// @route   GET /api/categories/:id
// @desc    Get single category with product count
// @access  Private
router.get('/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;

        const result = await db.query(
            `SELECT c.id, c.name, c.description, c.icon, c.display_order, c.created_at,
              COUNT(p.id) as product_count
       FROM categories c
       LEFT JOIN products p ON c.id = p.category_id AND p.is_active = true
       WHERE c.id = $1
       GROUP BY c.id`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Category not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Get category error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// @route   POST /api/categories
// @desc    Create a new category
// @access  Private (Admin only)
router.post('/', authenticate, isAdmin, categoryValidation, async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                errors: errors.array()
            });
        }

        const { name, description, icon, displayOrder } = req.body;

        // Check if category name already exists
        const existing = await db.query(
            'SELECT id FROM categories WHERE LOWER(name) = LOWER($1)',
            [name]
        );

        if (existing.rows.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'Category with this name already exists'
            });
        }

        const result = await db.query(
            `INSERT INTO categories (name, description, icon, display_order) 
       VALUES ($1, $2, $3, $4) 
       RETURNING *`,
            [name, description || null, icon || null, displayOrder || 0]
        );

        res.status(201).json({
            success: true,
            message: 'Category created successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Create category error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// @route   PUT /api/categories/:id
// @desc    Update a category
// @access  Private (Admin only)
router.put('/:id', authenticate, isAdmin, categoryValidation, async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                errors: errors.array()
            });
        }

        const { id } = req.params;
        const { name, description, icon, displayOrder } = req.body;

        // Check if category exists
        const existing = await db.query(
            'SELECT id FROM categories WHERE id = $1',
            [id]
        );

        if (existing.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Category not found'
            });
        }

        // Check for duplicate name (excluding current category)
        const duplicateName = await db.query(
            'SELECT id FROM categories WHERE LOWER(name) = LOWER($1) AND id != $2',
            [name, id]
        );

        if (duplicateName.rows.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'Category with this name already exists'
            });
        }

        const result = await db.query(
            `UPDATE categories 
       SET name = $1, description = $2, icon = $3, display_order = $4
       WHERE id = $5 
       RETURNING *`,
            [name, description || null, icon || null, displayOrder || 0, id]
        );

        res.json({
            success: true,
            message: 'Category updated successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Update category error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// @route   DELETE /api/categories/:id
// @desc    Delete a category
// @access  Private (Admin only)
router.delete('/:id', authenticate, isAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        // Check if category exists
        const existing = await db.query(
            'SELECT id FROM categories WHERE id = $1',
            [id]
        );

        if (existing.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Category not found'
            });
        }

        // Check if category has products
        const products = await db.query(
            'SELECT COUNT(*) as count FROM products WHERE category_id = $1 AND is_active = true',
            [id]
        );

        if (parseInt(products.rows[0].count) > 0) {
            return res.status(400).json({
                success: false,
                message: `Cannot delete category. It has ${products.rows[0].count} active products.`
            });
        }

        await db.query('DELETE FROM categories WHERE id = $1', [id]);

        res.json({
            success: true,
            message: 'Category deleted successfully'
        });
    } catch (error) {
        console.error('Delete category error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

module.exports = router;
