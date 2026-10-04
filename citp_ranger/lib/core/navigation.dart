import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'format.dart';

/// Opens the device maps app on a driving route to the site.
/// The in-app plot stays available when the phone has no tiles.
Future<void> openSiteDirections(
  BuildContext context, {
  required double latitude,
  required double longitude,
  required String label,
}) async {
  final candidates = <Uri>[
    if (Platform.isAndroid) Uri.parse('google.navigation:q=$latitude,$longitude&mode=d'),
    if (Platform.isAndroid) Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude'),
    if (Platform.isIOS) Uri.parse('http://maps.apple.com/?daddr=$latitude,$longitude'),
    if (Platform.isWindows) Uri.parse('bingmaps:?rtp=~pos.${latitude}_$longitude'),
    Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    ),
  ];
  for (final uri in candidates) {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return;
    } catch (_) {
      // Try the next maps app.
    }
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Maps did not open. The fix is still ${formatPoint(latitude, longitude)} ($label).'),
    ),
  );
}
