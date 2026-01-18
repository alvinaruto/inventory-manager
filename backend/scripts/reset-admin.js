require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const run = async () => {
    if (!process.env.DATABASE_URL) {
        console.error('❌ Error: DATABASE_URL environment variable is missing.');
        process.exit(1);
    }

    const pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: {
            rejectUnauthorized: false
        }
    });

    try {
        console.log('🔐 Resetting admin password...');

        const email = 'admin@shop.com';
        const newPassword = 'admin123';

        // Generate new hash
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(newPassword, salt);

        // Update password
        const result = await pool.query(
            'UPDATE users SET password_hash = $1 WHERE email = $2 RETURNING id, email',
            [passwordHash, email]
        );

        if (result.rowCount === 0) {
            console.log('⚠️ Admin user not found. Creating one...');
            await pool.query(
                `INSERT INTO users (email, password_hash, name, role) 
                 VALUES ($1, $2, 'Shop Admin', 'admin')`,
                [email, passwordHash]
            );
            console.log('✅ Admin user created successfully.');
        } else {
            console.log('✅ Admin password reset successfully.');
        }

    } catch (error) {
        console.error('❌ Reset failed:', error.message);
    } finally {
        await pool.end();
    }
};

run();
