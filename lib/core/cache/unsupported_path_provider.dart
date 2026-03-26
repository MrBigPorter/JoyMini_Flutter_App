// Stub implementation for path_provider when building for web
// Web browsers do not have direct file system access, so these methods return null or throw.

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Stub Directory class for web platform
class Directory {
  final String? path;
  
  Directory([this.path]);
  
  Future<Directory> create({bool recursive = false}) async => this;
  
  Future<bool> exists() async => false;
  
  Directory get absolute => this;
  
  @override
  String toString() => 'Directory($path)';
}

/// Stub File class for web platform  
class File {
  final String path;
  
  File(this.path);
  
  Future<bool> exists() async => false;
  
  Future<File> create({bool recursive = false}) async => this;
  
  Future<String> readAsString() async => '';
  
  Future<File> writeAsString(String contents) async => this;
  
  Future<void> delete() async {}
  
  @override
  String toString() => 'File($path)';
}

/// Web-compatible path_provider implementation
class UnsupportedPathProvider {
  /// Web does not have application support directory
  static Future<Directory?> getApplicationSupportDirectory() async {
    if (kIsWeb) {
      debugPrint('[PathProvider] Web platform does not support getApplicationSupportDirectory, returning null');
      return null;
    }
    // This should never be called on non-web platforms
    throw UnsupportedError('This stub should only be used on web platform');
  }

  /// Web does not have temporary directory in traditional sense
  static Future<Directory?> getTemporaryDirectory() async {
    if (kIsWeb) {
      debugPrint('[PathProvider] Web platform does not support getTemporaryDirectory, returning null');
      return null;
    }
    throw UnsupportedError('This stub should only be used on web platform');
  }

  /// Web does not have application documents directory  
  static Future<Directory?> getApplicationDocumentsDirectory() async {
    if (kIsWeb) {
      debugPrint('[PathProvider] Web platform does not support getApplicationDocumentsDirectory, returning null');
      return null;
    }
    throw UnsupportedError('This stub should only be used on web platform');
  }

  /// Web does not have downloads directory
  static Future<Directory?> getDownloadsDirectory() async {
    if (kIsWeb) {
      debugPrint('[PathProvider] Web platform does not support getDownloadsDirectory, returning null');
      return null;
    }
    throw UnsupportedError('This stub should only be used on web platform');
  }

  /// Web does not have external storage
  static Future<Directory?> getExternalStorageDirectory() async {
    if (kIsWeb) {
      debugPrint('[PathProvider] Web platform does not support getExternalStorageDirectory, returning null');
      return null;
    }
    throw UnsupportedError('This stub should only be used on web platform');
  }
}