import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dharana_app/core/models/models.dart';

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  static const String _apiPrefix = '$baseUrl/api/v1';
  static const _tokenKey = 'jwt_token';

  late final Dio _dio;
  final _picker = ImagePicker();

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _apiPrefix,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  String resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$baseUrl$url';
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final resp = await _dio.get('/profile');
    return resp.data as Map<String, dynamic>;
  }

  Future<void> updateProfile({String? name, String? username, String? bio}) async {
    await _dio.patch('/profile', data: {
      if (name != null) 'name': name,
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
    });
  }

  Future<List<Map<String, dynamic>>> getAvatars() async {
    final resp = await _dio.get('/profile/avatars');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  Future<void> addAvatar(String url) async {
    await _dio.post('/profile/avatars', queryParameters: {'url': url});
  }

  Future<void> deleteAvatar(int avatarId) async {
    await _dio.delete('/profile/avatars/$avatarId');
  }

  Future<void> setPrimaryAvatar(int avatarId) async {
    await _dio.put('/profile/avatars/$avatarId/primary');
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final resp = await _dio.get('/favorites');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  Future<void> toggleFavorite(String asanaName) async {
    final check = await _dio.get('/favorites/check/$asanaName');
    if (check.data['is_favorite'] == true) {
      await _dio.delete('/favorites/$asanaName');
    } else {
      await _dio.post('/favorites/$asanaName');
    }
  }

  Future<bool> isFavorite(String asanaName) async {
    final resp = await _dio.get('/favorites/check/$asanaName');
    return resp.data['is_favorite'] == true;
  }

  Future<Map<String, dynamic>> startPractice({int? sequenceId}) async {
    final resp = await _dio.post('/practice/start', data: {
      if (sequenceId != null) 'sequence_id': sequenceId,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<void> completePractice(
    int sessionId, {
    required List<String> asanasPracticed,
    required Map<String, int> asanaDurations,
    int restSeconds = 15,
  }) async {
    await _dio.put('/practice/$sessionId/complete', data: {
      'asanas_practiced': asanasPracticed,
      'asana_durations': asanaDurations,
      'rest_seconds': restSeconds,
    });
  }

  Future<Map<String, dynamic>> getPracticeHistory({int limit = 20, int offset = 0}) async {
    final resp = await _dio.get('/practice/history', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    final data = resp.data;
    if (data is Map<String, dynamic> && data['sessions'] is List) {
      return data;
    }
    if (data is List) {
      return {'is_premium': false, 'free_repeatable_limit': 3, 'sessions': data};
    }
    return {'is_premium': false, 'free_repeatable_limit': 3, 'sessions': <dynamic>[]};
  }

  Future<Map<String, dynamic>> getPracticeStats() async {
    final resp = await _dio.get('/practice/stats');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSequences() async {
    final resp = await _dio.get('/sequences');
    final data = resp.data;
    if (data is Map<String, dynamic> && data['sequences'] is List) {
      return data;
    }
    if (data is List) {
      return {
        'is_premium': false,
        'free_limit': 3,
        'limit_reached': false,
        'sequences': data,
      };
    }
    return {'is_premium': false, 'free_limit': 3, 'limit_reached': false, 'sequences': <dynamic>[]};
  }

  Future<Map<String, dynamic>> createSequence({
    required String name,
    String? description,
    required List<Map<String, dynamic>> asanas,
  }) async {
    final resp = await _dio.post('/sequences', data: {
      'name': name,
      'description': description,
      'asanas': asanas,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteSequence(int id) async {
    await _dio.delete('/sequences/$id');
  }

  Future<String?> uploadAvatarFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (picked == null) return null;
    return _uploadFile(File(picked.path));
  }

  Future<String?> uploadAvatarFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (picked == null) return null;
    return _uploadFile(File(picked.path));
  }

  Future<String> _uploadFile(File file) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final resp = await _dio.post('/profile/avatars/upload', data: formData);
    return resp.data['url'] as String;
  }

  Future<Video?> getAsanaVideo(String asanaName) async {
    try {
      final resp = await _dio.get('/videos/asana/$asanaName');
      return Video.fromJson(resp.data);
    } catch (_) {
      return null;
    }
  }

  Future<List<SequenceVideo>> getSequenceVideos() async {
    try {
      final resp = await _dio.get('/videos/sequences');
      return (resp.data as List).map((e) => SequenceVideo.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> scanVideos() async {
    await _dio.post('/videos/scan');
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final resp = await _dio.get('/admin/stats');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminStatsSeries({int days = 30}) async {
    final resp = await _dio.get('/admin/stats/series', queryParameters: {'days': days});
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminUsers({String? search}) async {
    final resp = await _dio.get('/admin/users', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'limit': 100,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminUserDetail(int userId) async {
    final resp = await _dio.get('/admin/users/$userId');
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAdminActivity() async {
    final resp = await _dio.get('/admin/activity', queryParameters: {'limit': 50});
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> setUserPremium(int userId, bool isPremium, {int days = 30}) async {
    final resp = await _dio.post('/admin/users/$userId/premium', data: {
      'is_premium': isPremium,
      'days': days,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final resp = await _dio.get('/subscription/status');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPaymentRequisites() async {
    final resp = await _dio.get('/payments/requisites');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadReceipt(
    File file, {
    String? paymentMethod,
    String? amount,
    String? contact,
  }) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      if (paymentMethod != null && paymentMethod.isNotEmpty) 'payment_method': paymentMethod,
      if (amount != null && amount.isNotEmpty) 'amount': amount,
      if (contact != null && contact.isNotEmpty) 'contact': contact,
    });
    final resp = await _dio.post('/payments/receipt', data: formData);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminPayments({String? status}) async {
    final resp = await _dio.get('/admin/payments', queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
      'limit': 100,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reviewPayment(int id, String status, int premiumDays) async {
    final resp = await _dio.post('/admin/payments/$id/review', data: {
      'status': status,
      'premium_days': premiumDays,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPaymentNotifications() async {
    final resp = await _dio.get('/payments/notifications');
    return resp.data as List<dynamic>;
  }

  Future<void> markPaymentNotificationsRead() async {
    await _dio.post('/payments/notifications/read');
  }

  Future<Map<String, dynamic>> createBroadcast({
    required String message,
    required bool audienceFree,
    required bool audiencePremium,
    required bool channelTelegram,
    required bool channelApp,
  }) async {
    final resp = await _dio.post('/admin/broadcast', data: {
      'message': message,
      'audience': {'free': audienceFree, 'premium': audiencePremium},
      'channels': {'telegram': channelTelegram, 'app': channelApp},
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> testBroadcast({
    required String message,
    required bool audienceFree,
    required bool audiencePremium,
    required bool channelTelegram,
    required bool channelApp,
  }) async {
    final resp = await _dio.post('/admin/broadcast/test', data: {
      'message': message,
      'audience': {'free': audienceFree, 'premium': audiencePremium},
      'channels': {'telegram': channelTelegram, 'app': channelApp},
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBroadcastNotifications() async {
    final resp = await _dio.get('/notifications/broadcast');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> markBroadcastNotificationsRead() async {
    final resp = await _dio.post('/notifications/broadcast/read');
    return resp.data as Map<String, dynamic>;
  }
}
