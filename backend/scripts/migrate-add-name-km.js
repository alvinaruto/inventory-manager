require('dotenv').config();
const { Pool } = require('pg');

const run = async () => {
    if (!process.env.DATABASE_URL) {
        console.error('❌ Error: DATABASE_URL environment variable is missing.');
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
        console.log('🚀 Running migration: Adding name_km to products table...');

        // Add name_km column if it doesn't exist
        await pool.query(`
            DO $$ 
            BEGIN 
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='products' AND column_name='name_km') THEN 
                    ALTER TABLE products ADD COLUMN name_km VARCHAR(255); 
                    RAISE NOTICE 'Added name_km column';
                ELSE 
                    RAISE NOTICE 'Column name_km already exists';
                END IF; 
            END $$;
        `);

        console.log('✅ Migration completed successfully!');

    } catch (error) {
        console.error('❌ Migration failed:', error.message);
    } finally {
        await pool.end();
    }
};

run();
