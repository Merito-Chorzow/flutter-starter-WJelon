import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/entries_store.dart';

class EntryDetailScreen extends StatelessWidget {
  final int entryId;
  const EntryDetailScreen({super.key, required this.entryId});

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return "${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EntriesStore>();
    final entry = store.byId(entryId);

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Szczegoly")),
        body: const Center(child: Text("Nie znaleziono wpisu (brak w pamieci).")),
      );
    }

    Uint8List? bytes;
    final b64 = entry.photoBase64;
    if (b64 != null && b64.isNotEmpty) {
      try {
        bytes = base64Decode(b64);
      } catch (_) {
        bytes = null;
      }
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Szczegoly")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (bytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(
                bytes!,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ] else ...[
            Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: scheme.surfaceContainerHighest,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        size: 34, color: scheme.onSurfaceVariant),
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
            ),
          ],
          const SizedBox(height: 16),
          Text(
            entry.title.trim().isEmpty ? "Bez tytulu" : entry.title.trim(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                _formatDate(entry.createdAt),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                entry.description.trim().isNotEmpty ? entry.description.trim() : "Brak opisu",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
