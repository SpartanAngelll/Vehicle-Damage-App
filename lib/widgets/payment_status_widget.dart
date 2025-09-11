import 'package:flutter/material.dart';
import '../models/payment_models.dart';

class PaymentStatusWidget extends StatelessWidget {
  final Payment? payment;
  final VoidCallback? onPayDepositPressed;
  final VoidCallback? onPayBalancePressed;
  final VoidCallback? onPayFullPressed;
  final VoidCallback? onRequestDepositPressed;
  final bool isProfessional;
  final bool showActions;

  const PaymentStatusWidget({
    super.key,
    this.payment,
    this.onPayDepositPressed,
    this.onPayBalancePressed,
    this.onPayFullPressed,
    this.onRequestDepositPressed,
    this.isProfessional = false,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    if (payment == null) {
      return _buildNoPaymentWidget();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment Status',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 8),

          _buildPaymentDetails(),

          if (payment!.isDepositRequired) ...[
            const SizedBox(height: 8),
            _buildDepositInfo(),
          ],

          if (showActions) ...[
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildNoPaymentWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            'No payment information available',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        payment!.status.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Total Amount',
            '${payment!.originalTotalAmount.toStringAsFixed(2)} ${payment!.currency}'),
        if (payment!.isDepositRequired) ...[
          _buildDetailRow('Deposit Required',
              '${payment!.depositRequired.toStringAsFixed(2)} ${payment!.currency}'),
          _buildDetailRow('Deposit Percentage',
              '${payment!.depositPercentage.toString()}%'),
          _buildDetailRow('Deposit Paid',
              '${payment!.depositPaid.toStringAsFixed(2)} ${payment!.currency}'),
          _buildDetailRow('Remaining Balance',
              '${payment!.remainingAmount.toStringAsFixed(2)} ${payment!.currency}'),
        ],
        if (payment!.transactionId != null)
          _buildDetailRow('Transaction ID', payment!.transactionId!),
        if (payment!.paidAt != null)
          _buildDetailRow('Paid At', _formatDateTime(payment!.paidAt!)),
      ],
    );
  }

  Widget _buildDepositInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${payment!.depositPercentage}% deposit required. Balance must be paid before job completion.',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (isProfessional) {
      return _buildProfessionalActions();
    } else {
      return _buildCustomerActions();
    }
  }

  Widget _buildProfessionalActions() {
    if (payment!.status == PaymentStatus.pending &&
        !payment!.isDepositRequired) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onRequestDepositPressed,
          icon: const Icon(Icons.request_quote, size: 18),
          label: const Text('Request Deposit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCustomerActions() {
    final needsDeposit = payment!.isDepositRequired &&
        payment!.depositPaid < payment!.depositRequired;
    final needsBalance =
        payment!.isDepositRequired && payment!.remainingAmount > 0;
    final needsFullPayment = !payment!.isDepositRequired && 
        payment!.status == PaymentStatus.pending;

    if (needsDeposit) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPayDepositPressed,
          icon: const Icon(Icons.payment, size: 18),
          label: const Text('Pay Deposit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );
    } else if (needsBalance) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPayBalancePressed,
          icon: const Icon(Icons.account_balance_wallet, size: 18),
          label: const Text('Pay Remaining Balance'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );
    } else if (needsFullPayment) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPayFullPressed,
          icon: const Icon(Icons.payment, size: 18),
          label: const Text('Pay Full Amount'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (payment!.status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.refunded:
        return Colors.blue;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (payment!.status) {
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.refunded:
        return Icons.refresh;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}