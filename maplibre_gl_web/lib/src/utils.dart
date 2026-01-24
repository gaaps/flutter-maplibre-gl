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
///
/// This function handles WASM compatibility issues where 'is List' checks
/// can fail even for actual List objects in dart2wasm.
JSAny? jsify(Object? dartObject) {
  print('[maplibre_gl] jsify: input type=${dartObject.runtimeType}');

  if (dartObject == null) return null;
  if (dartObject is String) return dartObject.toJS;
  if (dartObject is num) return dartObject.toJS;
  if (dartObject is bool) return dartObject.toJS;

  // Check if it's already a JSAny (including JSArray from JS interop)
  // ignore: invalid_runtime_check_with_js_interop_types
  if (dartObject is JSAny) {
    print('[maplibre_gl] jsify: already JSAny, returning as-is');
    return dartObject;
  }

  // For objects that already have jsObject property (like Layer, Source wrappers)
  if (dartObject is JsObjectWrapper) {
    print('[maplibre_gl] jsify: JsObjectWrapper, extracting jsObject');
    return dartObject.jsObject as JSAny;
  }

  if (dartObject is Map) {
    print('[maplibre_gl] jsify: handling as Map');
    return jsifyMap(Map<String, dynamic>.from(dartObject));
  }

  // Check for List explicitly first
  if (dartObject is List) {
    print('[maplibre_gl] jsify: handling as List');
    return _jsifyList(dartObject);
  }

  // Check for other Iterables
  if (dartObject is Iterable) {
    print('[maplibre_gl] jsify: handling as Iterable');
    return _jsifyList(dartObject.toList());
  }

  // WASM fallback: try to iterate on any unknown object
  // In dart2wasm, 'is List' checks can fail even for actual List objects
  // so we try iteration before falling back to JSON
  print('[maplibre_gl] jsify: fallback iteration for ${dartObject.runtimeType}');
  try {
    final asDynamic = dartObject as dynamic;
    // Try to iterate - this works for lists even when 'is List' fails
    return _jsifyListDynamic(asDynamic);
  } catch (e) {
    // Not iterable, fall through
    print('[maplibre_gl] jsify: iteration failed: $e');
  }

  // Fallback: try JSON roundtrip for any JSON-serializable object
  print('[maplibre_gl] jsify: using JSON roundtrip');
  try {
    return jsonParse(jsonEncode(dartObject));
  } catch (e) {
    // Last resort: assume it's already a JSAny
    print('[maplibre_gl] jsify: JSON roundtrip failed: $e, attempting cast');
    return dartObject as JSAny?;
  }
}

/// Converts a Dart List to a JavaScript array by building it element by element.
/// This avoids issues with List.toJS in dart2wasm.
JSArray<JSAny?> _jsifyList(List<dynamic> list) {
  final jsArray = <JSAny?>[];
  for (final item in list) {
    jsArray.add(jsify(item));
  }
  return jsArrayOf(jsArray);
}

/// Converts a dynamic list-like object to a JavaScript array.
/// Used as a fallback when 'is List' checks fail in WASM.
JSAny _jsifyListDynamic(dynamic listLike) {
  final jsArray = <JSAny?>[];
  for (final item in listLike) {
    jsArray.add(jsify(item));
  }
  return jsArrayOf(jsArray);
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
