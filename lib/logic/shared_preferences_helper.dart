import 'package:shared_preferences/shared_preferences.dart';

const String isSidebarOpenKey = 'is_sidebar_open';
const String panelWidthKey = 'side_panel_width';

// save double
Future<void> saveDouble(String key, double data) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(key, data);
}

// get double
Future<double?> getDouble(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble(key); // get side panel width or default width 150
}

// save bool
Future<void> saveBool(String key, bool data)async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, data);
}

//get bool
Future<bool?> getBool(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(key); // get side panel width or default width 150
}