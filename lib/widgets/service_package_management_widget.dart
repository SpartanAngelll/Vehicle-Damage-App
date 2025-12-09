import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/service_package.dart';
import '../services/service_package_service.dart';
import '../theme/app_theme.dart';

/// Widget for professionals to manage their service packages
class ServicePackageManagementWidget extends StatefulWidget {
  final String professionalId;
  final bool isCurrentUser;

  const ServicePackageManagementWidget({
    super.key,
    required this.professionalId,
    required this.isCurrentUser,
  });

  @override
  State<ServicePackageManagementWidget> createState() => _ServicePackageManagementWidgetState();
}

class _ServicePackageManagementWidgetState extends State<ServicePackageManagementWidget> {
  final ServicePackageService _service = ServicePackageService.instance;
  List<ServicePackage> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isCurrentUser) {
      _loadPackages();
    }
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    try {
      final packages = await _service.getServicePackages(
        professionalId: widget.professionalId,
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

  Future<void> _addServicePackage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServicePackageEditScreen(
          professionalId: widget.professionalId,
        ),
      ),
    );

    if (result == true) {
      _loadPackages();
    }
  }

  Future<void> _editServicePackage(ServicePackage package) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServicePackageEditScreen(
          professionalId: widget.professionalId,
          package: package,
        ),
      ),
    );

    if (result == true) {
      _loadPackages();
    }
  }

  Future<void> _deleteServicePackage(ServicePackage package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${package.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteServicePackage(package.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service deleted successfully')),
          );
          _loadPackages();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete service: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isCurrentUser) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addServicePackage,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_packages.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No services yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first service package to get started',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _packages.length,
            itemBuilder: (context, index) {
              final package = _packages[index];
              return _ServicePackageCard(
                package: package,
                onEdit: () => _editServicePackage(package),
                onDelete: () => _deleteServicePackage(package),
              );
            },
          ),
      ],
    );
  }
}

class _ServicePackageCard extends StatelessWidget {
  final ServicePackage package;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServicePackageCard({
    required this.package,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          package.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!package.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  if (package.description != null && package.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      package.description!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        package.formattedDuration,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        package.displayPrice,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen for editing/creating service packages
class ServicePackageEditScreen extends StatefulWidget {
  final String professionalId;
  final ServicePackage? package;

  const ServicePackageEditScreen({
    super.key,
    required this.professionalId,
    this.package,
  });

  @override
  State<ServicePackageEditScreen> createState() => _ServicePackageEditScreenState();
}

class _ServicePackageEditScreenState extends State<ServicePackageEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final ServicePackageService _service = ServicePackageService.instance;

  bool _isStartingFrom = false;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.package != null) {
      _nameController.text = widget.package!.name;
      _descriptionController.text = widget.package!.description ?? '';
      _priceController.text = widget.package!.price.toStringAsFixed(2);
      _durationController.text = widget.package!.durationMinutes.toString();
      _isStartingFrom = widget.package!.isStartingFrom;
      _isActive = widget.package!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final price = double.tryParse(_priceController.text);
      final duration = int.tryParse(_durationController.text);

      if (price == null || price <= 0) {
        throw Exception('Invalid price');
      }
      if (duration == null || duration <= 0) {
        throw Exception('Invalid duration');
      }

      if (widget.package != null) {
        // Update existing package
        final updated = widget.package!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          price: price,
          durationMinutes: duration,
          isStartingFrom: _isStartingFrom,
          isActive: _isActive,
          updatedAt: DateTime.now(),
        );
        await _service.updateServicePackage(updated);
      } else {
        // Create new package
        await _service.createServicePackage(
          professionalId: widget.professionalId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          price: price,
          durationMinutes: duration,
          isStartingFrom: _isStartingFrom,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.package != null
                ? 'Service updated successfully'
                : 'Service created successfully'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.package != null ? 'Edit Service' : 'Add Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Service name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Describe what this service includes...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price *',
                        border: OutlineInputBorder(),
                        prefixText: 'JMD ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Price is required';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Price must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Duration is required';
                        }
                        final duration = int.tryParse(value);
                        if (duration == null || duration <= 0) {
                          return 'Duration must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Price is "starting from"'),
                subtitle: const Text('Show "from" prefix before the price'),
                value: _isStartingFrom,
                onChanged: (value) => setState(() => _isStartingFrom = value),
              ),
              if (widget.package != null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Inactive services won\'t be visible to customers'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.package != null ? 'Update Service' : 'Create Service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


