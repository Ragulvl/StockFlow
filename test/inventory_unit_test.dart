import 'package:flutter_test/flutter_test.dart';
import 'package:stockflow/core/printer/esc_pos_formatter.dart';
import 'package:stockflow/core/printer/receipt_template.dart';
import 'package:stockflow/models/bill_model.dart';
import 'package:stockflow/models/product_model.dart';
import 'package:stockflow/repositories/bill_repository.dart';

void main() {
  group('StockFlow Comprehensive Domain & Architecture Tests', () {
    test('Dynamic packSize support (Pack size = 12)', () {
      final product = ProductModel(
        id: '1',
        name: 'Custom Gummy Pack 12',
        piecePrice: 10.0,
        packPrice: 100.0,
        packSize: 12, // Dynamic pack size 12
        stockInPieces: 125,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.availablePacks, 10);
      expect(product.availableRemainderPieces, 5);
      expect(product.stockFormatted, '10 Pk + 5 Pc (125 Pcs Total)');
    });

    test('Dynamic packSize support (Pack size = 24)', () {
      final product = ProductModel(
        id: '2',
        name: 'Jumbo Gummy Pack 24',
        piecePrice: 8.0,
        packPrice: 160.0,
        packSize: 24, // Dynamic pack size 24
        stockInPieces: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.availablePacks, 2);
      expect(product.availableRemainderPieces, 2);
    });

    test('CartItemInput equivalent pieces deduction calculation', () {
      final product = ProductModel(
        id: '1',
        name: 'Dark Chocolate Gummies',
        piecePrice: 15.0,
        packPrice: 135.0,
        packSize: 10,
        stockInPieces: 500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final singleCartItem = CartItemInput(
        product: product,
        unitType: 'SINGLE',
        quantity: 3,
      );

      final packCartItem = CartItemInput(
        product: product,
        unitType: 'PACK',
        quantity: 2,
      );

      expect(singleCartItem.equivalentPieces, 3);
      expect(packCartItem.equivalentPieces, 20); // 2 Packs * 10 Pcs
      expect(singleCartItem.totalPrice, 45.0);
      expect(packCartItem.totalPrice, 270.0);
    });

    test('ReceiptTemplate text preview compiler output', () {
      final template = ReceiptTemplate(
        storeName: 'ChocoGummy Delights',
        storePhone: '+91 98765 43210',
        receiptFooter: 'Enjoy your gummies!',
      );

      final bill = BillModel(
        id: 'b1',
        billNumber: 'INV-20260721-0001',
        subtotal: 135.0,
        grandTotal: 135.0,
        paymentMethod: 'CASH',
        createdAt: DateTime(2026, 7, 21, 14, 30),
        items: [
          BillItemModel(
            id: 'i1',
            billId: 'b1',
            productId: 'p1',
            productName: 'Dark Choco Gummy',
            unitType: 'PACK',
            quantity: 1,
            unitPrice: 135.0,
            equivalentPieces: 10,
            totalPrice: 135.0,
          ),
        ],
      );

      final preview = template.buildTextPreview(bill);
      print('\n=== GENERATED PREVIEW TEXT ===\n$preview\n==============================\n');
      expect(preview.contains('ChocoGummy Delights'), true);
      expect(preview.contains('INV-20260721-0001'), true);
      expect(preview.contains('135.00'), true);
    });

    test('CartItemInput custom unit price override for friends/special customers', () {
      final product = ProductModel(
        id: '1',
        name: 'Dark Chocolate Gummies',
        piecePrice: 15.0,
        packPrice: 135.0,
        packSize: 10,
        stockInPieces: 500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customCartItem = CartItemInput(
        product: product,
        unitType: 'SINGLE',
        quantity: 5,
        customUnitPrice: 10.0, // Custom special price 10.0 instead of 15.0
      );

      expect(customCartItem.unitPrice, 10.0);
      expect(customCartItem.totalPrice, 50.0);
    });

    test('ESC/POS 30-character line math formatting', () {
      final itemLine = EscPosFormatter.formatItemLine('Milk Choco', '2Pk', 'Rs.220.00');
      expect(itemLine.length, 30);

      final totalLine = EscPosFormatter.formatTotalLine('Subtotal', 'Rs.520.00');
      expect(totalLine.length, 30);
    });
  });
}
