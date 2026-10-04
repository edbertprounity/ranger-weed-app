import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Turns a stored `file://` path or a plain path into a filesystem path.
String resolvePhotoPath(String stored) {
  if (stored.startsWith('file:')) return Uri.parse(stored).toFilePath();
  return stored;
}

class PhotoStore {
  Future<Directory> _folder() async {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(root.path, 'citp_ranger_photos'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  Future<String> copyIn(String id, String sourcePath) async {
    final bytes = await File(resolvePhotoPath(sourcePath)).readAsBytes();
    return writeCompressed(id, bytes);
  }

  /// Resize and compress, then write under the app documents folder.
  /// The returned value is a `file://` URI stored in SQLite.
  Future<String> writeCompressed(String id, List<int> bytes) async {
    final jpg = _compress(bytes);
    final folder = await _folder();
    final dest = File(p.join(folder.path, '$id.jpg'));
    await dest.writeAsBytes(jpg, flush: true);
    return Uri.file(dest.path).toString();
  }

  Future<String> writeBytes(String id, List<int> bytes) => writeCompressed(id, bytes);

  Future<void> deleteIfPresent(String? stored) async {
    if (stored == null || stored.isEmpty) return;
    final file = File(resolvePhotoPath(stored));
    if (await file.exists()) await file.delete();
  }
}

Uint8List _compress(List<int> bytes, {int maxSide = 1600, int quality = 70}) {
  final decoded = img.decodeImage(Uint8List.fromList(bytes));
  if (decoded == null) return Uint8List.fromList(bytes);
  final longest = math.max(decoded.width, decoded.height);
  final fitted = longest <= maxSide
      ? decoded
      : decoded.width >= decoded.height
      ? img.copyResize(decoded, width: maxSide)
      : img.copyResize(decoded, height: maxSide);
  return Uint8List.fromList(img.encodeJpg(fitted, quality: quality));
}
