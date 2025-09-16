import 'package:flutter/material.dart';
import '../models/payout_models.dart' as payout_models;
import '../services/cashout_service.dart';
import '../widgets/cashout_widgets.dart';

/// Cash-out screen for service professionals
class CashOutScreen extends StatefulWidget {
  final String professionalId;

  const CashOutScreen({
    Key? key,
    required this.professionalId,
  }) : super(key: key);

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> with TickerProviderStateMixin {
  final CashOutService _cashOutService = CashOutService.instance;
  late TabController _tabController;
  payout_models.ProfessionalBalance? _balance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final balance = await _cashOutService.getProfessionalBalance(widget.professionalId);
      setState(() {
        _balance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load balance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Out'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                CashOutDashboard(professionalId: widget.professionalId),
                PayoutHistoryScreen(professionalId: widget.professionalId),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    final availableBalance = _balance?.availableBalance ?? 0.0;
    
    if (availableBalance <= 0) return null;

    return FloatingActionButton.extended(
      onPressed: _showCashOutDialog,
      icon: const Icon(Icons.money_off),
      label: const Text('Cash Out'),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    );
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Example integration screen showing how to add cash-out to existing professional dashboard
class ProfessionalDashboardWithCashOut extends StatefulWidget {
  final String professionalId;

  const ProfessionalDashboardWithCashOut({
    Key? key,
    required this.professionalId,
  }) : super(key: key);

  @override
  State<ProfessionalDashboardWithCashOut> createState() => _ProfessionalDashboardWithCashOutState();
}

class _ProfessionalDashboardWithCashOutState extends State<ProfessionalDashboardWithCashOut> {
  final CashOutService _cashOutService = CashOutService.instance;
  payout_models.ProfessionalBalance? _balance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoading = true);
    
    try {
      final balance = await _cashOutService.getProfessionalBalance(widget.professionalId);
      setState(() {
        _balance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Dashboard'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _navigateToCashOut,
            tooltip: 'Cash Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing dashboard content would go here
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            _buildQuickStatsCard(),
            const SizedBox(height: 16),
            _buildCashOutCard(),
            const SizedBox(height: 16),
            _buildRecentActivityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Here\'s what\'s happening with your business today.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Jobs Today', '5', Icons.work, Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem('Rating', '4.8', Icons.star, Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashOutCard() {
    final availableBalance = _balance?.availableBalance ?? 0.0;
    
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
                  'Earnings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _navigateToCashOut,
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Balance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cashOutService.formatAmount(availableBalance),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: availableBalance > 0 ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (availableBalance > 0)
                  ElevatedButton.icon(
                    onPressed: _showQuickCashOutDialog,
                    icon: const Icon(Icons.money_off, size: 16),
                    label: const Text('Cash Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem('Job completed', 'Auto repair - Honda Civic', '2 hours ago', Icons.check_circle, Colors.green),
            const SizedBox(height: 12),
            _buildActivityItem('Payment received', '\$150.00', '4 hours ago', Icons.payment, Colors.blue),
            const SizedBox(height: 12),
            _buildActivityItem('New job request', 'Brake service - Toyota Camry', '6 hours ago', Icons.work, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  void _navigateToCashOut() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CashOutScreen(
          professionalId: widget.professionalId,
        ),
      ),
    );
  }

  void _showQuickCashOutDialog() {
    showDialog(
      context: context,
      builder: (context) => CashOutDialog(
        professionalId: widget.professionalId,
        availableBalance: _balance?.availableBalance ?? 0.0,
        onCashOutSuccess: () {
          _loadBalance();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
