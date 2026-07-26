import 'dart:async';
import 'dart:typed_data';
import 'printer_adapter.dart';
import 'usb_printer_adapter.dart';

class PrintJob {
  final Uint8List data;
  final PrinterAdapter adapter;
  final Completer<bool> completer;

  PrintJob({
    required this.data,
    required this.adapter,
    required this.completer,
  });
}

/// Serial Mutex Queue Manager for Thermal ESC/POS Print Jobs
class PrintQueueManager {
  static final PrintQueueManager _instance = PrintQueueManager._internal();
  factory PrintQueueManager() => _instance;
  PrintQueueManager._internal();

  final List<PrintJob> _queue = [];
  bool _isProcessing = false;

  /// Enqueues a print job and returns a Future<bool> indicating hardware success/failure
  Future<bool> enqueuePrintJob(Uint8List dataBytes, {PrinterAdapter? adapter}) {
    final completer = Completer<bool>();
    _queue.add(PrintJob(
      data: dataBytes,
      adapter: adapter ?? UsbPrinterAdapter(),
      completer: completer,
    ));
    _processQueue();
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    final job = _queue.removeAt(0);

    try {
      final success = await job.adapter.printBytes(job.data).timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => false,
      );
      job.completer.complete(success);
    } catch (e) {
      job.completer.complete(false);
    } finally {
      _isProcessing = false;
      if (_queue.isNotEmpty) {
        scheduleMicrotask(_processQueue);
      }
    }
  }
}
