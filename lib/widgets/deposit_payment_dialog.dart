import 'package:flutter/material.dart';
import '../models/invoice_models.dart';
import '../models/payment_models.dart';

class DepositPaymentDialog extends StatefulWidget {
  final Invoice invoice;
  final Function(PaymentMethod) onDepositPaid;

  const DepositPaymentDialog({
    super.key,
    required this.invoice,
    required this.onDepositPaid,
  });

  @override
  State<DepositPaymentDialog> createState() => _DepositPaymentDialogState();
}

class _DepositPaymentDialogState extends State<DepositPaymentDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.creditCard;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Deposit Required'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Professional requires a deposit to secure your booking',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This ensures your service slot is reserved and the professional is committed to your job.',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentSummary(),
          const SizedBox(height: 16),
          const Text(
            'Select Payment Method:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...PaymentMethod.values.map((method) {
            return RadioListTile<PaymentMethod>(
              title: Text(_getPaymentMethodDisplayName(method)),
              subtitle: Text(_getPaymentMethodDescription(method)),
              value: method,
              groupValue: _selectedMethod,
              onChanged: _isProcessing
                  ? null
                  : (PaymentMethod? value) {
                      if (value != null) {
                        setState(() {
                          _selectedMethod = value;
                        });
                      }
                    },
            );
          }).toList(),
          if (_isProcessing) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text(
              'Processing deposit payment...',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isProcessing
              ? null
              : () async {
                  setState(() {
                    _isProcessing = true;
                  });
                  await widget.onDepositPaid(_selectedMethod);
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
          icon: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.payment),
          label: Text(_isProcessing ? 'Processing...' : 'Pay Deposit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service Total:'),
              Text(
                '${widget.invoice.totalAmount.toStringAsFixed(2)} ${widget.invoice.currency}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Deposit (${widget.invoice.depositPercentage}%):'),
              Text(
                '${widget.invoice.depositAmount.toStringAsFixed(2)} ${widget.invoice.currency}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amount Due Now:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${widget.invoice.depositAmount.toStringAsFixed(2)} ${widget.invoice.currency}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Balance Due Later:'),
              Text(
                '${widget.invoice.balanceAmount.toStringAsFixed(2)} ${widget.invoice.currency}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Cash on Service';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
    }
  }

  String _getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Visa, Mastercard, American Express';
      case PaymentMethod.debitCard:
        return 'Direct bank account debit';
      case PaymentMethod.bankTransfer:
        return 'Wire transfer or online banking';
      case PaymentMethod.cash:
        return 'Pay when service is completed';
      case PaymentMethod.mobileMoney:
        return 'Digicel, Flow, or other mobile wallet';
    }
  }
}
