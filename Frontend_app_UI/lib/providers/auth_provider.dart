import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? currentUser;
  bool isLoading = false;
  String? error;

  Future<bool> register(String username, String email, String password, [String? avatar]) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiService.instance.register(username, email, password, avatar);
      final token = response['token'];
      currentUser = UserModel.fromJson(response['user']);
      
      var box = Hive.box(AppConstants.userKey);
      await box.put(AppConstants.tokenKey, token);
      
      ApiService.instance.setToken(token);
      SocketService.instance.connect(token);
      
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiService.instance.login(email, password);
      final token = response['token'];
      currentUser = UserModel.fromJson(response['user']);
      
      var box = Hive.box(AppConstants.userKey);
      await box.put(AppConstants.tokenKey, token);
      
      ApiService.instance.setToken(token);
      SocketService.instance.connect(token);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    var box = Hive.box(AppConstants.userKey);
    await box.delete(AppConstants.tokenKey);
    
    ApiService.instance.clearToken();
    SocketService.instance.disconnect();
    currentUser = null;
    notifyListeners();
  }

  Future<bool> updateProfile(String? avatar, String? description) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiService.instance.updateProfile(avatar: avatar, description: description);
      currentUser = UserModel.fromJson(response['user']);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> tryAutoLogin() async {
    var box = Hive.box(AppConstants.userKey);
    String? token = box.get(AppConstants.tokenKey);

    if (token == null) return false;

    ApiService.instance.setToken(token);
    
    try {
      final response = await ApiService.instance.getMe();
      currentUser = UserModel.fromJson(response['user']);
      SocketService.instance.connect(token);
      notifyListeners();
      return true;
    } catch (e) {
      ApiService.instance.clearToken();
      await box.delete(AppConstants.tokenKey);
      return false;
    }
  }
}
