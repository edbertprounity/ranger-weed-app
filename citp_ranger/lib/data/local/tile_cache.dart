import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

/// Saves each opened map tile under the app documents folder.
/// A later visit with no connection still draws the tiles already stored.
class CachingTileProvider extends TileProvider {
  CachingTileProvider(this.directory);

  final Directory directory;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    final file = File(
      '${directory.path}/${coordinates.z}/${coordinates.x}/${coordinates.y}.png',
    );
    return _StoredTileImage(url, file, Map<String, String>.from(headers));
  }
}

class _StoredTileImage extends ImageProvider<_StoredTileImage> {
  const _StoredTileImage(this.url, this.file, this.headers);

  final String url;
  final File file;
  final Map<String, String> headers;

  @override
  Future<_StoredTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_StoredTileImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(_StoredTileImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1,
      informationCollector: () => [DiagnosticsProperty('URL', url)],
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    Uint8List bytes;
    if (await file.exists()) {
      bytes = await file.readAsBytes();
    } else {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        headers.forEach(request.headers.set);
        final response = await request.close();
        if (response.statusCode != 200) {
          throw StateError('Tile request failed');
        }
        bytes = await consolidateHttpClientResponseBytes(response);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
      } finally {
        client.close(force: true);
      }
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) {
    return other is _StoredTileImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
