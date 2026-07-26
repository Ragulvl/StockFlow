/// Helper utility to convert numeric currency values to words format (Indian Rupees format)
class NumberToWords {
  static const List<String> _units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const List<String> _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static String convertToWords(double amount) {
    if (amount <= 0) return 'Rupees Zero Only';

    final int integerPart = amount.floor();
    final int paisaPart = ((amount - integerPart) * 100).round();

    String words = _convertInteger(integerPart);
    words = words.trim();

    if (paisaPart > 0) {
      final String paisaWords = _convertInteger(paisaPart).trim();
      return 'Rupees $words and $paisaWords Paisa Only';
    }

    return 'Rupees $words Only';
  }

  static String _convertInteger(int n) {
    if (n == 0) return 'Zero';
    if (n < 20) return _units[n];
    if (n < 100) return '${_tens[n ~/ 10]} ${_units[n % 10]}';
    if (n < 1000) return '${_units[n ~/ 100]} Hundred ${_convertInteger(n % 100)}';
    if (n < 100000) return '${_convertInteger(n ~/ 1000)} Thousand ${_convertInteger(n % 1000)}';
    if (n < 10000000) return '${_convertInteger(n ~/ 100000)} Lakh ${_convertInteger(n % 100000)}';
    return '${_convertInteger(n ~/ 10000000)} Crore ${_convertInteger(n % 10000000)}';
  }
}
