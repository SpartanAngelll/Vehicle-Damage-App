// Quick script to verify database tables via CLI
const { Pool } = require('pg');
require('dotenv').config({ path: '../.env' });

const pool = new Pool({
  user: process.env.POSTGRES_USER || 'postgres',
  host: process.env.POSTGRES_HOST || 'localhost',
  database: process.env.POSTGRES_DB || 'postgres',
  password: process.env.POSTGRES_PASSWORD,
  port: process.env.POSTGRES_PORT || 5432,
  ssl: process.env.POSTGRES_SSL === 'true' || process.env.POSTGRES_SSL === '1' 
    ? {
        rejectUnauthorized: process.env.POSTGRES_SSL_REJECT_UNAUTHORIZED !== 'false'
      }
    : false,
});

async function verifyDatabase() {
  try {
    console.log('🔍 Verifying database tables...\n');
    
    // Check if users table exists
    const tableCheck = await pool.query(`
      SELECT 
        CASE 
          WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users')
          THEN 'EXISTS'
          ELSE 'DOES NOT EXIST'
        END as status
    `);
    
    const status = tableCheck.rows[0].status;
    if (status === 'EXISTS') {
      console.log('✅ users table EXISTS\n');
    } else {
      console.log('❌ users table DOES NOT EXIST\n');
      await pool.end();
      return;
    }
    
    // List all tables
    const tables = await pool.query(`
      SELECT 
        table_name,
        (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
      FROM information_schema.tables t
      WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);
    
    console.log(`📊 Found ${tables.rows.length} tables:\n`);
    tables.rows.forEach(table => {
      console.log(`   - ${table.table_name} (${table.column_count} columns)`);
    });
    
    // Check users table structure
    const columns = await pool.query(`
      SELECT 
        column_name,
        data_type,
        is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public' 
        AND table_name = 'users'
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 users table structure:');
    columns.rows.forEach(col => {
      console.log(`   - ${col.column_name} (${col.data_type}, nullable: ${col.is_nullable})`);
    });
    
    // Count users
    const userCount = await pool.query('SELECT COUNT(*) as count FROM users');
    console.log(`\n👥 Total users in database: ${userCount.rows[0].count}`);
    
    // List recent users
    const users = await pool.query(`
      SELECT 
        firebase_uid,
        email,
        full_name,
        role,
        created_at
      FROM users
      ORDER BY created_at DESC
      LIMIT 10
    `);
    
    if (users.rows.length > 0) {
      console.log('\n📝 Recent users:');
      users.rows.forEach(user => {
        console.log(`   - ${user.email} (${user.role})`);
        console.log(`     Firebase UID: ${user.firebase_uid}`);
        console.log(`     Created: ${user.created_at}`);
        console.log('');
      });
    } else {
      console.log('\n📝 No users found in database yet');
    }
    
    await pool.end();
    console.log('\n✅ Verification complete!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.code === '42P01') {
      console.error('   The users table does not exist. Please run the schema in Supabase SQL Editor.');
    } else if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
      console.error('   Could not connect to database. Check your connection settings.');
    }
    await pool.end();
    process.exit(1);
  }
}

verifyDatabase();

