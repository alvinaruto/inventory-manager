const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticate, isAdmin } = require('../middleware/auth');

// @route   GET /api/users
// @desc    Get all users (Admin only)
// @access  Private (Admin)
router.get('/', authenticate, isAdmin, async (req, res) => {
    try {
        const result = await db.query(
            `SELECT id, email, name, role, is_active, created_at, updated_at
       FROM users
       ORDER BY created_at DESC`
        );

        res.json({
            success: true,
            data: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        console.error('Get users error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// @route   GET /api/users/:id
// @desc    Get single user (Admin only)
// @access  Private (Admin)
router.get('/:id', authenticate, isAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        const result = await db.query(
            `SELECT id, email, name, role, is_active, created_at, updated_at
       FROM users WHERE id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// @route   PUT /api/users/:id
// @desc    Update user role/status (Admin only)
// @access  Private (Admin)
router.put('/:id', authenticate, isAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const { name, role, isActive } = req.body;

        // Prevent admin from deactivating themselves
        if (id === req.user.id && isActive === false) {
            return res.status(400).json({
                success: false,
                message: 'You cannot deactivate your own account'
            });
        }

        // Prevent changing own role
        if (id === req.user.id && role && role !== req.user.role) {
            return res.status(400).json({
                success: false,
                message: 'You cannot change your own role'
            });
        }

        const existing = await db.query('SELECT id FROM users WHERE id = $1', [id]);
        if (existing.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        const result = await db.query(
            `UPDATE users 
       SET name = COALESCE($1, name),
           role = COALESCE($2, role),
           is_active = COALESCE($3, is_active)
       WHERE id = $4
       RETURNING id, email, name, role, is_active, updated_at`,
            [name, role, isActive, id]
        );

        res.json({
            success: true,
            message: 'User updated successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Update user error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// @route   DELETE /api/users/:id
// @desc    Delete/deactivate user (Admin only)
// @access  Private (Admin)
router.delete('/:id', authenticate, isAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        // Prevent admin from deleting themselves
        if (id === req.user.id) {
            return res.status(400).json({
                success: false,
                message: 'You cannot delete your own account'
            });
        }

        const existing = await db.query('SELECT id FROM users WHERE id = $1', [id]);
        if (existing.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // Soft delete (deactivate)
        await db.query('UPDATE users SET is_active = false WHERE id = $1', [id]);

        res.json({
            success: true,
            message: 'User deactivated successfully'
        });
    } catch (error) {
        console.error('Delete user error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

module.exports = router;
