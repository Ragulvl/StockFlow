import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/printer/esc_pos_formatter.dart';
import '../../../../providers/dashboard_providers.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSales = ref.watch(todaySalesProvider);
    final orderCount = ref.watch(todayOrderCountProvider);
    final lowStockCount = ref.watch(stockAlertCountProvider);
    final paymentMap = ref.watch(paymentBreakdownProvider);
    final topProduct = ref.watch(topProductSoldProvider);
    final recentBillsAsync = ref.watch(recentBillsStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.cookie_rounded, color: AppColors.accentLime, size: 24),
                      ),


                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome Back', style: AppTypography.bodySmall),
                          Text('ChocoGummy Delights', style: AppTypography.headingMedium),
                        ],
                      ),
                    ],
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          tooltip: 'Notifications & Alerts',
                          icon: Icon(
                            lowStockCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                            color: lowStockCount > 0 ? AppColors.accentYellow : AppColors.textPrimary,
                          ),
                          onPressed: () => _showNotificationsModal(context, ref, lowStockCount, totalSales, orderCount),
                        ),
                      ),
                      if (lowStockCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.accentYellow,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                '$lowStockCount',
                                style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                ],
              ),
              const SizedBox(height: 24),


              // 2. Section: Performance Today
              Text('Performance Today', style: AppTypography.headingSmall),
              const SizedBox(height: 12),

              // KPI Row
              Row(
                children: [
                  // Total Sales Card (Neon Lime)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentLime,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Sales',
                                style: AppTypography.labelMedium.copyWith(color: Colors.black87),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black12,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.show_chart_rounded, color: Colors.black, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            EscPosFormatter.formatCurrency(totalSales),
                            style: AppTypography.headingLarge.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$orderCount Orders Today',
                            style: AppTypography.bodySmall.copyWith(color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Low Stock Alert / Status Card (Neon Yellow)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Stock Alerts',
                                style: AppTypography.labelMedium.copyWith(color: Colors.black87),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black12,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.warning_amber_rounded, color: Colors.black, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$lowStockCount Items',
                            style: AppTypography.headingLarge.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lowStockCount > 0 ? 'Need Reorder' : 'Stock Optimal',
                            style: AppTypography.bodySmall.copyWith(color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Quick Actions Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/billing'),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('New Sale'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/inventory'),
                      icon: const Icon(Icons.add_box_rounded),
                      label: const Text('Inventory'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Payment Methods Breakdown
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Methods Used', style: AppTypography.headingSmall),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildPaymentBadge('CASH', paymentMap['CASH'] ?? 0, totalSales, AppColors.accentLime),
                        const SizedBox(width: 8),
                        _buildPaymentBadge('UPI', paymentMap['UPI'] ?? 0, totalSales, AppColors.accentYellow),
                        const SizedBox(width: 8),
                        _buildPaymentBadge('CARD', paymentMap['CARD'] ?? 0, totalSales, AppColors.accentBlue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Top Product Sold Widget
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentLime.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: AppColors.accentLime, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Top Product Sold', style: AppTypography.bodySmall),
                          const SizedBox(height: 2),
                          Text(topProduct.key, style: AppTypography.labelLarge),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '${topProduct.value} Pcs Sold',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.accentLime, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Recent Bills List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Bills', style: AppTypography.headingSmall),
                  TextButton(
                    onPressed: () => context.go('/bills-history'),
                    child: Text(
                      'View All',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.accentLime),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              recentBillsAsync.when(
                data: (recentBills) {
                  if (recentBills.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'No sales recorded today yet.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentBills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final bill = recentBills[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
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
                                      '${bill.paymentMethod} • ${bill.createdAt.toString().substring(11, 16)}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              EscPosFormatter.formatCurrency(bill.grandTotal),
                              style: AppTypography.headingSmall.copyWith(color: AppColors.accentLime),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: AppColors.accentLime),
                  ),
                ),
                error: (err, _) => Text('Error loading bills: $err', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(String title, double amount, double totalSales, Color accentColor) {
    final double percentage = totalSales > 0 ? (amount / totalSales * 100) : 0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: AppTypography.headingSmall.copyWith(color: accentColor),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppColors.border,
                color: accentColor,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsModal(BuildContext context, WidgetRef ref, int lowStockCount, double totalSales, int orderCount) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surfaceCard,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AppColors.accentLime, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notifications & Alerts',
                              style: AppTypography.headingSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: lowStockCount > 0 ? AppColors.accentYellow.withValues(alpha: 0.2) : AppColors.accentLime.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lowStockCount > 0 ? '$lowStockCount Warnings' : 'All Clear',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: lowStockCount > 0 ? AppColors.accentYellow : AppColors.accentLime,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),

                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Low Stock Alert Item (if any)
                      if (lowStockCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accentYellow.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accentYellow.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.warning_amber_rounded, color: AppColors.accentYellow, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$lowStockCount products low in stock', style: AppTypography.labelLarge),
                                    const Text('Requires stock reorder', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentYellow,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  context.go('/inventory');
                                },
                                child: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // 2. Sales Summary Performance Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentLime.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.trending_up_rounded, color: AppColors.accentLime, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Today: ${EscPosFormatter.formatCurrency(totalSales)}', style: AppTypography.labelLarge),
                                  Text('$orderCount orders completed today', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                context.go('/analytics');
                              },
                              child: const Text('Analytics', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



}



