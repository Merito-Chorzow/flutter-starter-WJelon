import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/entry.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:3000";

  Future<List<Entry>> fetchEntries() async {
    final uri = Uri.parse("$baseUrl/entries");
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        throw Exception("API error: ${res.statusCode}");
      }
      final data = jsonDecode(res.body) as List<dynamic>;
      final entries = data.map((e) => Entry.fromJson(e as Map<String, dynamic>)).toList();
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } on SocketException {
      throw Exception("Brak internetu / brak polaczenia z API.");
    } on HttpException {
      throw Exception("Blad HTTP.");
    } on FormatException {
      throw Exception("Niepoprawny format danych z API.");
    }
  }

  Future<Entry> addEntry({
    required String title,
    required String description,
    String? photoBase64,
  }) async {
    final uri = Uri.parse("$baseUrl/entries");

    final payload = {
      "title": title,
      "description": description,
      "createdAt": DateTime.now().toUtc().toIso8601String(),
      "photoBase64": photoBase64,
    };

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 8));

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception("API error: ${res.statusCode}");
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return Entry.fromJson(json);
  }
}
