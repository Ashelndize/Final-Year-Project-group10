import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/offline/offline_database.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final data = await ApiClient.get(ApiEndpoints.me);
      _user = User.fromJson(data);
      _status = AuthStatus.authenticated;
    } catch (_) {
      await SecureStorage.clearTokens();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient.post(
        ApiEndpoints.login,
        {'username': username, 'password': password},
        auth: false,
      );
      await SecureStorage.saveTokens(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      final me = await ApiClient.get(ApiEndpoints.me);
      _user = User.fromJson(me);
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Network error. Please check your connection.';
      _loading = false;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required String password2,
    required String role,
    String phone = '',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiClient.post(
        ApiEndpoints.register,
        {
          'username': username,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
          'password2': password2,
          'role': role,
          if (phone.isNotEmpty) 'phone': phone,
        },
        auth: false,
      );
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Network error. Please check your connection.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Returns a map with keys: `success` (bool), `message` (String),
  /// and optionally `devToken` (String) when the backend is in dev mode.
  Future<Map<String, dynamic>> requestPasswordReset(String contact) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient.post(
        ApiEndpoints.passwordResetRequest,
        {'contact': contact},
        auth: false,
      );
      _loading = false;
      notifyListeners();
      return {
        'success': true,
        'message': data['detail'] as String? ?? 'Reset code sent.',
        'devToken': data['dev_token'] as String?,
        'devNote': data['dev_note'] as String?,
      };
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return {'success': false, 'message': e.message};
    } catch (_) {
      _error = 'Network error. Please check your connection.';
      _loading = false;
      notifyListeners();
      return {'success': false, 'message': _error!};
    }
  }

  Future<Map<String, dynamic>> confirmPasswordReset({
    required String token,
    required String newPassword,
    required String newPassword2,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient.post(
        ApiEndpoints.passwordResetConfirm,
        {'token': token, 'new_password': newPassword, 'new_password2': newPassword2},
        auth: false,
      );
      _loading = false;
      notifyListeners();
      return {'success': true, 'message': data['detail'] as String? ?? 'Password reset.'};
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return {'success': false, 'message': e.message};
    } catch (_) {
      _error = 'Network error. Please check your connection.';
      _loading = false;
      notifyListeners();
      return {'success': false, 'message': _error!};
    }
  }

  /// Re-fetches the current user from /auth/me/ and updates the in-memory user.
  Future<void> refreshUser() async {
    try {
      final data = await ApiClient.get(ApiEndpoints.me);
      _user = User.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      final refresh = await SecureStorage.getRefreshToken();
      if (refresh != null) {
        await ApiClient.post(ApiEndpoints.logout, {'refresh': refresh});
      }
    } catch (_) {}
    await SecureStorage.clearTokens();
    await OfflineDatabase.clearAll(); // prevent another user syncing previous user's data
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
