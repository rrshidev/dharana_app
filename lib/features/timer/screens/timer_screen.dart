import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/core/services/sound_service.dart';
import 'package:dharana_app/features/timer/screens/timer_setup_screen.dart';

enum TimerMode { idle, asana, rest, compensation, paused }

class TimerScreen extends StatefulWidget {
  final Sequence? sequence;
  final List<Map<String, dynamic>>? asanas;

  const TimerScreen({super.key, this.sequence, this.asanas});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  TimerMode _mode = TimerMode.idle;
  bool _isRunning = false;
  bool _isPaused = false;
  int _currentAsanaIndex = 0;
  int _secondsRemaining = 0;
  int _totalSeconds = 0;

  Timer? _timer;
  DateTime? _lastTick;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  List<Map<String, dynamic>> _asanas = [];
  final List<String> _completedAsanas = [];
  final Map<String, int> _asanaDurations = {};
  int _sessionId = 0;

  @override
  void initState() {
    super.initState();
    SoundService().init();
    _progressController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
      value: 0,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    if (widget.sequence != null) {
      _asanas = List<Map<String, dynamic>>.from(widget.sequence!.asanas);
    } else if (widget.asanas != null) {
      _asanas = List<Map<String, dynamic>>.from(widget.asanas!);
    }

    if (_asanas.isNotEmpty) {
      _secondsRemaining = _asanas[0]['duration_seconds'] ?? 60;
      _totalSeconds = _secondsRemaining;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPractice() async {
    if (_asanas.isEmpty) return;

    try {
      final resp = await ApiClient().startPractice();
      _sessionId = resp['id'] ?? 0;
    } catch (_) {}

    setState(() {
      _mode = TimerMode.asana;
      _isRunning = true;
      _isPaused = false;
      _currentAsanaIndex = 0;
      _completedAsanas.clear();
      _asanaDurations.clear();
      _secondsRemaining = _asanas[0]['duration_seconds'] ?? 60;
      _totalSeconds = _secondsRemaining;
      _progressController.value = 0;
    });
    _pulseController.repeat(reverse: true);
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isRunning || _isPaused) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final elapsed = now.difference(_lastTick!).inSeconds;
      if (elapsed < 1) return;
      _lastTick = now;

      setState(() {
        _secondsRemaining -= elapsed;
        if (_secondsRemaining < 0) _secondsRemaining = 0;
        if (_totalSeconds > 0) {
          _progressController.value = 1.0 - (_secondsRemaining / _totalSeconds);
        }
      });

      if (_secondsRemaining <= 3 && _secondsRemaining > 0) {
        SoundService().playBeep();
      }

      if (_secondsRemaining <= 0) {
        timer.cancel();
        SoundService().playDone();
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() async {
    SoundService().playDone();

    if (_mode == TimerMode.asana) {
      final name = _asanas[_currentAsanaIndex]['name'] as String;
      _completedAsanas.add(name);
      final duration = (_asanas[_currentAsanaIndex]['duration_seconds'] as int?) ?? 60;
      _asanaDurations[name] = (_asanaDurations[name] ?? 0) + duration;

      if (_currentAsanaIndex < _asanas.length - 1) {
        final restSeconds = _asanas[_currentAsanaIndex]['rest_seconds'] ?? 15;
        setState(() {
          _mode = TimerMode.rest;
          _secondsRemaining = restSeconds;
          _totalSeconds = restSeconds;
          _progressController.value = 0;
        });
        _startCountdown();
      } else {
        final compensation = 10;
        setState(() {
          _mode = TimerMode.compensation;
          _secondsRemaining = compensation;
          _totalSeconds = compensation;
          _progressController.value = 0;
        });
        _startCountdown();
      }
    } else if (_mode == TimerMode.rest) {
      _currentAsanaIndex++;
      final nextDuration = _asanas[_currentAsanaIndex]['duration_seconds'] ?? 60;
      setState(() {
        _mode = TimerMode.asana;
        _secondsRemaining = nextDuration;
        _totalSeconds = nextDuration;
        _progressController.value = 0;
      });
      _startCountdown();
    } else if (_mode == TimerMode.compensation) {
      _timer?.cancel();
      _pulseController.stop();
      setState(() {
        _isRunning = false;
        _mode = TimerMode.idle;
        _progressController.value = 1.0;
      });
      await _savePracticeResult();
      if (mounted) _showCompletionDialog();
    }
  }

  Future<void> _savePracticeResult() async {
    try {
      final restSeconds = _asanas.isNotEmpty ? (_asanas[0]['rest_seconds'] ?? 15) : 15;
      await ApiClient().completePractice(
        _sessionId,
        asanasPracticed: _completedAsanas,
        asanaDurations: _asanaDurations,
        restSeconds: restSeconds,
      );
    } catch (_) {}
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _pulseController.stop();
        _mode = TimerMode.paused;
      } else {
        _pulseController.repeat(reverse: true);
        _mode = _currentAsanaIndex < _asanas.length &&
                _completedAsanas.length <= _currentAsanaIndex
            ? TimerMode.asana
            : TimerMode.rest;
        _lastTick = DateTime.now();
        _startCountdown();
      }
    });
  }

