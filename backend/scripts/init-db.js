require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const run = async () => {
    // Check if DATABASE_URL is provided
    if (!process.env.DATABASE_URL) {
        console.error('❌ Error: DATABASE_URL environment variable is missing.');
        console.error('   Please create a .env file or pass it inline.');
        process.exit(1);
    }

    console.log(`🔌 Connecting to database...`);

    const pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: {
            rejectUnauthorized: false
        }
    });

    try {
        // Read the schema file
        const schemaPath = path.join(__dirname, '../database/schema.sql');
        const schemaSql = fs.readFileSync(schemaPath, 'utf8');

        console.log('📜 Reading schema.sql...');

        // Execute the schema SQL
        console.log('🚀 Executing schema migration...');
        await pool.query(schemaSql);

        console.log('✅ Database initialized successfully!');
        console.log('   - Tables created');
        console.log('   - Default admin user created (admin@shop.com / admin123)');
        console.log('   - Default categories and products seeded');

    } catch (error) {
        console.error('❌ Database initialization failed:', error.message);
        if (error.position) {
            console.error(`   at position: ${error.position}`);
        }
    } finally {
        await pool.end();
    }
};

run();
