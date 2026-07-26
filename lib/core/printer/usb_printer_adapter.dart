import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:usb_serial/usb_serial.dart';
import '../logger/app_logger.dart';
import 'printer_adapter.dart';

/// USB Thermal Printer Adapter implementing transient Open-Write-Flush-Close lifecycle
class UsbPrinterAdapter implements PrinterAdapter {
  static const MethodChannel _nativeChannel = MethodChannel("com.stockflow.stockflow/usb_printer");
  static const int targetVid = 0x0456; // 1110
  static const int targetPid = 0x0808; // 2056

  final UsbDevice? _specificDevice;

  UsbPrinterAdapter([this._specificDevice]);

  @override
  String get name => _specificDevice?.deviceName ?? 'USB ESC/POS Printer';

  @override
  String get connectionType => 'USB';

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      final List<dynamic>? devices = await _nativeChannel.invokeListMethod('getConnectedUsbDevices');
      if (devices != null && devices.isNotEmpty) return true;
      final serialDevices = await UsbSerial.listDevices();
      return serialDevices.isNotEmpty;
    } catch (e) {
      AppLogger.warning("Error checking USB printer availability", e, "UsbPrinterAdapter");
      return false;
    }
  }

  @override
  Future<bool> printBytes(Uint8List bytes) async {
    if (!Platform.isAndroid) {
      AppLogger.info("Non-Android platform detected: Simulating receipt printing for ${bytes.length} bytes", "UsbPrinterAdapter");
      return true; // Simulate successful receipt printing on desktop development environment
    }

    // 1. Try Native Android USB BulkTransfer Channel First (Supported on Hoin HOP-H58 & Class 7 USB Printers)
    try {
      final Map<String, dynamic> args = {
        'bytes': bytes,
        'vendorId': _specificDevice?.vid,
        'productId': _specificDevice?.pid,
        'deviceName': _specificDevice?.deviceName,
      };

      final bool? success = await _nativeChannel.invokeMethod<bool>('printRawBytes', args);
      if (success == true) {
        AppLogger.info("Native USB BulkTransfer printed ${bytes.length} bytes successfully on $name", "UsbPrinterAdapter");
        return true;
      }
    } catch (e) {
      AppLogger.warning("Native USB channel exception, trying UsbSerial fallback: $e", "UsbPrinterAdapter");
    }

    // 2. Fallback to UsbSerial driver
    return _printViaUsbSerial(bytes);
  }

  Future<bool> _printViaUsbSerial(Uint8List bytes) async {
    UsbPort? port;
    try {
      final devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        throw Exception("No USB devices found");
      }

      UsbDevice? targetDevice = _specificDevice;
      if (targetDevice == null) {
        // 1. Check for exact match (VID 0x0456 : PID 0x0808) or known thermal printer VIDs
        const knownPrinterVids = [0x0456, 0x0416, 0x0483, 0x1a86, 0x0403, 0x10c4, 0x04b8, 0x0dd4];
        try {
          targetDevice = devices.firstWhere(
            (d) => (d.vid == targetVid && d.pid == targetPid) || (d.vid != null && knownPrinterVids.contains(d.vid)),
          );
        } catch (_) {
          // 2. Fallback: Exclude USB hubs (VID 0x5e3, 0xbda, 0x343c)
          try {
            targetDevice = devices.firstWhere(
              (d) => d.vid != 0x5e3 && d.vid != 0xbda && d.vid != 0x343c,
            );
          } catch (_) {
            targetDevice = devices.first;
          }
        }
      }

      AppLogger.info("Opening USB printer endpoint: ${targetDevice.deviceName} (VID: ${targetDevice.vid}, PID: ${targetDevice.pid})", "UsbPrinterAdapter");

      port = await targetDevice.create();
      if (port == null) {
        throw Exception("Could not create USB port driver for ${targetDevice.deviceName}");
      }

      bool openResult = false;
      try {
        openResult = await port.open();
      } catch (_) {}

      // Retry open once after short delay if Android USB permission prompt was pending
      if (!openResult) {
        await Future.delayed(const Duration(milliseconds: 350));
        try {
          openResult = await port.open();
        } catch (_) {}
      }

      if (!openResult) {
        throw Exception("Failed to open USB port handle for ${targetDevice.deviceName}");
      }

      try {
        await port?.setDTR(true);
        await port?.setRTS(true);
      } catch (e) {
        AppLogger.warning("DTR/RTS not supported on printer endpoint", e, "UsbPrinterAdapter");
      }

      try {
        await port?.setPortParameters(
          9600,
          UsbPort.DATABITS_8,
          UsbPort.STOPBITS_1,
          UsbPort.PARITY_NONE,
        );
      } catch (e) {
        AppLogger.warning("Port parameters not supported on printer endpoint", e, "UsbPrinterAdapter");
      }

      await port?.write(bytes);
      await Future.delayed(const Duration(milliseconds: 300)); // Buffer flush delay

      AppLogger.info("Successfully flushed ${bytes.length} bytes to USB printer", "UsbPrinterAdapter");
      return true;
    } catch (e, stack) {
      AppLogger.error("Failed to print via USB adapter", e, stack, "UsbPrinterAdapter");
      return false;
    } finally {
      try {
        await port?.close();
      } catch (_) {}
    }
  }
}
