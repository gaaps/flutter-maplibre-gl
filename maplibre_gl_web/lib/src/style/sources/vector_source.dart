import 'dart:convert' show jsonEncode;
import 'dart:js_interop';
import 'package:maplibre_gl_web/src/interop/js.dart' show jsonParse;
import 'package:maplibre_gl_web/src/interop/style/sources/vector_source_interop.dart';
import 'package:maplibre_gl_web/src/style/sources/source.dart';

class VectorSource extends Source<VectorSourceJsImpl> {
  String? get url => jsObject.url;

  List<String>? get tiles =>
      jsObject.tiles.toDart.map((s) => s.toDart).toList();

  factory VectorSource({
    String? url,
    List<String>? tiles,
  }) {
    if (url != null && tiles != null) {
      throw Exception('Specify only one between url and tiles');
    }
    if (url != null) {
      return VectorSource.fromJsObject(VectorSourceJsImpl(
        type: 'vector',
        url: url,
      ));
    }
    return VectorSource.fromJsObject(VectorSourceJsImpl(
      type: 'vector',
      // Use JSON roundtrip for WASM compatibility - List.toJS has type issues in dart2wasm
      tiles: tiles != null ? jsonParse(jsonEncode(tiles)) as JSArray<JSString>? : null,
    ));
  }

  /// Creates a new VectorSource from a [jsObject].
  VectorSource.fromJsObject(super.jsObject) : super.fromJsObject();

  @override
  get dict {
    final dict = <String, dynamic>{
      'type': 'vector',
    };
    if (url != null) {
      dict['url'] = url;
    }
    if (tiles != null) {
      dict['tiles'] = tiles;
    }
    return dict;
  }
}
