import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/entries_store.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

class EntriesListScreen extends StatelessWidget {
  const EntriesListScreen({super.key});

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return "${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EntriesStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wpisy"),
        actions: [
          IconButton(
            tooltip: "Odswiez",
            onPressed: () => context.read<EntriesStore>().loadEntries(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<EntriesStore>().loadEntries(),
        child: Builder(
          builder: (_) {
            if (store.state == LoadState.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (store.state == LoadState.error) {
              return ErrorState(
                message: store.errorMessage ?? "Nieznany blad",
                onRetry: () => context.read<EntriesStore>().loadEntries(),
              );
            }

            if (store.entries.isEmpty) {
              return const EmptyState(
                title: "Brak wpisow",
                subtitle: "Dodaj pierwszy wpis i zrob zdjecie z kamery.",
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: store.entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = store.entries[i];

                Uint8List? thumb;
                final b64 = e.photoBase64;
                if (b64 != null && b64.isNotEmpty) {
                  try {
                    thumb = base64Decode(b64);
                  } catch (_) {
                    thumb = null;
                  }
                }

                return _EntryCard(
                  title: e.title.trim().isEmpty ? "Bez tytulu" : e.title.trim(),
                  description: e.description.trim().isEmpty ? "Brak opisu" : e.description.trim(),
                  dateText: _formatDate(e.createdAt),
                  thumbBytes: thumb,
                  onTap: () => Navigator.pushNamed(context, "/detail", arguments: e.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final String title;
  final String description;
  final String dateText;
  final Uint8List? thumbBytes;
  final VoidCallback onTap;

  const _EntryCard({
    required this.title,
    required this.description,
    required this.dateText,
    required this.thumbBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPhoto = thumbBytes != null;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(bytes: thumbBytes),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(icon: Icons.schedule, text: dateText),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Uint8List? bytes;
  const _Thumbnail({required this.bytes});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 72,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: bytes == null
            ? Container(
                color: scheme.surface,
                child: Icon(Icons.image_not_supported_outlined, color: scheme.onSurfaceVariant),
              )
            : Image.memory(bytes!, fit: BoxFit.cover),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
