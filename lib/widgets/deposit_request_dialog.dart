import 'package:flutter/material.dart';

class DepositRequestDialog extends StatefulWidget {
  final String bookingId;
  final String professionalId;
  final double totalAmount;
  final Function(int depositPercentage, String reason) onRequestDeposit;

  const DepositRequestDialog({
    super.key,
    required this.bookingId,
    required this.professionalId,
    required this.totalAmount,
    required this.onRequestDeposit,
  });

  @override
  State<DepositRequestDialog> createState() => _DepositRequestDialogState();
}

class _DepositRequestDialogState extends State<DepositRequestDialog> {
  int _depositPercentage = 20;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final depositAmount = widget.totalAmount * _depositPercentage / 100;
    final remainingAmount = widget.totalAmount - depositAmount;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.request_quote, color: Colors.orange),
          SizedBox(width: 8),
          Text('Request Deposit'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request a deposit from the customer to secure this booking.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            
            // Deposit percentage selection
            Text(
              'Deposit Percentage',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _depositPercentage.toDouble(),
                    min: 10,
                    max: 50,
                    divisions: 8,
                    label: '$_depositPercentage%',
                    onChanged: (value) {
                      setState(() {
                        _depositPercentage = value.round();
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$_depositPercentage%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Amount breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildAmountRow('Total Amount', widget.totalAmount),
                  _buildAmountRow('Deposit Amount', depositAmount),
                  _buildAmountRow('Remaining Balance', remainingAmount),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Reason field
            Text(
              'Reason for Deposit (Optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Explain why a deposit is required...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _requestDeposit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Request Deposit'),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            '${amount.toStringAsFixed(2)} JMD',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestDeposit() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onRequestDeposit(
        _depositPercentage,
        _reasonController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deposit request sent (${_depositPercentage}%)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request deposit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
