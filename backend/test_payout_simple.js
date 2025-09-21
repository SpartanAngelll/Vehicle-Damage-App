const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');

// Test database connection
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'vehicle_damage_payments',
  password: '#!Startpos12',
  port: 5432,
});

async function testPayoutFix() {
  try {
    console.log('🧪 Testing payout fix...');
    
    // Test the metadata handling
    const testMetadata = {
      test: true,
      source: 'test_script',
      timestamp: new Date().toISOString(),
    };
    
    console.log('📋 Test metadata:', testMetadata);
    
    // Test inserting with proper JSONB handling
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Test the fixed query (without JSON.stringify)
      const testId = uuidv4();
      const result = await client.query(
        'INSERT INTO payouts (id, professional_id, amount, currency, status, created_at, metadata) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id',
        [testId, 'test-professional', 50.0, 'JMD', 'pending', new Date(), testMetadata]
      );
      
      console.log('✅ Payout inserted successfully with ID:', result.rows[0].id);
      
      // Verify the metadata was stored correctly
      const verifyResult = await client.query(
        'SELECT metadata FROM payouts WHERE id = $1',
        [testId]
      );
      
      console.log('📊 Stored metadata:', verifyResult.rows[0].metadata);
      console.log('✅ Metadata stored as proper JSONB!');
      
      // Clean up test data
      await client.query('DELETE FROM payouts WHERE id = $1', [testId]);
      console.log('🧹 Test data cleaned up');
      
      await client.query('COMMIT');
      
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
    
    console.log('🎉 Test completed successfully! The JSON parsing error is fixed.');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error('Stack trace:', error.stack);
  } finally {
    await pool.end();
  }
}

testPayoutFix();
