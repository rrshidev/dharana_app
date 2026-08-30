class Asana {
  final String name;
  final String? categoryId;
  final String? categoryName;
  final String? description;
  final String? imageUrl;
  final int difficulty;
  final List<String> effects;
  final List<String> contraindications;

  Asana({
    required this.name,
    this.categoryId,
    this.categoryName,
    this.description,
    this.imageUrl,
    this.difficulty = 1,
    this.effects = const [],
    this.contraindications = const [],
  });

  factory Asana.fromJson(Map<String, dynamic> json) {
    return Asana(
      name: json['name'] ?? '',
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      description: json['description'],
      imageUrl: json['image_url'],
      difficulty: json['difficulty'] ?? 1,
      effects: List<String>.from(json['effects'] ?? []),
      contraindications: List<String>.from(json['contraindications'] ?? []),
    );
  }
}

class Category {
  final String id;
  final String displayName;
  final String description;
  final int asanaCount;

  Category({
    required this.id,
    required this.displayName,
    required this.description,
    required this.asanaCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? '',
      description: json['description'] ?? '',
      asanaCount: json['asana_count'] ?? 0,
    );
  }
}

class AsanaListResponse {
  final int total;
  final List<Asana> items;
  final int limit;
  final int offset;

  AsanaListResponse({
    required this.total,
    required this.items,
    required this.limit,
    required this.offset,
  });

  factory AsanaListResponse.fromJson(Map<String, dynamic> json) {
    return AsanaListResponse(
      total: json['total'] ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => Asana.fromJson(e))
          .toList(),
      limit: json['limit'] ?? 50,
      offset: json['offset'] ?? 0,
    );
  }
}

class User {
  final int id;
  final String? email;
  final String? name;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final int? telegramId;
  final bool isAdmin;
  final int totalPracticeMinutes;
  final int totalPracticeDays;
  final int currentStreak;
  final String? lastPracticeAt;
  final String? createdAt;

  User({
    required this.id,
    this.email,
    this.name,
    this.username,
    this.bio,
    this.avatarUrl,
    this.telegramId,
    this.isAdmin = false,
    this.totalPracticeMinutes = 0,
    this.totalPracticeDays = 0,
    this.currentStreak = 0,
    this.lastPracticeAt,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'],
      name: json['name'],
      username: json['username'],
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      telegramId: json['telegram_id'],
      isAdmin: json['is_admin'] ?? false,
      totalPracticeMinutes: json['total_practice_minutes'] ?? 0,
      totalPracticeDays: json['total_practice_days'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      lastPracticeAt: json['last_practice_at'],
      createdAt: json['created_at'],
    );
  }
}

class UserAvatar {
  final int id;
  final String url;
  final bool isPrimary;

  UserAvatar({required this.id, required this.url, this.isPrimary = false});

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    return UserAvatar(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }
}

class Favorite {
  final int id;
  final String asanaName;
  final String? createdAt;

  Favorite({required this.id, required this.asanaName, this.createdAt});

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] ?? 0,
      asanaName: json['asana_name'] ?? '',
      createdAt: json['created_at'],
    );
  }
}

class PracticeSession {
  final int id;
  final String status;
  final List<String> asanasPracticed;
  final Map<String, int> asanaDurations;
  final int restSeconds;
  final int totalDurationSeconds;
  final String? startedAt;
  final String? completedAt;
  final bool canRepeat;

  PracticeSession({
    required this.id,
    this.status = 'completed',
    this.asanasPracticed = const [],
    this.asanaDurations = const {},
    this.restSeconds = 15,
    this.totalDurationSeconds = 0,
    this.startedAt,
    this.completedAt,
    this.canRepeat = true,
  });

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'completed',
      asanasPracticed: List<String>.from(json['asanas_practiced'] ?? []),
      asanaDurations: Map<String, int>.from(json['asana_durations'] ?? {}),
      restSeconds: json['rest_seconds'] ?? 15,
      totalDurationSeconds: json['total_duration_seconds'] ?? 0,
      startedAt: json['started_at'],
      completedAt: json['completed_at'],
      canRepeat: json['can_repeat'] ?? true,
    );
  }
}

class PracticeStats {
  final int totalMinutes;
  final int totalDays;
  final int totalSessions;
  final int currentStreak;
  final List<Map<String, dynamic>> favoriteAsanas;

  PracticeStats({
    this.totalMinutes = 0,
    this.totalDays = 0,
    this.totalSessions = 0,
    this.currentStreak = 0,
    this.favoriteAsanas = const [],
  });

  factory PracticeStats.fromJson(Map<String, dynamic> json) {
    return PracticeStats(
      totalMinutes: json['total_minutes'] ?? 0,
      totalDays: json['total_days'] ?? 0,
      totalSessions: json['total_sessions'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      favoriteAsanas: List<Map<String, dynamic>>.from(json['favorite_asanas'] ?? []),
    );
  }
}

class Sequence {
  final int id;
  final String name;
  final String? description;
  final List<Map<String, dynamic>> asanas;
  final bool isPublic;
  final String? createdAt;

  Sequence({
    required this.id,
    required this.name,
    this.description,
    this.asanas = const [],
    this.isPublic = false,
    this.createdAt,
  });

  factory Sequence.fromJson(Map<String, dynamic> json) {
    return Sequence(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      asanas: List<Map<String, dynamic>>.from(json['asanas'] ?? []),
      isPublic: json['is_public'] ?? false,
      createdAt: json['created_at'],
    );
  }
}

class AuthResponse {
  final String accessToken;
  final User user;

  AuthResponse({required this.accessToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}

class SubscriptionStatus {
  final bool isPremium;
  final String? subscriptionType;
  final String? subscriptionStatus;
  final bool canGenerate;

  SubscriptionStatus({
    required this.isPremium,
    this.subscriptionType,
    this.subscriptionStatus,
    required this.canGenerate,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isPremium: json['is_premium'] ?? false,
      subscriptionType: json['subscription_type'],
      subscriptionStatus: json['subscription_status'],
      canGenerate: json['can_generate'] ?? true,
    );
  }
}

class Video {
  final int id;
  final String? asanaName;
  final bool isPremium;
  final bool accessible;
  final String? videoUrl;
  final String? message;

  Video({
    required this.id,
    this.asanaName,
    this.isPremium = false,
    this.accessible = false,
    this.videoUrl,
    this.message,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? 0,
      asanaName: json['asana_name'],
      isPremium: json['is_premium'] ?? false,
      accessible: json['accessible'] ?? false,
      videoUrl: json['video_url'],
      message: json['message'],
    );
  }
}

class SequenceVideo {
  final int id;
  final String name;
  final bool isPremium;
  final bool accessible;
  final String? videoUrl;

  SequenceVideo({
    required this.id,
    required this.name,
    this.isPremium = false,
    this.accessible = false,
    this.videoUrl,
  });

  factory SequenceVideo.fromJson(Map<String, dynamic> json) {
    return SequenceVideo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isPremium: json['is_premium'] ?? false,
      accessible: json['accessible'] ?? false,
      videoUrl: json['video_url'],
    );
  }
}
