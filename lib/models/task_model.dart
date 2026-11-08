/// A single task returned by the server.
///
/// The server (FastAPI on Hugging Face Spaces) exposes:
///   POST /start_download  -> { task_id }
///   GET  /status/{task_id} -> { task_id, url, status, total_size, downloaded,
///                              speed, file_path, original_filename, resumable,
///                              timestamp, error, eta_seconds, verified }
///   GET  /history          -> { history: [ ...same task objects... ] }
///
/// NOTE: The server does NOT expose media metadata (resolution / bitrate) and
/// does NOT expose single-file delete or rename endpoints. We report exactly
/// what the server gives us and never fabricate values.
class TaskModel {
  const TaskModel({
    required this.taskId,
    required this.url,
    required this.status,
    this.totalSize = 0,
    this.downloaded = 0,
    this.speed = 0.0,
    this.originalFilename,
    this.filePath,
    this.resumable,
    this.timestamp,
    this.error,
    this.etaSeconds,
    this.verified,
  });

  final String taskId;
  final String url;
  final String status; // downloading | completed | error | extracting | uploading_to_gofile
  final int totalSize;
  final int downloaded;
  final double speed; // bytes per second
  final String? originalFilename;
  final String? filePath;
  final bool? resumable;
  final int? timestamp; // unix seconds
  final String? error;
  final int? etaSeconds; // seconds
  final bool? verified;

  /// Create from the server's JSON map. Missing keys are treated as absent
  /// rather than invented — this keeps error handling logical.
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: (json['task_id'] ?? '') as String,
      url: (json['url'] ?? '') as String,
      status: (json['status'] ?? 'unknown') as String,
      totalSize: _toInt(json['total_size']) ?? 0,
      downloaded: _toInt(json['downloaded']) ?? 0,
      speed: _toDouble(json['speed']) ?? 0.0,
      originalFilename: json['original_filename'] as String?,
      filePath: json['file_path'] as String?,
      resumable: json['resumable'] as bool?,
      timestamp: _toInt(json['timestamp']),
      error: json['error'] as String?,
      etaSeconds: _toInt(json['eta_seconds']),
      verified: json['verified'] as bool?,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'url': url,
      'status': status,
      'total_size': totalSize,
      'downloaded': downloaded,
      'speed': speed,
      'original_filename': originalFilename,
      'file_path': filePath,
      'resumable': resumable,
      'timestamp': timestamp,
      'error': error,
      'eta_seconds': etaSeconds,
      'verified': verified,
    };
  }

  /// Human-friendly display name (falls back to the last URL segment).
  String get fileName {
    if (originalFilename != null && originalFilename!.isNotEmpty) {
      return originalFilename!;
    }
    final clean = url.split('?').first;
    final segments = clean.split('/');
    final last = segments.last;
    return last.isNotEmpty ? last : 'downloaded_file';
  }

  String get extension {
    final parts = fileName.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase();
  }

  bool get isVideo {
    return {'mp4', 'mkv', 'mov', 'avi', 'webm', 'flv', 'm4v', '3gp'}
        .contains(extension);
  }

  bool get isImage {
    return {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'ico'}
        .contains(extension);
  }

  bool get isAudio {
    return {'mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a'}.contains(extension);
  }

  bool get isZip => extension == 'zip';

  bool get isCompleted => status == 'completed';
  bool get isError => status == 'error';
  bool get isDownloading => status == 'downloading';
  bool get isActive => status == 'downloading' ||
      status == 'extracting' ||
      status == 'uploading_to_gofile';

  /// Progress fraction 0.0 -> 1.0. Never exceeds 1.0 (logical guard).
  double get progress {
    if (totalSize <= 0) return 0.0;
    final p = downloaded / totalSize;
    if (p < 0.0) return 0.0;
    if (p > 1.0) return 1.0;
    return p;
  }

  String get sizeFormatted => _formatBytes(totalSize);
  String get downloadedFormatted => _formatBytes(downloaded);

  String get speedFormatted {
    if (speed <= 0) return '--';
    return '${_formatBytes(speed.round())}/s';
  }

  String get etaFormatted {
    if (etaSeconds == null || etaSeconds! <= 0) return '--';
    final s = etaSeconds!;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}h ${m}m ${sec}s';
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'error':
        return 'Failed';
      case 'downloading':
        return 'Downloading';
      case 'extracting':
        return 'Extracting';
      case 'uploading_to_gofile':
        return 'Uploading';
      default:
        return 'Unknown';
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    var size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  TaskModel copyWith({
    String? taskId,
    String? url,
    String? status,
    int? totalSize,
    int? downloaded,
    double? speed,
    String? originalFilename,
    String? filePath,
    bool? resumable,
    int? timestamp,
    String? error,
    int? etaSeconds,
    bool? verified,
  }) {
    return TaskModel(
      taskId: taskId ?? this.taskId,
      url: url ?? this.url,
      status: status ?? this.status,
      totalSize: totalSize ?? this.totalSize,
      downloaded: downloaded ?? this.downloaded,
      speed: speed ?? this.speed,
      originalFilename: originalFilename ?? this.originalFilename,
      filePath: filePath ?? this.filePath,
      resumable: resumable ?? this.resumable,
      timestamp: timestamp ?? this.timestamp,
      error: error ?? this.error,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      verified: verified ?? this.verified,
    );
  }
}

/// Server status (from GET /server_status). Reported exactly as received.
class ServerStatus {
  const ServerStatus({
    required this.serverOnline,
    this.ramTotal,
    this.ramUsed,
    this.ramPercent,
    this.storageTotal,
    this.storageUsed,
    this.storageFree,
    this.storagePercent,
    this.activeTasks,
    this.uptime,
    this.pingMs,
    this.temperature,
  });

  final bool serverOnline;
  final int? ramTotal;
  final int? ramUsed;
    final double? ramPercent;
  final int? storageTotal;
  final int? storageUsed;
  final int? storageFree;
  final double? storagePercent;
  final int? activeTasks;
  final double? uptime;
  final int? pingMs;
  final int? temperature;

  factory ServerStatus.fromJson(Map<String, dynamic> json) {
    return ServerStatus(
      serverOnline: json['server_online'] == true,
      ramTotal: _toInt(json['ram_total']),
      ramUsed: _toInt(json['ram_used']),
      ramPercent: _toDouble(json['ram_percent']),
      storageTotal: _toInt(json['storage_total']),
      storageUsed: _toInt(json['storage_used']),
      storageFree: _toInt(json['storage_free']),
      storagePercent: _toDouble(json['storage_percent']),
      activeTasks: _toInt(json['active_tasks']),
      uptime: _toDouble(json['uptime']),
      pingMs: _toInt(json['ping_ms']),
      temperature: _toInt(json['temperature']),
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
