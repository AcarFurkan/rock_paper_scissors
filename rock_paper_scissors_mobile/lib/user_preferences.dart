import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user.dart'; // User class'ınızın bulunduğu dosya

class UserPreferences {
  static const String _userKey = 'user';

  // User nesnesini SharedPreferences'a kaydet
  static Future<bool> saveUser(User user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(user.toMap()); // User nesnesini JSON string'e dönüştür
    return prefs.setString(_userKey, jsonString); // JSON string'i kaydet
  }

  // SharedPreferences'dan User nesnesini oku
  static Future<User?> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_userKey);
    if (jsonString != null) {
      Map<String, dynamic> userMap = json.decode(jsonString); // JSON string'i Map'e dönüştür
      return User.fromMap(userMap); // Map'i kullanarak User nesnesini oluştur
    }
    return null;
  }

  // User nesnesini SharedPreferences'dan sil
  static Future<bool> removeUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.remove(_userKey); // User nesnesini sil
  }
}
