import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user_id';

  static Future<void> registerUser({
    required String email,
    required String password,
    required String name,
    required String userType, // 'buyer' or 'seller'
    Map<String, dynamic>? additionalInfo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    List<Map<String, dynamic>> users = [];

    if (usersJson != null) {
      users = (json.decode(usersJson) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    // Check if user already exists
    if (users.any((user) => user['email'] == email)) {
      throw Exception('User with this email already exists');
    }

    // Create new user
    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'email': email,
      'password': password, // In a real app, this should be hashed
      'name': name,
      'userType': userType,
      'createdAt': DateTime.now().toIso8601String(),
      ...?additionalInfo,
    };

    users.add(newUser);
    await prefs.setString(_usersKey, json.encode(users));
  }

  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    if (usersJson == null) return null;

    final users = (json.decode(usersJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final user = users.firstWhere(
      (user) => user['email'] == email && user['password'] == password,
      orElse: () => {},
    );

    if (user.isNotEmpty) {
      await prefs.setString(_currentUserKey, user['id']);
      return user;
    }

    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString(_currentUserKey);
    final usersJson = prefs.getString(_usersKey);

    if (currentUserId == null || usersJson == null) return null;

    final users = (json.decode(usersJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return users.firstWhere(
      (user) => user['id'] == currentUserId,
      orElse: () => {},
    );
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey) != null;
  }

  static Future<void> updateUser(Map<String, dynamic> updates) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString(_currentUserKey);
    final usersJson = prefs.getString(_usersKey);

    if (currentUserId == null || usersJson == null) return;

    List<Map<String, dynamic>> users = (json.decode(usersJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final index = users.indexWhere((user) => user['id'] == currentUserId);
    if (index != -1) {
      users[index].addAll(updates);
      await prefs.setString(_usersKey, json.encode(users));
    }
  }
}
