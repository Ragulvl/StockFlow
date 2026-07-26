import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/printer/esc_pos_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/product_model.dart';
import '../../../../providers/billing_providers.dart';
import '../../../../providers/dashboard_providers.dart';
import '../widgets/payment_dialog.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _showStockGuardSnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.danger,
        content: Text(
          'Cannot add item: Inventory stock limit reached!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final cartItems = ref.watch(cartItemsProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final grandTotal = ref.watch(cartGrandTotalProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive split screen if width > 700px (Tablet/POS terminal ratio)
            final bool isWideScreen = constraints.maxWidth > 700;

            if (isWideScreen) {
              return Row(
                children: [
                  // Left: Product Selection Grid
                  Expanded(
                    flex: 6,
                    child: _buildProductSelectionSection(productsAsync),
                  ),
                  const VerticalDivider(width: 1),
                  // Right: Cart & Checkout Sidebar
                  Expanded(
                    flex: 4,
                    child: _buildCartSidebarSection(cartItems, subtotal, grandTotal),
                  ),
                ],
              );
            }

            // Small Screen (Mobile): Bottom Sheet for Cart or Tabbed View
            return Column(
              children: [
                Expanded(
                  child: _buildProductSelectionSection(productsAsync),
                ),
                _buildMobileCartSummaryFooter(cartItems, grandTotal),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Product Selection Grid & Search Bar
  Widget _buildProductSelectionSection(AsyncValue<List<ProductModel>> productsAsync) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('POS Terminal', style: AppTypography.headingMedium),
                  Text('Select products to add to cart', style: AppTypography.bodySmall),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  tooltip: 'POS Quick Actions',
                  icon: const Icon(Icons.point_of_sale_rounded, color: AppColors.accentLime),
                  onPressed: () => _showPosQuickActionsModal(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),


          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) {
              ref.read(searchQueryTextProvider.notifier).state = val;
            },
            decoration: InputDecoration(
              hintText: 'Search gummies by name...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryTextProvider.notifier).state = '';
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Products Grid
          Expanded(
            child: productsAsync.when(
              data: (allProducts) {
                final filtered = ref.watch(searchQueryProvider(allProducts));
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No products found.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _buildProductCard(product);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accentLime),
              ),
              error: (err, _) => Center(
                child: Text('Error loading products: $err', style: const TextStyle(color: AppColors.danger)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Product Card Widget
  Widget _buildProductCard(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.isLowStock ? AppColors.accentYellow.withValues(alpha: 0.5) : AppColors.border,
          width: product.isLowStock ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentLime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cookie_rounded, color: AppColors.accentLime, size: 20),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.isLowStock ? AppColors.accentYellow.withValues(alpha: 0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: product.isLowStock ? AppColors.accentYellow : AppColors.border),
                  ),
                  child: Text(
                    '${product.availablePacks} Pk + ${product.availableRemainderPieces} Pc',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: product.isLowStock ? AppColors.accentYellow : AppColors.accentLime,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            style: AppTypography.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '1 Pc: ${EscPosFormatter.formatCurrency(product.piecePrice)} | 1 Pk (${product.packSize} Pcs): ${EscPosFormatter.formatCurrency(product.packPrice)}',
            style: AppTypography.bodySmall,
            maxLines: 2,
          ),
          const Spacer(),

          // Add Buttons Row (Single vs Pack)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  onPressed: product.stockInPieces < 1
                      ? null
                      : () {
                          final success = ref.read(cartItemsProvider.notifier).addProduct(product, 'SINGLE');
                          if (!success) _showStockGuardSnackBar();
                        },
                  child: const Text('+1 Pc', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  onPressed: product.stockInPieces < product.packSize
                      ? null
                      : () {
                          final success = ref.read(cartItemsProvider.notifier).addProduct(product, 'PACK');
                          if (!success) _showStockGuardSnackBar();
                        },
                  child: const Text('+1 Pk', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Cart Sidebar Section (Tablet/Wide POS ratio)
  Widget _buildCartSidebarSection(List cartItems, double subtotal, double grandTotal) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Order', style: AppTypography.headingSmall),
              if (cartItems.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    ref.read(cartItemsProvider.notifier).clearCart();
                    ref.read(discountAmountProvider.notifier).state = 0.0;
                    _discountController.clear();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                  label: const Text('Clear', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Cart Items List
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Your cart is empty',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                        Text(
                          'Tap +1 Pc or +1 Pk on a gummy product',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItemTile(index, item);
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Cart Summary Calculations
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: AppTypography.bodyMedium),
                    Text(EscPosFormatter.formatCurrency(subtotal), style: AppTypography.labelLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Discount (Rs.)', style: AppTypography.bodyMedium),
                    SizedBox(
                      width: 90,
                      height: 36,
                      child: TextField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                        onChanged: (val) {
                          final disc = double.tryParse(val) ?? 0.0;
                          ref.read(discountAmountProvider.notifier).state = disc;
                        },
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          hintText: '0.00',
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Payable', style: AppTypography.headingSmall),
                    Text(
                      EscPosFormatter.formatCurrency(grandTotal),
                      style: AppTypography.headingMedium.copyWith(color: AppColors.accentLime),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Checkout Button
          ElevatedButton.icon(
            onPressed: cartItems.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (_) => const PaymentDialog(),
                    );
                  },
            icon: const Icon(Icons.payment_rounded),
            label: Text('Proceed to Pay (${EscPosFormatter.formatCurrency(grandTotal)})'),
          ),
        ],
      ),
    );
  }

  void _showCustomPriceDialog(int index, dynamic item) {
    final controller = TextEditingController(
      text: item.unitPrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.accentYellow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Set Custom Unit Price',
                  style: AppTypography.headingSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product: ${item.product.name} (${item.unitType})',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Original Unit Price: ${EscPosFormatter.formatCurrency(item.unitType == "PACK" ? item.product.packPrice : item.product.piecePrice)}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Custom Price per Unit (Rs.)',
                  prefixText: 'Rs. ',
                  hintText: 'Enter custom amount',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Reset to standard price
                ref.read(cartItemsProvider.notifier).updateCustomUnitPrice(index, null);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Reset Standard', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final customVal = double.tryParse(controller.text.trim());
                if (customVal != null && customVal >= 0) {
                  ref.read(cartItemsProvider.notifier).updateCustomUnitPrice(index, customVal);
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Set Custom Price'),
            ),
          ],
        );
      },
    );
  }

  /// Individual Cart Item Tile with Unit Switcher Pill & Custom Price Action
  Widget _buildCartItemTile(int index, item) {
    final bool hasCustomPrice = item.customUnitPrice != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasCustomPrice ? AppColors.accentYellow : AppColors.border,
          width: hasCustomPrice ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.product.name,
                  style: AppTypography.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                onPressed: () {
                  ref.read(cartItemsProvider.notifier).removeItem(index);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Interactive Unit Switcher Pill (SINGLE vs PACK)
                  InkWell(
                    onTap: () {
                      final success = ref.read(cartItemsProvider.notifier).toggleUnitType(index);
                      if (!success) _showStockGuardSnackBar();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.unitType == 'PACK' ? AppColors.accentYellow.withValues(alpha: 0.2) : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: item.unitType == 'PACK' ? AppColors.accentYellow : AppColors.accentLime,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.unitType == 'PACK' ? Icons.inventory_2_rounded : Icons.pie_chart_outline_rounded,
                            size: 13,
                            color: item.unitType == 'PACK' ? AppColors.accentYellow : AppColors.accentLime,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.unitType == 'PACK' ? 'PACK' : 'SINGLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.unitType == 'PACK' ? AppColors.accentYellow : AppColors.accentLime,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.swap_horiz_rounded, size: 12, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Custom Price Action Button / Badge
                  InkWell(
                    onTap: () => _showCustomPriceDialog(index, item),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasCustomPrice ? AppColors.accentYellow.withValues(alpha: 0.2) : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasCustomPrice ? AppColors.accentYellow : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasCustomPrice ? Icons.local_offer_rounded : Icons.edit_note_rounded,
                            size: 13,
                            color: hasCustomPrice ? AppColors.accentYellow : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            hasCustomPrice ? 'Custom Price' : 'Edit Price',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hasCustomPrice ? AppColors.accentYellow : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Total Price
              Text(
                EscPosFormatter.formatCurrency(item.totalPrice),
                style: AppTypography.labelLarge.copyWith(
                  color: hasCustomPrice ? AppColors.accentYellow : AppColors.accentLime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quantity Adjuster Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '= ${item.equivalentPieces} Pcs deducted',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 16),
                      onPressed: () {
                        ref.read(cartItemsProvider.notifier).updateQuantity(index, item.quantity - 1);
                      },
                    ),
                    Text(
                      '${item.quantity}',
                      style: AppTypography.labelLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      onPressed: () {
                        final success = ref.read(cartItemsProvider.notifier).updateQuantity(index, item.quantity + 1);
                        if (!success) _showStockGuardSnackBar();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mobile Cart Summary Drawer Trigger Footer
  Widget _buildMobileCartSummaryFooter(List cartItems, double grandTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${cartItems.length} Items in Cart', style: AppTypography.bodySmall),
              Text(
                EscPosFormatter.formatCurrency(grandTotal),
                style: AppTypography.headingSmall.copyWith(color: AppColors.accentLime),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(160, 48),
            ),
            onPressed: cartItems.isEmpty
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.surface,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => SizedBox(
                        height: MediaQuery.of(context).size.height * 0.75,
                        child: _buildCartSidebarSection(cartItems, ref.read(cartSubtotalProvider), grandTotal),
                      ),
                    );
                  },
            icon: const Icon(Icons.shopping_bag_rounded),
            label: const Text('View Cart'),
          ),
        ],
      ),
    );
  }

  void _showPosQuickActionsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text('POS Terminal Quick Actions', style: AppTypography.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.danger),
                title: const Text('Clear Active Cart', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('Remove all items from current order', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  ref.read(cartItemsProvider.notifier).clearCart();
                  ref.read(discountAmountProvider.notifier).state = 0.0;
                  _discountController.clear();
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.danger,
                      content: Text('Cart cleared successfully'),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.settings_rounded, color: AppColors.accentLime),
                title: const Text('Printer & Store Settings', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('Configure store name, GSTIN & USB printer', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(dialogContext);
                  context.go('/settings');
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

