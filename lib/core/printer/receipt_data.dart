class ReceiptItemData {
  final String name;
  final String unitType; // 'SINGLE' or 'PACK'
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  ReceiptItemData({
    required this.name,
    required this.unitType,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class ReceiptData {
  final String storeName;
  final String? storeTagline;
  final String? storeAddress;
  final String? storeState;
  final String? storePhone;
  final String? storeEmail;
  final String? storePan;
  final String? fssaiLicense;
  final String? gstin;
  final String? bankAccountName;
  final String? bankName;
  final String? bankAccountNo;
  final String? bankIfsc;
  final String? storeDeclaration;
  final String billNumber;
  final DateTime dateTime;
  final String paymentMethod;
  final List<ReceiptItemData> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final double amountTendered;
  final double changeReturned;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerState;
  final String? receiptFooter;
  final bool showBankDetails;
  final bool showPan;

  ReceiptData({
    required this.storeName,
    this.storeTagline,
    this.storeAddress,
    this.storeState,
    this.storePhone,
    this.storeEmail,
    this.storePan,
    this.fssaiLicense,
    this.gstin,
    this.bankAccountName,
    this.bankName,
    this.bankAccountNo,
    this.bankIfsc,
    this.storeDeclaration,
    required this.billNumber,
    required this.dateTime,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.grandTotal,
    this.amountTendered = 0.0,
    this.changeReturned = 0.0,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerState,
    this.receiptFooter,
    this.showBankDetails = false,
    this.showPan = false,
  });
}

