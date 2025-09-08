import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _expiringThresholdKey = 'expiring_threshold_days';
  static const int _defaultThreshold = 30;

  // Get the current expiring threshold
  static Future<int> getExpiringThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_expiringThresholdKey) ?? _defaultThreshold;
  }

  // Set the expiring threshold
  static Future<void> setExpiringThreshold(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_expiringThresholdKey, days);
  }

  // Get available threshold options
  static List<int> getThresholdOptions() {
    return [7, 14, 30, 60, 90];
  }

  // Get threshold display text
  static String getThresholdDisplayText(int days) {
    if (days == 7) return '1 week';
    if (days == 14) return '2 weeks';
    if (days == 30) return '1 month';
    if (days == 60) return '2 months';
    if (days == 90) return '3 months';
    return '$days days';
  }
}
