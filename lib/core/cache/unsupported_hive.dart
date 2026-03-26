// Stub file for Hive when building for web
class Box {
  Future<void> put(String key, String value) async {}
  String? get(String key) => null;
  Future<void> delete(String key) async {}
  Future<void> clear() async {}
}

class Hive {
  static Future<void> initFlutter() async {}
  static Future<Box> openBox(String name) async => Box();
}