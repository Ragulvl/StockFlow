import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../utils/number_to_words.dart';
import 'esc_pos_formatter.dart';
import 'raster_converter.dart';
import 'receipt_data.dart';

/// Pure Dart ESC/POS Binary Command Encoder matching the Dinez POS Thermal Printing Architecture
class EscPosBuilder {
  final List<int> _bytes = [];

  List<int> get bytes => List.unmodifiable(_bytes);

  /// ESC @ - Reset printer
  void initialize() {
    _bytes.addAll([0x1B, 0x40]);
  }

  /// ESC a n - Justification (0: Left, 1: Center, 2: Right)
  void setJustification(int align) {
    _bytes.addAll([0x1B, 0x61, align]);
  }

  /// ESC E n - Bold text (1: ON, 0: OFF)
  void setBold(bool enable) {
    _bytes.addAll([0x1B, 0x45, enable ? 1 : 0]);
  }

  /// Line feed (LF)
  void lineFeed([int lines = 1]) {
    for (int i = 0; i < lines; i++) {
      _bytes.add(0x0A);
    }
  }

  /// Append ASCII String Line
  void textLine(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final asciiBytes = Latin1Codec().encode(line);
      _bytes.addAll(asciiBytes);
      _bytes.add(0x0A);
    }
  }

  /// Append ESC/POS Raster Bit Image
  void imageRaster(img.Image logoImage, {int targetWidth = 200}) {
    final rasterBytes = RasterConverter.toEscPosRaster(logoImage, targetWidth: targetWidth);
    _bytes.addAll(rasterBytes);
    lineFeed();
  }

  /// Append CODE39 1D Barcode
  void barcodeCode39(String text) {
    setJustification(1); // Center
    _bytes.addAll([0x1D, 0x68, 45]); // GS h 45 - Height 45 dots
    _bytes.addAll([0x1D, 0x77, 2]); // GS w 2 - Module width 2
    _bytes.addAll([0x1D, 0x48, 2]); // GS H 2 - HRI font below
    _bytes.addAll([0x1D, 0x66, 1]); // GS f 1 - Font B

    final cleanText = text.replaceAll(RegExp(r'[^A-Z0-9\-\.\ \$\/\+\%]'), '');
    _bytes.addAll([0x1D, 0x6B, 4]); // GS k 4 (CODE39)
    _bytes.addAll(ascii.encode(cleanText));
    _bytes.add(0x00); // Terminating NUL
    lineFeed();
  }

  /// GS V 0 - Paper Auto-Cut
  void cutPaper() {
    lineFeed(3);
    _bytes.addAll([0x1D, 0x56, 0x00]);
  }

  /// End-to-End ESC/POS Receipt Compilation
  static Uint8List buildReceiptBytes(ReceiptData data, {img.Image? logoImage}) {
    final builder = EscPosBuilder();

    // 1. Reset
    builder.initialize();

    // 2. Optional Raster Logo
    if (logoImage != null) {
      builder.setJustification(1);
      builder.imageRaster(logoImage, targetWidth: 200);
    }

    // 3. Header Section (Centered)
    builder.setJustification(1);
    builder.setBold(true);
    builder.textLine('GST CASH BILL');
    builder.textLine(data.storeName);
    builder.setBold(false);

    if (data.storeTagline != null && data.storeTagline!.isNotEmpty) {
      builder.textLine(EscPosFormatter.center(data.storeTagline!));
    }
    if (data.storeAddress != null && data.storeAddress!.isNotEmpty) {
      builder.textLine(EscPosFormatter.center(data.storeAddress!));
    }
    if (data.storeState != null && data.storeState!.isNotEmpty) {
      builder.textLine(EscPosFormatter.center('State: ${data.storeState!}'));
    }
    if (data.storePhone != null && data.storePhone!.isNotEmpty) {
      builder.textLine(EscPosFormatter.center('Contact: ${data.storePhone!}'));
    }
    if (data.storeEmail != null && data.storeEmail!.isNotEmpty) {
      builder.textLine(EscPosFormatter.center(data.storeEmail!));
    }

    builder.textLine(EscPosFormatter.divider('='));

    // 4. Order Metadata & Buyer Details (Left)
    builder.setJustification(0);
    builder.textLine(EscPosFormatter.formatKeyValue('Invoice No', data.billNumber, labelWidth: 10));
    builder.textLine(EscPosFormatter.formatKeyValue('Dated', data.dateTime.toString().substring(0, 10), labelWidth: 10));
    builder.textLine(EscPosFormatter.formatKeyValue('Mode/Terms', data.paymentMethod, labelWidth: 10));
    builder.textLine(EscPosFormatter.divider('-'));

    if (data.customerName != null && data.customerName!.isNotEmpty) {
      builder.textLine('Buyer (Bill to):');
      builder.textLine(EscPosFormatter.formatKeyValue('  Name', data.customerName!, labelWidth: 8));
      if (data.customerAddress != null && data.customerAddress!.isNotEmpty) {
        builder.textLine(EscPosFormatter.formatKeyValue('  Addr', data.customerAddress!, labelWidth: 8));
      }
      if (data.customerPhone != null && data.customerPhone!.isNotEmpty) {
        builder.textLine(EscPosFormatter.formatKeyValue('  Ph', data.customerPhone!, labelWidth: 8));
      }
      if (data.customerState != null && data.customerState!.isNotEmpty) {
        builder.textLine(EscPosFormatter.formatKeyValue('  State', data.customerState!, labelWidth: 8));
      }
      builder.textLine(EscPosFormatter.divider('-'));
    }

    // 5. Items Header Table
    builder.setBold(true);
    builder.textLine(EscPosFormatter.formatItemHeader());
    builder.setBold(false);
    builder.textLine(EscPosFormatter.divider('-'));

    // 6. Item Rows
    for (final item in data.items) {
      builder.textLine(EscPosFormatter.formatSmartItemBlock(
        name: item.name,
        quantity: item.quantity,
        unitType: item.unitType,
        unitPrice: item.unitPrice,
        totalPrice: item.totalPrice,
      ));
    }

    builder.textLine(EscPosFormatter.divider('-'));

    // 7. Totals Section
    builder.textLine(EscPosFormatter.formatTotalLine('Subtotal', EscPosFormatter.formatCurrency(data.subtotal)));
    if (data.discount > 0) {
      builder.textLine(EscPosFormatter.formatTotalLine('Discount', '-${EscPosFormatter.formatCurrency(data.discount)}'));
    }
    if (data.tax > 0) {
      builder.textLine(EscPosFormatter.formatTotalLine('Tax', EscPosFormatter.formatCurrency(data.tax)));
    }

    builder.textLine(EscPosFormatter.divider('='));
    builder.setBold(true);
    builder.textLine(EscPosFormatter.formatTotalLine('TOTAL', EscPosFormatter.formatCurrency(data.grandTotal)));
    builder.setBold(false);

    if (data.paymentMethod == 'CASH' && data.amountTendered > 0) {
      builder.textLine(EscPosFormatter.formatTotalLine('Tendered', EscPosFormatter.formatCurrency(data.amountTendered)));
      builder.textLine(EscPosFormatter.formatTotalLine('Change', EscPosFormatter.formatCurrency(data.changeReturned)));
    }

    builder.textLine(EscPosFormatter.divider('-'));

    // 8. Amount Chargeable in Words
    final amountInWords = NumberToWords.convertToWords(data.grandTotal);
    builder.textLine('Amount Chargeable (in words):');
    final wordLines = EscPosFormatter.wrapText(amountInWords, width: EscPosFormatter.lineWidth, indent: '  ');
    for (final wl in wordLines) {
      builder.textLine(wl);
    }
    builder.textLine(EscPosFormatter.divider('-'));

    // 9. Bank Details (Only printed if showBankDetails privacy toggle is enabled)
    if (data.showBankDetails && data.bankAccountNo != null && data.bankAccountNo!.isNotEmpty) {
      builder.textLine("Company's Bank Details:");
      if (data.bankAccountName != null && data.bankAccountName!.isNotEmpty) {
        builder.textLine(EscPosFormatter.formatKeyValue('  A/c Holder', data.bankAccountName!, labelWidth: 12));
      }
      if (data.bankName != null && data.bankName!.isNotEmpty) {
        builder.textLine(EscPosFormatter.formatKeyValue('  Bank Name', data.bankName!, labelWidth: 12));
      }
      builder.textLine(EscPosFormatter.formatKeyValue('  A/c No.', data.bankAccountNo!, labelWidth: 12));
      if (data.bankIfsc != null && data.bankIfsc!.isNotEmpty) {
        builder.textLine(EscPosFormatter.formatKeyValue('  IFS Code', data.bankIfsc!, labelWidth: 12));
      }
      builder.textLine(EscPosFormatter.divider('-'));
    }

    // 10. Company PAN (Only printed if showPan privacy toggle is enabled)
    if (data.showPan && data.storePan != null && data.storePan!.isNotEmpty) {
      builder.textLine("Company's PAN: ${data.storePan!}");
    }

    // 11. Declaration Text
    if (data.storeDeclaration != null && data.storeDeclaration!.isNotEmpty) {
      builder.textLine('Declaration:');
      final decLines = EscPosFormatter.wrapText(data.storeDeclaration!, width: EscPosFormatter.lineWidth, indent: '  ');
      for (final dl in decLines) {
        builder.textLine(dl);
      }
      builder.textLine(EscPosFormatter.divider('-'));
    }

    // 12. Signatory Section
    builder.setJustification(1);
    builder.textLine('Authorised Signatory');
    builder.textLine(EscPosFormatter.divider('-'));

    // 13. Footer Message
    if (data.receiptFooter != null && data.receiptFooter!.isNotEmpty) {
      builder.textLine(EscPosFormatter.center(data.receiptFooter!));
    }

    // 14. Paper Cut
    builder.cutPaper();

    return Uint8List.fromList(builder.bytes);
  }
}
