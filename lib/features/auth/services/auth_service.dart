import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';

class AuthService {
  final _api = ApiClient();

  Future<AuthResponse> register(String email, String password, String name) async {
    final response = await _api.dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
    });
    final auth = AuthResponse.fromJson(response.data);
    await _api.saveToken(auth.accessToken);
    return auth;
  }

  Future<AuthResponse> login(String email, String password) async {
    final response = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final auth = AuthResponse.fromJson(response.data);
    await _api.saveToken(auth.accessToken);
    return auth;
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _api.dio.get('/auth/me');
      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    if (token == null) return false;
    final user = await getCurrentUser();
    return user != null;
  }

  Future<void> logout() async {
    await _api.deleteToken();
  }

  Future<AuthResponse> telegramLogin(int telegramId) async {
    final response = await _api.dio.post('/auth/telegram', data: {
      'telegram_id': telegramId,
    });
    final auth = AuthResponse.fromJson(response.data);
    await _api.saveToken(auth.accessToken);
    return auth;
  }

  Future<AuthResponse> verifyTelegramCode(String code) async {
    final response = await _api.dio.post('/auth/telegram/verify', data: {
      'code': code,
    });
    final auth = AuthResponse.fromJson(response.data);
    await _api.saveToken(auth.accessToken);
    return auth;
  }
}
