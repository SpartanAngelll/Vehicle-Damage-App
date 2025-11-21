import 'package:flutter/material.dart';
import 'package:vehicle_damage_app/widgets/glow_card.dart';
import '../utils/category_image_helper.dart';

class AutoScrollingServices extends StatefulWidget {
  final VoidCallback? onServiceTap;

  const AutoScrollingServices({
    super.key,
    this.onServiceTap,
  });

  @override
  State<AutoScrollingServices> createState() => _AutoScrollingServicesState();
}

class _AutoScrollingServicesState extends State<AutoScrollingServices>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  late Animation<double> _scrollAnimation;

  final List<Map<String, dynamic>> _services = [
    {'id': 'mechanics', 'name': 'Automotive', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'id': 'plumbers', 'name': 'Plumbing', 'icon': Icons.plumbing, 'color': Colors.cyan},
    {'id': 'electricians', 'name': 'Electrical', 'icon': Icons.electrical_services, 'color': Colors.amber},
    {'id': 'hairdressers_barbers', 'name': 'Hair', 'icon': Icons.content_cut, 'color': Colors.pink},
    {'id': 'makeup_artists', 'name': 'Makeup', 'icon': Icons.face, 'color': Colors.purple},
    {'id': 'nail_technicians', 'name': 'Nails', 'icon': Icons.brush, 'color': Colors.red},
    {'id': 'cleaners', 'name': 'Cleaning', 'icon': Icons.cleaning_services, 'color': Colors.green},
    {'id': 'landscapers', 'name': 'Landscaping', 'icon': Icons.grass, 'color': Colors.lightGreen},
    {'id': 'carpenters', 'name': 'Carpentry', 'icon': Icons.build, 'color': Colors.brown},
    {'id': 'painters', 'name': 'Painting', 'icon': Icons.format_paint, 'color': Colors.orange},
    {'id': 'technicians', 'name': 'Repair', 'icon': Icons.engineering, 'color': Colors.indigo},
    {'id': 'appliance_repair', 'name': 'Appliances', 'icon': Icons.home_repair_service, 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(seconds: 20), // Slower for smoother movement
      vsync: this,
    );
    
    _scrollAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scrollController,
      curve: Curves.easeInOut, // Smoother curve
    ));

    // Start the animation
    _scrollController.repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400, // Fixed height for the scrolling area
      child: AnimatedBuilder(
        animation: _scrollAnimation,
        builder: (context, child) {
          return CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildScrollingContent(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScrollingContent() {
    // Create a list that includes the services twice for seamless looping
    final double itemHeight = 120.0; // Slightly taller for 2-column layout
    final double totalHeight = (_services.length / 2).ceil() * itemHeight; // Divide by 2 for columns
    final double scrollOffset = _scrollAnimation.value * totalHeight;

    return Transform.translate(
      offset: Offset(0, -scrollOffset),
      child: Column(
        children: [
          // First set of services in 2 columns
          _buildServiceGrid(),
          // Second set of services for seamless looping
          _buildServiceGrid(),
        ],
      ),
    );
  }

  Widget _buildServiceGrid() {
    return Column(
      children: _buildServiceRows(),
    );
  }

  List<Widget> _buildServiceRows() {
    List<Widget> rows = [];
    
    // Group services into pairs for 2-column layout
    for (int i = 0; i < _services.length; i += 2) {
      List<Widget> rowItems = [];
      
      // First column item
      if (i < _services.length) {
        rowItems.add(
          Expanded(
            child: _buildServiceItem(_services[i], 120.0),
          ),
        );
      }
      
      // Second column item
      if (i + 1 < _services.length) {
        rowItems.add(
          Expanded(
            child: _buildServiceItem(_services[i + 1], 120.0),
          ),
        );
      } else {
        // Add empty space if odd number of items
        rowItems.add(
          Expanded(
            child: SizedBox(height: 120.0),
          ),
        );
      }
      
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: rowItems,
          ),
        ),
      );
    }
    
    return rows;
  }

  Widget _buildServiceItem(Map<String, dynamic> service, double height) {
    final categoryColor = service['color'] as Color;
    final serviceName = service['name'] as String;
    final imageUrl = CategoryImageHelper.getCategoryImageUrl(serviceName);
    
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ServiceCategoryCard(
        name: serviceName,
        icon: service['icon'] as IconData,
        color: categoryColor,
        imageUrl: imageUrl,
        onTap: widget.onServiceTap ?? () {
          Navigator.pushNamed(context, '/serviceRequest');
        },
      ),
    );
  }
}
