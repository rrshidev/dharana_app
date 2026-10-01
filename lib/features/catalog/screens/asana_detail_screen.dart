import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/app/language_controller.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/shared/widgets/share_button.dart';
import 'package:dharana_app/l10n/app_localizations.dart';
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite
                ? l10n.addedToFavorites
                : l10n.removedFromFavorites),
            backgroundColor: AppTheme.SurfaceLight,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.errorMessage('$e')),
              backgroundColor: AppTheme.Danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = LanguageController.instance.value.languageCode;
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.AccentInk))
          : _asana == null
              ? Center(child: Text(l10n.asanaNotFound))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 350,
                      pinned: true,
                      actions: [
                        ShareButton(
                          message:
                              '${_asana!.displayName(lang)}\nhttps://dharana.ru/$lang/asana/${Uri.encodeComponent(widget.asanaName)}',
                        ),
                        IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? AppTheme.Danger : AppTheme.TextPrimary,
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
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        '${ApiClient.baseUrl}${_asana!.imageUrl}',
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppTheme.Surface,
                                      child: Icon(
                                        Icons.self_improvement,
                                        size: 80,
                                        color: AppTheme.AccentInk,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: AppTheme.Surface,
                                child: Icon(
                                  Icons.self_improvement,
                                  size: 80,
                                  color: AppTheme.AccentInk,
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
                              _asana!.displayName(
                                  Localizations.localeOf(context).languageCode),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.SurfaceLight,
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
                                    label: Text(_effectLabel(l10n, effect)),
                                    backgroundColor: AppTheme.SurfaceLight,
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
                                  color: AppTheme.Danger.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.Danger.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded,
                                            color: AppTheme.Danger, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          l10n.contraindications,
                                          style: TextStyle(
                                            color: AppTheme.Danger,
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
                                            style: TextStyle(
                                                color: AppTheme.TextSecondary)),
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
                                l10n.description,
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
                                l10n.video,
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
                                  color: AppTheme.SurfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.AccentInk.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock, color: AppTheme.AccentInk),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.videoPremium,
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _video!.message ?? l10n.getPremium,
                                            style: TextStyle(fontSize: 12, color: AppTheme.TextSecondary),
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
                                  context.push(
                                    '/timer',
                                    extra: <Map<String, dynamic>>[
                                      {
                                        'name': _asana!.name,
                                        'duration_seconds': 60,
                                        'rest_seconds': 15,
                                      }
                                    ],
                                  );
                                },
                                icon: const Icon(Icons.timer_outlined),
                                label: Text(l10n.startPractice),
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

  String _effectLabel(AppLocalizations l10n, String effect) {
    switch (effect) {
      case 'back_pain':
        return l10n.effectBackPain;
      case 'calm_mind':
        return l10n.effectCalmMind;
      case 'boost_energy':
        return l10n.effectBoostEnergy;
      case 'digestion':
        return l10n.effectDigestion;
      case 'flexibility':
        return l10n.effectFlexibility;
      case 'balance':
        return l10n.effectBalance;
      case 'strength':
        return l10n.effectStrength;
      case 'stress_relief':
        return l10n.effectStressRelief;
    }
    return effect;
  }
}