  void _stopPractice() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _mode = TimerMode.idle;
    });
    if (_completedAsanas.isNotEmpty) {
      _savePracticeResult();
    }
  }

  void _showCompletionDialog() {
    final totalDuration = _asanaDurations.values.fold(0, (sum, v) => sum + v);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.Surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppTheme.AccentGreen, size: 64),
            const SizedBox(height: 16),
            Text('Практика завершена!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '${_completedAsanas.length} асан · ${_fmt(totalDuration)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _resetTimer();
              },
              child: const Text('Начать заново'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _mode = TimerMode.idle;
      _currentAsanaIndex = 0;
      _completedAsanas.clear();
      _asanaDurations.clear();
      _progressController.value = 0;
      if (_asanas.isNotEmpty) {
        _secondsRemaining = _asanas[0]['duration_seconds'] ?? 60;
        _totalSeconds = _secondsRemaining;
      }
    });
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _modeLabel() {
    switch (_mode) {
      case TimerMode.idle:
        return 'Готов';
      case TimerMode.asana:
        return 'Асана';
      case TimerMode.rest:
        return 'Отдых';
      case TimerMode.compensation:
        return 'Завершение';
      case TimerMode.paused:
        return 'Пауза';
    }
  }

  Color _modeColor() {
    switch (_mode) {
      case TimerMode.idle:
        return AppTheme.TextSecondary;
      case TimerMode.asana:
        return AppTheme.Accent;
      case TimerMode.rest:
        return AppTheme.AccentGreen;
      case TimerMode.compensation:
        return const Color(0xFF7B8CDE);
      case TimerMode.paused:
        return AppTheme.TextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.Background,
      appBar: AppBar(
        title: const Text('Таймер'),
        backgroundColor: AppTheme.Background,
        actions: [
          if (_isRunning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopPractice,
              tooltip: 'Остановить',
            ),
        ],
      ),
      body: _asanas.isEmpty
          ? _buildEmptyState()
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildTimerCircle(),
                  const SizedBox(height: 20),
                  _buildAsanaInfo(),
                  const SizedBox(height: 24),
                  _buildControls(),
                  const SizedBox(height: 16),
                  _buildProgressList(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 64, color: AppTheme.TextSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Нет асан для практики', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Добавьте асаны в настройках', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const TimerSetupScreen()),
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('Настроить'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle() {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _pulseController]),
      builder: (context, child) {
        final pulse = (_isRunning && !_isPaused)
            ? 1.0 + (_pulseController.value * 0.02)
            : 1.0;
        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: _progressController.value,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.SurfaceLight,
                    valueColor: AlwaysStoppedAnimation(_modeColor()),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _fmt(_secondsRemaining),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: _modeColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _modeLabel(),
                      style: TextStyle(
                        fontSize: 14,
                        color: _modeColor().withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAsanaInfo() {
    if (_asanas.isEmpty) return const SizedBox();
    final current = _asanas[_currentAsanaIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            current['name'] ?? '',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${_currentAsanaIndex + 1} / ${_asanas.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (!_isRunning && _mode == TimerMode.idle) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startPractice,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Начать практику'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.replay,
          label: 'Заново',
          onTap: _resetTimer,
        ),
        const SizedBox(width: 24),
        _buildControlButton(
          icon: _isPaused ? Icons.play_arrow : Icons.pause,
          label: _isPaused ? 'Продолжить' : 'Пауза',
          onTap: _togglePause,
          isLarge: true,
        ),
        const SizedBox(width: 24),
        _buildControlButton(
          icon: Icons.skip_next,
          label: 'Далее',
          onTap: _skipToNext,
        ),
      ],
    );
  }

  void _skipToNext() {
    if (!_isRunning || _isPaused) return;
    _timer?.cancel();
    _secondsRemaining = 0;
    _onTimerComplete();
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 64.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLarge ? AppTheme.Accent : AppTheme.SurfaceLight,
              border: Border.all(color: AppTheme.CardBorder),
            ),
            child: Icon(
              icon,
              color: isLarge ? AppTheme.Background : AppTheme.TextPrimary,
              size: isLarge ? 32 : 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: AppTheme.TextSecondary)),
        ],
      ),
    );
  }

  Widget _buildProgressList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _asanas.length,
        itemBuilder: (context, index) {
          final asana = _asanas[index];
          final isCompleted = _completedAsanas.contains(asana['name']);
          final isCurrent = index == _currentAsanaIndex &&
              (_mode == TimerMode.asana || _mode == TimerMode.paused);

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrent
                  ? _modeColor().withValues(alpha: 0.15)
                  : isCompleted
                      ? AppTheme.AccentGreen.withValues(alpha: 0.08)
                      : AppTheme.Surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent
                    ? _modeColor().withValues(alpha: 0.5)
                    : isCompleted
                        ? AppTheme.AccentGreen.withValues(alpha: 0.3)
                        : AppTheme.CardBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isCurrent
                          ? Icons.play_circle
                          : Icons.circle_outlined,
                  color: isCompleted
                      ? AppTheme.AccentGreen
                      : isCurrent
                          ? _modeColor()
                          : AppTheme.TextSecondary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    asana['name'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: isCompleted
                          ? AppTheme.AccentGreen
                          : isCurrent
                              ? AppTheme.TextPrimary
                              : AppTheme.TextSecondary,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  '${asana['duration_seconds'] ?? 60}с',
                  style: TextStyle(fontSize: 11, color: AppTheme.TextSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
