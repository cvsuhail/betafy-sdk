import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsStore {
  static const _installIdKey = 'tester_heartbeat_install_id';
  static const _pendingHeartbeatsKey = 'tester_heartbeat_pending';

  SharedPrefsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPrefsStore> instance() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsStore(prefs);
  }

  String? get installId => _prefs.getString(_installIdKey);

  Future<void> persistInstallId(String id) async {
    await _prefs.setString(_installIdKey, id);
  }

  Future<List<String>> pendingHeartbeats() async {
    final raw = _prefs.getStringList(_pendingHeartbeatsKey);
    return raw ?? <String>[];
  }

  Future<void> savePending(List<String> values) async {
    await _prefs.setStringList(_pendingHeartbeatsKey, values);
  }

  Future<void> appendPending(String payload) async {
    final list = await pendingHeartbeats();
    list.add(payload);
    await savePending(list);
  }

  Future<void> clearPending() async {
    await _prefs.remove(_pendingHeartbeatsKey);
  }

  Future<void> pruneOldest(int maxEntries) async {
    final list = await pendingHeartbeats();
    if (list.length <= maxEntries) return;
    final trimmed = list.sublist(list.length - maxEntries);
    await savePending(trimmed);
  }
}
