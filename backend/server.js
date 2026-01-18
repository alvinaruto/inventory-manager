require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

// Import routes
const authRoutes = require('./routes/auth');
const categoriesRoutes = require('./routes/categories');
const productsRoutes = require('./routes/products');
const dashboardRoutes = require('./routes/dashboard');
const usersRoutes = require('./routes/users');

// Initialize express app
const app = express();

// ======================
// Middleware
// ======================

// Enable CORS for all origins (adjust for production)
app.use(cors({
    origin: process.env.NODE_ENV === 'production' && process.env.ALLOWED_ORIGINS
        ? process.env.ALLOWED_ORIGINS.split(',')
        : '*', // Default to allowing all if not configured
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Parse JSON bodies
app.use(express.json({ limit: '10mb' }));

// Parse URL-encoded bodies
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging (development only)
if (process.env.NODE_ENV !== 'production') {
    app.use((req, res, next) => {
        console.log(`📨 ${new Date().toISOString()} - ${req.method} ${req.path}`);
        next();
    });
}

// ======================
// API Routes
// ======================
app.use('/api/auth', authRoutes);
app.use('/api/categories', categoriesRoutes);
app.use('/api/products', productsRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/users', usersRoutes);

// ======================
// Health Check
// ======================
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        message: 'Inventory Management API is running',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Root path handler
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'Inventory Management API is running. Access endpoints at /api',
        documentation: '/api'
    });
});

// API Info
app.get('/api', (req, res) => {
    res.json({
        success: true,
        name: 'Inventory Management API',
        version: '1.0.0',
        description: 'Backend API for Religious Offerings Shop Inventory Management',
        endpoints: {
            auth: '/api/auth',
            categories: '/api/categories',
            products: '/api/products',
            dashboard: '/api/dashboard',
            users: '/api/users',
            health: '/api/health'
        }
    });
});

// ======================
// Error Handling
// ======================

// 404 handler
app.use((req, res, next) => {
    res.status(404).json({
        success: false,
        message: `Route ${req.method} ${req.path} not found`
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('❌ Error:', err);

    // Handle specific error types
    if (err.name === 'ValidationError') {
        return res.status(400).json({
            success: false,
            message: 'Validation error',
            errors: err.errors
        });
    }

    if (err.name === 'UnauthorizedError') {
        return res.status(401).json({
            success: false,
            message: 'Unauthorized access'
        });
    }

    // Default error response
    res.status(err.status || 500).json({
        success: false,
        message: process.env.NODE_ENV === 'production'
            ? 'Internal server error'
            : err.message
    });
});

// ======================
// Start Server
// ======================
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log('');
    console.log('╔═══════════════════════════════════════════════════════════╗');
    console.log('║     🏪 INVENTORY MANAGEMENT API SERVER                     ║');
    console.log('╠═══════════════════════════════════════════════════════════╣');
    console.log(`║  🚀 Server running on port ${PORT}                            ║`);
    console.log(`║  🌍 Environment: ${(process.env.NODE_ENV || 'development').padEnd(37)}║`);
    console.log(`║  📅 Started at: ${new Date().toLocaleString().padEnd(38)}║`);
    console.log('╠═══════════════════════════════════════════════════════════╣');
    console.log('║  📍 API Endpoints:                                        ║');
    console.log(`║     http://localhost:${PORT}/api                              ║`);
    console.log(`║     http://localhost:${PORT}/api/health                       ║`);
    console.log('╚═══════════════════════════════════════════════════════════╝');
    console.log('');
});

module.exports = app;
