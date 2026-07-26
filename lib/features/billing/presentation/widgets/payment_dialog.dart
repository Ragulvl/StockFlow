import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/printer/esc_pos_formatter.dart';
import '../../../../core/printer/receipt_template.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/billing_providers.dart';
import '../../../../providers/repository_providers.dart';
import 'receipt_preview_dialog.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog({super.key});

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  String _selectedPaymentMethod = 'CASH';
  final TextEditingController _tenderedController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _customerAddressController = TextEditingController();
  final TextEditingController _customerStateController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _tenderedController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _customerStateController.dispose();
    super.dispose();
  }

  void _setQuickTender(double amount) {
    setState(() {
      _tenderedController.text = amount.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = ref.watch(cartGrandTotalProvider);
    final discount = ref.watch(discountAmountProvider);
    final cartItems = ref.watch(cartItemsProvider);

    final double tenderedAmount = double.tryParse(_tenderedController.text) ?? 0.0;
    final double changeReturned = (tenderedAmount - grandTotal).clamp(0.0, double.infinity);

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Checkout Payment', style: AppTypography.headingMedium),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text('Total Amount Payable', style: AppTypography.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    EscPosFormatter.formatCurrency(grandTotal),
                    style: AppTypography.headingXLarge.copyWith(color: AppColors.accentLime),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Method Selector
            Text('Payment Method', style: AppTypography.labelLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPaymentOption('CASH', Icons.payments_rounded),
                const SizedBox(width: 8),
                _buildPaymentOption('UPI', Icons.qr_code_scanner_rounded),
                const SizedBox(width: 8),
                _buildPaymentOption('CARD', Icons.credit_card_rounded),
              ],
            ),
            const SizedBox(height: 20),

            // Cash Tendered Options (If Cash selected)
            if (_selectedPaymentMethod == 'CASH') ...[
              Text('Amount Tendered', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _tenderedController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.headingSmall,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixText: 'Rs. ',
                  hintText: 'Enter cash received',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildQuickCashButton('Exact', grandTotal),
                  const SizedBox(width: 6),
                  _buildQuickCashButton('Rs.100', 100),
                  const SizedBox(width: 6),
                  _buildQuickCashButton('Rs.500', 500),
                  const SizedBox(width: 6),
                  _buildQuickCashButton('Rs.2000', 2000),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Change to Return:', style: AppTypography.bodyMedium),
                  Text(
                    EscPosFormatter.formatCurrency(changeReturned),
                    style: AppTypography.headingSmall.copyWith(
                      color: changeReturned > 0 ? AppColors.accentYellow : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Customer Details (Optional)
            ExpansionTile(
              title: Text('Customer Details (Optional)', style: AppTypography.bodyMedium),
              childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
              iconColor: AppColors.accentLime,
              collapsedIconColor: AppColors.textMuted,
              children: [
                TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer / Buyer Name',
                    hintText: 'e.g. MR.RAJA',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Customer Phone',
                    hintText: 'e.g. 9940745913',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customerAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Address / City',
                    hintText: 'e.g. CBE',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customerStateController,
                  decoration: const InputDecoration(
                    labelText: 'State Name & Code',
                    hintText: 'e.g. Tamil Nadu, Code : 33',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Confirm & Print Action Button
            ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      setState(() => _isProcessing = true);
                      try {
                        final billRepo = ref.read(billRepositoryProvider);
                        final printerRepo = ref.read(printerRepositoryProvider);
                        final settingsRepo = ref.read(settingsRepositoryProvider);

                        // 1. Execute DB Atomic Checkout
                        final bill = await billRepo.checkout(
                          cartItems: cartItems,
                          paymentMethod: _selectedPaymentMethod,
                          discount: discount,
                          amountTendered: _selectedPaymentMethod == 'CASH' ? tenderedAmount : grandTotal,
                          customerName: _customerNameController.text.trim().isEmpty ? null : _customerNameController.text.trim(),
                          customerPhone: _customerPhoneController.text.trim().isEmpty ? null : _customerPhoneController.text.trim(),
                          customerAddress: _customerAddressController.text.trim().isEmpty ? null : _customerAddressController.text.trim(),
                          customerState: _customerStateController.text.trim().isEmpty ? null : _customerStateController.text.trim(),
                        );

                        // 2. Build Receipt & Dispatch to Thermal Printer Queue in background
                        final storeSettings = await settingsRepo.getStoreSettings();
                        final template = ReceiptTemplate(
                          storeName: storeSettings.storeName,
                          storeTagline: storeSettings.storeTagline,
                          storeAddress: storeSettings.storeAddress,
                          storeState: storeSettings.storeState,
                          storePhone: storeSettings.storePhone,
                          storeEmail: storeSettings.storeEmail,
                          storePan: storeSettings.storePan,
                          fssaiLicense: storeSettings.fssaiLicense,
                          gstin: storeSettings.gstin,
                          bankAccountName: storeSettings.bankAccountName,
                          bankName: storeSettings.bankName,
                          bankAccountNo: storeSettings.bankAccountNo,
                          bankIfsc: storeSettings.bankIfsc,
                          storeDeclaration: storeSettings.storeDeclaration,
                          receiptFooter: storeSettings.receiptFooter,
                          showBankDetails: storeSettings.showBankDetails,
                          showPan: storeSettings.showPan,
                        );

                        final escPosBytes = template.buildEscPosBytes(bill);
                        // Non-blocking print dispatch so UI never buffers
                        printerRepo.printReceiptBytes(escPosBytes);

                        // 3. Clear Cart State
                        ref.read(cartItemsProvider.notifier).clearCart();
                        ref.read(discountAmountProvider.notifier).state = 0.0;

                        if (context.mounted) {
                          Navigator.of(context).pop(); // Close checkout dialog
                          showDialog(
                            context: context,
                            builder: (_) => ReceiptPreviewDialog(bill: bill),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.danger,
                              content: Text('Checkout failed: $e'),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isProcessing = false);
                      }
                    },
              child: _isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                    )
                  : Text('Confirm & Print Receipt (${EscPosFormatter.formatCurrency(grandTotal)})'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon) {
    final bool isSelected = _selectedPaymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = method),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentLime : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accentLime : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.black : AppColors.textPrimary),
              const SizedBox(height: 4),
              Text(
                method,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashButton(String label, double amount) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          minimumSize: Size.zero,
        ),
        onPressed: () => _setQuickTender(amount),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
