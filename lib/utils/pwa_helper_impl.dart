// dart:js_interop bridge for PWA signals set by pwa_sw.js / index.html
// This file is imported only from pwa_helper.dart via the _WebPwa class.
// It should not be imported directly elsewhere.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

abstract class _PwaJs {
  /// Returns true if window.__pwaInstallReady === true
  static bool get isInstallReady {
    try {
      final v = (web.window as JSObject).getProperty('__pwaInstallReady'.toJS);
      if (v.isUndefinedOrNull) return false;
      return (v as JSBoolean).toDart;
    } catch (_) {
      return false;
    }
  }

  /// Calls window.triggerPwaInstall() and returns the result
  static bool triggerInstall() {
    try {
      final fn = (web.window as JSObject).getProperty('triggerPwaInstall'.toJS);
      if (fn.isUndefinedOrNull) return false;
      final result = (web.window as JSObject).callMethod('triggerPwaInstall'.toJS);
      if (result.isUndefinedOrNull) return false;
      return (result as JSBoolean).toDart;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if window.__pwaUpdateReady === true
  static bool get isUpdateReady {
    try {
      final v = (web.window as JSObject).getProperty('__pwaUpdateReady'.toJS);
      if (v.isUndefinedOrNull) return false;
      return (v as JSBoolean).toDart;
    } catch (_) {
      return false;
    }
  }

  /// Reloads the page to apply a new SW version
  static void reload() {
    try {
      web.window.location.reload();
    } catch (_) {}
  }

  /// Returns true if running in standalone (installed PWA) mode
  static bool get isStandalone {
    try {
      final mql = web.window.matchMedia('(display-mode: standalone)');
      return mql.matches;
    } catch (_) {
      return false;
    }
  }
}

