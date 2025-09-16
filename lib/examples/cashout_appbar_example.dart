import 'package:flutter/material.dart';
import '../services/payout_service.dart';
import '../models/payout_models.dart';
import '../screens/cashout_screen.dart';

/// Example showing how the cash-out section appears in the top left app bar
class CashOutAppBarExample extends StatefulWidget {
  const CashOutAppBarExample({super.key});

  @override
  State<CashOutAppBarExample> createState() => _CashOutAppBarExampleState();
}

class _CashOutAppBarExampleState extends State<CashOutAppBarExample> {
  final PayoutService _payoutService = PayoutService.instance;
  ProfessionalBalance? _balance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      // Example professional ID - replace with actual ID
      const String exampleProfessionalId = 'example_professional_123';
      final balance = await _payoutService.getProfessionalBalance(exampleProfessionalId);
      setState(() {
        _balance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading balance: $e');
    }
  }

  void _navigateToCashOut() {
    if (_balance == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CashOutScreen(
          professionalId: 'example_professional_123',
        ),
      ),
    ).then((_) {
      // Refresh balance when returning from cash-out screen
      _loadBalance();
    });
  }

  String _formatBalance(double balance) {
    if (balance == 0) return '\$0';
    if (balance < 1) return '\$${balance.toStringAsFixed(2)}';
    if (balance < 100) return '\$${balance.toStringAsFixed(1)}';
    return '\$${balance.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        leading: _balance != null
            ? Container(
                margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _navigateToCashOut,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatBalance(_balance!.availableBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : _isLoading
                ? Container(
                    margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBalance,
            tooltip: 'Refresh Balance',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings tapped')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'Cash-Out Section in App Bar',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The cash-out button appears in the top left of the app bar',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_balance != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Current Balance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatBalance(_balance!.availableBalance),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Earned: \$${_balance!.totalEarned.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Total Paid Out: \$${_balance!.totalPaidOut.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading balance...'),
            ] else ...[
              const Text('No balance data available'),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCashOut,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Go to Cash-Out Screen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
