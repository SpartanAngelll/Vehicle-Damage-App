const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
const pool = new Pool({
  user: process.env.POSTGRES_USER || 'postgres',
  host: process.env.POSTGRES_HOST || 'localhost',
  database: process.env.POSTGRES_DB || 'vehicle_damage_payments',
  password: process.env.POSTGRES_PASSWORD || '#!Startpos12',
  port: process.env.POSTGRES_PORT || 5432,
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
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
app.listen(port, () => {
  console.log(`🚀 Cash-out API server running on port ${port}`);
  console.log(`📊 Health check: http://localhost:${port}/api/health`);
});

module.exports = app;
