import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/task_model.dart';

/// Thin client over the user-configured server.
///
/// The base URL is injected by [SettingsService] and is NEVER hardcoded here.
/// Every method throws a descriptive [Exception] on failure so the UI can show
/// an honest error instead of a fake success.
class ApiService {
  ApiService({required this.baseUrl});

  /// Base URL of the server (e.g. https://thed1-aiagent.hf.space).
  /// No trailing slash.
  String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// POST /start_download  -> { task_id }
  Future<String> startDownload(String url) async {
    if (baseUrl.isEmpty) {
      throw Exception('Server URL is not set. Open Settings and add it.');
    }
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw Exception('Please enter a URL.');
    }
    final uri = _uri('/start_download');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': trimmed}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final taskId = data['task_id'] as String?;
      if (taskId == null || taskId.isEmpty) {
        throw Exception('Server did not return a task_id.');
      }
      return taskId;
    }
    throw Exception('Start download failed (HTTP ${response.statusCode}).');
  }

  /// GET /status/{task_id}  -> task object
  Future<TaskModel> getStatus(String taskId) async {
    final uri = _uri('/status/$taskId');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TaskModel.fromJson(data);
    }
    if (response.statusCode == 404) {
      throw Exception('Task not found on server.');
    }
    throw Exception('Status check failed (HTTP ${response.statusCode}).');
  }

  /// GET /history  -> { history: [tasks] }
  Future<List<TaskModel>> getHistory() async {
    final uri = _uri('/history');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['history'] as List<dynamic>? ?? [];
      return list
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('History load failed (HTTP ${response.statusCode}).');
  }

  /// GET /server_status  -> server info
  Future<ServerStatus> getServerStatus() async {
    final uri = _uri('/server_status');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ServerStatus.fromJson(data);
    }
    throw Exception('Server status failed (HTTP ${response.statusCode}).');
  }

  /// Direct download URL for a completed task (used by copy-link / stream).
  String downloadUrl(String taskId) => '$baseUrl/download/$taskId';

  /// Direct stream URL for a completed task (Range / 206 supported).
  String streamUrl(String taskId) => '$baseUrl/stream/$taskId';
}
