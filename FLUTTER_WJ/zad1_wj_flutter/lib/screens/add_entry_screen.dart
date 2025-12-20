import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/entries_store.dart';
import 'camera_capture_screen.dart';

class AddEntryScreen extends StatefulWidget {
  final VoidCallback? onSaved;

  const AddEntryScreen({super.key, this.onSaved});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  XFile? _photoFile;
  String? _photoBase64;

  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCameraAndTakePhoto() async {
    final result = await Navigator.push<CameraCaptureResult>(
      context,
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );

    if (result == null) return;

    final file = result.file;
    final bytes = await File(file.path).readAsBytes();
    final b64 = base64Encode(bytes);

    if (!mounted) return;
    setState(() {
      _photoFile = file;
      _photoBase64 = b64;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Zdjecie dodane.")),
    );
  }

  void _removePhoto() {
    setState(() {
      _photoFile = null;
      _photoBase64 = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final store = context.read<EntriesStore>();
    final created = await store.createEntry(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      photoBase64: _photoBase64, // opcjonalne
    );

    setState(() => _saving = false);

    if (!mounted) return;

    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(store.errorMessage ?? "Nie udalo sie zapisac wpisu.")),
      );
      return;
    }

    _titleCtrl.clear();
    _descCtrl.clear();
    _removePhoto();

    // Jesli AddEntry jest zakladka w HomeShell -> callback zmienia index na liste + odswieza
    widget.onSaved?.call();

    // Jesli AddEntry jest uruchamiane jako route (/add) -> mozna wrocic
    if (Navigator.canPop(context) && widget.onSaved == null) {
      Navigator.pop(context);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Zapisano wpis.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget photoPreview() {
      if (_photoFile == null) {
        return Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
            color: scheme.surface,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined, color: scheme.onSurfaceVariant, size: 28),
                const SizedBox(height: 8),
                Text(
                  "Brak zdjecia",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_photoFile!.path),
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Dodaj wpis")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Szczegoly", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: "Nazwa wpisu",
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Podaj nazwe" : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: "Opis wpisu",
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Podaj opis" : null,
                    ),

                    const SizedBox(height: 16),
                    Text("Zdjecie", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),

                    photoPreview(),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _openCameraAndTakePhoto,
                            icon: const Icon(Icons.photo_camera),
                            label: Text(_photoFile == null ? "Zrob zdjecie" : "Zrob ponownie"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _photoFile == null ? null : _removePhoto,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text("Usun"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text("Zapisz wpis"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
