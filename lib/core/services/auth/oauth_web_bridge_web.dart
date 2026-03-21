import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web_pkg;

String safeWebOrigin() {
  try {
    return web_pkg.window.location.origin;
  } catch (_) {
    return 'unknown';
  }
}

String? getJsGsiInitKey() {
  try {
    final value =
        (web_pkg.window as JSObject).getProperty<JSAny?>('__gsiInitKey'.toJS);
    if (value == null) return null;
    return (value as JSString).toDart;
  } catch (_) {
    return null;
  }
}

void setJsGsiInitKey(String value) {
  try {
    (web_pkg.window as JSObject).setProperty('__gsiInitKey'.toJS, value.toJS);
  } catch (_) {
    // ignore bridge failures; init still works without this cache
  }
}

