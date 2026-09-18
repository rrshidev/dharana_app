import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  static const _difficulties = ['beginner', 'intermediate', 'advanced'];
  static const _durations = [15, 30, 60];
  static const _focuses = ['', 'back', 'legs', 'balance', 'flexibility', 'energy'];

  final _api = ApiClient();

  String _difficulty = 'intermediate';
  int _duration = 30;
  String _focus = '';

  bool _generating = false;
  bool _starting = false;
  Map<String, dynamic>? _result;
  bool _limitHit = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
      _limitHit = false;
      _result = null;
    });
    try {
      final resp = await _api.generatePractice(
        difficulty: _difficulty,
        durationMinutes: _duration,
        focus: _focus.isEmpty ? null : _focus,
      );
      if (mounted) setState(() => _result = resp);
    } on DioException catch (e) {
      if (mounted) {
        if (e.response?.statusCode == 403) {
          setState(() => _limitHit = true);
        } else {
          setState(() => _error = 'Не удалось сгенерировать практику. Попробуйте ещё раз.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не удалось сгенерировать практику. Попробуйте ещё раз.');
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _start() async {
    final result = _result;
    if (result == null) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await _api.startPractice();
    } catch (_) {}

    if (mounted) {
      setState(() => _starting = false);
      final items = result['items'] as List<dynamic>? ?? [];
      final asanas = items.map((e) {
        final m = (e as Map<String, dynamic>);
        return {
          'name': m['name'],
          'duration_seconds': m['duration_seconds'],
          'rest_seconds': m['rest_seconds'] ?? 0,
        };
      }).toList();
      await context.push('/timer', extra: asanas);
    }
  }

  String _fmtTotal(int seconds) {
    final m = seconds ~/ 60;
    if (m >= 60 && m % 60 == 0) return '${m ~/ 60} час';
    return '$m минут';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Генератор практики'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Подберём последовательность асан под ваш уровень и цели.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          _Section(
            title: 'Уровень',
            children: _difficultyChips(),
          ),
          const SizedBox(height: 20),

          _Section(
            title: 'Длительность',
            children: _durationChips(),
          ),
          const SizedBox(height: 20),

          _Section(
            title: 'Фокус',
            children: _focusChips(),
          ),
          const SizedBox(height: 24),

          if (_limitHit) _limitCard(context),

          if (_error != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.Danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: AppTheme.Danger),
                ),
              ),
            ),
          ],

          if (_result == null)
            FilledButton(
              onPressed: _generating ? null : _generate,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_generating ? 'Составляем последовательность…' : 'Сгенерировать'),
            )
          else
            _resultCard(context),

          if (_starting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  List<Widget> _difficultyChips() {
    return _difficulties.map((d) {
      final label = switch (d) {
        'beginner' => 'Начинающий',
        'intermediate' => 'Средний',
        _ => 'Продвинутый',
      };
      return _Chip(
        label: label,
        selected: _difficulty == d,
        onTap: () {
          setState(() {
            _difficulty = d;
            _result = null;
          });
        },
      );
    }).toList();
  }

  List<Widget> _durationChips() {
    return _durations.map((d) {
      return _Chip(
        label: '$d минут',
        selected: _duration == d,
        onTap: () {
          setState(() {
            _duration = d;
            _result = null;
          });
        },
      );
    }).toList();
  }

  List<Widget> _focusChips() {
    return _focuses.map((f) {
      final label = switch (f) {
        '' => 'Без фокуса',
        'back' => 'Спина',
        'legs' => 'Ноги',
        'balance' => 'Баланс',
        'flexibility' => 'Гибкость',
        _ => 'Энергия',
      };
      return _Chip(
        label: label,
        selected: _focus == f,
        onTap: () {
          setState(() {
            _focus = f;
            _result = null;
          });
        },
      );
    }).toList();
  }

  Widget _resultCard(BuildContext context) {
    final result = _result!;
    final items = (result['items'] as List<dynamic>? ?? []);
    final totalSeconds = (result['total_duration_seconds'] as num?)?.toInt() ?? 0;
    final calories = (result['estimated_calories'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ваша практика', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => setState(() => _result = null),
              child: const Text('Пересобрать'),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.Surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.CardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(items.length, (i) {
                final item = items[i] as Map<String, dynamic>;
                final name = item['name'] ?? '';
                final dure = (item['duration_seconds'] as num?)?.toInt() ?? 0;
                final rest = (item['rest_seconds'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1}.',
                          style: TextStyle(color: AppTheme.TextSecondary, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      Text(
                        rest > 0 ? '$dure с + $rest с' : '$dure с',
                        style: TextStyle(color: AppTheme.TextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Row(
                children: [
                  Text(
                    'Асан: ${items.length}',
                    style: TextStyle(color: AppTheme.TextSecondary, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    'Итого: ${_fmtTotal(totalSeconds)}',
                    style: TextStyle(color: AppTheme.TextSecondary, fontSize: 13),
                  ),
                  if (calories > 0)
                    Text(
                      ' · ~$calories ккал',
                      style: TextStyle(color: AppTheme.TextSecondary, fontSize: 13),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _starting ? null : _start,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Начать практику'),
        ),
      ],
    );
  }

  Widget _limitCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.Surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.CardBorder),
      ),
      child: Column(
        children: [
          const Text('⏳', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            'Лимит на сегодня исчерпан',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Бесплатно можно генерировать одну практику в день. Подключите Premium — и практикуйте без ограничений.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.TextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push('/subscription'),
              child: const Text('Получить Premium'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppTheme.TextSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.Accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppTheme.Accent : AppTheme.CardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? AppTheme.Accent : AppTheme.TextSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}