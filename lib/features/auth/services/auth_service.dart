import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
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
      authorizeUrl: 'https://id.vk.ru/authorize',
      // Пустой scope, как на сайте: запрошенный VK email в ответе user_info
      // всё равно не приходит, а лишний согласу��щий экран мешает входу.
      scope: '',
    ),
  };

  /// Провайдеры, требующие PKCE (S256). У VK ID без code_challenge authorize
  /// отдаёт "code_challenge or code_challenge_method is invalid".
  static const Set<String> _pkceProviders = {'vk'};

  /// Обмен authorization code → access_token у VK ID. Серверный обмен невозможен
  /// (эндпоинт требует `device_id`, а `/oauth2/user_info` проверяет уже готовый
  /// токен), поэтому код меняет сам клиент — ровно как их SDK.
  static const String vkTokenUrl = 'https://id.vk.ru/oauth2/auth';

  /// VK ID принимает `code_challenge_method` только `S256`/`s256`: значение
  /// `sha256` заставляет их SPA падать на «Ошибка загрузки» ещё до формы
  /// входа — в любом движке (проверено 2026-10-06 в Chrome и Firefox).
  /// Нижний регистр `s256` — как в ссылках их собственного SAK-клиента.
  static const Map<String, String> _pkceMethods = {'vk': 's256'};

  /// Nonce последнего начатого OAuth-флоу: приложение само сверяет state в
  /// колбэке (в вебе это делает double-submit кука, здесь её нет — Cookies
  /// браузера нам не подконтрольны).
  static String? _pendingState;
  static String? _pendingProvider;
  static String? _pendingCodeVerifier;

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

final query = <String, String>{
 'client_id': clientId,
 'redirect_uri': appCallbackUrl(provider),
 'response_type': 'code',
 'scope': config.scope,
 'state': state,
};
if (_pkceProviders.contains(provider)) {
      final verifier = _randomNonce() + _randomNonce();
      _pendingCodeVerifier = verifier;
      query['code_challenge'] = _pkceChallenge(verifier);
      query['code_challenge_method'] =
          _pkceMethods[provider] ?? 'S256';
    } else {
      _pendingCodeVerifier = null;
    }

    final uri = Uri.parse(config.authorizeUrl).replace(queryParameters: query);
      try {
        // VK: в Chrome Custom Tab (flutter_custom_tabs по умолчанию открывает
        // Chrome, а не дефолтный браузер). Ранний «Ошибка загрузки» был НЕ
        // движком браузера: страница VK падала из-за code_challenge_method=
        // sha256 в любом движке (см. заметку у _pkceMethods). Chrome Custom Tab
        // оставляем как стабильный выбор движка и корректный возврат по
        // dharana:// через мост колбэк-страницы.
        // Яндекс — в системном браузере: подтверждённый рабочий путь.
        if (provider == 'vk') {
          await custom_tabs.launchUrl(uri);
        } else {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!launched) throw Exception('Could not open the browser');
        }
      } catch (_) {
        _pendingState = null;
        _pendingProvider = null;
        _pendingCodeVerifier = null;
        rethrow;
      }
    }

  /// Завершает флоу по ссылке из колбэка: сверяет state, обменивает код на
  /// JWT. Возвращает true, если это был наш OAuth-колбэк (и его удалось).
