import 'dart:convert' show jsonEncode;
import 'dart:js_interop';
import 'interop/js.dart';

/// Returns Dart representation from JS Object.
dynamic dartify(Object? jsObject) {
  if (_isBasicType(jsObject)) {
    return jsObject;
  }

  // Convert JSAny types to Dart primitives
  // ignore: invalid_runtime_check_with_js_interop_types
  if (jsObject is JSAny) {
    if (jsObject.isA<JSBoolean>()) {
      return (jsObject as JSBoolean).toDart;
    }

    if (jsObject.isA<JSNumber>()) {
      return (jsObject as JSNumber).toDartDouble;
    }

    if (jsObject.isA<JSString>()) {
      return (jsObject as JSString).toDart;
    }
  }

  // Handle list
  if (jsObject is Iterable) {
    return jsObject.map(dartify).toList();
  }

  // Assume a map then...
  return dartifyMap(jsObject);
}

/// Returns `true` if the [value] is a very basic built-in type - e.g.
/// `null`, [num], [bool] or [String]. It returns `false` in the other case.
bool _isBasicType(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return true;
  }
  return false;
}

Map<String, dynamic> dartifyMap(Object? jsObject) {
  if (jsObject == null) return {};

  final keys = objectKeys(jsObject);
  final map = <String, dynamic>{};
  for (final key in keys) {
    final value = getJsProperty(jsObject as JSObject, key);
    map[key] = dartify(value);
  }
  return map;
}

/// Converts a Dart object to a JavaScript object.
JSAny? jsify(Object? dartObject) {
  if (dartObject == null) return null;
  if (dartObject is String) return dartObject.toJS;
  if (dartObject is num) return dartObject.toJS;
  if (dartObject is bool) return dartObject.toJS;
  // Check for List first, then Iterable as fallback
  // Use JSON roundtrip for reliable WASM compatibility
  // Direct .toJS on List<JSAny?> has type issues in dart2wasm
  if (dartObject is List) {
    return jsonParse(jsonEncode(dartObject));
  }
  if (dartObject is Iterable) {
    return jsonParse(jsonEncode(dartObject.toList()));
  }
  if (dartObject is Map) {
    return jsifyMap(Map<String, dynamic>.from(dartObject));
  }
  // For objects that already have jsObject property (like Layer, Source wrappers)
  if (dartObject is JsObjectWrapper) {
    return dartObject.jsObject as JSAny;
  }
  // Check if it's already a JS value (JSAny)
  // ignore: invalid_runtime_check_with_js_interop_types
  if (dartObject is JSAny) {
    return dartObject;
  }
  // Fallback: try to encode as JSON if possible
  try {
    return jsonParse(jsonEncode(dartObject));
  } catch (_) {
    // Last resort: this may fail for non-JS types
    return dartObject as JSAny?;
  }
}

/// Converts a Dart Map to a JavaScript object.
JSObject jsifyMap(Map<String, dynamic> map) {
  final jsObj = createJsObject();
  map.forEach((key, value) {
    final jsValue = jsify(value);
    setJsProperty(jsObj, key, jsValue);
  });
  return jsObj;
}
