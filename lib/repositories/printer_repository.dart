import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import '../core/logger/app_logger.dart';
import '../core/printer/print_queue.dart';
import '../core/printer/printer_adapter.dart';
import '../core/printer/usb_printer_adapter.dart';

class PrinterRepository {
  final PrintQueueManager _queueManager;
  PrinterAdapter _activeAdapter;

  PrinterRepository(this._queueManager, [PrinterAdapter? adapter])
      : _activeAdapter = adapter ?? UsbPrinterAdapter();

  PrinterAdapter get activeAdapter => _activeAdapter;

  void setActiveAdapter(PrinterAdapter adapter) {
    AppLogger.info("Switching printer adapter to ${adapter.name} (${adapter.connectionType})", "PrinterRepository");
    _activeAdapter = adapter;
  }

  Future<bool> checkPrinterAvailable() async {
    return _activeAdapter.isAvailable();
  }

  Future<List<UsbDevice>> getConnectedUsbDevices() async {
    try {
      return await UsbSerial.listDevices();
    } catch (e) {
      AppLogger.warning("Error listing USB devices", e, "PrinterRepository");
      return [];
    }
  }

  /// Dispatches print bytes to serial mutex queue manager
  Future<bool> printReceiptBytes(Uint8List bytes) async {
    AppLogger.info("Enqueuing ${bytes.length} receipt bytes for printing using ${_activeAdapter.name}", "PrinterRepository");
    return _queueManager.enqueuePrintJob(bytes, adapter: _activeAdapter);
  }
}
