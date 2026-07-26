import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../models/bill_model.dart';
import '../utils/number_to_words.dart';
import 'esc_pos_builder.dart';
import 'esc_pos_formatter.dart';
import 'receipt_data.dart';

/// Decoupled Receipt Template Engine producing raw ESC/POS bytes or structured text summaries
class ReceiptTemplate {
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
  final String? receiptFooter;
  final bool showBankDetails;
  final bool showPan;

  ReceiptTemplate({
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
    this.receiptFooter,
    this.showBankDetails = false,
    this.showPan = false,
  });

  ReceiptData buildReceiptData(BillModel bill) {
    return ReceiptData(
      storeName: storeName,
      storeTagline: storeTagline,
      storeAddress: storeAddress,
      storeState: storeState,
      storePhone: storePhone,
      storeEmail: storeEmail,
      storePan: storePan,
      fssaiLicense: fssaiLicense,
      gstin: gstin,
      bankAccountName: bankAccountName,
      bankName: bankName,
      bankAccountNo: bankAccountNo,
      bankIfsc: bankIfsc,
      storeDeclaration: storeDeclaration,
      billNumber: bill.billNumber,
      dateTime: bill.createdAt,
      paymentMethod: bill.paymentMethod,
      items: bill.items
          .map((i) => ReceiptItemData(
                name: i.productName,
                unitType: i.unitType,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                totalPrice: i.totalPrice,
              ))
          .toList(),
      subtotal: bill.subtotal,
      discount: bill.discount,
      tax: bill.tax,
      grandTotal: bill.grandTotal,
      amountTendered: bill.amountTendered,
      changeReturned: bill.changeReturned,
      customerName: bill.customerName,
      customerPhone: bill.customerPhone,
      customerAddress: bill.customerAddress,
      customerState: bill.customerState,
      receiptFooter: receiptFooter,
      showBankDetails: showBankDetails,
      showPan: showPan,
    );
  }

  /// Exports to ESC/POS hardware bytes
  Uint8List buildEscPosBytes(BillModel bill, {img.Image? logoImage}) {
    final receiptData = buildReceiptData(bill);
    return EscPosBuilder.buildReceiptBytes(receiptData, logoImage: logoImage);
  }

  /// Exports raw formatted text report to ESC/POS hardware bytes
  Uint8List buildEscPosBytesFromRaw(String text) {
    final builder = EscPosBuilder();
    builder.initialize();
    builder.setJustification(1);
    builder.setBold(true);
    builder.textLine(storeName);
    builder.setBold(false);
    builder.textLine(EscPosFormatter.divider('='));
    builder.setJustification(0);
    builder.textLine(text);
    builder.textLine(EscPosFormatter.divider('-'));
    if (receiptFooter != null && receiptFooter!.isNotEmpty) {
      builder.setJustification(1);
      builder.textLine(receiptFooter!);
    }
    builder.cutPaper();
    return Uint8List.fromList(builder.bytes);
  }

  /// Exports to plain text monospace string for on-screen receipt preview dialogs matching GST Cash Bill format
  String buildTextPreview(BillModel bill) {
    final buffer = StringBuffer();
    buffer.writeln(EscPosFormatter.center('GST CASH BILL'));
    buffer.writeln(EscPosFormatter.center(storeName));
    if (storeTagline != null && storeTagline!.isNotEmpty) {
      buffer.writeln(EscPosFormatter.center(storeTagline!));
    }
    if (storeAddress != null && storeAddress!.isNotEmpty) {
      buffer.writeln(EscPosFormatter.center(storeAddress!));
    }
    if (storeState != null && storeState!.isNotEmpty) {
      buffer.writeln(EscPosFormatter.center('State: $storeState'));
    }
    if (storePhone != null && storePhone!.isNotEmpty) {
      buffer.writeln(EscPosFormatter.center('Contact: $storePhone'));
    }
    if (storeEmail != null && storeEmail!.isNotEmpty) {
      buffer.writeln(EscPosFormatter.center(storeEmail!));
    }
    buffer.writeln(EscPosFormatter.divider('='));

    buffer.writeln(EscPosFormatter.formatKeyValue('Invoice No', bill.billNumber, labelWidth: 10));
    buffer.writeln(EscPosFormatter.formatKeyValue('Dated', bill.createdAt.toString().substring(0, 10), labelWidth: 10));
    buffer.writeln(EscPosFormatter.formatKeyValue('Mode/Terms', bill.paymentMethod, labelWidth: 10));
    buffer.writeln(EscPosFormatter.divider('-'));

    if (bill.customerName != null && bill.customerName!.isNotEmpty) {
      buffer.writeln('Buyer (Bill to):');
      buffer.writeln(EscPosFormatter.formatKeyValue('  Name', bill.customerName!, labelWidth: 8));
      if (bill.customerAddress != null && bill.customerAddress!.isNotEmpty) {
        buffer.writeln(EscPosFormatter.formatKeyValue('  Addr', bill.customerAddress!, labelWidth: 8));
      }
      if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty) {
        buffer.writeln(EscPosFormatter.formatKeyValue('  Ph', bill.customerPhone!, labelWidth: 8));
      }
      if (bill.customerState != null && bill.customerState!.isNotEmpty) {
        buffer.writeln(EscPosFormatter.formatKeyValue('  State', bill.customerState!, labelWidth: 8));
      }
      buffer.writeln(EscPosFormatter.divider('-'));
    }

