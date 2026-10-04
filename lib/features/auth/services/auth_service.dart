import 'dart:convert';
import 'dart:math';

import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  final _api = ApiClient();

  // Web Client ID из Google Cloud Console (для получения idToken на Android).
  // Задаётся при сборке: --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  // Client ID Яндекс OAuth (тот же, что и на сайте) — задаётся при сборке:
  // --dart-define=YANDEX_CLIENT_ID=...
  static const String yandexClientId = String.fromEnvironment(
    'YANDEX_CLIENT_ID',
    defaultValue: '',
  );

  // Client ID VK ID — задаётся при сборке: --dart-define=VK_CLIENT_ID=...
  // Кнопка MAX использует тот же вход (отдельного OAuth у MAX нет).
  static const String vkClientId = String.fromEnvironment(
    'VK_CLIENT_ID',
    defaultValue: '',
  );

  /// Кнопки входа показываем только если ключ реально задан на сборке —
  /// иначе пользователь ждёт ошибки вместо входа.
  static bool isProviderConfigured(String provider) =>
      provider == 'vk' ? vkClientId.isNotEmpty : yandexClientId.isNotEmpty;

  /// Домен сайта: на нём живут и assetlinks.json для App Links, и веб-колбэки.
  static const String siteBase = String.fromEnvironment(
    'SITE_BASE_URL',
    defaultValue: 'https://dharana.ru',
  );

  /// Куда провайдер возвращает браузер в приложении. Это App Link (https),
  /// потому что Яндекс требует https-redirect_uri; ОС перехватывает ссылку
  /// и открывает приложение (assetlinks.json уже верифицирован).
  static String appCallbackUrl(String provider) =>
      '$siteBase/app/auth/$provider/callback';

  static const Map<String, ({String authorizeUrl, String scope})>
      _providers = {
    'yandex': (
      authorizeUrl: 'https://oauth.yandex.ru/authorize',
      scope: 'login:email login:info',
    ),
    'vk': (
      authorizeUrl: 'https://id.vk.com/oauth2/authorize',
      scope: 'email',
    ),
  };

  /// Nonce последнего начатого OAuth-флоу: приложение само сверяет state в
  /// колбэке (в вебе это делает double-submit кука, здесь её нет — Cookies
  /// браузера нам не подконтрольны).
  static String? _pendingState;
  static String? _pendingProvider;

  /// Открывает страницу входа провайдера в системном браузере. Возвращаться
  /// приложение будет через App Link — обработка в app.dart (_handleLink).
  Future<void> beginOAuthLogin(String provider) async {
    final clientId = provider == 'vk' ? vkClientId : yandexClientId;
    final config = _providers[provider];
    if (config == null) throw Exception('Unknown OAuth provider: $provider');
    if (clientId.isEmpty) {
      throw Exception('$provider client id is not set');
    }

    final state = _randomNonce();
    _pendingState = state;
    _pendingProvider = provider;

    final uri = Uri.parse(config.authorizeUrl).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': appCallbackUrl(provider),
        'response_type': 'code',
        'scope': config.scope,
        'state': state,
      },
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _pendingState = null;
      _pendingProvider = null;
      throw Exception('Could not open the browser');
    }
  }

  /// Завершает флоу по ссылке из колбэка: сверяет state, обменивает код на
  /// JWT. Возвращает true, если это был наш OAuth-колбэк (и его удалось).
  Future<bool> completeOAuthCallback(Uri uri) async {
    final provider = _pendingProvider;
    final expectedState = _pendingState;
    if (provider == null || expectedState == null) return false;
    if (!uri.path.endsWith('/app/auth/$provider/callback')) return false;

    // Разовый: любой второй колбэк (например, повторное открытие ссылки из
    // истории браузера) уже не наш.
    _pendingState = null;
    _pendingProvider = null;

    final error = uri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      throw Exception('OAUTH_DENIED');
    }
    final state = uri.queryParameters['state'];
    if (state == null || state != expectedState) {
      throw Exception('OAUTH_INVALID_STATE');
    }
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw Exception('OAUTH_NO_CODE');
    }

    final response = await _api.dio.post('/auth/$provider', data: {
      'code': code,
      'redirect_uri': appCallbackUrl(provider),
    });
    final auth = AuthResponse.fromJson(response.data);
    await _api.saveToken(auth.accessToken);
    return true;
  }

  /// Отменяет ожидание возврата из браузера (пользователь вернулся сам).
  static void cancelOAuthLogin() {
    _pendingState = null;
    _pendingProvider = null;
  }

  static String _randomNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

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

  Future<bool> requestPasswordReset(String email) async {
    final response = await _api.dio.post('/auth/password-reset/send', data: {
      'email': email,
    });
    return response.data is Map && response.data['ok'] == true;
  }

  Future<void> resetPassword(String token, String password) async {
    await _api.dio.post('/auth/password-reset/confirm', data: {
      'token': token,
      'password': password,
    });
  }
}
