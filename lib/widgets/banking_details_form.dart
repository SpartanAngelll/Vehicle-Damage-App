import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/banking_details.dart';
import '../utils/responsive_utils.dart';

class BankingDetailsForm extends StatefulWidget {
  final BankingDetailsFormData? initialData;
  final Function(BankingDetailsFormData) onSave;
  final VoidCallback? onCancel;
  final bool isLoading;

  const BankingDetailsForm({
    super.key,
    this.initialData,
    required this.onSave,
    this.onCancel,
    this.isLoading = false,
  });

  @override
  State<BankingDetailsForm> createState() => _BankingDetailsFormState();
}

class _BankingDetailsFormState extends State<BankingDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _branchCodeController = TextEditingController();
  final _swiftCodeController = TextEditingController();
  final _ibanController = TextEditingController();

  String _accountType = 'checking';
  String _currency = 'JMD';
  bool _isInternational = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _bankNameController.text = data.bankName;
      _accountNumberController.text = data.accountNumber;
      _accountHolderNameController.text = data.accountHolderName;
      _routingNumberController.text = data.routingNumber;
      _branchCodeController.text = data.branchCode ?? '';
      _swiftCodeController.text = data.swiftCode ?? '';
      _ibanController.text = data.iban ?? '';
      _accountType = data.accountType;
      _currency = data.currency;
      _isInternational = data.swiftCode != null && data.swiftCode!.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    _routingNumberController.dispose();
    _branchCodeController.dispose();
    _swiftCodeController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Basic Information"),
            _buildBankNameField(context),
            _buildAccountHolderNameField(context),
            _buildAccountTypeField(context),
            _buildCurrencyField(context),
            
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
            
            _buildSectionHeader(context, "Account Details"),
            _buildAccountNumberField(context),
            _buildRoutingNumberField(context),
            _buildBranchCodeField(context),
            
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
            
            _buildSectionHeader(context, "International Transfer (Optional)"),
            _buildInternationalToggle(context),
            if (_isInternational) ...[
              _buildSwiftCodeField(context),
              _buildIbanField(context),
            ],
            
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
            
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: ResponsiveUtils.getResponsiveFontSize(
            context,
            mobile: 18,
            tablet: 20,
            desktop: 22,
          ),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildBankNameField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
      child: TextFormField(
        controller: _bankNameController,
        decoration: InputDecoration(
          labelText: 'Bank Name *',
          hintText: 'Enter bank name',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.account_balance),
        ),
        validator: BankingDetails.validateBankName,
        textInputAction: TextInputAction.next,
      ),
    );
  }

  Widget _buildAccountHolderNameField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
      child: TextFormField(
        controller: _accountHolderNameController,
        decoration: InputDecoration(
          labelText: 'Account Holder Name *',
          hintText: 'Enter account holder name',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
        validator: BankingDetails.validateAccountHolderName,
        textInputAction: TextInputAction.next,
      ),
    );
  }

  Widget _buildAccountTypeField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
      child: DropdownButtonFormField<String>(
        value: _accountType,
        decoration: InputDecoration(
          labelText: 'Account Type *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.account_balance_wallet),
        ),
        items: [
          DropdownMenuItem(value: 'checking', child: Text('Checking')),
          DropdownMenuItem(value: 'savings', child: Text('Savings')),
          DropdownMenuItem(value: 'business', child: Text('Business')),
        ],
        onChanged: (value) {
          setState(() {
            _accountType = value ?? 'checking';
          });
        },
        isExpanded: true,
      ),
    );
  }

  Widget _buildCurrencyField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
      child: DropdownButtonFormField<String>(
        value: _currency,
        decoration: InputDecoration(
          labelText: 'Currency *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.attach_money),
        ),
        items: [
          DropdownMenuItem(value: 'JMD', child: Text('JMD')),
          DropdownMenuItem(value: 'USD', child: Text('USD')),
          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
          DropdownMenuItem(value: 'GBP', child: Text('GBP')),
        ],
        onChanged: (value) {
          setState(() {
            _currency = value ?? 'JMD';
          });
        },
        isExpanded: true,
      ),
    );
  }

  Widget _buildAccountNumberField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
      child: TextFormField(
        controller: _accountNumberController,
        decoration: InputDecoration(
          labelText: 'Account Number *',
          hintText: 'Enter account number',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.credit_card),
        ),
        validator: BankingDetails.validateAccountNumber,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        textInputAction: TextInputAction.next,
      ),
    );
  }

  Widget _buildRoutingNumberField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
      child: TextFormField(
        controller: _routingNumberController,
        decoration: InputDecoration(
          labelText: 'Routing Number *',
          hintText: 'Enter routing number',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.route),
        ),
        validator: BankingDetails.validateRoutingNumber,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        textInputAction: TextInputAction.next,
      ),
    );
  }

  Widget _buildBranchCodeField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
      child: TextFormField(
        controller: _branchCodeController,
        decoration: InputDecoration(
          labelText: 'Branch Code (Optional)',
          hintText: 'Enter branch code',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.location_on),
        ),
        textInputAction: TextInputAction.next,
      ),
    );
  }

  Widget _buildInternationalToggle(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
      child: Row(
        children: [
          Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enable international transfers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
              ),
            ),
          ),
          Switch(
            value: _isInternational,
            onChanged: (value) {
              setState(() {
                _isInternational = value;
                if (!value) {
                  _swiftCodeController.clear();
                  _ibanController.clear();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwiftCodeField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
      child: TextFormField(
        controller: _swiftCodeController,
        decoration: InputDecoration(
          labelText: 'SWIFT Code',
          hintText: 'Enter SWIFT code (8 or 11 characters)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.flight),
        ),
        validator: BankingDetails.validateSwiftCode,
        textCapitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.next,
        onChanged: (value) {
          setState(() {
            _swiftCodeController.value = _swiftCodeController.value.copyWith(
              text: value.toUpperCase(),
              selection: TextSelection.collapsed(offset: value.length),
            );
          });
        },
      ),
    );
  }

  Widget _buildIbanField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
      child: TextFormField(
        controller: _ibanController,
        decoration: InputDecoration(
          labelText: 'IBAN',
          hintText: 'Enter IBAN',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.public),
        ),
        validator: BankingDetails.validateIban,
        textCapitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.done,
        onChanged: (value) {
          setState(() {
            _ibanController.value = _ibanController.value.copyWith(
              text: value.toUpperCase().replaceAll(RegExp(r'[\s\-]'), ''),
              selection: TextSelection.collapsed(offset: value.length),
            );
          });
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (widget.onCancel != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: widget.isLoading ? null : widget.onCancel,
              child: Text(
                'Cancel',
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
          ),
          SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : _handleSave,
            child: widget.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    'Save Banking Details',
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
        ),
      ],
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final formData = BankingDetailsFormData(
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.replaceAll(RegExp(r'[\s\-]'), ''),
        accountHolderName: _accountHolderNameController.text.trim(),
        routingNumber: _routingNumberController.text.replaceAll(RegExp(r'[\s\-]'), ''),
        branchCode: _branchCodeController.text.trim().isNotEmpty ? _branchCodeController.text.trim() : null,
        swiftCode: _isInternational && _swiftCodeController.text.trim().isNotEmpty 
            ? _swiftCodeController.text.trim().toUpperCase() 
            : null,
        iban: _isInternational && _ibanController.text.trim().isNotEmpty 
            ? _ibanController.text.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '') 
            : null,
        accountType: _accountType,
        currency: _currency,
      );

      widget.onSave(formData);
    }
  }
}
