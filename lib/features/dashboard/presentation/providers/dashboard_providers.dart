import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/core_providers.dart';

class DashboardMetrics {
  final double totalSalesToday;
  final int totalOrdersToday;
  final int lowStockItemCount;
  final Map<String, double> paymentMethodTotals;
  final String topSoldProduct;
  final int topSoldQuantity;
  final List<Bill> recentBills;

  DashboardMetrics({
    required this.totalSalesToday,
    required this.totalOrdersToday,
    required this.lowStockItemCount,
    required this.paymentMethodTotals,
    required this.topSoldProduct,
    required this.topSoldQuantity,
    required this.recentBills,
  });
}

final dashboardMetricsProvider = StreamProvider<DashboardMetrics>((ref) async* {
  final db = ref.watch(appDatabaseProvider);

  // Watch bills and products streams
  await for (final _ in db.watchRecentBills()) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final allBillsWithItems = await db.getAllBillsWithItems();
    final allProducts = await db.getAllProducts();

    // Filter today's bills
    final todayBillsWithItems = allBillsWithItems.where((b) => b.bill.createdAt.isAfter(todayStart)).toList();

    double totalSales = 0.0;
    final paymentMap = <String, double>{'CASH': 0.0, 'UPI': 0.0, 'CARD': 0.0};
    final productQtyMap = <String, int>{};

    for (final b in todayBillsWithItems) {
      totalSales += b.bill.grandTotal;
      paymentMap[b.bill.paymentMethod] = (paymentMap[b.bill.paymentMethod] ?? 0) + b.bill.grandTotal;

      for (final item in b.items) {
        productQtyMap[item.productName] = (productQtyMap[item.productName] ?? 0) + item.equivalentPieces;
      }
    }

    // Determine top sold product
    String topProduct = 'Dark Chocolate Gummies';
    int topQty = 0;
    if (productQtyMap.isNotEmpty) {
      final sortedEntries = productQtyMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topProduct = sortedEntries.first.key;
      topQty = sortedEntries.first.value;
    }

    // Low stock count (Products where stockInPieces <= minStockAlert)
    final lowStockCount = allProducts.where((p) => p.stockInPieces <= p.minStockAlert).length;

    final recentBills = allBillsWithItems.take(5).map((b) => b.bill).toList();

    yield DashboardMetrics(
      totalSalesToday: totalSales,
      totalOrdersToday: todayBillsWithItems.length,
      lowStockItemCount: lowStockCount,
      paymentMethodTotals: paymentMap,
      topSoldProduct: topProduct,
      topSoldQuantity: topQty,
      recentBills: recentBills,
    );
  }
});