    buffer.writeln(EscPosFormatter.formatItemHeader());
    buffer.writeln(EscPosFormatter.divider('-'));
    for (final item in bill.items) {
      buffer.writeln(EscPosFormatter.formatSmartItemBlock(
        name: item.productName,
        quantity: item.quantity,
        unitType: item.unitType,
        unitPrice: item.unitPrice,
        totalPrice: item.totalPrice,
      ));
    }
    buffer.writeln(EscPosFormatter.divider('-'));
    buffer.writeln(EscPosFormatter.formatTotalLine('Subtotal', EscPosFormatter.formatCurrency(bill.subtotal)));
    if (bill.discount > 0) {
      buffer.writeln(EscPosFormatter.formatTotalLine('Discount', '-${EscPosFormatter.formatCurrency(bill.discount)}'));
    }
    if (bill.tax > 0) {
      buffer.writeln(EscPosFormatter.formatTotalLine('Tax', EscPosFormatter.formatCurrency(bill.tax)));
    }
    buffer.writeln(EscPosFormatter.divider('='));
    buffer.writeln(EscPosFormatter.formatTotalLine('TOTAL', EscPosFormatter.formatCurrency(bill.grandTotal)));
    buffer.writeln(EscPosFormatter.divider('-'));

    // Amount Chargeable in words
    final amountInWords = NumberToWords.convertToWords(bill.grandTotal);
    buffer.writeln('Amount Chargeable (in words):');
    final wordLines = EscPosFormatter.wrapText(amountInWords, width: EscPosFormatter.lineWidth, indent: '  ');
    for (final wl in wordLines) {
      buffer.writeln(wl);
    }
    buffer.writeln(EscPosFormatter.divider('-'));

    // Bank Details (Only printed if showBankDetails privacy toggle is enabled)
    if (showBankDetails && bankAccountNo != null && bankAccountNo!.isNotEmpty) {
      buffer.writeln("Company's Bank Details:");
      if (bankAccountName != null && bankAccountName!.isNotEmpty) {
        buffer.writeln(EscPosFormatter.formatKeyValue('  A/c Holder', bankAccountName!, labelWidth: 12));
      }
      if (bankName != null && bankName!.isNotEmpty) {
        buffer.writeln(EscPosFormatter.formatKeyValue('  Bank Name', bankName!, labelWidth: 12));
      }
      buffer.writeln(EscPosFormatter.formatKeyValue('  A/c No.', bankAccountNo!, labelWidth: 12));
      if (bankIfsc != null && bankIfsc!.isNotEmpty) {
        buffer.writeln(EscPosFormatter.formatKeyValue('  IFS Code', bankIfsc!, labelWidth: 12));
      }
      buffer.writeln(EscPosFormatter.divider('-'));
    }

    // Company PAN (Only printed if showPan privacy toggle is enabled)
    if (showPan && storePan != null && storePan!.isNotEmpty) {
      buffer.writeln("Company's PAN: $storePan");
    }

    if (storeDeclaration != null && storeDeclaration!.isNotEmpty) {
      buffer.writeln('Declaration:');
      final decLines = EscPosFormatter.wrapText(storeDeclaration!, width: EscPosFormatter.lineWidth, indent: '  ');
      for (final dl in decLines) {
        buffer.writeln(dl);
      }
      buffer.writeln(EscPosFormatter.divider('-'));
    }

    buffer.writeln(EscPosFormatter.center('Authorised Signatory'));
    buffer.writeln(EscPosFormatter.divider('-'));

    if (receiptFooter != null && receiptFooter!.isNotEmpty) {
      buffer.writeln(EscPosFormatter.center(receiptFooter!));
    }
    return buffer.toString();
  }
}
