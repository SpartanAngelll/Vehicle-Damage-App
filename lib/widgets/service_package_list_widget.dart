import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/service_package.dart';
import '../models/service_professional.dart';
import '../services/service_package_service.dart';
import '../services/firebase_firestore_service.dart';
import '../screens/customer_booking_screen.dart';
import '../models/user_state.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

/// Widget for customers to view and book service packages
/// Inspired by the mobile app screenshot with clean, modern design
class ServicePackageListWidget extends StatefulWidget {
  final String professionalId;
  final String? professionalName;
  final bool isCustomerView;

  const ServicePackageListWidget({
    super.key,
    required this.professionalId,
    this.professionalName,
    this.isCustomerView = true,
  });

  @override
  State<ServicePackageListWidget> createState() => _ServicePackageListWidgetState();
}

class _ServicePackageListWidgetState extends State<ServicePackageListWidget> {
  final ServicePackageService _service = ServicePackageService.instance;
  List<ServicePackage> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    try {
      final packages = await _service.getServicePackages(
        professionalId: widget.professionalId,
        activeOnly: true, // Only show active services to customers
      );
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load services: $e')),
        );
      }
    }
  }

  Future<void> _bookService(ServicePackage package) async {
    try {
      // Get user state for customer info
      // IMPORTANT: Always use currentUser?.uid first to ensure we use the current Firebase Auth UID
      // userState.userId can be stale from local storage and won't match the JWT token
      final userState = Provider.of<UserState>(context, listen: false);
      final customerId = userState.currentUser?.uid ?? userState.userId;
      final customerName = userState.currentUser?.displayName ?? 
                          userState.fullName ?? 
                          'Customer';

      if (customerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to book a service')),
        );
        return;
      }

      // Fetch professional details
      final firestoreService = FirebaseFirestoreService();
      final professional = await firestoreService.getServiceProfessional(widget.professionalId);

      if (professional == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Professional not found')),
        );
        return;
      }

      // Navigate to booking screen with service package details
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerBookingScreen(
            professional: professional,
            customerId: customerId,
            customerName: customerName,
            serviceTitle: package.name,
            serviceDescription: package.description ?? package.name,
            agreedPrice: package.price,
            location: professional.businessAddress ?? 
                     professional.address ?? 
                     'Location to be determined',
          ),
        ),
      );

      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book service: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_packages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No services available',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'This professional hasn\'t added any services yet',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show first few services, then "See all" button
    final displayCount = 4;
    final showSeeAll = _packages.length > displayCount;
    final displayPackages = showSeeAll
        ? _packages.take(displayCount).toList()
        : _packages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service list
        ...displayPackages.map((package) => _ServicePackageListItem(
              package: package,
              onBook: () => _bookService(package),
            )),
        
        // "See all" button if there are more services
        if (showSeeAll)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: OutlinedButton(
                onPressed: () => _showAllServices(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('See all'),
              ),
            ),
          ),
        
        // Bottom bar with service count and "Book now" button
        if (widget.isCustomerView)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_packages.length} ${_packages.length == 1 ? 'service' : 'services'} available',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showAllServices(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Book now'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showAllServices() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Services',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Services list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _packages.length,
                  itemBuilder: (context, index) {
                    final package = _packages[index];
                    return _ServicePackageListItem(
                      package: package,
                      onBook: () {
                        Navigator.pop(context);
                        _bookService(package);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual service package list item
/// Designed to match the mobile app screenshot style
class _ServicePackageListItem extends StatelessWidget {
  final ServicePackage package;
  final VoidCallback onBook;

  const _ServicePackageListItem({
    required this.package,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Duration
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          package.formattedDuration,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Price
                    Text(
                      package.displayPrice,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (package.description != null &&
                    package.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    package.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Book button
          SizedBox(
            width: isMobile ? 80 : 100,
            child: OutlinedButton(
              onPressed: onBook,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: const Text(
                'Book',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

