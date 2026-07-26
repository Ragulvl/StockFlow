import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/printer/esc_pos_formatter.dart';
import '../../../../core/printer/receipt_template.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/bill_model.dart';
import '../../../../providers/repository_providers.dart';

final billsHistoryQueryProvider = StateProvider<String>((ref) => '');
final billsHistoryPaymentFilterProvider = StateProvider<String>((ref) => 'ALL');

class BillsHistoryScreen extends ConsumerStatefulWidget {
  const BillsHistoryScreen({super.key});

  @override
  ConsumerState<BillsHistoryScreen> createState() => _BillsHistoryScreenState();
}

class _BillsHistoryScreenState extends ConsumerState<BillsHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billRepo = ref.watch(billRepositoryProvider);
    final searchQuery = ref.watch(billsHistoryQueryProvider).toLowerCase().trim();
    final paymentFilter = ref.watch(billsHistoryPaymentFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bills & Invoices History', style: AppTypography.headingMedium),
                      Text('Reprint thermal receipts and inspect sales history', style: AppTypography.bodySmall),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      tooltip: 'Export & Print Daily Sales Summary',
                      icon: const Icon(Icons.receipt_long_rounded, color: AppColors.accentLime),
                      onPressed: () => _showExportSummaryModal(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),


              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(billsHistoryQueryProvider.notifier).state = val;
                },
                decoration: InputDecoration(
                  hintText: 'Search by bill number or customer name...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(billsHistoryQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPaymentChip('ALL', paymentFilter),
                    const SizedBox(width: 8),
                    _buildPaymentChip('CASH', paymentFilter),
                    const SizedBox(width: 8),
                    _buildPaymentChip('UPI', paymentFilter),
                    const SizedBox(width: 8),
                    _buildPaymentChip('CARD', paymentFilter),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stream List of Invoices
              Expanded(
                child: StreamBuilder<List<BillModel>>(
                  stream: billRepo.watchBills(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.accentLime));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No bills recorded yet.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      );
                    }

                    var bills = snapshot.data!;

                    // Search filter
                    if (searchQuery.isNotEmpty) {
                      bills = bills
                          .where((b) =>
                              b.billNumber.toLowerCase().contains(searchQuery) ||
                              (b.customerName?.toLowerCase().contains(searchQuery) ?? false) ||
                              (b.customerPhone?.toLowerCase().contains(searchQuery) ?? false))
                          .toList();
                    }

                    // Payment Filter
                    if (paymentFilter != 'ALL') {
                      bills = bills.where((b) => b.paymentMethod == paymentFilter).toList();
                    }

                    if (bills.isEmpty) {
                      return Center(
                        child: Text(
                          'No matching bills found.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: bills.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        return _buildBillCard(bill);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String method, String activeMethod) {
    final bool isSelected = method == activeMethod;
    return ChoiceChip(
      label: Text(method),
      selected: isSelected,
      selectedColor: AppColors.accentLime,
      backgroundColor: AppColors.surfaceCard,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? AppColors.accentLime : AppColors.border),
      onSelected: (_) {
        ref.read(billsHistoryPaymentFilterProvider.notifier).state = method;
      },
    );
  }

  Widget _buildBillCard(BillModel bill) {
    final String itemsSummary = bill.items.map((i) => '${i.productName} (${i.quantity}${i.unitType == 'PACK' ? 'Pk' : 'Pc'})').join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_outlined, color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.billNumber, style: AppTypography.labelLarge),
                      const SizedBox(height: 2),
                      Text(
                        bill.createdAt.toString().substring(0, 16),
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  bill.paymentMethod,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentLime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Items: $itemsSummary',
            style: AppTypography.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                EscPosFormatter.formatCurrency(bill.grandTotal),
                style: AppTypography.headingSmall.copyWith(color: AppColors.accentLime),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: () => _reprintBill(bill),
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('Reprint Receipt', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _reprintBill(BillModel bill) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final printerRepo = ref.read(printerRepositoryProvider);

    final storeSettings = await settingsRepo.getStoreSettings();
    final template = ReceiptTemplate(
      storeName: storeSettings.storeName,
      storeTagline: storeSettings.storeTagline,
      storeAddress: storeSettings.storeAddress,
      storePhone: storeSettings.storePhone,
      fssaiLicense: storeSettings.fssaiLicense,
      gstin: storeSettings.gstin,
      receiptFooter: storeSettings.receiptFooter,
    );

    final escPosBytes = template.buildEscPosBytes(bill);
    final success = await printerRepo.printReceiptBytes(escPosBytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? AppColors.accentLime : AppColors.danger,
          content: Text(
            success ? 'Reprint dispatched to thermal printer queue' : 'Printer error: Check USB connection',
            style: TextStyle(color: success ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _showExportSummaryModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text('Sales History Options', style: AppTypography.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.copy_rounded, color: AppColors.accentLime),
                title: const Text('Export Bills to Clipboard', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('Copy formatted invoice history records to clipboard', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  final billRepo = ref.read(billRepositoryProvider);
                  final allBills = await billRepo.getAllBills();
                  final textData = allBills.map((b) => '${b.billNumber} | ${b.createdAt.toString().substring(0, 16)} | ${b.paymentMethod} | ${EscPosFormatter.formatCurrency(b.grandTotal)}').join('\n');

                  await Clipboard.setData(ClipboardData(text: textData));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.accentLime,
                        content: Text('Bills history copied to Clipboard!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close', style: TextStyle(color: AppColors.accentLime)),
            ),
          ],
        );
      },
    );
  }
}


