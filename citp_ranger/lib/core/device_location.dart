import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'field_permissions.dart';

class DeviceFix {
  const DeviceFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
}

/// Reads the device GPS. A phone can do this with no internet connection.
Future<DeviceFix> readDeviceLocation() async {
  if (!kIsWeb) {
    final allowed = await FieldPermissions.location();
    if (!allowed) throw StateError('denied');
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw StateError('off');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw StateError('denied');
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
  return DeviceFix(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracy: position.accuracy,
  );
}
