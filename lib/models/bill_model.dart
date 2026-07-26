class BillItemModel {
  final String id;
  final String billId;
  final String productId;
  final String productName;
  final String unitType; // 'SINGLE' or 'PACK'
  final int quantity; // Number of Singles or Packs purchased
  final double unitPrice;
  final int equivalentPieces; // Total pieces deducted from stock (quantity for SINGLE, quantity * product.packSize for PACK)
  final double totalPrice;

  BillItemModel({
    required this.id,
    required this.billId,
    required this.productId,
    required this.productName,
    required this.unitType,
    required this.quantity,
    required this.unitPrice,
    required this.equivalentPieces,
    required this.totalPrice,
  });
}

class BillModel {
  final String id;
  final String billNumber;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final String paymentMethod; // CASH, UPI, CARD
  final double amountTendered;
  final double changeReturned;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerState;
  final DateTime createdAt;
  final List<BillItemModel> items;

  BillModel({
    required this.id,
    required this.billNumber,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.grandTotal,
    required this.paymentMethod,
    this.amountTendered = 0.0,
    this.changeReturned = 0.0,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerState,
    required this.createdAt,
    required this.items,
  });
}

