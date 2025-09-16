import 'package:flutter/material.dart';
import '../screens/cashout_screen.dart';
import '../services/cashout_service.dart';
import '../widgets/cashout_widgets.dart';

/// Example showing how to integrate cash-out feature into existing professional dashboard
class ProfessionalDashboardIntegrationExample extends StatefulWidget {
  final String professionalId;

  const ProfessionalDashboardIntegrationExample({
    Key? key,
    required this.professionalId,
  }) : super(key: key);

  @override
  State<ProfessionalDashboardIntegrationExample> createState() => _ProfessionalDashboardIntegrationExampleState();
}

class _ProfessionalDashboardIntegrationExampleState extends State<ProfessionalDashboardIntegrationExample> {
  final CashOutService _cashOutService = CashOutService.instance;
  ProfessionalBalance? _balance;
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
          // Add cash-out button to app bar
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _navigateToCashOut,
            tooltip: 'Cash Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Existing dashboard content
                  _buildWelcomeCard(),
                  const SizedBox(height: 16),
                  
                  // Add cash-out balance card
                  _buildCashOutBalanceCard(),
                  const SizedBox(height: 16),
                  
                  // Existing dashboard content
                  _buildQuickStatsCard(),
                  const SizedBox(height: 16),
                  _buildRecentJobsCard(),
                ],
              ),
            ),
      // Add floating action button for quick cash-out
      floatingActionButton: _buildFloatingActionButton(),
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

  Widget _buildCashOutBalanceCard() {
    final availableBalance = _balance?.availableBalance ?? 0.0;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Earnings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: availableBalance > 0 ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        availableBalance > 0 
                            ? 'Ready for cash-out'
                            : 'No available balance',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: availableBalance > 0 ? Colors.green[600] : Colors.grey[600],
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
            if (_balance != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildBalanceStat(
                      'Total Earned',
                      _cashOutService.formatAmount(_balance!.totalEarned),
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBalanceStat(
                      'Total Paid Out',
                      _cashOutService.formatAmount(_balance!.totalPaidOut),
                      Icons.payment,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceStat(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
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
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem('Reviews', '23', Icons.rate_review, Colors.green),
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
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildRecentJobsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Jobs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildJobItem('Auto repair - Honda Civic', '\$150.00', '2 hours ago', Icons.check_circle, Colors.green),
            const SizedBox(height: 12),
            _buildJobItem('Brake service - Toyota Camry', '\$200.00', '4 hours ago', Icons.check_circle, Colors.green),
            const SizedBox(height: 12),
            _buildJobItem('Oil change - Ford Focus', '\$75.00', '6 hours ago', Icons.schedule, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildJobItem(String title, String amount, String time, IconData icon, Color color) {
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
                amount,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green[600],
                  fontWeight: FontWeight.bold,
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

  Widget? _buildFloatingActionButton() {
    final availableBalance = _balance?.availableBalance ?? 0.0;
    
    if (availableBalance <= 0) return null;

    return FloatingActionButton.extended(
      onPressed: _showQuickCashOutDialog,
      icon: const Icon(Icons.money_off),
      label: const Text('Cash Out'),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
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

/// Example showing how to add cash-out to existing bottom navigation
class ProfessionalBottomNavigationExample extends StatefulWidget {
  final String professionalId;

  const ProfessionalBottomNavigationExample({
    Key? key,
    required this.professionalId,
  }) : super(key: key);

  @override
  State<ProfessionalBottomNavigationExample> createState() => _ProfessionalBottomNavigationExampleState();
}

class _ProfessionalBottomNavigationExampleState extends State<ProfessionalBottomNavigationExample> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const Center(child: Text('Dashboard')),
    const Center(child: Text('Jobs')),
    const Center(child: Text('Messages')),
    const Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      // Add cash-out floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCashOut,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.account_balance_wallet),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
}

/// Example showing how to add cash-out to existing drawer menu
class ProfessionalDrawerExample extends StatelessWidget {
  final String professionalId;

  const ProfessionalDrawerExample({
    Key? key,
    required this.professionalId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Professional Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('My Jobs'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          // Add cash-out menu item
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
            title: const Text('Cash Out'),
            subtitle: const Text('Manage your earnings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CashOutScreen(
                    professionalId: professionalId,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
