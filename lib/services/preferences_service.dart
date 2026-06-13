import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._();
  factory PreferencesService() => _instance;
  PreferencesService._();

  static const _keyNamaUser = 'nama_user';
  static const _keyDeviceName = 'device_name';
  static const _keyDeviceIp = 'device_ip';
  static const _keyGeminiApiKey = 'gemini_api_key';

  Future<String> getNamaUser() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyNamaUser) ?? '';
  }

  Future<void> setNamaUser(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyNamaUser, value);
  }

  Future<String> getDeviceName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyDeviceName) ?? '';
  }

  Future<String> getDeviceIp() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyDeviceIp) ?? '';
  }

  Future<void> setDevice(String name, String ip) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyDeviceName, name);
    await p.setString(_keyDeviceIp, ip);
  }

  Future<String> getGeminiApiKey() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyGeminiApiKey) ?? '';
  }

  Future<void> setGeminiApiKey(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyGeminiApiKey, value);
  }

  Future<void> clearDevice() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyDeviceName);
    await p.remove(_keyDeviceIp);
  }
}
