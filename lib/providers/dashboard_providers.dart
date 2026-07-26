import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bill_model.dart';
import '../models/product_model.dart';
import 'repository_providers.dart';

/// Base Stream Provider for Today's Bills
final todayBillsStreamProvider = StreamProvider<List<BillModel>>((ref) {
  final billRepo = ref.watch(billRepositoryProvider);
  return billRepo.watchBills().map((bills) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return bills.where((b) => b.createdAt.isAfter(todayStart)).toList();
  });
});

/// Base Stream Provider for Product Stock Alerts
final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final inventoryRepo = ref.watch(inventoryRepositoryProvider);
  return inventoryRepo.watchProducts();
});

/// Granular Provider: Today's Total Sales Amount
final todaySalesProvider = Provider<double>((ref) {
  final todayBills = ref.watch(todayBillsStreamProvider).value ?? [];
  return todayBills.fold<double>(0.0, (sum, bill) => sum + bill.grandTotal);
});

/// Granular Provider: Today's Total Order Count
final todayOrderCountProvider = Provider<int>((ref) {
  final todayBills = ref.watch(todayBillsStreamProvider).value ?? [];
  return todayBills.length;
});

/// Granular Provider: Low Stock Count
final stockAlertCountProvider = Provider<int>((ref) {
  final products = ref.watch(productsStreamProvider).value ?? [];
  return products.where((p) => p.isLowStock).length;
});

/// Granular Provider: Payment Method Percentages Map
final paymentBreakdownProvider = Provider<Map<String, double>>((ref) {
  final todayBills = ref.watch(todayBillsStreamProvider).value ?? [];
  final map = <String, double>{'CASH': 0.0, 'UPI': 0.0, 'CARD': 0.0};
  for (final bill in todayBills) {
    map[bill.paymentMethod] = (map[bill.paymentMethod] ?? 0.0) + bill.grandTotal;
  }
  return map;
});

/// Granular Provider: Top Product Sold Today
final topProductSoldProvider = Provider<MapEntry<String, int>>((ref) {
  final todayBills = ref.watch(todayBillsStreamProvider).value ?? [];
  final qtyMap = <String, int>{};

  for (final bill in todayBills) {
    for (final item in bill.items) {
      qtyMap[item.productName] = (qtyMap[item.productName] ?? 0) + item.equivalentPieces;
    }
  }

  if (qtyMap.isEmpty) {
    return const MapEntry('Dark Chocolate Gummies', 0);
  }
  final sorted = qtyMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.first;
});

/// Granular Provider: Recent 5 Bills
final recentBillsStreamProvider = StreamProvider<List<BillModel>>((ref) {
  final billRepo = ref.watch(billRepositoryProvider);
  return billRepo.watchBills().map((bills) => bills.take(5).toList());
});
