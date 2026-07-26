/// Helper utility for 30-character column math & formatting on 58mm ESC/POS printers.
class EscPosFormatter {
  static const int lineWidth = 30;

  /// Creates a horizontal separator line (e.g. `==============================` or `------------------------------`)
  static String divider([String char = '-']) {
    return char * lineWidth;
  }

  /// Word-wraps text to fit within [width] without breaking words in half.
  static List<String> wrapText(String text, {int width = lineWidth, String indent = ''}) {
    if (text.trim().isEmpty) return [];

    final lines = <String>[];
    final words = text.split(RegExp(r'\s+'));
    var currentLine = StringBuffer();
    final maxLen = width - indent.length;

    for (final word in words) {
      if (word.isEmpty) continue;

      if (currentLine.isEmpty) {
        if (word.length > maxLen) {
          // Word itself is longer than line width, hard split it
          for (int i = 0; i < word.length; i += maxLen) {
            final end = (i + maxLen < word.length) ? i + maxLen : word.length;
            lines.add('$indent${word.substring(i, end)}');
          }
        } else {
          currentLine.write(word);
        }
      } else if (currentLine.length + 1 + word.length <= maxLen) {
        currentLine.write(' $word');
      } else {
        lines.add('$indent${currentLine.toString()}');
        currentLine = StringBuffer();
        if (word.length > maxLen) {
          for (int i = 0; i < word.length; i += maxLen) {
            final end = (i + maxLen < word.length) ? i + maxLen : word.length;
            lines.add('$indent${word.substring(i, end)}');
          }
        } else {
          currentLine.write(word);
        }
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add('$indent${currentLine.toString()}');
    }

    return lines;
  }

  /// Centers single or multi-line text cleanly within 30 characters
  static String center(String text) {
    if (text.trim().isEmpty) return '';
    final wrapped = wrapText(text, width: lineWidth);
    final buffer = StringBuffer();
    for (int i = 0; i < wrapped.length; i++) {
      final line = wrapped[i];
      final leftPadding = (lineWidth - line.length) ~/ 2;
      final rightPadding = lineWidth - line.length - leftPadding;
      buffer.write('${' ' * leftPadding}$line${' ' * rightPadding}');
      if (i < wrapped.length - 1) {
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  /// Formats key-value pairs (e.g. `Invoice No : INV-20260726-0001`) with wrapping support
  static String formatKeyValue(String label, String value, {int labelWidth = 10}) {
    final prefix = label.padRight(labelWidth);
    final valIndent = ' ' * (labelWidth + 2);
    final fullPrefix = '$prefix: ';

    if (fullPrefix.length + value.length <= lineWidth) {
      return '$fullPrefix$value';
    }

    final valWidth = lineWidth - fullPrefix.length;
    final wrappedVal = wrapText(value, width: valWidth);

    if (wrappedVal.isEmpty) return fullPrefix;

    final buffer = StringBuffer();
    buffer.write('$fullPrefix${wrappedVal[0]}');
    for (int i = 1; i < wrappedVal.length; i++) {
      buffer.writeln();
      buffer.write('$valIndent${wrappedVal[i]}');
    }
    return buffer.toString();
  }

  /// Formats 3 Columns for Header Table: ITEM (18), QTY (4), AMOUNT (8) = 30 Chars
  static String formatItemHeader() {
    final col1 = 'ITEM'.padRight(18);
    final col2 = 'QTY'.padLeft(4);
    final col3 = 'AMOUNT'.padLeft(8);
    return '$col1$col2$col3';
  }

  /// Formats 3 Columns for Header Table: ITEM (18), QTY (4), AMOUNT (8)
  static String formatItemLine(String name, String qty, String price) {
    const nameWidth = 18;
    const qtyWidth = 4;
    const priceWidth = 8;

    final formattedName = name.length > nameWidth
        ? name.substring(0, nameWidth)
        : name.padRight(nameWidth);
    final formattedQty = qty.length > qtyWidth
        ? qty.substring(0, qtyWidth)
        : qty.padLeft(qtyWidth);
    final formattedPrice = price.length > priceWidth
        ? price.substring(0, priceWidth)
        : price.padLeft(priceWidth);

    return '$formattedName$formattedQty$formattedPrice';
  }

  /// Compact receipt item block for 58mm paper:
  /// Line 1: Col 0-17: Item Name (first 18 chars), Col 18-21: `[qty]`, Col 22-29: `[numericAmount]`
  /// Line 2 (if needed): Remainder of Item Name + parenthetical unit rate
  static String formatSmartItemBlock({
    required String name,
    required int quantity,
    required String unitType,
    required double unitPrice,
    required double totalPrice,
  }) {
    const itemWidth = 18;
    const qtyWidth = 4;
    const amountWidth = 8;

    final qtyLabel = unitType == 'PACK' ? 'Pk' : 'Pc';
    final qtyStr = '$quantity$qtyLabel';
    final amountStr = totalPrice.toStringAsFixed(2);
    
    // Parenthetical unit rate if qty > 1
    final rateStr = (quantity > 1 && unitPrice > 0)
        ? ' (${unitPrice.toStringAsFixed(2)}/$qtyLabel)'
        : '';

    final nameLines = wrapText(name, width: itemWidth);
    if (nameLines.isEmpty) return '';

    final buffer = StringBuffer();

    // 1. Line 1: Item Name (first 18 chars) | QTY | AMOUNT
    final col1 = nameLines[0].padRight(itemWidth);
    final col2 = qtyStr.padLeft(qtyWidth);
    final col3 = amountStr.padLeft(amountWidth);
    buffer.write('$col1$col2$col3');

    // 2. Line 2 (if needed): Remainder of Item Name + rateStr
    final remainderName = nameLines.length > 1 ? nameLines.sublist(1).join(' ') : '';
    final line2Text = '$remainderName$rateStr'.trim();

    if (line2Text.isNotEmpty) {
      buffer.writeln();
      final wrappedLine2 = wrapText(line2Text, width: lineWidth);
      for (int i = 0; i < wrappedLine2.length; i++) {
        buffer.write(wrappedLine2[i]);
        if (i < wrappedLine2.length - 1) {
          buffer.writeln();
        }
      }
    }

    return buffer.toString();
  }

  /// Formats 2 Columns for Totals: Label (Left) and Value (Right) totaling 32 Chars
  static String formatTotalLine(String label, String value) {
    if (label.length + value.length >= lineWidth) {
      final maxLabelWidth = lineWidth - value.length - 1;
      final truncatedLabel = label.length > maxLabelWidth ? label.substring(0, maxLabelWidth) : label;
      final spaces = lineWidth - truncatedLabel.length - value.length;
      return '$truncatedLabel${' ' * (spaces > 0 ? spaces : 1)}$value';
    }
    final padding = lineWidth - label.length - value.length;
    return '$label${' ' * padding}$value';
  }

  /// Formats currency to ASCII "Rs." replacing unicode "₹" to prevent broken printer code pages
  static String formatCurrency(double amount) {
    final prefix = amount < 0 ? '-Rs.' : 'Rs.';
    return '$prefix${amount.abs().toStringAsFixed(2)}';
  }
}
