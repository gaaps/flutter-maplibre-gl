@JS()
library;

import 'dart:js_interop';

/// This class is a wrapper for the jsObject. All the specific JsObject
/// wrappers extend from it.
abstract class JsObjectWrapper<T> {
  /// JS object.
  final T jsObject;

  /// Creates a new JsObjectWrapper type from a [jsObject].
  JsObjectWrapper.fromJsObject(this.jsObject);
}

@JS('Object.keys')
external JSArray<JSString> _objectKeysJs(JSAny? obj);

/// Returns the keys of a JavaScript object as a Dart List&lt;String&gt;.
List<String> objectKeys(Object? obj) {
  if (obj == null) return [];
  final jsObj = obj as JSAny;
  return _objectKeysJs(jsObj).toDart.map((key) => key.toDart).toList();
}

/// Extension type to add property getter/setter to JSObject.
extension type JSObjectExt._(JSObject _) implements JSObject {
  external JSAny? operator [](String property);
  external void operator []=(String property, JSAny? value);
}

/// Helper function to get a property from a JavaScript object.
JSAny? getJsProperty(JSObject obj, String propertyName) {
  return (obj as JSObjectExt)[propertyName];
}

/// Helper function to set a property on a JavaScript object.
void setJsProperty(JSObject obj, String propertyName, JSAny? value) {
  (obj as JSObjectExt)[propertyName] = value;
}

/// Creates an empty JavaScript object literal.
@JS('Object.create')
external JSObject _createJsObject(JSAny? prototype);

/// Helper function to create an empty JavaScript object.
JSObject createJsObject() {
  return _createJsObject(null);
}

/// Parse a JSON string using JavaScript's native JSON.parse.
@JS('JSON.parse')
external JSAny jsonParse(String text);

/// Creates an empty JavaScript array.
@JS('Array')
external JSArray<T> _newJsArray<T extends JSAny?>();

/// Extension to add push method to JSArray.
extension JSArrayPush<T extends JSAny?> on JSArray<T> {
  external void push(T item);
}

/// Creates a JavaScript array from a list of JS objects.
/// This is a WASM-compatible alternative to List<JSAny?>.toJS
/// which has type inference issues in dart2wasm.
JSArray<T> jsArrayOf<T extends JSAny?>(List<T> items) {
  final arr = _newJsArray<T>();
  for (final item in items) {
    arr.push(item);
  }
  return arr;
}
