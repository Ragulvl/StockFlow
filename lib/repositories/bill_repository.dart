import 'package:uuid/uuid.dart';
import '../core/database/app_database.dart';
import '../core/logger/app_logger.dart';
import '../models/bill_model.dart';
import '../models/product_model.dart';

class CartItemInput {
  final ProductModel product;
  final String unitType; // 'SINGLE' or 'PACK'
  final int quantity;
  final double? customUnitPrice;

  CartItemInput({
    required this.product,
    required this.unitType,
    required this.quantity,
    this.customUnitPrice,
  });

  /// Dynamic price per unit (overridden if custom price set)
  double get unitPrice => customUnitPrice ?? (unitType == 'PACK' ? product.packPrice : product.piecePrice);

  /// Dynamic total price
  double get totalPrice => unitPrice * quantity;

  /// Dynamic equivalent pieces deducted from stock (1 * qty for SINGLE, product.packSize * qty for PACK)
  int get equivalentPieces => unitType == 'PACK' ? (quantity * product.packSize) : quantity;
}

class BillRepository {
  final AppDatabase _db;

  BillRepository(this._db);

  BillModel _mapToDomain(Bill bill, List<BillItem> items) {
    return BillModel(
      id: bill.id,
      billNumber: bill.billNumber,
      subtotal: bill.subtotal,
      discount: bill.discount,
      tax: bill.tax,
      grandTotal: bill.grandTotal,
      paymentMethod: bill.paymentMethod,
      amountTendered: bill.amountTendered,
      changeReturned: bill.changeReturned,
      customerName: bill.customerName,
      customerPhone: bill.customerPhone,
      customerAddress: bill.customerAddress,
      customerState: bill.customerState,
      createdAt: bill.createdAt,
      items: items
          .map((i) => BillItemModel(
                id: i.id,
                billId: i.billId,
                productId: i.productId,
                productName: i.productName,
                unitType: i.unitType,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                equivalentPieces: i.equivalentPieces,
                totalPrice: i.totalPrice,
              ))
          .toList(),
    );
  }

  Stream<List<BillModel>> watchBills() async* {
    await for (final _ in _db.watchRecentBills()) {
      final allBills = await _db.getAllBillsWithItems();
      yield allBills.map((b) => _mapToDomain(b.bill, b.items)).toList();
    }
  }

  Future<List<BillModel>> getAllBills() async {
    final list = await _db.getAllBillsWithItems();
    return list.map((b) => _mapToDomain(b.bill, b.items)).toList();
  }

  Future<BillModel?> getBillById(String billId) async {
    final b = await _db.getBillWithItemsById(billId);
    return b != null ? _mapToDomain(b.bill, b.items) : null;
  }

  /// Executes atomic POS checkout transaction: generates bill number, inserts bill & items, decrements piece stock.
  Future<BillModel> checkout({
    required List<CartItemInput> cartItems,
    required String paymentMethod,
    double discount = 0.0,
    double tax = 0.0,
    double amountTendered = 0.0,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? customerState,
  }) async {
    const uuid = Uuid();
    final now = DateTime.now();

    final billNumber = await _db.generateNextBillNumber();
    final billId = uuid.v4();

    double subtotal = 0.0;
    final billItemsData = <BillItem>[];

    for (final item in cartItems) {
      subtotal += item.totalPrice;
      billItemsData.add(
        BillItem(
          id: uuid.v4(),
          billId: billId,
          productId: item.product.id,
          productName: item.product.name,
          unitType: item.unitType,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          equivalentPieces: item.equivalentPieces,
          totalPrice: item.totalPrice,
        ),
      );
    }

    final grandTotal = (subtotal - discount + tax).clamp(0.0, double.infinity);
    final changeReturned = (amountTendered - grandTotal).clamp(0.0, double.infinity);

    final billData = Bill(
      id: billId,
      billNumber: billNumber,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      amountTendered: amountTendered,
      changeReturned: changeReturned,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerState: customerState,
      createdAt: now,
    );

    AppLogger.info("Creating bill $billNumber ($paymentMethod) for Total: Rs.$grandTotal", "BillRepository");

    final result = await _db.createBillTransaction(
      billData: billData,
      itemsData: billItemsData,
    );

    return _mapToDomain(result.bill, result.items);
  }
}
