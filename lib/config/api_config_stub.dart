/// Non-web implementation: there is no `window.apiConfig`, so always null.
///
/// Kept as the default target of the conditional import in `api_config.dart`
/// so that mobile builds never reach for `dart:js_interop`.
String? readWebApiConfig(String key) => null;
