import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../repositories/bill_repository.dart';

class CartStateNotifier extends StateNotifier<List<CartItemInput>> {
  CartStateNotifier() : super([]);

  /// Adds a product to cart with dynamic stock guard checking piece availability
  bool addProduct(ProductModel product, String unitType, {int quantity = 1}) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id && item.unitType == unitType,
    );

    // Calculate currently added pieces for this product across all unit types in cart
    final totalAddedPiecesInCart = state
        .where((item) => item.product.id == product.id)
        .fold<int>(0, (sum, item) => sum + item.equivalentPieces);

    final requestedPieces = unitType == 'PACK' ? (quantity * product.packSize) : quantity;

    if (totalAddedPiecesInCart + requestedPieces > product.stockInPieces) {
      return false; // Out of stock guard triggered!
    }

    if (existingIndex >= 0) {
      final existing = state[existingIndex];
      final updatedList = List<CartItemInput>.from(state);
      updatedList[existingIndex] = CartItemInput(
        product: product,
        unitType: unitType,
        quantity: existing.quantity + quantity,
        customUnitPrice: existing.customUnitPrice,
      );
      state = updatedList;
    } else {
      state = [
        ...state,
        CartItemInput(
          product: product,
          unitType: unitType,
          quantity: quantity,
        ),
      ];
    }
    return true;
  }

  /// Updates unit price override for custom pricing (e.g. friends/special deals)
  void updateCustomUnitPrice(int index, double? customPrice) {
    if (index < 0 || index >= state.length) return;
    final item = state[index];
    final updatedList = List<CartItemInput>.from(state);
    updatedList[index] = CartItemInput(
      product: item.product,
      unitType: item.unitType,
      quantity: item.quantity,
      customUnitPrice: (customPrice != null && customPrice >= 0) ? customPrice : null,
    );
    state = updatedList;
  }

  /// Updates quantity of an existing cart item
  bool updateQuantity(int index, int newQty) {
    if (newQty <= 0) {
      removeItem(index);
      return true;
    }

    final item = state[index];
    final otherItemsPieces = state
        .asMap()
        .entries
        .where((e) => e.key != index && e.value.product.id == item.product.id)
        .fold<int>(0, (sum, e) => sum + e.value.equivalentPieces);

    final requestedPieces = item.unitType == 'PACK' ? (newQty * item.product.packSize) : newQty;

    if (otherItemsPieces + requestedPieces > item.product.stockInPieces) {
      return false; // Stock guard block
    }

    final updatedList = List<CartItemInput>.from(state);
    updatedList[index] = CartItemInput(
      product: item.product,
      unitType: item.unitType,
      quantity: newQty,
      customUnitPrice: item.customUnitPrice,
    );
    state = updatedList;
    return true;
  }

  /// Toggles unit type between SINGLE and PACK
  bool toggleUnitType(int index) {
    final item = state[index];
    final newUnitType = item.unitType == 'SINGLE' ? 'PACK' : 'SINGLE';
    final otherItemsPieces = state
        .asMap()
        .entries
        .where((e) => e.key != index && e.value.product.id == item.product.id)
        .fold<int>(0, (sum, e) => sum + e.value.equivalentPieces);

    final requestedPieces = newUnitType == 'PACK' ? (item.quantity * item.product.packSize) : item.quantity;

    if (otherItemsPieces + requestedPieces > item.product.stockInPieces) {
      return false; // Stock guard block
    }

    final updatedList = List<CartItemInput>.from(state);
    updatedList[index] = CartItemInput(
      product: item.product,
      unitType: newUnitType,
      quantity: item.quantity,
      customUnitPrice: null, // Reset custom price when changing unit type
    );
    state = updatedList;
    return true;
  }

  void removeItem(int index) {
    final updatedList = List<CartItemInput>.from(state);
    updatedList.removeAt(index);
    state = updatedList;
  }

  void clearCart() {
    state = [];
  }
}

final cartItemsProvider = StateNotifierProvider<CartStateNotifier, List<CartItemInput>>((ref) {
  return CartStateNotifier();
});

final discountAmountProvider = StateProvider<double>((ref) => 0.0);

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartItemsProvider);
  return items.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
});

final cartGrandTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final discount = ref.watch(discountAmountProvider);
  return (subtotal - discount).clamp(0.0, double.infinity);
});

final searchQueryProvider = Provider.family<List<ProductModel>, List<ProductModel>>((ref, allProducts) {
  final query = ref.watch(searchQueryTextProvider).toLowerCase().trim();
  if (query.isEmpty) return allProducts;
  return allProducts.where((p) => p.name.toLowerCase().contains(query) || (p.description?.toLowerCase().contains(query) ?? false)).toList();
});

final searchQueryTextProvider = StateProvider<String>((ref) => '');
