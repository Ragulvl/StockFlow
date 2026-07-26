import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import 'dashboard_providers.dart';

enum StockFilterType { all, lowStock, inStock }

final selectedStockFilterProvider = StateProvider<StockFilterType>((ref) => StockFilterType.all);

final filteredInventoryProductsProvider = Provider<List<ProductModel>>((ref) {
  final products = ref.watch(productsStreamProvider).value ?? [];
  final filter = ref.watch(selectedStockFilterProvider);
  final searchQuery = ref.watch(inventorySearchQueryProvider).toLowerCase().trim();

  var list = products;

  // Search filter
  if (searchQuery.isNotEmpty) {
    list = list.where((p) => p.name.toLowerCase().contains(searchQuery) || (p.description?.toLowerCase().contains(searchQuery) ?? false)).toList();
  }

  // Stock status filter
  switch (filter) {
    case StockFilterType.lowStock:
      return list.where((p) => p.isLowStock).toList();
    case StockFilterType.inStock:
      return list.where((p) => !p.isLowStock).toList();
    case StockFilterType.all:
      return list;
  }
});

final inventorySearchQueryProvider = StateProvider<String>((ref) => '');
