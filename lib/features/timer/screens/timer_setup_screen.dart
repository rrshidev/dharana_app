import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/features/timer/screens/timer_screen.dart';

class TimerSetupScreen extends StatefulWidget {
  const TimerSetupScreen({super.key});

  @override
  State<TimerSetupScreen> createState() => _TimerSetupScreenState();
}

class _TimerSetupScreenState extends State<TimerSetupScreen> {
  final _api = ApiClient();
  List<Asana> _allAsanas = [];
  final List<Map<String, dynamic>> _selectedAsanas = [];
  int _defaultAsanaDuration = 60;
  int _defaultRestDuration = 15;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAsanas();
  }

  Future<void> _loadAsanas() async {
    try {
      final resp = await _api.dio.get('/asanas', queryParameters: {'limit': 200});
      final data = resp.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => Asana.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _allAsanas = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addAsana(Asana asana) {
    final exists = _selectedAsanas.any((a) => a['name'] == asana.name);
    if (exists) return;
    setState(() {
      _selectedAsanas.add({
        'name': asana.name,
        'duration_seconds': _defaultAsanaDuration,
        'rest_seconds': _defaultRestDuration,
      });
    });
  }

  void _removeAsana(int index) {
    setState(() => _selectedAsanas.removeAt(index));
  }

  void _startPractice() {
    if (_selectedAsanas.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(asanas: _selectedAsanas),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка практики')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.Accent))
          : Column(
              children: [
                _buildTimeSettings(),
                _buildSelectedAsanas(),
                _buildAsanaPicker(),
                _buildStartButton(),
              ],
            ),
    );
  }

  Widget _buildTimeSettings() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Время по умолчанию', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDurationPicker(
                    label: 'Асана',
                    value: _defaultAsanaDuration,
                    onChanged: (v) {
                      setState(() {
                        _defaultAsanaDuration = v;
                        for (final a in _selectedAsanas) {
                          a['duration_seconds'] = v;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDurationPicker(
                    label: 'Отдых',
                    value: _defaultRestDuration,
                    onChanged: (v) {
                      setState(() {
                        _defaultRestDuration = v;
                        for (final a in _selectedAsanas) {
                          a['rest_seconds'] = v;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationPicker({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final options = [5, 10, 15, 30, 45, 60, 90, 120, 180, 300];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.SurfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.CardBorder),
          ),
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppTheme.Surface,
            style: TextStyle(color: AppTheme.TextPrimary),
            items: options.map((s) => DropdownMenuItem(
              value: s,
              child: Text(_fmt(s)),
            )).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  String _fmt(int s) {
    if (s < 60) return '${s}с';
    final m = s ~/ 60;
    final sec = s % 60;
    return sec > 0 ? '${m}м ${sec}с' : '${m}мин';
  }

  Widget _buildSelectedAsanas() {
    if (_selectedAsanas.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.playlist_add, size: 48, color: AppTheme.TextSecondary.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('Добавьте асаны из списка ниже',
                style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Expanded(
      flex: 2,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text('Последовательность (${_selectedAsanas.length})',
                style: Theme.of(context).textTheme.titleMedium),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _selectedAsanas.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _selectedAsanas.removeAt(oldIndex);
                  _selectedAsanas.insert(newIndex, item);
                  setState(() {});
                },
                itemBuilder: (context, index) {
                  final a = _selectedAsanas[index];
                  return Card(
                    key: ValueKey('$index-${a['name']}'),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${index + 1}', style: TextStyle(color: AppTheme.TextSecondary)),
                          const SizedBox(width: 8),
                          Icon(Icons.drag_handle, color: AppTheme.TextSecondary, size: 20),
                        ],
                      ),
                      title: Text(a['name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${_fmt(a['duration_seconds'])} асана / ${_fmt(a['rest_seconds'])} отдых',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: AppTheme.TextSecondary,
                        onPressed: () => _removeAsana(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsanaPicker() {
    final selectedNames = _selectedAsanas.map((a) => a['name']).toSet();
    final available = _allAsanas.where((a) => !selectedNames.contains(a.name)).toList();

    return Expanded(
      flex: 2,
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text('Доступные асаны', style: Theme.of(context).textTheme.titleMedium),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final asana = available[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.add_circle_outline, color: AppTheme.Accent, size: 20),
                    title: Text(asana.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: asana.categoryName != null
                        ? Text(asana.categoryName!, style: Theme.of(context).textTheme.bodySmall)
                        : null,
                    onTap: () => _addAsana(asana),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _selectedAsanas.isEmpty ? null : _startPractice,
          icon: const Icon(Icons.play_arrow),
          label: Text('Начать практику (${_selectedAsanas.length} асан)'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            disabledBackgroundColor: AppTheme.SurfaceLight,
          ),
        ),
      ),
    );
  }
}
