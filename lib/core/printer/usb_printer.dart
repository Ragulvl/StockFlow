import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';

class UsbPrinterDevice {
  final String deviceName;
  final int vendorId;
  final int productId;

  UsbPrinterDevice({
    required this.deviceName,
    required this.vendorId,
    required this.productId,
  });
}

/// USB ESC/POS Hardware Device Adapter implementing Transient Connection Lifecycle
class UsbPrinterAdapter {
  // Target Default Thermal Printer VID/PID
  static const int targetVid = 0x0456; // 1110
  static const int targetPid = 0x0808; // 2056

  /// Scan connected USB devices for thermal printers
  static Future<List<UsbDevice>> getConnectedUsbDevices() async {
    try {
      final devices = await UsbSerial.listDevices();
      return devices;
    } catch (e) {
      return [];
    }
  }

  /// Sends raw ESC/POS byte array to USB Printer using transient Open-Write-Flush-Close lifecycle
  static Future<bool> printBytes(Uint8List bytes, {UsbDevice? specificDevice}) async {
    UsbPort? port;
    try {
      final devices = await getConnectedUsbDevices();
      if (devices.isEmpty) {
        throw Exception("No USB devices found");
      }

      // 1. Select Printer Device (Match VID/PID or pick specified/first available device)
      UsbDevice? targetDevice = specificDevice;
      if (targetDevice == null) {
        targetDevice = devices.firstWhere(
          (d) => d.vid == targetVid && d.pid == targetPid,
          orElse: () => devices.first,
        );
      }

      // 2. Open Handle
      port = await targetDevice.create();
      final bool openResult = await port?.open() ?? false;
      if (!openResult) {
        throw Exception("Failed to open USB printer port");
      }

      // 3. Configure Serial Parameters
      await port?.setDTR(true);
      await port?.setRTS(true);
      await port?.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      // 4. Bulk Write Bytes
      await port?.write(bytes);

      // 5. 200ms Buffer Flush Delay to prevent buffer corruption
      await Future.delayed(const Duration(milliseconds: 200));

      return true;
    } catch (e) {
      return false;
    } finally {
      // 6. Close Handle to free USB endpoint
      try {
        await port?.close();
      } catch (_) {}
    }
  }
}
