import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedCategoryIds);
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
    });
    widget.onCategoriesChanged(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
        GridView.builder(
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
        ),
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
}
