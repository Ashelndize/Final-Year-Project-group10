import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static const _timeout = Duration(seconds: 15);

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await SecureStorage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, dynamic> _parse(http.Response response) {
    if (response.body.isEmpty) return {};
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'detail': response.body};
    }
  }

  static String _extractMessage(Map<String, dynamic> body) {
    if (body.containsKey('detail')) return body['detail'].toString();
    final msgs = body.values
        .expand((v) => v is List ? v.map((e) => e.toString()) : [v.toString()])
        .take(3)
        .join('; ');
    return msgs.isNotEmpty ? msgs : 'An error occurred.';
  }

  static void _checkStatus(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = _parse(response);
    throw ApiException(
      statusCode: response.statusCode,
      message: _extractMessage(body),
      errors: body,
    );
  }

  // Attempts to refresh the access token. Returns true on success.
  static Future<bool> _refreshToken() async {
    final refresh = await SecureStorage.getRefreshToken();
    if (refresh == null) return false;
    try {
      final response = await http
          .post(
            Uri.parse(ApiEndpoints.tokenRefresh),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refresh}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = _parse(response);
        final newAccess = data['access'] as String?;
        if (newAccess != null) {
          await SecureStorage.saveTokens(access: newAccess, refresh: refresh);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? queryParams,
  }) async {
    final uri = queryParams != null
        ? Uri.parse(url).replace(queryParameters: queryParams)
        : Uri.parse(url);
    var response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    if (response.statusCode == 401) {
      if (await _refreshToken()) {
        response =
            await http.get(uri, headers: await _headers()).timeout(_timeout);
      }
    }
    _checkStatus(response);
    return _parse(response);
  }

  static Future<Map<String, dynamic>> getList(
    String url, {
    Map<String, String>? queryParams,
  }) async {
    final uri = queryParams != null
        ? Uri.parse(url).replace(queryParameters: queryParams)
        : Uri.parse(url);
    var response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    if (response.statusCode == 401) {
      if (await _refreshToken()) {
        response =
            await http.get(uri, headers: await _headers()).timeout(_timeout);
      }
    }
    _checkStatus(response);
    final body = jsonDecode(response.body);
    if (body is List) return {'results': body, 'count': body.length};
    return body as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> data, {
    bool auth = true,
  }) async {
    var response = await http
        .post(
          Uri.parse(url),
          headers: await _headers(auth: auth),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    if (response.statusCode == 401 && auth) {
      if (await _refreshToken()) {
        response = await http
            .post(
              Uri.parse(url),
              headers: await _headers(auth: auth),
              body: jsonEncode(data),
            )
            .timeout(_timeout);
      }
    }
    _checkStatus(response);
    return _parse(response);
  }

  static Future<Map<String, dynamic>> patch(
    String url,
    Map<String, dynamic> data,
  ) async {
    var response = await http
        .patch(
          Uri.parse(url),
          headers: await _headers(),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    if (response.statusCode == 401) {
      if (await _refreshToken()) {
        response = await http
            .patch(
              Uri.parse(url),
              headers: await _headers(),
              body: jsonEncode(data),
            )
            .timeout(_timeout);
      }
    }
    _checkStatus(response);
    return _parse(response);
  }

  static Future<void> delete(String url) async {
    var response =
        await http.delete(Uri.parse(url), headers: await _headers()).timeout(_timeout);
    if (response.statusCode == 401) {
      if (await _refreshToken()) {
        response = await http
            .delete(Uri.parse(url), headers: await _headers())
            .timeout(_timeout);
      }
    }
    _checkStatus(response);
  }
}
