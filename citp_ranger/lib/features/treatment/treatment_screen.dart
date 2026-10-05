import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/field_permissions.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/local/photo_store.dart';
import '../../state/app_controller.dart';
import '../../widgets/app_logo.dart';

class TreatmentScreen extends StatefulWidget {
  const TreatmentScreen({super.key, required this.siteId});

  final String siteId;

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _days = TextEditingController(text: '30');
  String? _photoPath;
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    _days.dispose();
    super.dispose();
  }

  int get _followUpDays {
    final parsed = int.tryParse(_days.text.trim());
    if (parsed == null || parsed < 1) return 30;
    if (parsed > 365) return 365;
    return parsed;
  }

  DateTime get _due => DateTime.now().add(Duration(days: _followUpDays));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const BrandTitle('Update status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Record the spray, add a photo if it helps the next visit, and set when to come back.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'What was sprayed, and how it looked',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Photo note', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_photoPath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(resolvePhotoPath(_photoPath!)),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
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
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Next visit', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'One month is the usual return. Change it when this site needs a shorter or longer gap.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final days in [7, 14, 30, 60, 90])
                ChoiceChip(
                  label: Text(days == 30 ? '1 month' : '$days days'),
                  selected: _followUpDays == days,
                  onSelected: (_) {
                    _days.text = '$days';
                    setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _days,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Days until re-check'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text('Come back on ${formatDate(_due)}', style: const TextStyle(color: muted)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save treatment'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
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
      final shot = await ImagePicker().pickImage(source: source, imageQuality: 70, maxWidth: 1600);
      if (shot == null || !mounted) return;
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      final stored = await context.read<AppController>().stagePhoto(bytes);
      if (!mounted) return;
      setState(() => _photoPath = stored);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open a photo. Try the other button.')),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<AppController>().addTreatment(
      widget.siteId,
      _notes.text,
      followUpDays: _followUpDays,
      photoSourcePath: _photoPath,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
