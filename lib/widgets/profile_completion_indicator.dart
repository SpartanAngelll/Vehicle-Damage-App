import 'package:flutter/material.dart';
import '../models/user_state.dart';
import '../services/profile_auto_fill_service.dart';

class ProfileCompletionIndicator extends StatelessWidget {
  final UserState userState;
  final VoidCallback? onTap;

  const ProfileCompletionIndicator({
    super.key,
    required this.userState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completeness = ProfileAutoFillService.checkProfileCompleteness(userState);
    final missingFields = ProfileAutoFillService.getMissingRequiredFields(userState);
    final completionPercentage = _calculateCompletionPercentage(completeness);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    completionPercentage == 100 ? Icons.check_circle : Icons.info,
                    color: completionPercentage == 100 
                        ? Colors.green 
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Profile Completion',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completionPercentage%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: completionPercentage == 100 
                          ? Colors.green 
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Progress bar
              LinearProgressIndicator(
                value: completionPercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  completionPercentage == 100 
                      ? Colors.green 
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              
              if (missingFields.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Missing required fields:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: missingFields.map((field) => Chip(
                    label: Text(
                      field,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.orange[100],
                    labelStyle: TextStyle(
                      color: Colors.orange[800],
                    ),
                  )).toList(),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Profile is complete!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              
              if (onTap != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Tap to edit profile',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _calculateCompletionPercentage(Map<String, bool> completeness) {
    if (completeness.isEmpty) return 0;
    
    final totalFields = completeness.length;
    final completedFields = completeness.values.where((isComplete) => isComplete).length;
    
    return ((completedFields / totalFields) * 100).round();
  }
}
