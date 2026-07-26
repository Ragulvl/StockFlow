import 'dart:convert';
import '../core/database/app_database.dart';
import '../core/logger/app_logger.dart';

class BackupRepository {
  final AppDatabase _db;

  BackupRepository(this._db);

  /// Serializes products, bills, bill items, and settings into an offline JSON backup payload string
  Future<String> exportBackupJson() async {
    AppLogger.info("Generating offline JSON database backup export", "BackupRepository");

    final products = await _db.getAllProducts();
    final billsWithItems = await _db.getAllBillsWithItems();
    final settingsMap = await _db.getAllSettings();

    final backupMap = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'products': products.map((p) => {
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'piece_price': p.piecePrice,
        'pack_price': p.packPrice,
        'pack_size': p.packSize,
        'stock_in_pieces': p.stockInPieces,
        'min_stock_alert': p.minStockAlert,
        'created_at': p.createdAt.toIso8601String(),
        'updated_at': p.updatedAt.toIso8601String(),
      }).toList(),
      'bills': billsWithItems.map((b) => {
        'id': b.bill.id,
        'bill_number': b.bill.billNumber,
        'subtotal': b.bill.subtotal,
        'discount': b.bill.discount,
        'tax': b.bill.tax,
        'grand_total': b.bill.grandTotal,
        'payment_method': b.bill.paymentMethod,
        'amount_tendered': b.bill.amountTendered,
        'change_returned': b.bill.changeReturned,
        'customer_name': b.bill.customerName,
        'customer_phone': b.bill.customerPhone,
        'created_at': b.bill.createdAt.toIso8601String(),
        'items': b.items.map((item) => {
          'id': item.id,
          'bill_id': item.billId,
          'product_id': item.productId,
          'product_name': item.productName,
          'unit_type': item.unitType,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'equivalent_pieces': item.equivalentPieces,
          'total_price': item.totalPrice,
        }).toList(),
      }).toList(),
      'settings': settingsMap,
    };

    return jsonEncode(backupMap);
  }
}
