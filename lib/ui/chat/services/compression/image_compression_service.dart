import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

// 条件导入！
import 'image_compression_stub.dart' if (dart.library.js_interop) 'image_compression_web.dart';

class ImageCompressionService {
  static Future<XFile> compressForUpload(XFile file) async {
    try {
      final int size = await file.length();
      if (size < 500 * 1024) return file;

      if (kIsWeb) {
        return await compressWebCanvasImpl(file, quality: 0.8, maxWidth: 1920);
      } else {
        return await _compressMobile(file, 1920, 80);
      }
    } catch (e) { return file; }
  }

  /// Generate a tiny thumbnail from an XFile (reads the file internally).
  static Future<Uint8List> getTinyThumbnail(XFile file) async {
    try {
      if (kIsWeb) {
        final XFile tinyFile = await compressWebCanvasImpl(file, quality: 0.5, maxWidth: 200);
        return await tinyFile.readAsBytes();
      } else {
        final XFile tinyFile = await _compressMobile(file, 200, 50);
        return await tinyFile.readAsBytes();
      }
    } catch (e) { return Uint8List(0); }
  }

  /// Generate a tiny thumbnail directly from raw bytes, avoiding a second disk read.
  /// Used by sendImage after the file has already been read for other purposes.
  static Future<Uint8List> getTinyThumbnailFromBytes(Uint8List bytes) async {
    if (bytes.isEmpty) return Uint8List(0);
    try {
      if (kIsWeb) {
        // Web: wrap bytes in XFile and use the existing canvas implementation
        final tempFile = XFile.fromData(bytes, mimeType: 'image/jpeg');
        final tinyFile = await compressWebCanvasImpl(tempFile, quality: 0.5, maxWidth: 200);
        return await tinyFile.readAsBytes();
      } else {
        // Mobile: compress bytes in-memory without writing a temp file
        return await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 200,
          minHeight: 200,
          quality: 50,
          format: CompressFormat.jpeg,
        );
      }
    } catch (e) { return Uint8List(0); }
  }

  static Future<Uint8List?> captureWebVideoFrame(String blobUrl) async {
    return await captureWebVideoFrameImpl(blobUrl);
  }

  static Future<XFile> _compressMobile(XFile file, int minWidth, int quality) async {
    final String filePath = file.path;
    // Use p.withoutExtension to safely handle paths containing multiple dots
    // e.g. /data/user/0/com.app/1.2/image.png → correct base path extraction
    final String outPath = "${p.withoutExtension(filePath)}_opt_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
        filePath, outPath, minWidth: minWidth, minHeight: minWidth, quality: quality, format: CompressFormat.jpeg);
    return result ?? file;
  }
}