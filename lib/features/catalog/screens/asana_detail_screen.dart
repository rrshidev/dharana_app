import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/features/timer/screens/timer_screen.dart';
import 'package:video_player/video_player.dart';

class AsanaDetailScreen extends StatefulWidget {
  final String asanaName;

  const AsanaDetailScreen({super.key, required this.asanaName});

  @override
  State<AsanaDetailScreen> createState() => _AsanaDetailScreenState();
}

class _AsanaDetailScreenState extends State<AsanaDetailScreen> {
  final _api = ApiClient();
  Asana? _asana;
  bool _isLoading = true;
  bool _isFavorite = false;
  Video? _video;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadAsana();
    _checkFavorite();
    _loadVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadAsana() async {
    try {
      final response =
          await _api.dio.get('/asanas/${Uri.encodeComponent(widget.asanaName)}');
      if (mounted) {
        setState(() {
          _asana = Asana.fromJson(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final fav = await _api.isFavorite(widget.asanaName);
      if (mounted) setState(() => _isFavorite = fav);
    } catch (_) {}
  }

  Future<void> _loadVideo() async {
    try {
      final video = await _api.getAsanaVideo(widget.asanaName);
      if (video != null && video.accessible && video.videoUrl != null && mounted) {
        setState(() => _video = video);
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse('${ApiClient.baseUrl}${video.videoUrl}'),
        )..initialize().then((_) {
            if (mounted) setState(() => _isVideoInitialized = true);
          });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    try {
      await _api.toggleFavorite(widget.asanaName);
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Добавлено в избранное' : 'Удалено из избранного'),
            backgroundColor: AppTheme.surfaceLight,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _asana == null
              ? const Center(child: Text('Асана не найдена'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 350,
                      pinned: true,
                      actions: [
                        IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? AppTheme.danger : AppTheme.textPrimary,
                          ),
                          onPressed: _toggleFavorite,
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _asana!.imageUrl != null
                            ? InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 3.0,
                                child: Center(
                                  child: Image.network(
                                    '${ApiClient.baseUrl}${_asana!.imageUrl}',
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppTheme.surface,
                                      child: const Icon(
                                        Icons.self_improvement,
                                        size: 80,
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: AppTheme.surface,
                                child: const Icon(
                                  Icons.self_improvement,
                                  size: 80,
                                  color: AppTheme.accent,
                                ),
                              ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _asana!.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _asana!.categoryName ?? '',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppTheme.starsText(_asana!.difficulty),
                                  style: AppTheme.difficultyStars(_asana!.difficulty),
                                ),
                              ],
                            ),
                            if (_asana!.effects.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _asana!.effects.map((effect) {
                                  return Chip(
                                    label: Text(_effectLabel(effect)),
                                    backgroundColor: AppTheme.surfaceLight,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 0),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                            ],
                            if (_asana!.contraindications.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.danger.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded,
                                            color: AppTheme.danger, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Противопоказания',
                                          style: TextStyle(
                                            color: AppTheme.danger,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...(_asana!.contraindications.map(
                                      (c) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text('• $c',
                                            style: const TextStyle(
                                                color: AppTheme.textSecondary)),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ],
                            if (_asana!.description != null &&
                                _asana!.description!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Описание',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _asana!.description!,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.6,
                                    ),
                              ),
                            ],
                            if (_video != null && _video!.accessible && _isVideoInitialized) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Видео',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      VideoPlayer(_videoController!),
                                      if (!_videoController!.value.isPlaying)
                                        GestureDetector(
                                          onTap: () => setState(() => _videoController!.play()),
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (_video != null && !_video!.accessible) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock, color: AppTheme.accent),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Видео доступно по подписке',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _video!.message ?? 'Оформите Premium для доступа',
                                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TimerScreen(
                                        asanas: [
                                          {'name': _asana!.name, 'duration_seconds': 60, 'rest_seconds': 15}
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.timer_outlined),
                                label: const Text('Начать практику'),
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _effectLabel(String effect) {
    const labels = {
      'back_pain': '🦴 Спина',
      'calm_mind': '🧘 Успокоение',
      'boost_energy': '⚡ Энергия',
      'digestion': '🌿 Пищеварение',
      'flexibility': '🤸 Гибкость',
      'balance': '⚖️ Баланс',
      'strength': '💪 Сила',
      'stress_relief': '😌 Антистресс',
    };
    return labels[effect] ?? effect;
  }
}
