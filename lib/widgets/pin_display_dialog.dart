import 'package:flutter/material.dart';

/// Dialog to display the 4-digit PIN to the customer when they click "On My Way"
class PinDisplayDialog extends StatelessWidget {
  final String pin;
  final bool isCustomer;
  final String? instruction;

  const PinDisplayDialog({
    super.key,
    required this.pin,
    this.isCustomer = true,
    this.instruction,
  });

  static Future<void> show(
    BuildContext context, {
    required String pin,
    bool isCustomer = true,
    String? instruction,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PinDisplayDialog(
          pin: pin,
          isCustomer: isCustomer,
          instruction: instruction,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultInstruction = isCustomer
        ? 'Show this PIN to your service professional when you arrive:'
        : 'Ask the customer for this PIN when you arrive:';
    
    final explanation = isCustomer
        ? 'The professional will need this PIN to start your job.'
        : 'The customer will show you this PIN to verify job start.';

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.security,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isCustomer ? 'Your Verification PIN' : 'Customer Verification PIN',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            instruction ?? defaultInstruction,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  isCustomer ? 'Your PIN' : 'Customer PIN',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pin,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            explanation,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: const Text('Got it!'),
        ),
      ],
    );
  }
}

