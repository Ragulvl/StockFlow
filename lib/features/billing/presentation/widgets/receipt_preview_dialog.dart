import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/printer/receipt_template.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/bill_model.dart';
import '../../../../providers/repository_providers.dart';

class ReceiptPreviewDialog extends ConsumerWidget {
  final BillModel bill;

  const ReceiptPreviewDialog({
    super.key,
    required this.bill,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsRepo = ref.watch(settingsRepositoryProvider);

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: FutureBuilder(
        future: settingsRepo.getStoreSettings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: AppColors.accentLime)),
            );
          }

          final storeSettings = snapshot.data!;
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

          final previewText = template.buildTextPreview(bill);

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.accentLime, size: 28),
                        const SizedBox(width: 10),
                        Text('Payment Complete', style: AppTypography.headingSmall),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        previewText,
                        softWrap: false,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: AppColors.accentLime,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.done_all_rounded),
                        label: const Text('Done'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final printerRepo = ref.read(printerRepositoryProvider);
                          final escPosBytes = template.buildEscPosBytes(bill);
                          final success = await printerRepo.printReceiptBytes(escPosBytes);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: success ? AppColors.accentLime : AppColors.danger,
                                content: Text(
                                  success ? 'Receipt dispatched to printer queue' : 'Printer error: Check USB connection',
                                  style: TextStyle(color: success ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('Reprint Receipt'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
