import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/service_category.dart';
import 'glow_card.dart';

class ServiceCategorySelector extends StatefulWidget {
  final List<ServiceCategory> availableCategories;
  final List<String> selectedCategoryIds;
  final Function(List<String>) onCategoriesChanged;
  final bool allowMultiple;
  final String? title;
  final String? subtitle;

  const ServiceCategorySelector({
    super.key,
    required this.availableCategories,
    required this.selectedCategoryIds,
    required this.onCategoriesChanged,
    this.allowMultiple = true,
    this.title,
    this.subtitle,
  });

  @override
  State<ServiceCategorySelector> createState() => _ServiceCategorySelectorState();
}

class _ServiceCategorySelectorState extends State<ServiceCategorySelector> {
  late List<String> _selectedIds;
  String? _dropdownValue; // For multi-select dropdown

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedCategoryIds);
  }

  @override
  void didUpdateWidget(ServiceCategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryIds != widget.selectedCategoryIds) {
      _selectedIds = List.from(widget.selectedCategoryIds);
    }
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedIds.contains(categoryId)) {
        if (widget.allowMultiple || _selectedIds.length > 1) {
          _selectedIds.remove(categoryId);
        }
      } else {
        if (widget.allowMultiple) {
          _selectedIds.add(categoryId);
        } else {
          _selectedIds = [categoryId];
        }
      }
      // Reset dropdown value after selection for multi-select
      if (widget.allowMultiple) {
        _dropdownValue = null;
      }
    });
    widget.onCategoriesChanged(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Use dropdown on web, grid on mobile
        if (isWeb)
          _buildDropdownSelector(context)
        else
          _buildGridSelector(context),
        
        if (widget.allowMultiple && _selectedIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${_selectedIds.length} category${_selectedIds.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownSelector(BuildContext context) {
    if (widget.allowMultiple) {
      // Multi-select dropdown using chips
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown for adding categories
          DropdownButtonFormField<String>(
            value: _dropdownValue,
            decoration: InputDecoration(
              labelText: 'Select Service Category',
              hintText: _selectedIds.isEmpty 
                  ? 'Choose a category' 
                  : 'Add another category',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: widget.availableCategories
                .where((cat) => !_selectedIds.contains(cat.id))
                .map((category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Row(
                  children: [
                    Icon(
                      category.icon,
                      color: category.color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(category.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (categoryId) {
              if (categoryId != null) {
                _toggleCategory(categoryId);
              }
            },
            validator: widget.allowMultiple
                ? null
                : (value) {
                    if (_selectedIds.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
          ),
          
          // Display selected categories as chips
          if (_selectedIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedIds.map((categoryId) {
                final category = widget.availableCategories
                    .firstWhere((cat) => cat.id == categoryId);
                return Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        size: 18,
                        color: category.color,
                      ),
                      const SizedBox(width: 6),
                      Text(category.name),
                    ],
                  ),
                  onDeleted: () => _toggleCategory(categoryId),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  backgroundColor: category.color.withOpacity(0.1),
                  side: BorderSide(color: category.color),
                );
              }).toList(),
            ),
          ],
        ],
      );
    } else {
      // Single select dropdown
      return DropdownButtonFormField<String>(
        value: _selectedIds.isNotEmpty ? _selectedIds.first : null,
        decoration: InputDecoration(
          labelText: 'Select Service Category',
          hintText: 'Choose a category',
          prefixIcon: _selectedIds.isNotEmpty
              ? Icon(
                  widget.availableCategories
                      .firstWhere((cat) => cat.id == _selectedIds.first)
                      .icon,
                  color: widget.availableCategories
                      .firstWhere((cat) => cat.id == _selectedIds.first)
                      .color,
                )
              : const Icon(Icons.category),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: widget.availableCategories.map((category) {
          return DropdownMenuItem<String>(
            value: category.id,
            child: Row(
              children: [
                Icon(
                  category.icon,
                  color: category.color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(category.name),
              ],
            ),
          );
        }).toList(),
        onChanged: (categoryId) {
          if (categoryId != null) {
            setState(() {
              _selectedIds = [categoryId];
            });
            widget.onCategoriesChanged(_selectedIds);
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a category';
          }
          return null;
        },
      );
    }
  }

  Widget _buildGridSelector(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1, // Slightly taller for better text display
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: widget.availableCategories.length,
      itemBuilder: (context, index) {
        final category = widget.availableCategories[index];
        final isSelected = _selectedIds.contains(category.id);
        
        return Container(
          child: ServiceCategoryCard(
            name: category.name,
            icon: category.icon,
            color: category.color,
            isSelected: isSelected,
            onTap: () => _toggleCategory(category.id),
          ),
        );
      },
    );
  }
}
