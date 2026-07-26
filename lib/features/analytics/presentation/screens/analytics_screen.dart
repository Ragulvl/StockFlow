import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/printer/esc_pos_formatter.dart';
import '../../../../core/printer/receipt_template.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/analytics_providers.dart';
import '../../../../providers/repository_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRange = ref.watch(analyticsDateRangeProvider);
    final analyticsAsync = ref.watch(analyticsSummaryProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Row with Export Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Analytics & Business Insights', style: AppTypography.headingMedium),
                        Text('Financial metrics, revenue trends & stock valuation', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  analyticsAsync.when(
                    data: (data) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        tooltip: 'Export Analytics Report',
                        icon: const Icon(Icons.share_rounded, color: AppColors.accentLime),
                        onPressed: () => _showExportOptionsModal(context, ref, data, activeRange),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Date Range Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AnalyticsDateRange.values.map((range) {
                    final bool isSelected = range == activeRange;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(range.label),
                        selected: isSelected,
                        selectedColor: AppColors.accentLime,
                        backgroundColor: AppColors.surfaceCard,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(color: isSelected ? AppColors.accentLime : AppColors.border),
                        onSelected: (_) {
                          ref.read(analyticsDateRangeProvider.notifier).state = range;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Analytics Content Body
              analyticsAsync.when(
                data: (data) => _buildAnalyticsBody(context, data, activeRange),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60.0),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accentLime),
                  ),
                ),
                error: (err, stack) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: Text('Error loading analytics data: $err', style: const TextStyle(color: AppColors.danger)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsBody(BuildContext context, AnalyticsSummaryData data, AnalyticsDateRange activeRange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Summary Cards Grid
        _buildKpiGrid(data),
        const SizedBox(height: 24),

        // Revenue Trend Chart Section
        _buildRevenueChartCard(data, activeRange),
        const SizedBox(height: 24),

        // Payment Method Share & Inventory Health Row
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPaymentShareCard(data)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInventoryValuationCard(data)),
                ],
              );
            }
            return Column(
              children: [
                _buildPaymentShareCard(data),
                const SizedBox(height: 24),
                _buildInventoryValuationCard(data),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Top Selling Products Leaderboard
        _buildTopProductsCard(data),
      ],
    );
  }

  Widget _buildKpiGrid(AnalyticsSummaryData data) {
    return Column(
      children: [
        Row(
          children: [
            // Revenue KPI
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
                        Text('Total Revenue', style: AppTypography.labelMedium.copyWith(color: Colors.black87)),
                        const Icon(Icons.payments_rounded, color: Colors.black, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      EscPosFormatter.formatCurrency(data.totalRevenue),
                      style: AppTypography.headingLarge.copyWith(color: Colors.black, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text('${data.totalOrders} Completed Orders', style: AppTypography.bodySmall.copyWith(color: Colors.black54, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Average Order Value KPI
            Expanded(
              child: Container(
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
                        Text('Average Order', style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted)),
                        const Icon(Icons.trending_up_rounded, color: AppColors.accentLime, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      EscPosFormatter.formatCurrency(data.averageOrderValue),
                      style: AppTypography.headingMedium.copyWith(color: AppColors.accentLime, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Per Checkout Session', style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Units Sold KPI
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
                        Text('Gummies Sold', style: AppTypography.labelMedium.copyWith(color: Colors.black87)),
                        const Icon(Icons.cookie_rounded, color: Colors.black, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${data.totalPiecesSold} Pcs',
                      style: AppTypography.headingLarge.copyWith(color: Colors.black, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text('Single & Pack total', style: AppTypography.bodySmall.copyWith(color: Colors.black54, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Discounts Granted KPI
            Expanded(
              child: Container(
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
                        Text('Discounts Given', style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted)),
                        const Icon(Icons.sell_outlined, color: AppColors.accentYellow, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      EscPosFormatter.formatCurrency(data.totalDiscounts),
                      style: AppTypography.headingMedium.copyWith(color: AppColors.accentYellow, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Total bill reductions', style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueChartCard(AnalyticsSummaryData data, AnalyticsDateRange range) {
    final points = data.dailySalesData;
    final maxRevenue = points.map((p) => p.revenue).fold(0.0, (prev, curr) => curr > prev ? curr : prev);
    final double maxY = maxRevenue > 0 ? maxRevenue * 1.25 : 1000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue Breakdown', style: AppTypography.headingSmall),
                  Text(
                    range == AnalyticsDateRange.today ? 'Hourly sales trend today' : 'Daily sales performance (${range.label})',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accentLime, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Sales (Rs.)', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final p = points[group.x.toInt()];
                      return BarTooltipItem(
                        '${p.label}\n${EscPosFormatter.formatCurrency(p.revenue)}\n${p.ordersCount} orders',
                        const TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        if (value >= 1000) {
                          return Text('${(value / 1000).toStringAsFixed(1)}k', style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
                        }
                        return Text(value.toInt().toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                        final rawLabel = points[idx].label;
                        final displayLabel = rawLabel.contains(',') ? rawLabel.split(',')[0] : rawLabel;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            displayLabel,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => const FlLine(color: AppColors.border, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                barGroups: points.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pt = entry.value;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: pt.revenue,
                        color: AppColors.accentLime,
                        width: points.length > 15 ? 8 : 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentShareCard(AnalyticsSummaryData data) {
    final double total = data.totalRevenue;
    final double cashPct = total > 0 ? (data.cashRevenue / total * 100) : 0;
    final double upiPct = total > 0 ? (data.upiRevenue / total * 100) : 0;
    final double cardPct = total > 0 ? (data.cardRevenue / total * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Channels', style: AppTypography.headingSmall),
          Text('Revenue distribution by payment mode', style: AppTypography.bodySmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 36,
                      sections: [
                        PieChartSectionData(
                          color: AppColors.accentLime,
                          value: data.cashRevenue > 0 ? data.cashRevenue : 0.001,
                          title: '${cashPct.toStringAsFixed(0)}%',
                          radius: 36,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        PieChartSectionData(
                          color: AppColors.accentYellow,
                          value: data.upiRevenue > 0 ? data.upiRevenue : 0.001,
                          title: '${upiPct.toStringAsFixed(0)}%',
                          radius: 36,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        PieChartSectionData(
                          color: AppColors.accentBlue,
                          value: data.cardRevenue > 0 ? data.cardRevenue : 0.001,
                          title: '${cardPct.toStringAsFixed(0)}%',
                          radius: 36,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPaymentLegendRow('CASH', data.cashRevenue, data.cashOrdersCount, AppColors.accentLime),
                      const SizedBox(height: 10),
                      _buildPaymentLegendRow('UPI', data.upiRevenue, data.upiOrdersCount, AppColors.accentYellow),
                      const SizedBox(height: 10),
                      _buildPaymentLegendRow('CARD', data.cardRevenue, data.cardOrdersCount, AppColors.accentBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentLegendRow(String name, double rev, int count, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.labelMedium),
              Text('$count orders', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
            ],
          ),
        ),
        Text(EscPosFormatter.formatCurrency(rev), style: AppTypography.labelMedium.copyWith(color: color)),
      ],
    );
  }

  Widget _buildInventoryValuationCard(AnalyticsSummaryData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inventory Valuation', style: AppTypography.headingSmall),
                  Text('Total stock worth on hand', style: AppTypography.bodySmall),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: AppColors.accentYellow, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            EscPosFormatter.formatCurrency(data.inventoryValuation),
            style: AppTypography.headingLarge.copyWith(color: AppColors.accentYellow, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.category_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text('Total Products: ${data.totalProductsCount}', style: AppTypography.bodySmall),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      data.lowStockProductsCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                      size: 16,
                      color: data.lowStockProductsCount > 0 ? AppColors.accentYellow : AppColors.accentLime,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${data.lowStockProductsCount} Low Stock',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: data.lowStockProductsCount > 0 ? AppColors.accentYellow : AppColors.accentLime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsCard(AnalyticsSummaryData data) {
    final topList = data.topProducts;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Selling Products Leaderboard', style: AppTypography.headingSmall),
          Text('Ranked by total sales revenue generated', style: AppTypography.bodySmall),
          const SizedBox(height: 16),
          if (topList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text('No product sales recorded in this period.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topList.length > 5 ? 5 : topList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = topList[index];
                final maxRev = topList.first.totalRevenue;
                final double progress = maxRev > 0 ? (item.totalRevenue / maxRev) : 0.0;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: index == 0 ? AppColors.accentLime : (index == 1 ? AppColors.accentYellow : AppColors.surfaceCard),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: index < 2 ? Colors.black : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('${item.totalPiecesSold} Pcs sold', style: AppTypography.bodySmall),
                              ],
                            ),
                          ),
                          Text(
                            EscPosFormatter.formatCurrency(item.totalRevenue),
                            style: AppTypography.labelLarge.copyWith(color: AppColors.accentLime, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.border,
                          color: index == 0 ? AppColors.accentLime : (index == 1 ? AppColors.accentYellow : AppColors.accentBlue),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showExportOptionsModal(BuildContext context, WidgetRef ref, AnalyticsSummaryData data, AnalyticsDateRange range) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Export Analytics Report', style: AppTypography.headingSmall),
              const SizedBox(height: 4),
              Text('Timeframe: ${range.label}', style: AppTypography.bodySmall),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Copy Text Summary Button
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.copy_rounded, color: AppColors.accentLime),
                title: const Text('Copy Text Summary to Clipboard', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('Includes revenue, order count, AOV & top products', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  final summaryText = '''
*** STOCKFLOW BUSINESS REPORT ***
Range: ${range.label}
Total Revenue: ${EscPosFormatter.formatCurrency(data.totalRevenue)}
Total Orders: ${data.totalOrders}
Average Order Value: ${EscPosFormatter.formatCurrency(data.averageOrderValue)}
Total Gummies Sold: ${data.totalPiecesSold} Pcs
Discounts Given: ${EscPosFormatter.formatCurrency(data.totalDiscounts)}
Payment Breakdown:
  - CASH: ${EscPosFormatter.formatCurrency(data.cashRevenue)} (${data.cashOrdersCount} orders)
  - UPI: ${EscPosFormatter.formatCurrency(data.upiRevenue)} (${data.upiOrdersCount} orders)
  - CARD: ${EscPosFormatter.formatCurrency(data.cardRevenue)} (${data.cardOrdersCount} orders)
Inventory Stock Valuation: ${EscPosFormatter.formatCurrency(data.inventoryValuation)}
Top Product: ${data.topProducts.isNotEmpty ? data.topProducts.first.productName : 'N/A'}
Generated on: ${DateTime.now().toString().substring(0, 16)}
''';
                  Clipboard.setData(ClipboardData(text: summaryText));
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.accentLime,
                      content: Text('Analytics summary report copied to Clipboard!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
              const Divider(),

              // Print Report on Thermal Printer Button
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.print_rounded, color: AppColors.accentYellow),
                title: const Text('Print Summary on Thermal Printer', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('Send summary report to USB ESC/POS thermal printer', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  final settingsRepo = ref.read(settingsRepositoryProvider);
                  final printerRepo = ref.read(printerRepositoryProvider);
                  final store = await settingsRepo.getStoreSettings();

                  final template = ReceiptTemplate(
                    storeName: store.storeName,
                    storeTagline: 'Analytics Report (${range.label})',
                    storeAddress: store.storeAddress,
                    storePhone: store.storePhone,
                    receiptFooter: 'Generated via StockFlow POS',
                  );

                  final printText = '''
Range: ${range.label}
Date: ${DateTime.now().toString().substring(0, 16)}
------------------------------
TOTAL REVENUE  : ${EscPosFormatter.formatCurrency(data.totalRevenue)}
TOTAL ORDERS   : ${data.totalOrders}
AVG ORDER VAL  : ${EscPosFormatter.formatCurrency(data.averageOrderValue)}
TOTAL GUMMIES  : ${data.totalPiecesSold} Pcs
TOTAL DISCOUNT : ${EscPosFormatter.formatCurrency(data.totalDiscounts)}
------------------------------
PAYMENT BREAKDOWN
CASH: ${EscPosFormatter.formatCurrency(data.cashRevenue)} (${data.cashOrdersCount})
UPI : ${EscPosFormatter.formatCurrency(data.upiRevenue)} (${data.upiOrdersCount})
CARD: ${EscPosFormatter.formatCurrency(data.cardRevenue)} (${data.cardOrdersCount})

------------------------------
INVENTORY VALUATION
Worth: ${EscPosFormatter.formatCurrency(data.inventoryValuation)}
Items: ${data.totalProductsCount} (${data.lowStockProductsCount} Low)
''';

                  final bytes = template.buildEscPosBytesFromRaw(printText);
                  final success = await printerRepo.printReceiptBytes(bytes);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: success ? AppColors.accentLime : AppColors.danger,
                        content: Text(
                          success ? 'Analytics report sent to thermal printer!' : 'Printer error: Check USB connection',
                          style: TextStyle(color: success ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                        ),
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
