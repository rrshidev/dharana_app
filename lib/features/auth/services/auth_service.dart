import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _api = ApiClient();

  // Web Client ID из Google Cloud Console (для получения idToken на Android).
  // Задаётся при сборке: --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

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

  Future<AuthResponse?> loginWithGoogle() async {
    final gsi = GoogleSignIn(
      scopes: ['email'],
      serverClientId: googleWebClientId.isEmpty ? null : googleWebClientId,
    );
    final account = await gsi.signIn();
    if (account == null) return null; // пользователь отменил выбор

    try {
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw Exception('Google id_token not available. GOOGLE_WEB_CLIENT_ID not set?');
      }
      final response = await _api.dio.post('/auth/google', data: {
        'id_token': idToken,
        'name': account.displayName,
        'avatar_url': account.photoUrl,
      });
      final result = AuthResponse.fromJson(response.data);
      await _api.saveToken(result.accessToken);
      return result;
    } finally {
      // Сбрасываем состояние, чтобы следующий вход снова предлагал выбор аккаунта.
      await gsi.signOut();
    }
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
