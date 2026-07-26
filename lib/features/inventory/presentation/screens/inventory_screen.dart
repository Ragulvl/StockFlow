import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/printer/esc_pos_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/product_model.dart';
import '../../../../providers/inventory_providers.dart';
import '../../../../providers/repository_providers.dart';
import '../widgets/add_edit_product_dialog.dart';
import '../widgets/stock_adjustment_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = ref.watch(filteredInventoryProductsProvider);
    final activeFilter = ref.watch(selectedStockFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inventory Management', style: AppTypography.headingMedium),
                      Text('Stock maintained strictly in pieces', style: AppTypography.bodySmall),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 46),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddEditProductDialog(),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Search & Stock Filter Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(inventorySearchQueryProvider.notifier).state = val;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search products by name...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(inventorySearchQueryProvider.notifier).state = '';
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Products', StockFilterType.all, activeFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('Low Stock Alerts', StockFilterType.lowStock, activeFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('In Stock', StockFilterType.inStock, activeFilter),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Products Inventory List
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No products found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildInventoryCard(product);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, StockFilterType type, StockFilterType activeType) {
    final bool isSelected = type == activeType;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.accentLime,
      backgroundColor: AppColors.surfaceCard,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? AppColors.accentLime : AppColors.border),
      onSelected: (_) {
        ref.read(selectedStockFilterProvider.notifier).state = type;
      },
    );
  }

  Widget _buildInventoryCard(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.isLowStock ? AppColors.accentYellow : AppColors.border,
          width: product.isLowStock ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.cookie_rounded, color: AppColors.accentLime, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: AppTypography.headingSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (product.description != null && product.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(product.description!, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Stock Alert Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: product.isLowStock ? AppColors.accentYellow.withValues(alpha: 0.2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: product.isLowStock ? AppColors.accentYellow : AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      product.isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                      size: 14,
                      color: product.isLowStock ? AppColors.accentYellow : AppColors.accentLime,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.isLowStock ? 'Low Stock' : 'In Stock',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: product.isLowStock ? AppColors.accentYellow : AppColors.accentLime,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Price & Stock Grid Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Stock:', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                    Text(
                      product.stockFormatted,
                      style: AppTypography.labelLarge.copyWith(color: AppColors.accentLime, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Single Piece Price:', style: AppTypography.bodySmall),
                    Text(EscPosFormatter.formatCurrency(product.piecePrice), style: AppTypography.labelMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pack Price (${product.packSize} Pcs):', style: AppTypography.bodySmall),
                    Text(EscPosFormatter.formatCurrency(product.packPrice), style: AppTypography.labelMedium.copyWith(color: AppColors.accentLime)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => StockAdjustmentDialog(product: product),
                  );
                },
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Adjust Stock', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddEditProductDialog(productToEdit: product),
                  );
                },
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                onPressed: () => _confirmDeleteProduct(product),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text('Delete Product?', style: AppTypography.headingSmall),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final repo = ref.read(inventoryRepositoryProvider);
              await repo.deleteProduct(product.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.danger,
                    content: Text('Product "${product.name}" deleted'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
