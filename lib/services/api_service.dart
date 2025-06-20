import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucasbeatsfederacao/utils/constants.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class ApiService {
  final String _baseUrl = backendBaseUrl;
  String get baseUrl => _baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Timeout aumentado para lidar com cold start do Render.com
  static const Duration _defaultTimeout = Duration(seconds: 90);
  static const Duration _shortTimeout = Duration(seconds: 30);

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    Logger.info('API Response Status: $statusCode, Body: ${response.body}');

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          Logger.error('Error decoding JSON response: ${e.toString()}');
          throw Exception('Failed to decode JSON response');
        }
      } else {
        return null;
      }
    } else {
      String errorMessage = 'API Error ($statusCode)';
      try {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map && decodedBody.containsKey('msg')) {
          errorMessage = decodedBody['msg'] + " (Code: $statusCode)";
        } else if (decodedBody is Map && decodedBody.containsKey('errors')) {
          final errors = decodedBody['errors'] as List;
          errorMessage = "${errors.map((e) => e['msg']).join(', ')} (Code: $statusCode)";
        } else if (response.body.isNotEmpty) {
           errorMessage = "${response.body} (Code: $statusCode)";
        }
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? "${response.body} (Code: $statusCode)" : errorMessage;
      }
      Logger.error('API Error: $statusCode - $errorMessage');
      throw Exception(errorMessage);
    }
  }

  // Método para fazer retry em caso de timeout (útil para cold start)
  Future<dynamic> _makeRequestWithRetry(Future<http.Response> Function() requestFunction, {int maxRetries = 2}) async {
    int attempts = 0;
    while (attempts <= maxRetries) {
      try {
        final response = await requestFunction();
        return _handleResponse(response);
      } catch (e) {
        attempts++;
        if (e.toString().contains('TimeoutException') && attempts <= maxRetries) {
          Logger.warning('Request timeout, retrying... (attempt $attempts/$maxRetries)');
          await Future.delayed(Duration(seconds: 2 * attempts)); // Backoff progressivo
          continue;
        }
        rethrow;
      }
    }
  }

  Future<dynamic> get(String endpoint, {bool requireAuth = true, Duration? timeout}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API GET Request: $url');
    
    return await _makeRequestWithRetry(() async {
      return await http.get(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
      ).timeout(timeout ?? _defaultTimeout);
    });
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool requireAuth = true, Duration? timeout}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API POST Request: $url, Data: ${jsonEncode(data)}');
    
    return await _makeRequestWithRetry(() async {
      return await http.post(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
        body: jsonEncode(data),
      ).timeout(timeout ?? _defaultTimeout);
    });
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data, {bool requireAuth = true, Duration? timeout}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API PUT Request: $url, Data: ${jsonEncode(data)}');
    
    return await _makeRequestWithRetry(() async {
      return await http.put(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
        body: jsonEncode(data),
      ).timeout(timeout ?? _defaultTimeout);
    });
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true, Duration? timeout}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API DELETE Request: $url');
    
    return await _makeRequestWithRetry(() async {
      return await http.delete(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
      ).timeout(timeout ?? _defaultTimeout);
    });
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data, {bool requireAuth = true, Duration? timeout}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API PATCH Request: $url, Data: ${jsonEncode(data)}');
    
    return await _makeRequestWithRetry(() async {
      return await http.patch(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
        body: jsonEncode(data),
      ).timeout(timeout ?? _defaultTimeout);
    });
  }

  // Método específico para manter o servidor ativo (ping)
  Future<void> keepServerAlive() async {
    try {
      Logger.info('Enviando ping para manter servidor ativo...');
      await get('/', requireAuth: false, timeout: _shortTimeout);
      Logger.info('Ping enviado com sucesso.');
    } catch (e) {
      Logger.warning('Falha no ping do servidor: ${e.toString()}');
    }
  }
}

