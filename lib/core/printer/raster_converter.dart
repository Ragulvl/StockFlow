import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Converts an image into ESC/POS GS v 0 raster bit image bytes.
class RasterConverter {
  /// Transforms a decoded [img.Image] into raw ESC/POS raster bit image commands (`GS v 0`).
  static Uint8List toEscPosRaster(img.Image srcImage, {int targetWidth = 200}) {
    // 1. Resize preserving aspect ratio
    final resized = img.copyResize(srcImage, width: targetWidth);

    // 2. Grayscale conversion
    final grayscale = img.grayscale(resized);

    final width = grayscale.width;
    final height = grayscale.height;
    final bytesPerRow = (width + 7) ~/ 8;

    final bitmapData = <int>[];

    // 3. Thresholding & Bit-packing (MSB first)
    for (int y = 0; y < height; y++) {
      for (int xByte = 0; xByte < bytesPerRow; xByte++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final x = xByte * 8 + bit;
          if (x < width) {
            final pixel = grayscale.getPixel(x, y);
            final luminance = img.getLuminance(pixel);
            if (luminance < 128) {
              // Dark pixel -> Print dot
              byte |= (0x80 >> bit);
            }
          }
        }
        bitmapData.add(byte);
      }
    }

    // 4. Wrap with GS v 0 command
    const gs = 0x1D;
    final xL = bytesPerRow & 0xFF;
    final xH = (bytesPerRow >> 8) & 0xFF;
    final yL = height & 0xFF;
    final yH = (height >> 8) & 0xFF;

    final command = <int>[
      gs, 0x76, 0x30, 0x00, // GS v 0 0 (normal 1x1 scale)
      xL, xH, yL, yH,
      ...bitmapData,
    ];

    return Uint8List.fromList(command);
  }
}
