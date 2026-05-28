import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/room_model.dart';
import '../models/message_model.dart';

class ApiService {
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> register(String username, String email, String password, [String? avatar]) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        if (avatar != null) 'avatar': avatar,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/auth/me'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to fetch user');
    }
  }

  Future<Map<String, dynamic>> updateProfile({String? avatar, String? description}) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/auth/profile'),
      headers: _headers,
      body: jsonEncode({
        if (avatar != null) 'avatar': avatar,
        if (description != null) 'description': description,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to update profile');
    }
  }

  Future<List<RoomModel>> getRooms() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/rooms'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      List<dynamic> roomsJson = data['rooms'] ?? [];
      return roomsJson.map((json) => RoomModel.fromJson(json)).toList();
    } else {
      throw Exception(data['error'] ?? 'Failed to fetch rooms');
    }
  }

  Future<RoomModel> createRoom(String name, String description) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/rooms'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return RoomModel.fromJson(data['room']);
    } else {
      throw Exception(data['error'] ?? 'Failed to create room');
    }
  }

  Future<RoomModel> createDirectRoom(String targetUsername) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/rooms/direct'),
      headers: _headers,
      body: jsonEncode({
        'targetUsername': targetUsername,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return RoomModel.fromJson(data['room']);
    } else {
      throw Exception(data['error'] ?? 'Failed to create direct room');
    }
  }

  Future<RoomModel> joinRoom(String inviteCode) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/rooms/join'),
      headers: _headers,
      body: jsonEncode({
        'inviteCode': inviteCode,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return RoomModel.fromJson(data['room']);
    } else {
      throw Exception(data['error'] ?? 'Failed to join room');
    }
  }

  Future<RoomModel> updateRoom(String roomId, String name, String description) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/rooms/$roomId'),
      headers: _headers,
      body: jsonEncode({'name': name, 'description': description}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return RoomModel.fromJson(json['room']);
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception(error ?? 'Failed to update room');
    }
  }

  Future<List<MessageModel>> getMessages(String roomId, [String? before]) async {
    String url = '${AppConstants.baseUrl}/api/rooms/$roomId/messages';
    if (before != null) {
      url += '?before=$before';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      List<dynamic> messagesJson = data['messages'] ?? [];
      return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception(data['error'] ?? 'Failed to fetch messages');
    }
  }

  Future<void> leaveRoom(String roomId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/rooms/$roomId/leave'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to leave room');
    }
  }
}
