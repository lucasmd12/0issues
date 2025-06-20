import 'package:flutter/foundation.dart'; // Para ChangeNotifier
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _token;
  UserModel? _currentUser;
  String? _lastErrorMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _lastErrorMessage;

  ApiService get apiService => _apiService;

  AuthService() {
    _checkInitialAuthStatus();
  }

  Future<void> _checkInitialAuthStatus() async {
    Logger.info("Checking initial authentication status...");
    final storedToken = await _secureStorage.read(key: "jwt_token");
    if (storedToken != null) {
      Logger.info("Token found, attempting to fetch profile...");
      _token = storedToken;
      try {
        await fetchUserProfile();
        if (_currentUser != null) {
          _isAuthenticated = true;
          Logger.info("User authenticated from stored token.");
        } else {
          await logout(); // Clear invalid token/state
        }
      } catch (e) {
        Logger.error("Failed to fetch profile with stored token: ${e.toString()}");
        _lastErrorMessage = e.toString();
        await logout(); // Clear invalid token/state
      }
    } else {
      Logger.info("No stored token found.");
      _isAuthenticated = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    if (_token == null) {
      Logger.warning("Cannot fetch profile without a token.");
      _lastErrorMessage = "Not authenticated";
      throw Exception(_lastErrorMessage);
    }
    try {
      final response = await _apiService.get("/api/auth/profile", requireAuth: true);
      if (response != null && response is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson(response);
        Logger.info("User profile fetched successfully: ${_currentUser?.username}");
        _lastErrorMessage = null;
        notifyListeners();
      } else {
        Logger.warning("Failed to parse user profile from response.");
        _currentUser = null;
        _lastErrorMessage = "Failed to get user profile";
        throw Exception(_lastErrorMessage);
      }
    } catch (e) {
      Logger.error("Error fetching user profile: ${e.toString()}");
      _lastErrorMessage = e.toString();
      _currentUser = null;
      rethrow;
    }
  }

  Future<bool> login(String username, String password) async {
    setLoading(true);
    _lastErrorMessage = null;
    try {
      final response = await _apiService.post(
        "/api/auth/login",
        {"username": username, "password": password},
        requireAuth: false,
      );

      if (response != null && response is Map<String, dynamic> && response.containsKey("token")) {
        final newToken = response["token"] as String?;
        if (newToken != null) {
          await _secureStorage.write(key: "jwt_token", value: newToken);
          _token = newToken;
          await fetchUserProfile();
          if (_currentUser != null) {
             setAuthenticated(true);
             Logger.info("Login successful for user: ${_currentUser?.username}");
             return true;
          } else {
            _lastErrorMessage = "Profile fetch failed after login";
            await _clearAuthData();
            setAuthenticated(false);
            return false;
          }
        } else {
           _lastErrorMessage = "Token not found in login response";
           throw Exception(_lastErrorMessage);
        }
      } else {
         _lastErrorMessage = response?["msg"] ?? "Invalid login response format";
         throw Exception(_lastErrorMessage);
      }
    } catch (e) {
      Logger.error("Login error: ${e.toString()}");
      _lastErrorMessage = e.toString().replaceFirst("Exception: ", "");
      await _clearAuthData();
      setAuthenticated(false);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> register(String username, String password) async {
    setLoading(true);
    _lastErrorMessage = null;
    try {
      final response = await _apiService.post(
        "/api/auth/register",
        {"username": username, "password": password},
        requireAuth: false,
      );

      if (response != null) {
          Logger.info("Registration request successful for user: $username. Attempting to log in automatically...");
          // Tenta logar o usuário automaticamente após o registro bem-sucedido
          return await login(username, password);
      } else {
          Logger.info("Registration request successful (no content) for user: $username. Attempting to log in automatically...");
          return await login(username, password);
      }

    } catch (e) {
      Logger.error("Registration error: ${e.toString()}");
      _lastErrorMessage = e.toString().replaceFirst("Exception: ", "");
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    Logger.info("Logging out user...");
    setLoading(true);
    await _clearAuthData();
    setAuthenticated(false);
    Logger.info("Logout successful");
    setLoading(false);
  }

  Future<void> _clearAuthData() async {
     _currentUser = null;
     _token = null;
     await _secureStorage.delete(key: "jwt_token");
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void setAuthenticated(bool authenticated) {
    if (_isAuthenticated != authenticated) {
        _isAuthenticated = authenticated;
        notifyListeners();
    }
  }

  @override
  void dispose() {
    Logger.info("Disposing AuthService.");
    super.dispose();
  }
}

