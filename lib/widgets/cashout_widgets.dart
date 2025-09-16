import 'package:flutter/material.dart';
import '../models/payout_models.dart' as payout_models;
import '../services/cashout_service.dart';

/// Cash-out dashboard widget for service professionals
class CashOutDashboard extends StatefulWidget {
  final String professionalId;

  const CashOutDashboard({
    Key? key,
    required this.professionalId,
  }) : super(key: key);

  @override
  State<CashOutDashboard> createState() => _CashOutDashboardState();
}

class _CashOutDashboardState extends State<CashOutDashboard> {
  final CashOutService _cashOutService = CashOutService.instance;
  payout_models.ProfessionalBalance? _balance;
  payout_models.CashOutStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final balance = await _cashOutService.getProfessionalBalance(widget.professionalId);
      final stats = await _cashOutService.getCashOutStats(widget.professionalId);
      
      setState(() {
        _balance = balance;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load cash-out data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 16),
          _buildStatsCards(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 16),
          _buildRecentPayouts(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final availableBalance = _balance?.availableBalance ?? 0.0;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Available Balance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _cashOutService.formatAmount(availableBalance),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              availableBalance > 0 
                  ? 'Ready for cash-out'
                  : 'No available balance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: availableBalance > 0 ? Colors.green[600] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Earned',
            _cashOutService.formatAmount(_stats!.totalEarned),
            Icons.trending_up,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Paid Out',
            _cashOutService.formatAmount(_stats!.totalPaidOut),
            Icons.payment,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final availableBalance = _balance?.availableBalance ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: availableBalance > 0 ? _showCashOutDialog : null,
                    icon: const Icon(Icons.money_off),
                    label: const Text('Cash Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _viewPayoutHistory,
                    icon: const Icon(Icons.history),
                    label: const Text('History'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPayouts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Payouts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _viewPayoutHistory,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecentPayoutsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPayoutsList() {
    return StreamBuilder<List<payout_models.Payout>>(
      stream: _cashOutService.getPayoutsStream(widget.professionalId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final payouts = snapshot.data ?? [];
        final recentPayouts = payouts.take(3).toList();

        if (recentPayouts.isEmpty) {
          return const Text('No payouts yet');
        }

        return Column(
          children: recentPayouts.map((payout) => _buildPayoutItem(payout)).toList(),
        );
      },
    );
  }

  Widget _buildPayoutItem(payout_models.Payout payout) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(payout.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cashOutService.formatAmount(payout.amount),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _cashOutService.getStatusDisplayText(payout.status),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(payout.status),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _cashOutService.formatDate(payout.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(payout_models.PayoutStatus status) {
    switch (status) {
      case payout_models.PayoutStatus.pending:
        return Colors.orange;
      case payout_models.PayoutStatus.success:
        return Colors.green;
      case payout_models.PayoutStatus.failed:
        return Colors.red;
    }
  }

  void _showCashOutDialog() {
    showDialog(
      context: context,
      builder: (context) => CashOutDialog(
        professionalId: widget.professionalId,
        availableBalance: _balance?.availableBalance ?? 0.0,
        onCashOutSuccess: () {
          _loadData();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _viewPayoutHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PayoutHistoryScreen(
          professionalId: widget.professionalId,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Cash-out dialog for requesting payouts
class CashOutDialog extends StatefulWidget {
  final String professionalId;
  final double availableBalance;
  final VoidCallback onCashOutSuccess;

  const CashOutDialog({
    Key? key,
    required this.professionalId,
    required this.availableBalance,
    required this.onCashOutSuccess,
  }) : super(key: key);

  @override
  State<CashOutDialog> createState() => _CashOutDialogState();
}

class _CashOutDialogState extends State<CashOutDialog> {
  final CashOutService _cashOutService = CashOutService.instance;
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.availableBalance.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Cash Out'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Balance: ${_cashOutService.formatAmount(widget.availableBalance)}'),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount to Cash Out',
              prefixText: '\$',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Minimum: \$10.00 | Maximum: \$10,000.00',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processCashOut,
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Request Cash Out'),
        ),
      ],
    );
  }

  Future<void> _processCashOut() async {
    final amount = double.tryParse(_amountController.text);
    
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    if (amount < 10) {
      _showErrorSnackBar('Minimum cash-out amount is \$10');
      return;
    }

    if (amount > 10000) {
      _showErrorSnackBar('Maximum cash-out amount is \$10,000');
      return;
    }

    if (amount > widget.availableBalance) {
      _showErrorSnackBar('Amount exceeds available balance');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await _cashOutService.requestCashOut(
        professionalId: widget.professionalId,
        amount: amount,
      );

      if (response.success) {
        _showSuccessSnackBar('Cash-out request submitted successfully');
        widget.onCashOutSuccess();
      } else {
        _showErrorSnackBar(response.error ?? 'Cash-out request failed');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to process cash-out request: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Payout history screen
class PayoutHistoryScreen extends StatefulWidget {
  final String professionalId;

  const PayoutHistoryScreen({
    Key? key,
    required this.professionalId,
  }) : super(key: key);

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  final CashOutService _cashOutService = CashOutService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout History'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<payout_models.Payout>>(
        stream: _cashOutService.getPayoutsStream(widget.professionalId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final payouts = snapshot.data ?? [];

          if (payouts.isEmpty) {
            return const Center(
              child: Text('No payouts yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: payouts.length,
            itemBuilder: (context, index) {
              final payout = payouts[index];
              return _buildPayoutCard(payout);
            },
          );
        },
      ),
    );
  }

  Widget _buildPayoutCard(payout_models.Payout payout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _cashOutService.formatAmount(payout.amount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(payout.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _cashOutService.getStatusDisplayText(payout.status),
                    style: TextStyle(
                      color: _getStatusColor(payout.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Requested: ${_cashOutService.formatDate(payout.createdAt)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (payout.completedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Completed: ${_cashOutService.formatDate(payout.completedAt!)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (payout.paymentProcessorTransactionId != null) ...[
              const SizedBox(height: 4),
              Text(
                'Transaction ID: ${payout.paymentProcessorTransactionId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontFamily: 'monospace',
                ),
              ),
            ],
            if (payout.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  payout.errorMessage!,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(payout_models.PayoutStatus status) {
    switch (status) {
      case payout_models.PayoutStatus.pending:
        return Colors.orange;
      case payout_models.PayoutStatus.success:
        return Colors.green;
      case payout_models.PayoutStatus.failed:
        return Colors.red;
    }
  }
}
