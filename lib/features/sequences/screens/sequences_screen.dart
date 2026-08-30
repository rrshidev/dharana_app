import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:video_player/video_player.dart';

class SequencesScreen extends StatefulWidget {
  const SequencesScreen({super.key});

  @override
  State<SequencesScreen> createState() => _SequencesScreenState();
}

class _SequencesScreenState extends State<SequencesScreen> {
  final _api = ApiClient();
  List<SequenceVideo> _sequences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSequences();
  }

  Future<void> _loadSequences() async {
    try {
      final sequences = await _api.getSequenceVideos();
      if (mounted) {
        setState(() {
          _sequences = sequences;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Готовые комплексы'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _sequences.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_outlined, size: 64, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'Комплексы пока не добавлены',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSequences,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sequences.length,
                    itemBuilder: (context, index) {
                      final seq = _sequences[index];
                      return _SequenceCard(sequence: seq);
                    },
                  ),
                ),
    );
  }
}

class _SequenceCard extends StatefulWidget {
  final SequenceVideo sequence;
  const _SequenceCard({required this.sequence});

  @override
  State<_SequenceCard> createState() => _SequenceCardState();
}

class _SequenceCardState extends State<_SequenceCard> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null && widget.sequence.videoUrl != null) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse('${ApiClient.baseUrl}${widget.sequence.videoUrl}'),
      )..initialize().then((_) {
          setState(() {});
          _controller!.play();
          _isPlaying = true;
        });
    } else if (_controller != null) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          _isPlaying = false;
        } else {
          _controller!.play();
          _isPlaying = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              color: AppTheme.surfaceLight,
              child: Center(
                child: widget.sequence.accessible
                    ? IconButton(
                        icon: const Icon(Icons.play_circle_outline, size: 56, color: AppTheme.accent),
                        onPressed: _togglePlay,
                      )
                    : const Icon(Icons.lock, size: 40, color: AppTheme.textSecondary),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sequence.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      if (widget.sequence.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Premium',
                            style: TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.sequence.accessible && _controller != null && _controller!.value.isInitialized)
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: _togglePlay,
                    color: AppTheme.accent,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
