// Web平台专用实现：从 URL 查询参数读取 ?type
// 条件导入：仅在 Web 平台编译
//
// 使用 package:web + dart:js_interop（Dart 3.6+ 的官方 Web 互操作），
// 不再依赖已废弃的 dart:html。

import 'package:web/web.dart' as web;

class TestModeServiceWeb {
  /// 从当前 URL 查询参数中获取 `type` 的值。
  /// 例如：/?type=test → 返回 'test'
  /// 如果参数不存在则返回 null。
  static String? getTypeParam() {
    try {
      final search = web.window.location.search;
      if (search.isEmpty) return null;
      final queryString = search.startsWith('?') ? search.substring(1) : search;
      final params = Uri.splitQueryString(queryString);
      return params['type'];
    } catch (e) {
      return null;
    }
  }
}
