import 'package:shared_preferences/shared_preferences.dart';

/// Stores the server URL in SharedPreferences.
///
/// Nothing is hardcoded to a single server — the default is the HF space but
/// the user can change it at any time in Settings.
class SettingsService {
  static const String _keyServerUrl = 'server_url';
  static const String _defaultServerUrl =
      'https://thed1-aiagent.hf.space';

  Future<String> getServerUrl() async {
    final prefs = await _prefs;
    return prefs.getString(_keyServerUrl) ?? _defaultServerUrl;
  }

  Future<void> setServerUrl(String url) async {
    final cleaned = url.trim();
    final normalized = cleaned.endsWith('/')
        ? cleaned.substring(0, cleaned.length - 1)
        : cleaned;
    final prefs = await _prefs;
    await prefs.setString(_keyServerUrl, normalized);
  }

  Future<void> resetToDefault() async {
    final prefs = await _prefs;
    await prefs.setString(_keyServerUrl, _defaultServerUrl);
  }

  late final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();
}
