import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import '../services/api_service.dart';

enum LoadState { idle, loading, error }

class EntriesStore extends ChangeNotifier {
  final ApiService api;

  EntriesStore(this.api);

  List<Entry> entries = [];
  LoadState state = LoadState.idle;
  String? errorMessage;

  Future<void> loadEntries() async {
    state = LoadState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      entries = await api.fetchEntries();
      state = LoadState.idle;
    } catch (e) {
      state = LoadState.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Entry? byId(int id) {
    try {
      return entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Entry?> createEntry({
    required String title,
    required String description,
    String? photoBase64,
  }) async {
    try {
      final created = await api.addEntry(
        title: title,
        description: description,
        photoBase64: photoBase64,
      );
      entries.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
