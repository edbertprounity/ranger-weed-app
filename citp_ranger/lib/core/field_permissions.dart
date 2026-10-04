import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class FieldPermissions {
  static Future<bool> camera() => _ask(Permission.camera);

  static Future<bool> photos() async {
    if (!_needsRuntime) return true;
    if (Platform.isAndroid) {
      final images = await Permission.photos.request();
      if (images.isGranted || images.isLimited) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> location() => _ask(Permission.locationWhenInUse);

  static bool get _needsRuntime {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static Future<bool> _ask(Permission permission) async {
    if (!_needsRuntime) return true;
    final status = await permission.request();
    return status.isGranted || status.isLimited;
  }
}
