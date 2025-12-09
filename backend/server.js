require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection with SSL support for Supabase
const pool = new Pool({
  user: process.env.POSTGRES_USER || 'postgres',
  host: process.env.POSTGRES_HOST || 'localhost',
  database: process.env.POSTGRES_DB || 'vehicle_damage_payments',
  password: (() => {
    if (!process.env.POSTGRES_PASSWORD) {
      throw new Error('POSTGRES_PASSWORD environment variable is required');
    }
    return process.env.POSTGRES_PASSWORD;
  })(),
  port: process.env.POSTGRES_PORT || 5432,
  // SSL configuration for Supabase (required)
  ssl: process.env.POSTGRES_SSL === 'true' || process.env.POSTGRES_SSL === '1' 
    ? {
        rejectUnauthorized: process.env.POSTGRES_SSL_REJECT_UNAUTHORIZED !== 'false'
      }
    : false,
  // Connection pool settings
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 10000, // Return an error after 10 seconds if connection cannot be established
});

// Test database connection on startup
pool.on('connect', () => {
  console.log('✅ Connected to Supabase database');
});

pool.on('error', (err) => {
  console.error('❌ Database connection error:', err.message);
  if (err.code === 'ENOTFOUND') {
    console.error('   DNS resolution failed. Check your network connection and Supabase hostname.');
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Get all users (for verification/testing)
app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT 
        id,
        firebase_uid,
        email,
        full_name,
        display_name,
        role,
        phone_number,
        is_verified,
        is_active,
        created_at,
        updated_at
      FROM users
      ORDER BY created_at DESC
      LIMIT 50`
    );

    res.json({
      success: true,
      count: result.rows.length,
      users: result.rows.map(row => ({
        id: row.id,
        firebase_uid: row.firebase_uid,
        email: row.email,
        full_name: row.full_name,
        display_name: row.display_name,
        role: row.role,
        phone_number: row.phone_number,
        is_verified: row.is_verified,
        is_active: row.is_active,
        created_at: row.created_at?.toISOString(),
        updated_at: row.updated_at?.toISOString(),
      })),
    });
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Get user by Firebase UID
app.get('/api/users/firebase/:firebaseUid', async (req, res) => {
  try {
    const { firebaseUid } = req.params;
    
    const result = await pool.query(
      `SELECT 
        id,
        firebase_uid,
        email,
        full_name,
        display_name,
        role,
        phone_number,
        is_verified,
        is_active,
        created_at,
        updated_at
      FROM users
      WHERE firebase_uid = $1`,
      [firebaseUid]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
        message: `No user found with Firebase UID: ${firebaseUid}`
      });
    }

    const user = result.rows[0];
    res.json({
      success: true,
      user: {
        id: user.id,
        firebase_uid: user.firebase_uid,
        email: user.email,
        full_name: user.full_name,
        display_name: user.display_name,
        role: user.role,
        phone_number: user.phone_number,
        is_verified: user.is_verified,
        is_active: user.is_active,
        created_at: user.created_at?.toISOString(),
        updated_at: user.updated_at?.toISOString(),
      },
    });
  } catch (error) {
    console.error('Error getting user:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Get user count by role
app.get('/api/users/stats', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT 
        role,
        COUNT(*) as count
      FROM users
      GROUP BY role
      ORDER BY count DESC`
    );

    const totalResult = await pool.query('SELECT COUNT(*) as total FROM users');
    const total = parseInt(totalResult.rows[0].total);

    res.json({
      success: true,
      total_users: total,
      by_role: result.rows.map(row => ({
        role: row.role,
        count: parseInt(row.count),
      })),
    });
  } catch (error) {
    console.error('Error getting user stats:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Get professional balance
app.get('/api/professionals/:professionalId/balance', async (req, res) => {
  try {
    const { professionalId } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM professional_balances WHERE professional_id = $1',
      [professionalId]
    );

    if (result.rows.length === 0) {
      // Create initial balance if it doesn't exist
      await pool.query(
        'INSERT INTO professional_balances (professional_id, available_balance, total_earned, total_paid_out, last_updated, created_at) VALUES ($1, $2, $3, $4, $5, $6)',
        [professionalId, 0.0, 0.0, 0.0, new Date(), new Date()]
      );
      
      return res.json({
        professional_id: professionalId,
        available_balance: 0.0,
        total_earned: 0.0,
        total_paid_out: 0.0,
        last_updated: new Date().toISOString(),
        created_at: new Date().toISOString(),
      });
    }

    const balance = result.rows[0];
    res.json({
      professional_id: balance.professional_id,
      available_balance: parseFloat(balance.available_balance),
      total_earned: parseFloat(balance.total_earned),
      total_paid_out: parseFloat(balance.total_paid_out),
      last_updated: balance.last_updated.toISOString(),
      created_at: balance.created_at.toISOString(),
    });
  } catch (error) {
    console.error('Error getting professional balance:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get payout history
app.get('/api/professionals/:professionalId/payouts', async (req, res) => {
  try {
    const { professionalId } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM payouts WHERE professional_id = $1 ORDER BY created_at DESC',
      [professionalId]
    );

    const payouts = result.rows.map(row => ({
      id: row.id,
      professional_id: row.professional_id,
      amount: parseFloat(row.amount),
      currency: row.currency,
      status: row.status,
      payment_processor_transaction_id: row.payment_processor_transaction_id,
      payment_processor_response: row.payment_processor_response,
      created_at: row.created_at.toISOString(),
      completed_at: row.completed_at?.toISOString(),
      error_message: row.error_message,
      metadata: row.metadata,
    }));

    res.json({ payouts });
  } catch (error) {
    console.error('Error getting payout history:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get payout by ID
app.get('/api/payouts/:payoutId', async (req, res) => {
  try {
    const { payoutId } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM payouts WHERE id = $1',
      [payoutId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Payout not found' });
    }

    const payout = result.rows[0];
    res.json({
      id: payout.id,
      professional_id: payout.professional_id,
      amount: parseFloat(payout.amount),
      currency: payout.currency,
      status: payout.status,
      payment_processor_transaction_id: payout.payment_processor_transaction_id,
      payment_processor_response: payout.payment_processor_response,
      created_at: payout.created_at.toISOString(),
      completed_at: payout.completed_at?.toISOString(),
      error_message: payout.error_message,
      metadata: payout.metadata,
    });
  } catch (error) {
    console.error('Error getting payout by ID:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Validate cash-out request
app.post('/api/cashout/validate', async (req, res) => {
  try {
    const { professional_id, amount } = req.body;

    if (!professional_id || !amount) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (amount <= 0) {
      return res.json({
        is_valid: false,
        error: 'Amount must be greater than 0',
      });
    }

    if (amount < 10) {
      return res.json({
        is_valid: false,
        error: 'Minimum cash-out amount is $10',
      });
    }

    if (amount > 10000) {
      return res.json({
        is_valid: false,
        error: 'Maximum cash-out amount is $10,000',
      });
    }

    // Get professional balance
    const balanceResult = await pool.query(
      'SELECT * FROM professional_balances WHERE professional_id = $1',
      [professional_id]
    );

    if (balanceResult.rows.length === 0) {
      return res.json({
        is_valid: false,
        error: 'Professional not found',
      });
    }

    const balance = balanceResult.rows[0];
    const availableBalance = parseFloat(balance.available_balance);

    if (availableBalance < amount) {
      return res.json({
        is_valid: false,
        error: `Insufficient balance. Available: $${availableBalance.toFixed(2)}`,
      });
    }

    // Check for pending payouts
    const pendingResult = await pool.query(
      'SELECT COUNT(*) FROM payouts WHERE professional_id = $1 AND status = $2',
      [professional_id, 'pending']
    );

    const pendingCount = parseInt(pendingResult.rows[0].count);
    if (pendingCount > 0) {
      return res.json({
        is_valid: false,
        error: 'You have a pending cash-out request. Please wait for it to be processed.',
      });
    }

    res.json({
      is_valid: true,
      available_balance: availableBalance,
    });
  } catch (error) {
    console.error('Error validating cash-out request:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Process cash-out request
app.post('/api/cashout', async (req, res) => {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    const { professional_id, amount, metadata } = req.body;

    if (!professional_id || !amount) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (amount <= 0) {
      return res.status(400).json({ error: 'Amount must be greater than 0' });
    }

    // Get and validate professional balance
    const balanceResult = await client.query(
      'SELECT * FROM professional_balances WHERE professional_id = $1 FOR UPDATE',
      [professional_id]
    );

    if (balanceResult.rows.length === 0) {
      return res.status(404).json({ error: 'Professional not found' });
    }

    const balance = balanceResult.rows[0];
    const availableBalance = parseFloat(balance.available_balance);

    if (availableBalance < amount) {
      return res.status(400).json({
        error: `Insufficient balance. Available: $${availableBalance.toFixed(2)}`,
      });
    }

    // Check for pending payouts
    const pendingResult = await client.query(
      'SELECT COUNT(*) FROM payouts WHERE professional_id = $1 AND status = $2',
      [professional_id, 'pending']
    );

    const pendingCount = parseInt(pendingResult.rows[0].count);
    if (pendingCount > 0) {
      return res.status(400).json({
        error: 'You have a pending cash-out request. Please wait for it to be processed.',
      });
    }

    // Create payout record
    const payoutId = uuidv4();
    const now = new Date();

    await client.query(
      'INSERT INTO payouts (id, professional_id, amount, currency, status, created_at, metadata) VALUES ($1, $2, $3, $4, $5, $6, $7)',
      [payoutId, professional_id, amount, 'JMD', 'pending', now, metadata || {}]
    );

    // Process payout through payment processor (mock implementation)
    const payoutResult = await processPayoutWithPaymentProcessor({
      payoutId,
      professionalId: professional_id,
      amount,
    });

    if (payoutResult.success) {
      // Update payout status to success
      await client.query(
        'UPDATE payouts SET status = $1, payment_processor_transaction_id = $2, payment_processor_response = $3, completed_at = $4 WHERE id = $5',
        ['success', payoutResult.transactionId, payoutResult.response, new Date(), payoutId]
      );

      // Reset professional's available balance to 0
      await client.query(
        'UPDATE professional_balances SET available_balance = $1, total_paid_out = total_paid_out + $2, last_updated = $3 WHERE professional_id = $4',
        [0.0, amount, new Date(), professional_id]
      );

      await client.query('COMMIT');

      res.json({
        success: true,
        message: 'Cash-out processed successfully',
        payout: {
          id: payoutId,
          professional_id,
          amount,
          currency: 'JMD',
          status: 'success',
          payment_processor_transaction_id: payoutResult.transactionId,
          payment_processor_response: payoutResult.response,
          created_at: now.toISOString(),
          completed_at: new Date().toISOString(),
          metadata: metadata || {},
        },
      });
    } else {
      // Update payout status to failed
      await client.query(
        'UPDATE payouts SET status = $1, error_message = $2, completed_at = $3 WHERE id = $4',
        ['failed', payoutResult.error, new Date(), payoutId]
      );

      await client.query('COMMIT');

      res.json({
        success: false,
        error: payoutResult.error,
        payout: {
          id: payoutId,
          professional_id,
          amount,
          currency: 'JMD',
          status: 'failed',
          error_message: payoutResult.error,
          created_at: now.toISOString(),
          completed_at: new Date().toISOString(),
          metadata: metadata || {},
        },
      });
    }
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error processing cash-out request:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

// Get cash-out statistics
app.get('/api/professionals/:professionalId/cashout-stats', async (req, res) => {
  try {
    const { professionalId } = req.params;
    
    // Get balance info
    const balanceResult = await pool.query(
      'SELECT * FROM professional_balances WHERE professional_id = $1',
      [professionalId]
    );

    if (balanceResult.rows.length === 0) {
      return res.json({
        available_balance: 0.0,
        total_earned: 0.0,
        total_paid_out: 0.0,
        pending_payouts: 0,
        completed_payouts: 0,
        failed_payouts: 0,
      });
    }

    const balance = balanceResult.rows[0];

    // Get payout counts
    const statsResult = await pool.query(
      'SELECT status, COUNT(*) FROM payouts WHERE professional_id = $1 GROUP BY status',
      [professionalId]
    );

    const stats = {
      pending: 0,
      success: 0,
      failed: 0,
    };

    statsResult.rows.forEach(row => {
      stats[row.status] = parseInt(row.count);
    });

    res.json({
      available_balance: parseFloat(balance.available_balance),
      total_earned: parseFloat(balance.total_earned),
      total_paid_out: parseFloat(balance.total_paid_out),
      pending_payouts: stats.pending,
      completed_payouts: stats.success,
      failed_payouts: stats.failed,
    });
  } catch (error) {
    console.error('Error getting cash-out stats:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Cancel payout
app.delete('/api/payouts/:payoutId', async (req, res) => {
  try {
    const { payoutId } = req.params;
    
    const result = await pool.query(
      'UPDATE payouts SET status = $1 WHERE id = $2 AND status = $3 RETURNING id',
      ['cancelled', payoutId, 'pending']
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Payout not found or cannot be cancelled' });
    }

    res.json({ message: 'Payout cancelled successfully' });
  } catch (error) {
    console.error('Error cancelling payout:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==============================================
// SERVICE PACKAGES API ENDPOINTS
// ==============================================

// Get all service packages for a professional
app.get('/api/professionals/:professionalId/service-packages', async (req, res) => {
  try {
    const { professionalId } = req.params;
    const { active_only } = req.query;
    
    let query = 'SELECT * FROM service_packages WHERE professional_id = $1';
    const params = [professionalId];
    
    if (active_only === 'true') {
      query += ' AND is_active = $2';
      params.push(true);
    }
    
    query += ' ORDER BY sort_order ASC, created_at DESC';
    
    const result = await pool.query(query, params);
    
    const packages = result.rows.map(row => ({
      id: row.id,
      professional_id: row.professional_id,
      name: row.name,
      description: row.description,
      price: parseFloat(row.price),
      currency: row.currency,
      duration_minutes: row.duration_minutes,
      is_starting_from: row.is_starting_from,
      is_active: row.is_active,
      sort_order: row.sort_order,
      created_at: row.created_at.toISOString(),
      updated_at: row.updated_at.toISOString(),
      metadata: row.metadata || {},
    }));
    
    res.json({ packages });
  } catch (error) {
    console.error('Error getting service packages:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get a single service package by ID
app.get('/api/service-packages/:packageId', async (req, res) => {
  try {
    const { packageId } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM service_packages WHERE id = $1',
      [packageId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Service package not found' });
    }
    
    const row = result.rows[0];
    res.json({
      id: row.id,
      professional_id: row.professional_id,
      name: row.name,
      description: row.description,
      price: parseFloat(row.price),
      currency: row.currency,
      duration_minutes: row.duration_minutes,
      is_starting_from: row.is_starting_from,
      is_active: row.is_active,
      sort_order: row.sort_order,
      created_at: row.created_at.toISOString(),
      updated_at: row.updated_at.toISOString(),
      metadata: row.metadata || {},
    });
  } catch (error) {
    console.error('Error getting service package:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create a new service package
app.post('/api/professionals/:professionalId/service-packages', async (req, res) => {
  try {
    const { professionalId } = req.params;
    const { name, description, price, currency, duration_minutes, is_starting_from, sort_order, metadata } = req.body;
    
    // Validation
    if (!name || !price || !duration_minutes) {
      return res.status(400).json({ error: 'Missing required fields: name, price, duration_minutes' });
    }
    
    if (price <= 0) {
      return res.status(400).json({ error: 'Price must be greater than 0' });
    }
    
    if (duration_minutes <= 0) {
      return res.status(400).json({ error: 'Duration must be greater than 0' });
    }
    
    const packageId = uuidv4();
    const now = new Date();
    
    const result = await pool.query(
      `INSERT INTO service_packages (
        id, professional_id, name, description, price, currency, 
        duration_minutes, is_starting_from, is_active, sort_order, 
        created_at, updated_at, metadata
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *`,
      [
        packageId,
        professionalId,
        name,
        description || null,
        price,
        currency || 'JMD',
        duration_minutes,
        is_starting_from || false,
        true, // is_active defaults to true
        sort_order || 0,
        now,
        now,
        metadata || {},
      ]
    );
    
    const row = result.rows[0];
    res.status(201).json({
      id: row.id,
      professional_id: row.professional_id,
      name: row.name,
      description: row.description,
      price: parseFloat(row.price),
      currency: row.currency,
      duration_minutes: row.duration_minutes,
      is_starting_from: row.is_starting_from,
      is_active: row.is_active,
      sort_order: row.sort_order,
      created_at: row.created_at.toISOString(),
      updated_at: row.updated_at.toISOString(),
      metadata: row.metadata || {},
    });
  } catch (error) {
    console.error('Error creating service package:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update a service package
app.put('/api/service-packages/:packageId', async (req, res) => {
  try {
    const { packageId } = req.params;
    const { name, description, price, currency, duration_minutes, is_starting_from, is_active, sort_order, metadata } = req.body;
    
    // Build dynamic update query
    const updates = [];
    const values = [];
    let paramIndex = 1;
    
    if (name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      values.push(name);
    }
    if (description !== undefined) {
      updates.push(`description = $${paramIndex++}`);
      values.push(description);
    }
    if (price !== undefined) {
      if (price <= 0) {
        return res.status(400).json({ error: 'Price must be greater than 0' });
      }
      updates.push(`price = $${paramIndex++}`);
      values.push(price);
    }
    if (currency !== undefined) {
      updates.push(`currency = $${paramIndex++}`);
      values.push(currency);
    }
    if (duration_minutes !== undefined) {
      if (duration_minutes <= 0) {
        return res.status(400).json({ error: 'Duration must be greater than 0' });
      }
      updates.push(`duration_minutes = $${paramIndex++}`);
      values.push(duration_minutes);
    }
    if (is_starting_from !== undefined) {
      updates.push(`is_starting_from = $${paramIndex++}`);
      values.push(is_starting_from);
    }
    if (is_active !== undefined) {
      updates.push(`is_active = $${paramIndex++}`);
      values.push(is_active);
    }
    if (sort_order !== undefined) {
      updates.push(`sort_order = $${paramIndex++}`);
      values.push(sort_order);
    }
    if (metadata !== undefined) {
      updates.push(`metadata = $${paramIndex++}`);
      values.push(metadata);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }
    
    // Always update updated_at
    updates.push(`updated_at = $${paramIndex++}`);
    values.push(new Date());
    
    values.push(packageId);
    
    const query = `UPDATE service_packages 
                   SET ${updates.join(', ')} 
                   WHERE id = $${paramIndex}
                   RETURNING *`;
    
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Service package not found' });
    }
    
    const row = result.rows[0];
    res.json({
      id: row.id,
      professional_id: row.professional_id,
      name: row.name,
      description: row.description,
      price: parseFloat(row.price),
      currency: row.currency,
      duration_minutes: row.duration_minutes,
      is_starting_from: row.is_starting_from,
      is_active: row.is_active,
      sort_order: row.sort_order,
      created_at: row.created_at.toISOString(),
      updated_at: row.updated_at.toISOString(),
      metadata: row.metadata || {},
    });
  } catch (error) {
    console.error('Error updating service package:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete a service package
app.delete('/api/service-packages/:packageId', async (req, res) => {
  try {
    const { packageId } = req.params;
    
    const result = await pool.query(
      'DELETE FROM service_packages WHERE id = $1 RETURNING id',
      [packageId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Service package not found' });
    }
    
    res.json({ message: 'Service package deleted successfully' });
  } catch (error) {
    console.error('Error deleting service package:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Mock payment processor integration
async function processPayoutWithPaymentProcessor({ payoutId, professionalId, amount }) {
  try {
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Check if payment processor is configured
    const isConfigured = process.env.PAYMENT_PROCESSOR_API_KEY && process.env.PAYMENT_PROCESSOR_API_KEY !== '';

    if (!isConfigured) {
      // Mock successful payout for development
      return {
        success: true,
        transactionId: `MOCK_${Date.now()}`,
        response: {
          status: 'success',
          transaction_id: `MOCK_${Date.now()}`,
          amount: amount,
          currency: 'JMD',
          processed_at: new Date().toISOString(),
          processor: 'mock',
        },
      };
    }

    // TODO: Implement actual payment processor API call
    // This would be where you integrate with Stripe, PayPal, etc.
    throw new Error('Payment processor integration not implemented');

  } catch (error) {
    console.error('Payment processor error:', error);
    return {
      success: false,
      error: `Payment processor error: ${error.message}`,
    };
  }
}

// Start server
// Listen on 0.0.0.0 to accept connections from other devices on the network
const host = process.env.HOST || '0.0.0.0';
app.listen(port, host, () => {
  console.log(`🚀 Cash-out API server running on ${host}:${port}`);
  console.log(`📊 Health check: http://localhost:${port}/api/health`);
  console.log(`📱 Network access: http://192.168.0.53:${port}/api/health`);
});

module.exports = app;
