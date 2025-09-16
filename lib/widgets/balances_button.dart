import 'package:flutter/material.dart';
import '../services/cashout_service.dart';
import '../models/payout_models.dart' as payout_models;

/// A button widget that displays the professional's balance in a style similar to bottom nav bar items
class BalancesButton extends StatefulWidget {
  final String professionalId;
  final VoidCallback? onPressed;
  final bool showLabel;
  final double? size;

  const BalancesButton({
    Key? key,
    required this.professionalId,
    this.onPressed,
    this.showLabel = true,
    this.size,
  }) : super(key: key);

  @override
  State<BalancesButton> createState() => _BalancesButtonState();
}

class _BalancesButtonState extends State<BalancesButton> {
  final CashOutService _cashOutService = CashOutService.instance;
  payout_models.ProfessionalBalance? _balance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await _cashOutService.getProfessionalBalance(widget.professionalId);
      if (mounted) {
        setState(() {
          _balance = balance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableBalance = _balance?.availableBalance ?? 0.0;
    final iconSize = widget.size ?? 24.0;
    
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with balance indicator
            Stack(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: iconSize,
                  color: availableBalance > 0 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (availableBalance > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 2),
              // Balance text
              _isLoading
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Text(
                      _formatBalance(availableBalance),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: availableBalance > 0 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatBalance(double balance) {
    if (balance == 0) return '\$0';
    if (balance < 1) return '\$${balance.toStringAsFixed(2)}';
    if (balance < 100) return '\$${balance.toStringAsFixed(1)}';
    if (balance < 1000) return '\$${balance.toStringAsFixed(0)}';
    return '\$${(balance / 1000).toStringAsFixed(1)}k';
  }
}

/// A compact balances button for app bar use
class CompactBalancesButton extends StatelessWidget {
  final String professionalId;
  final VoidCallback? onPressed;

  const CompactBalancesButton({
    Key? key,
    required this.professionalId,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BalancesButton(
      professionalId: professionalId,
      onPressed: onPressed,
      showLabel: false,
      size: 24, // Standard icon size for app bar
    );
  }
}
