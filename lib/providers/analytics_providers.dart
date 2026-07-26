import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'repository_providers.dart';


enum AnalyticsDateRange { today, last7Days, last30Days, allTime }

extension AnalyticsDateRangeX on AnalyticsDateRange {
  String get label {
    switch (this) {
      case AnalyticsDateRange.today:
        return 'Today';
      case AnalyticsDateRange.last7Days:
        return '7 Days';
      case AnalyticsDateRange.last30Days:
        return '30 Days';
      case AnalyticsDateRange.allTime:
        return 'All Time';
    }
  }
}

class ProductAnalyticsItem {
  final String productName;
  final int totalPiecesSold;
  final double totalRevenue;

  ProductAnalyticsItem({
    required this.productName,
    required this.totalPiecesSold,
    required this.totalRevenue,
  });
}

class DailySalesPoint {
  final String label;
  final DateTime date;
  final double revenue;
  final int ordersCount;

  DailySalesPoint({
    required this.label,
    required this.date,
    required this.revenue,
    required this.ordersCount,
  });
}

class AnalyticsSummaryData {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final int totalPiecesSold;
  final double totalDiscounts;
  final double cashRevenue;
  final double upiRevenue;
  final double cardRevenue;
  final int cashOrdersCount;
  final int upiOrdersCount;
  final int cardOrdersCount;
  final List<ProductAnalyticsItem> topProducts;
  final List<DailySalesPoint> dailySalesData;
  final double inventoryValuation;
  final int totalProductsCount;
  final int lowStockProductsCount;

  AnalyticsSummaryData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.totalPiecesSold,
    required this.totalDiscounts,
    required this.cashRevenue,
    required this.upiRevenue,
    required this.cardRevenue,
    required this.cashOrdersCount,
    required this.upiOrdersCount,
    required this.cardOrdersCount,
    required this.topProducts,
    required this.dailySalesData,
    required this.inventoryValuation,
    required this.totalProductsCount,
    required this.lowStockProductsCount,
  });
}

final analyticsDateRangeProvider = StateProvider<AnalyticsDateRange>((ref) => AnalyticsDateRange.last7Days);

final analyticsSummaryProvider = StreamProvider<AnalyticsSummaryData>((ref) async* {
  final billRepo = ref.watch(billRepositoryProvider);
  final inventoryRepo = ref.watch(inventoryRepositoryProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);

  await for (final allBills in billRepo.watchBills()) {
    final allProducts = await inventoryRepo.getAllProducts();

    final now = DateTime.now();
    DateTime cutoffDate;

    switch (dateRange) {
      case AnalyticsDateRange.today:
        cutoffDate = DateTime(now.year, now.month, now.day);
        break;
      case AnalyticsDateRange.last7Days:
        cutoffDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        break;
      case AnalyticsDateRange.last30Days:
        cutoffDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
        break;
      case AnalyticsDateRange.allTime:
        cutoffDate = DateTime(2020, 1, 1);
        break;
    }

    final filteredBills = allBills.where((b) => b.createdAt.isAfter(cutoffDate) || b.createdAt.isAtSameMomentAs(cutoffDate)).toList();

    double totalRevenue = 0.0;
    double totalDiscounts = 0.0;
    int totalPiecesSold = 0;
    double cashRevenue = 0.0;
    double upiRevenue = 0.0;
    double cardRevenue = 0.0;
    int cashOrdersCount = 0;
    int upiOrdersCount = 0;
    int cardOrdersCount = 0;

    final productStats = <String, ProductAnalyticsItem>{};

    for (final bill in filteredBills) {
      totalRevenue += bill.grandTotal;
      totalDiscounts += bill.discount;

      switch (bill.paymentMethod.toUpperCase()) {
        case 'CASH':
          cashRevenue += bill.grandTotal;
          cashOrdersCount++;
          break;
        case 'UPI':
          upiRevenue += bill.grandTotal;
          upiOrdersCount++;
          break;
        case 'CARD':
          cardRevenue += bill.grandTotal;
          cardOrdersCount++;
          break;
      }

      for (final item in bill.items) {
        totalPiecesSold += item.equivalentPieces;

        final existing = productStats[item.productName];
        if (existing != null) {
          productStats[item.productName] = ProductAnalyticsItem(
            productName: item.productName,
            totalPiecesSold: existing.totalPiecesSold + item.equivalentPieces,
            totalRevenue: existing.totalRevenue + item.totalPrice,
          );
        } else {
          productStats[item.productName] = ProductAnalyticsItem(
            productName: item.productName,
            totalPiecesSold: item.equivalentPieces,
            totalRevenue: item.totalPrice,
          );
        }
      }
    }

    final sortedProducts = productStats.values.toList()..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    // Calculate Daily Sales Points for Chart
    final List<DailySalesPoint> dailySalesData = [];
    if (dateRange == AnalyticsDateRange.today) {
      // Hourly breakdown for Today
      for (int hour = 8; hour <= 22; hour += 2) {
        final startHour = DateTime(now.year, now.month, now.day, hour);
        final endHour = DateTime(now.year, now.month, now.day, hour + 2);
        final hourBills = filteredBills.where((b) => b.createdAt.isAfter(startHour.subtract(const Duration(seconds: 1))) && b.createdAt.isBefore(endHour)).toList();
        final rev = hourBills.fold(0.0, (sum, b) => sum + b.grandTotal);
        dailySalesData.add(DailySalesPoint(
          label: '${hour.toString().padLeft(2, '0')}:00',
          date: startHour,
          revenue: rev,
          ordersCount: hourBills.length,
        ));
      }
    } else {
      // Daily breakdown
      final int daysCount = dateRange == AnalyticsDateRange.last7Days
          ? 7
          : (dateRange == AnalyticsDateRange.last30Days ? 30 : 14);

      for (int i = daysCount - 1; i >= 0; i--) {
        final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final nextD = d.add(const Duration(days: 1));
        final dayBills = filteredBills.where((b) => b.createdAt.isAfter(d.subtract(const Duration(seconds: 1))) && b.createdAt.isBefore(nextD)).toList();
        final rev = dayBills.fold(0.0, (sum, b) => sum + b.grandTotal);
        final label = DateFormat('E, MMM d').format(d);
        dailySalesData.add(DailySalesPoint(
          label: label,
          date: d,
          revenue: rev,
          ordersCount: dayBills.length,
        ));
      }
    }

    // Inventory Valuation
    double inventoryVal = 0.0;
    int lowStockCount = 0;
    for (final p in allProducts) {
      inventoryVal += (p.stockInPieces * p.piecePrice);
      if (p.isLowStock) lowStockCount++;
    }

    final totalOrders = filteredBills.length;
    final double avgOrderVal = totalOrders > 0 ? (totalRevenue / totalOrders) : 0.0;

    yield AnalyticsSummaryData(
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      averageOrderValue: avgOrderVal,
      totalPiecesSold: totalPiecesSold,
      totalDiscounts: totalDiscounts,
      cashRevenue: cashRevenue,
      upiRevenue: upiRevenue,
      cardRevenue: cardRevenue,
      cashOrdersCount: cashOrdersCount,
      upiOrdersCount: upiOrdersCount,
      cardOrdersCount: cardOrdersCount,
      topProducts: sortedProducts,
      dailySalesData: dailySalesData,
      inventoryValuation: inventoryVal,
      totalProductsCount: allProducts.length,
      lowStockProductsCount: lowStockCount,
    );
  }
});
