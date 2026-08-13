// This file is only ever compiled for web, via the conditional import in
// api_config.dart. The lint exists to stop web-only libraries leaking into
// mobile builds, which is exactly what that conditional import prevents.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Reads a key out of the `window.apiConfig` object injected at build time by
/// `build.js` (or at request time by `server.js`).
///
/// Returns null when the object is absent, the key is missing, or the value is
/// an empty string, so callers can treat "not configured" uniformly.
///
/// Note there are no `is`/`as` checks against JS types here: those are not
/// supported on interop types and behave differently between dart2js and
/// dart2wasm. `getProperty` carries the typing instead.
String? readWebApiConfig(String key) {
  try {
    final config = globalContext.getProperty<JSObject?>('apiConfig'.toJS);
    if (config == null) return null;

    final value = config.getProperty<JSAny?>(key.toJS)?.dartify();
    if (value is String && value.isNotEmpty) return value;
    return null;
  } catch (_) {
    return null;
  }
}
