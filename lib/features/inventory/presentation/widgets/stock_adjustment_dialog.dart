import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/product_model.dart';
import '../../../../providers/repository_providers.dart';

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  final ProductModel product;

  const StockAdjustmentDialog({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  bool _isAddition = true; // true = Add Stock, false = Reduce/Damage Stock
  String _unitType = 'PACK'; // PACK or SINGLE
  final TextEditingController _qtyController = TextEditingController(text: '1');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int qty = int.tryParse(_qtyController.text) ?? 0;
    final int deltaPieces = _unitType == 'PACK' ? (qty * widget.product.packSize) : qty;
    final int signedDelta = _isAddition ? deltaPieces : -deltaPieces;
    final int newStockInPieces = (widget.product.stockInPieces + signedDelta).clamp(0, 999999);

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Adjust Stock', style: AppTypography.headingMedium),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(widget.product.name, style: AppTypography.bodySmall.copyWith(color: AppColors.accentLime)),
            const SizedBox(height: 16),

            // Stock Info Card
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
                  Text('Current Stock:', style: AppTypography.bodyMedium),
                  Text(
                    widget.product.stockFormatted,
                    style: AppTypography.labelLarge.copyWith(color: AppColors.accentLime),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Adjustment Type Segmented Buttons (Add vs Remove)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isAddition = true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isAddition ? AppColors.accentLime : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _isAddition ? AppColors.accentLime : AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          '+ Add Stock',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isAddition ? Colors.black : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isAddition = false),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isAddition ? AppColors.danger : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: !_isAddition ? AppColors.danger : AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          '- Remove Stock',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_isAddition ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Unit Type Switcher (Packs vs Pieces)
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Packs (${widget.product.packSize} Pcs/Pk)', style: AppTypography.bodySmall),
                    value: 'PACK',
                    groupValue: _unitType,
                    activeColor: AppColors.accentLime,
                    onChanged: (val) => setState(() => _unitType = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Single Pieces', style: AppTypography.bodySmall),
                    value: 'SINGLE',
                    groupValue: _unitType,
                    activeColor: AppColors.accentLime,
                    onChanged: (val) => setState(() => _unitType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quantity Input
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              style: AppTypography.headingSmall,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _unitType == 'PACK' ? 'Number of Packs' : 'Number of Pieces',
                hintText: 'Enter quantity',
              ),
            ),
            const SizedBox(height: 16),

            // Live Calculation Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Adjustment in Pieces:', style: AppTypography.bodySmall),
                      Text(
                        '${_isAddition ? '+' : '-'}$deltaPieces Pcs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isAddition ? AppColors.accentLime : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('New Total Stock:', style: AppTypography.bodyMedium),
                      Text(
                        '$newStockInPieces Pcs (${newStockInPieces ~/ widget.product.packSize} Pk + ${newStockInPieces % widget.product.packSize} Pc)',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.accentLime),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            ElevatedButton(
              onPressed: _isSubmitting || qty <= 0
                  ? null
                  : () async {
                      setState(() => _isSubmitting = true);
                      try {
                        final repository = ref.read(inventoryRepositoryProvider);
                        await repository.adjustStock(widget.product.id, signedDelta);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.accentLime,
                              content: Text(
                                'Stock adjusted for ${widget.product.name} to $newStockInPieces pieces',
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
                              content: Text('Failed to adjust stock: $e'),
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
                  : Text('Confirm Stock ${_isAddition ? 'Addition' : 'Reduction'}'),
            ),
          ],
        ),
      ),
    );
  }
}
