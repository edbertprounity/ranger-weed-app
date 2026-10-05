import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/device_location.dart';
import '../../core/field_permissions.dart';
import '../../core/role.dart';
import '../../core/species.dart';
import '../../core/theme.dart';
import '../../data/models/site.dart';
import '../../data/models/treatment.dart';
import '../../state/app_controller.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/site_map.dart';
import '../../widgets/site_photo.dart';

class SiteFormScreen extends StatefulWidget {
  const SiteFormScreen({super.key, this.siteId});

  final String? siteId;

  @override
  State<SiteFormScreen> createState() => _SiteFormScreenState();
}

class _SiteFormScreenState extends State<SiteFormScreen> {
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lng = TextEditingController();
  Site? _site;
  bool _locating = false;
  bool _saving = false;
  double? _accuracy;
  bool _placedByHand = false;
  Future<void> _writes = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final controller = context.read<AppController>();
    final existing = widget.siteId == null ? null : controller.siteById(widget.siteId!);
    final site = existing ?? await controller.createDraft();
    if (!mounted) return;
    _notes.text = site.notes;
    _lat.text = site.latitude?.toStringAsFixed(5) ?? '';
    _lng.text = site.longitude?.toStringAsFixed(5) ?? '';
    setState(() => _site = site);
  }

  @override
  void dispose() {
    _notes.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final site = _site;
    if (site == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final controller = context.watch<AppController>();
    final current = controller.siteById(site.id) ?? site;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) return;
        await _writes;
        final saved = controller.siteById(site.id);
        if (saved != null &&
            saved.status == SiteStatus.draft &&
            (controller.role == AppRole.public || _isBlank(saved))) {
          await controller.discardDraft(saved.id);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: BrandTitle(controller.role == AppRole.public ? 'Report a weed' : 'Log infestation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            controller.role == AppRole.public
                ? 'Send the report. It is reviewed before it is listed.'
                : 'Draft saved on this phone as you go.',
          ),
          const SizedBox(height: 16),
          Text('Species', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final species in WeedSpecies.all)
                ChoiceChip(
                  label: Text(species.name),
                  selected: current.speciesKey == species.key,
                  onSelected: (_) => _update(current.copyWith(speciesKey: species.key)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SitePhoto(site: current),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Photo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _locating ? null : _useLocation,
            icon: _locating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: const Text('Add my location'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Uses this device’s GPS. A phone can do this with no internet.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          if (_gpsLabel != null) ...[
            const SizedBox(height: 10),
            _GpsBadge(label: _gpsLabel!, tone: _gpsTone),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: SiteMap(
              views: current.hasLocation ? [SiteView(site: current)] : const [],
              expand: true,
              onOpen: (_) {},
              onPick: (point) => _placePin(current, point),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap the map to place or correct the pin if the GPS drifts.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  onChanged: (_) => _saveCoordinates(current),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lng,
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  onChanged: (_) => _saveCoordinates(current),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Notes'),
            onChanged: (value) => _update(current.copyWith(notes: value)),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : () => _publish(current),
            child: Text(
              context.read<AppController>().role == AppRole.public
                  ? 'Submit for review'
                  : 'Add to the list',
            ),
          ),
          TextButton(
            onPressed: () => _discard(current),
            child: const Text('Discard draft'),
          ),
        ],
      ),
    ),
    );
  }

  bool _isBlank(Site site) {
    return site.speciesKey.isEmpty &&
        site.notes.trim().isEmpty &&
        !site.hasLocation &&
        (site.photoPath == null || site.photoPath!.isEmpty);
  }

  Future<void> _update(Site site) {
    setState(() => _site = site);
    _writes = _writes.then((_) async {
      if (!mounted) return;
      await context.read<AppController>().saveSite(site);
    });
    return _writes;
  }

  void _saveCoordinates(Site site) {
    final latText = _lat.text.trim();
    final lngText = _lng.text.trim();
    final lat = latText.isEmpty ? null : double.tryParse(latText);
    final lng = lngText.isEmpty ? null : double.tryParse(lngText);
    if (latText.isNotEmpty && lat == null) return;
    if (lngText.isNotEmpty && lng == null) return;
    if (lat != null && (lat < -90 || lat > 90)) return;
    if (lng != null && (lng < -180 || lng > 180)) return;
    _update(site.copyWith(latitude: lat, longitude: lng));
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final site = _site;
    if (site == null) return;
    final allowed = source == ImageSource.camera
        ? await FieldPermissions.camera()
        : await FieldPermissions.photos();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera or photo access is needed to attach a picture.')),
      );
      return;
    }
    try {
      final shot = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (shot == null || !mounted) return;
      final bytes = await shot.readAsBytes();
      _writes = _writes.then((_) async {
        if (!mounted) return;
        await context.read<AppController>().attachPhotoBytes(site.id, bytes);
      });
      await _writes;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open a photo. Try the other button.')),
      );
    }
  }

  void _placePin(Site site, LatLng point) {
    _lat.text = point.latitude.toStringAsFixed(5);
    _lng.text = point.longitude.toStringAsFixed(5);
    setState(() => _placedByHand = true);
    _update(site.copyWith(latitude: point.latitude, longitude: point.longitude));
  }

  String? get _gpsLabel {
    if (_placedByHand) return 'Pin placed on the map';
    final meters = _accuracy;
    if (meters == null) return null;
    final rounded = meters.round();
    if (rounded <= 10) return 'GPS $rounded m · strong';
    if (rounded <= 30) return 'GPS $rounded m · usable';
    return 'GPS $rounded m · weak. Tap the map to move the pin.';
  }

  _GpsTone get _gpsTone {
    if (_placedByHand) return _GpsTone.placed;
    final meters = _accuracy;
    if (meters == null || meters <= 10) return _GpsTone.strong;
    if (meters <= 30) return _GpsTone.usable;
    return _GpsTone.weak;
  }

  Future<void> _useLocation() async {
    setState(() => _locating = true);
    try {
      final fix = await readDeviceLocation();
      if (!mounted || _site == null) return;
      _lat.text = fix.latitude.toStringAsFixed(5);
      _lng.text = fix.longitude.toStringAsFixed(5);
      setState(() {
        _accuracy = fix.accuracy;
        _placedByHand = false;
      });
      await _update(_site!.copyWith(latitude: fix.latitude, longitude: fix.longitude));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This device could not read a GPS fix. Type the coordinates or tap the map.')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _publish(Site site) async {
    setState(() => _saving = true);
    await _writes;
    if (!mounted) return;
    final error = await context.read<AppController>().publishSite(site.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _discard(Site site) async {
    await context.read<AppController>().discardDraft(site.id);
    if (mounted) Navigator.of(context).pop();
  }
}

enum _GpsTone { strong, usable, weak, placed }

class _GpsBadge extends StatelessWidget {
  const _GpsBadge({required this.label, required this.tone});

  final String label;
  final _GpsTone tone;

  @override
  Widget build(BuildContext context) {
    final fill = switch (tone) {
      _GpsTone.strong || _GpsTone.placed => clearFill,
      _GpsTone.usable => pendingFill,
      _GpsTone.weak => overdueFill,
    };
    final color = switch (tone) {
      _GpsTone.strong || _GpsTone.placed => clearInk,
      _GpsTone.usable => pendingInk,
      _GpsTone.weak => overdueInk,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
