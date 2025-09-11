import 'package:flutter/material.dart';
import '../models/service.dart';

class TravelModeSelector extends StatefulWidget {
  final Service service;
  final TravelMode? selectedMode;
  final Function(TravelMode, String?, double?) onModeChanged;

  const TravelModeSelector({
    super.key,
    required this.service,
    this.selectedMode,
    required this.onModeChanged,
  });

  @override
  State<TravelModeSelector> createState() => _TravelModeSelectorState();
}

class _TravelModeSelectorState extends State<TravelModeSelector> {
  TravelMode? _selectedMode;
  final TextEditingController _addressController = TextEditingController();
  double? _calculatedTravelFee;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.selectedMode ?? widget.service.defaultTravel;
    // Defer the callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTravelFee();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _updateTravelFee() {
    if (_selectedMode == TravelMode.proTravels && widget.service.hasTravelFee) {
      _calculatedTravelFee = widget.service.travelFee;
    } else {
      _calculatedTravelFee = null;
    }
    
    widget.onModeChanged(
      _selectedMode!,
      _selectedMode == TravelMode.proTravels ? _addressController.text : null,
      _calculatedTravelFee,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Default option (customer travels)
            _buildTravelOption(
              mode: TravelMode.customerTravels,
              title: 'Go to Shop',
              subtitle: widget.service.fullShopAddress.isNotEmpty 
                  ? widget.service.fullShopAddress
                  : 'Professional\'s shop location',
              icon: Icons.store,
              color: Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            // Professional travels option (if available)
            if (widget.service.proTravelsAvailable) ...[
              _buildTravelOption(
                mode: TravelMode.proTravels,
                title: 'Request Pro to Travel',
                subtitle: widget.service.hasTravelFee 
                    ? 'Travel fee: \$${widget.service.travelFee!.toStringAsFixed(2)}'
                    : 'Professional will come to you',
                icon: Icons.directions_car,
                color: Colors.green,
              ),
              
              // Address input for pro travel
              if (_selectedMode == TravelMode.proTravels) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Your Address',
                    hintText: 'Enter your full address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    // Defer the callback to avoid setState during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _updateTravelFee();
                    });
                  },
                ),
              ],
            ],
            
            // Remote option (if applicable)
            if (widget.service.defaultTravel == TravelMode.remote) ...[
              _buildTravelOption(
                mode: TravelMode.remote,
                title: 'Remote Service',
                subtitle: 'Service will be provided remotely',
                icon: Icons.video_call,
                color: Colors.purple,
              ),
            ],
            
            // Travel fee display
            if (_calculatedTravelFee != null && _calculatedTravelFee! > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Travel Fee: \$${_calculatedTravelFee!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTravelOption({
    required TravelMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
        // Defer the callback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateTravelFee();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
