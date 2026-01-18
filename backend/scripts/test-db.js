const db = require('../config/database');

async function testConnection() {
    try {
        console.log('🔄 Testing database connection...');

        const result = await db.query('SELECT NOW() as current_time');
        console.log('✅ Database connected successfully!');
        console.log(`📅 Server time: ${result.rows[0].current_time}`);

        // Test tables exist
        const tablesResult = await db.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);

        console.log('\n📋 Available tables:');
        tablesResult.rows.forEach(row => {
            console.log(`   - ${row.table_name}`);
        });

        process.exit(0);
    } catch (error) {
        console.error('❌ Database connection failed:', error.message);
        process.exit(1);
    }
}

testConnection();