Future<bool> completeOAuthCallback(Uri uri) async {
    // Лог для диагностики: что именно провайдер вернул в App Link.
    debugPrint('OAuth callback: $uri');
final provider = _pendingProvider;
    final expectedState = _pendingState;
    if (provider == null || expectedState == null) return false;
    // Пути бывают двух видов: App Link `/app/auth/{p}/callback` и запасной
    // вариант по собственной схеме `/auth/{p}/callback` (см. AndroidManifest).
    if (!uri.path.endsWith('/auth/$provider/callback')) return false;

final codeVerifier = _pendingCodeVerifier;

// Разовый: любой второй колбэк (например, повторное открытие ссылки из
// истории браузера) уже не наш.
_pendingState = null;
_pendingProvider = null;
_pendingCodeVerifier = null;

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

    // VK ID: обмен кода на токен делаем сами — серверный обмен невозможен
    // (нужен device_id из колбэка), а /auth/vk на бэкенде проверяет готовый
    // access_token. Остальные провайдеры (Яндекс) обменивает бэкенд.
    if (provider == 'vk') {
      final deviceId = uri.queryParameters['device_id'];
      final token = await _exchangeVkCode(code, deviceId, state, codeVerifier);
      final vkResponse = await _api.dio.post('/auth/vk', data: {
        'access_token': token,
      });
      final auth = AuthResponse.fromJson(vkResponse.data);
      await _api.saveToken(auth.accessToken);
      return true;
    }

    final response = await _api.dio.post('/auth/$provider', data: {
      'code': code,
      'redirect_uri': appCallbackUrl(provider),
      if (codeVerifier != null) 'code_verifier': codeVerifier,
      // У Яндекса credentials выдаются на каждую платформу отдельно, поэтому
      // код обменяет сервер secret'ом ИМЕННО этого клиента.
      if (yandexClientId.isNotEmpty) 'client_id': yandexClientId,
    });
    final auth = AuthResponse.fromJson(response.data);
    await _api.saveToken(auth.accessToken);
    return true;
  }

  /// `POST id.vk.ru/oauth2/auth` — public client, без client_secret (по PKCE).
  Future<String> _exchangeVkCode(
    String code,
    String? deviceId,
    String state,
    String? codeVerifier,
  ) async {
    if (deviceId == null || deviceId.isEmpty) {
      throw Exception('OAUTH_NO_DEVICE_ID');
    }
    if (codeVerifier == null || codeVerifier.isEmpty) {
      throw Exception('OAUTH_NO_VERIFIER');
    }
    // Public client, без client_secret (PKCE). client_id и redirect_uri
    // ОБЯЗАТЕЛЬНЫ: без них эндпоинт отвечает HTTP 500 с пустым телом
    // (проверено 2026-10-06), а Dio бросает исключение, которое маскируется
    // под общую ошибку входа. Код приходит в v2-формате (vk2.a.*) — это
    // ок, сервер сам определяет flow по коду.
    final dio = Dio();
    final response = await dio.post(
      vkTokenUrl,
      queryParameters: {
        'grant_type': 'authorization_code',
        'redirect_uri': appCallbackUrl('vk'),
        'client_id': vkClientId,
        'code_verifier': codeVerifier,
        'state': state,
        'device_id': deviceId,
      },
      data: 'code=$code',
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
        headers: {'Accept': 'application/json'},
        responseType: ResponseType.plain,
      ),
    );
    final body = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (body is! Map || body['error'] != null) {
      debugPrint(
        'VK token exchange failed: ${response.statusCode} ${response.data}',
      );
      throw Exception('OAUTH_VK_TOKEN_FAILED');
    }
    final token = body['access_token'];
    if (token is! String || token.isEmpty) {
      throw Exception('OAUTH_VK_TOKEN_FAILED');
    }
    return token;
  }

/// Отменяет ожидание возврата из браузера (пользователь вернулся сам).
static void cancelOAuthLogin() {
_pendingState = null;
_pendingProvider = null;
_pendingCodeVerifier = null;
}

static String _randomNonce() {
final random = Random.secure();
final bytes = List<int>.generate(16, (_) => random.nextInt(256));
return base64Url.encode(bytes).replaceAll('=', '');
}

/// PKCE: code_challenge = BASE64URL(SHA-256(verifier)) без padding.
static String _pkceChallenge(String verifier) {
final digest = sha256.convert(utf8.encode(verifier)).bytes;
return base64Url.encode(digest).replaceAll('=', '');
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
