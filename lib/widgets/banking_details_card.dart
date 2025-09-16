import 'package:flutter/material.dart';
import '../models/banking_details.dart';
import '../utils/responsive_utils.dart';

class BankingDetailsCard extends StatelessWidget {
  final BankingDetails? bankingDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onAdd;
  final bool isLoading;

  const BankingDetailsCard({
    super.key,
    this.bankingDetails,
    this.onEdit,
    this.onAdd,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
            
            if (isLoading)
              _buildLoadingState(context)
            else if (bankingDetails == null)
              _buildEmptyState(context)
            else
              _buildBankingDetailsContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.account_balance,
          color: Theme.of(context).colorScheme.primary,
          size: ResponsiveUtils.getResponsiveFontSize(
            context,
            mobile: 24,
            tablet: 28,
            desktop: 32,
          ),
        ),
        SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
        Expanded(
          child: Text(
            'Banking Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (bankingDetails != null && onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit),
            tooltip: 'Edit banking details',
          ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
          Text(
            'Loading banking details...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.account_balance_outlined,
          size: ResponsiveUtils.getResponsiveFontSize(
            context,
            mobile: 48,
            tablet: 56,
            desktop: 64,
          ),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
        Text(
          'No banking details added',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
        Text(
          'Add your banking details to receive payments from completed jobs.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
        if (onAdd != null)
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add),
            label: Text(
              'Add Banking Details',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBankingDetailsContent(BuildContext context) {
    final details = bankingDetails!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(context, 'Bank Name', details.bankName),
        _buildInfoRow(context, 'Account Holder', details.accountHolderName),
        _buildInfoRow(context, 'Account Number', details.maskedAccountNumber),
        _buildInfoRow(context, 'Routing Number', details.routingNumber),
        
        if (details.branchCode != null && details.branchCode!.isNotEmpty)
          _buildInfoRow(context, 'Branch Code', details.branchCode!),
        
        _buildInfoRow(context, 'Account Type', _capitalizeFirst(details.accountType)),
        _buildInfoRow(context, 'Currency', details.currency),
        
        if (details.isInternational) ...[
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
          _buildInternationalSection(context, details),
        ],
        
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
        _buildStatusSection(context, details),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternationalSection(BuildContext context, BankingDetails details) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.primary,
                size: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 24,
                  desktop: 28,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
              Text(
                'International Transfer Details',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
          
          if (details.swiftCode != null && details.swiftCode!.isNotEmpty)
            _buildInfoRow(context, 'SWIFT Code', details.swiftCode!),
          
          if (details.iban != null && details.iban!.isNotEmpty)
            _buildInfoRow(context, 'IBAN', details.iban!),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, BankingDetails details) {
    return Row(
      children: [
        Icon(
          details.isVerified ? Icons.verified : Icons.pending,
          color: details.isVerified 
              ? Colors.green 
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: ResponsiveUtils.getResponsiveFontSize(
            context,
            mobile: 20,
            tablet: 24,
            desktop: 28,
          ),
        ),
        SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.isVerified ? 'Verified' : 'Pending Verification',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  fontWeight: FontWeight.w500,
                  color: details.isVerified 
                      ? Colors.green 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (details.lastUsedForPayout != null)
                Text(
                  'Last used: ${_formatDate(details.lastUsedForPayout!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
