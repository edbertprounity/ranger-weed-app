import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/device_location.dart';
import '../core/format.dart';
import '../core/priority.dart';
import '../core/species.dart';
import '../core/theme.dart';
import '../data/local/tile_cache.dart';
import '../data/models/treatment.dart';

class SiteMap extends StatefulWidget {
  const SiteMap({
    super.key,
    required this.views,
    required this.onOpen,
    this.expand = false,
    this.onPick,
  });

  final List<SiteView> views;
  final ValueChanged<SiteView> onOpen;
  final bool expand;
  final ValueChanged<LatLng>? onPick;

  @override
  State<SiteMap> createState() => _SiteMapState();
}

class _SiteMapState extends State<SiteMap> {
  final MapController _mapController = MapController();
  Directory? _tiles;
  SiteView? _hovered;
  LatLng? _device;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _openTileFolder();
  }

  Future<void> _openTileFolder() async {
    try {
      final root = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(root.path, 'citp_ranger_tiles'));
      if (!await folder.exists()) await folder.create(recursive: true);
      if (mounted) setState(() => _tiles = folder);
    } catch (_) {
      // The map can still open from the network.
    }
  }

  Future<void> _addMyLocation() async {
    setState(() => _locating = true);
    try {
      final fix = await readDeviceLocation();
      if (!mounted) return;
      final point = LatLng(fix.latitude, fix.longitude);
      setState(() => _device = point);
      _mapController.move(point, 15);
      widget.onPick?.call(point);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This device could not read a GPS fix. You can still tap the map.')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  static const _country = LatLng(-14.36, 143.68);

  @override
  Widget build(BuildContext context) {
    final views = widget.views;
    final onOpen = widget.onOpen;
    final plotted = <SiteView>[];
    final ranks = <int>[];
    final colors = <Color>[];
    final now = DateTime.now().toUtc();
    for (var i = 0; i < views.length; i++) {
      final view = views[i];
      if (!view.site.hasLocation) continue;
      plotted.add(view);
      ranks.add(i + 1);
      colors.add(switch (bandFor(view, now)) {
        PriorityBand.overdue => pinOverdue,
        PriorityBand.untreated => pinPending,
        PriorityBand.scheduled => pinClear,
      });
    }
    final points = [
      for (final view in plotted) LatLng(view.site.latitude!, view.site.longitude!),
    ];
    final map = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              key: widget.onPick == null
                  ? ValueKey(points.map((point) => '${point.latitude},${point.longitude}').join('|'))
                  : ValueKey(points.isEmpty ? 'empty' : 'placed'),
              options: MapOptions(
                initialCenter: points.isEmpty ? _country : points.first,
                initialZoom: points.length == 1 ? 14 : 11,
                onTap: widget.onPick == null ? null : (_, point) => widget.onPick!(point),
                initialCameraFit: points.length < 2
                    ? null
                    : CameraFit.coordinates(
                        coordinates: points,
                        padding: const EdgeInsets.all(48),
                        maxZoom: 14,
                      ),
                minZoom: 4,
                maxZoom: 18,
                backgroundColor: const Color(0xFFD5D0C4),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.scrollWheelZoom |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.flingAnimation,
                ),
              ),
              children: [
                if (kIsWeb)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.citp.prototype',
                    tileProvider: NetworkTileProvider(),
                  )
                else if (_tiles == null)
                  const ColoredBox(color: Color(0xFFD5D0C4))
                else
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.citp.prototype',
                    tileProvider: CachingTileProvider(_tiles!),
                  ),
                MarkerLayer(
                  markers: [
                    for (var i = 0; i < plotted.length; i++)
                      Marker(
                        point: points[i],
                        width: _hovered?.site.id == plotted[i].site.id ? 42 : 34,
                        height: _hovered?.site.id == plotted[i].site.id ? 42 : 34,
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hovered = plotted[i]),
                          onExit: (_) => setState(() => _hovered = null),
                          child: GestureDetector(
                            onTap: () => onOpen(plotted[i]),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors[i],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${ranks[i]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_device != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _device!,
                        width: 22,
                        height: 22,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF3D7EFF),
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 3)),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap'),
                  backgroundColor: Color(0xCC121212),
                ),
              ],
            ),
          ),
          if (_hovered != null)
            Positioned(
              left: 12,
              top: 12,
              child: _PinDetails(view: _hovered!),
            ),
          Positioned(
            right: 12,
            bottom: 28,
            child: Material(
              color: panel,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                tooltip: 'Add my location',
                onPressed: _locating ? null : _addMyLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.expand) Expanded(child: map) else SizedBox(height: 280, width: double.infinity, child: map),
        const SizedBox(height: 8),
        const Row(
          children: [
            _LegendDot(color: pinOverdue, label: 'Return'),
            SizedBox(width: 12),
            _LegendDot(color: pinPending, label: 'Treat'),
            SizedBox(width: 12),
            _LegendDot(color: pinClear, label: 'On schedule'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          kIsWeb
              ? 'Drag to move. Add my location uses this device’s GPS and does not need internet. The map picture does.'
              : plotted.isEmpty
              ? 'No located sites yet. Drag the map. Tiles opened here stay on this phone.'
              : 'Drag to move. Hover a pin for the site. Add my location uses GPS and works without internet.',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _PinDetails extends StatelessWidget {
  const _PinDetails({required this.view});

  final SiteView view;

  @override
  Widget build(BuildContext context) {
    final site = view.site;
    final now = DateTime.now();
    final band = bandFor(view, now.toUtc());
    final status = switch (band) {
      PriorityBand.overdue => followUpLabel(view.treatment!.nextCheckDue, now),
      PriorityBand.untreated => 'No spray on record',
      PriorityBand.scheduled => followUpLabel(view.treatment!.nextCheckDue, now),
    };
    return Material(
      color: const Color(0xF0121212),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              WeedSpecies.byKey(site.speciesKey)?.name ?? 'Unspecified',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(status, style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              formatPoint(site.latitude, site.longitude),
              style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
            ),
            Text(
              'Logged by ${site.rangerName}',
              style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}
