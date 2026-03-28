import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cross_file/cross_file.dart';
import 'asset_store.dart';

class PlatformAssetStore implements AssetStore {
  String _docPath = '';

  @override
  String get basePath => _docPath;

  @override
  Future<void> init() async {
    if (kIsWeb) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      _docPath = dir.path;
    } catch (e) {
      // Handle MissingPluginException or other path_provider errors
      // This can happen during testing or if plugin is not properly initialized
      debugPrint('[PlatformAssetStore] Failed to get documents directory: $e');
      // Use a fallback approach - try to get temporary directory instead
      try {
        final tempDir = await getTemporaryDirectory();
        _docPath = tempDir.path;
        debugPrint('[PlatformAssetStore] Using temporary directory as fallback: $_docPath');
      } catch (fallbackError) {
        debugPrint('[PlatformAssetStore] Fallback also failed: $fallbackError');
        // Set a default path or leave empty - the app can still function
        _docPath = '';
      }
    }
  }

  @override
  Future<void> saveFile(XFile source, String fileName, String subDir) async {
    if (kIsWeb) return;

    final targetDir = Directory(p.join(_docPath, subDir));
    if (!targetDir.existsSync()) targetDir.createSync(recursive: true);
    final targetPath = p.join(targetDir.path, fileName);
    await File(source.path).copy(targetPath);
  }

  @override
  bool existsSync(String fullPath) {
    if (kIsWeb) return true;

    return fullPath.isNotEmpty && File(fullPath).existsSync();
  }

  @override
  Future<String?> getCachedAvatarPath(String key) async {
    if (kIsWeb) return null;

    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'group_avatars', '$key.png');
    return File(path).existsSync() ? path : null;
  }

  @override
  Future<void> saveAvatar(String key, Uint8List bytes) async {
    if (kIsWeb) return;

    final dir = await getTemporaryDirectory();
    final avatarDir = Directory(p.join(dir.path, 'group_avatars'));
    if (!avatarDir.existsSync()) avatarDir.createSync(recursive: true);
    await File(p.join(avatarDir.path, '$key.png')).writeAsBytes(bytes);
  }
}