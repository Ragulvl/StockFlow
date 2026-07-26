import 'dart:typed_data';

/// Abstract hardware printer interface allowing pluggable USB, Bluetooth, or Network implementations
abstract class PrinterAdapter {
  String get name;
  String get connectionType; // USB, BLUETOOTH, NETWORK

  Future<bool> isAvailable();
  Future<bool> printBytes(Uint8List bytes);
}
