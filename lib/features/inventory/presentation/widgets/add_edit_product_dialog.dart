import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/product_model.dart';
import '../../../../providers/repository_providers.dart';

class AddEditProductDialog extends ConsumerStatefulWidget {
  final ProductModel? productToEdit;

  const AddEditProductDialog({
    super.key,
    this.productToEdit,
  });

  @override
  ConsumerState<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends ConsumerState<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _piecePriceController;
  late TextEditingController _packPriceController;
  late TextEditingController _packSizeController;
  late TextEditingController _stockPiecesController;
  late TextEditingController _minStockController;

  bool _isSubmitting = false;

  bool get isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _piecePriceController = TextEditingController(text: p != null ? p.piecePrice.toStringAsFixed(2) : '');
    _packPriceController = TextEditingController(text: p != null ? p.packPrice.toStringAsFixed(2) : '');
    _packSizeController = TextEditingController(text: p != null ? p.packSize.toString() : '10');
    _stockPiecesController = TextEditingController(text: p != null ? p.stockInPieces.toString() : '100');
    _minStockController = TextEditingController(text: p != null ? p.minStockAlert.toString() : '50');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _piecePriceController.dispose();
    _packPriceController.dispose();
    _packSizeController.dispose();
    _stockPiecesController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEditing ? 'Edit Product' : 'Add New Gummy Product', style: AppTypography.headingMedium),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Name
              TextFormField(
                controller: _nameController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter product name' : null,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g. Mango Chili Gummies',
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Tangy mango infused gummies',
                ),
              ),
              const SizedBox(height: 12),

              // Piece & Pack Pricing Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _piecePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        final v = double.tryParse(val ?? '');
                        if (v == null || v <= 0) return 'Invalid price';
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Single Piece Price',
                        prefixText: 'Rs. ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _packPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        final v = double.tryParse(val ?? '');
                        if (v == null || v <= 0) return 'Invalid price';
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Pack Price',
                        prefixText: 'Rs. ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pack Size (Dynamic) & Min Stock Threshold Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _packSizeController,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final v = int.tryParse(val ?? '');
                        if (v == null || v <= 0) return 'Invalid size';
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Pieces per Pack',
                        hintText: '10',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final v = int.tryParse(val ?? '');
                        if (v == null || v < 0) return 'Invalid threshold';
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Min Stock Alert (Pcs)',
                        hintText: '50',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stock in Pieces (If Adding new product)
              if (!isEditing) ...[
                TextFormField(
                  controller: _stockPiecesController,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    final v = int.tryParse(val ?? '');
                    if (v == null || v < 0) return 'Invalid stock';
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Initial Stock (in Total Pieces)',
                    hintText: '500',
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 16),

              // Action Buttons
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isSubmitting = true);

                        try {
                          final repo = ref.read(inventoryRepositoryProvider);
                          final name = _nameController.text.trim();
                          final desc = _descController.text.trim().isEmpty ? null : _descController.text.trim();
                          final piecePrice = double.parse(_piecePriceController.text);
                          final packPrice = double.parse(_packPriceController.text);
                          final packSize = int.parse(_packSizeController.text);
                          final minStockAlert = int.parse(_minStockController.text);

                          if (isEditing) {
                            final updatedProduct = widget.productToEdit!.copyWith(
                              name: name,
                              description: desc,
                              piecePrice: piecePrice,
                              packPrice: packPrice,
                              packSize: packSize,
                              minStockAlert: minStockAlert,
                            );
                            await repo.updateProduct(updatedProduct);
                          } else {
                            final initialStock = int.parse(_stockPiecesController.text);
                            await repo.addProduct(
                              name: name,
                              description: desc,
                              piecePrice: piecePrice,
                              packPrice: packPrice,
                              packSize: packSize,
                              initialStockInPieces: initialStock,
                              minStockAlert: minStockAlert,
                            );
                          }

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.accentLime,
                                content: Text(
                                  isEditing ? 'Product updated successfully' : 'New product added successfully',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.danger,
                                content: Text('Error saving product: $e'),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
