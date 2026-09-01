import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';

const _categories = <String, String>{
  'sit_lie+': 'Асаны сидя и лёжа',
  'stay+': 'Асаны стоя',
  'hand+': 'Балансы на руках',
  'coup+': 'Перевёрнутые асаны',
  'sag+': 'Прогибы',
  'power+': 'Силовые асаны',
};

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final _api = ApiClient();
  int _tab = 0; // 0 - Асаны, 1 - Готовые комплексы

  List<AdminAsana> _asanas = [];
  List<AdminSequence> _sequences = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadAsanas(), _loadSequences()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadAsanas() async {
    final items = await _api.getAdminAsanas();
    if (mounted) setState(() => _asanas = items);
  }

  Future<void> _loadSequences() async {
    final items = await _api.getAdminSequences();
    if (mounted) setState(() => _sequences = items);
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppTheme.danger : AppTheme.surfaceLight,
      ),
    );
  }

  Future<String?> _pickVideoFile() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.video);
    if (res == null || res.files.isEmpty) return null;
    return res.files.single.path;
  }

  Future<String?> _pickImageFile() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    return picked?.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контент'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Асаны')),
                ButtonSegment(value: 1, label: Text('Комплексы')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _tab == 0
                    ? _asanasView()
                    : _sequencesView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.background,
        onPressed: _tab == 0 ? _createAsana : _addSequence,
        icon: const Icon(Icons.add),
        label: Text(_tab == 0 ? 'Новая асана' : 'Добавить комплекс'),
      ),
    );
  }

  Widget _asanasView() {
    if (_asanas.isEmpty) {
      return const Center(child: Text('Асаны не найдены'));
    }
    return RefreshIndicator(
      onRefresh: _loadAsanas,
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        itemCount: _asanas.length,
        itemBuilder: (context, i) => _asanaCard(_asanas[i]),
      ),
    );
  }

  Widget _sequencesView() {
    if (_sequences.isEmpty) {
      return const Center(child: Text('Готовые комплексы не найдены'));
    }
    return RefreshIndicator(
      onRefresh: _loadSequences,
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        itemCount: _sequences.length,
        itemBuilder: (context, i) => _sequenceCard(_sequences[i]),
      ),
    );
  }

  Widget _asanaCard(AdminAsana a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: a.imageUrl != null
                ? Image.network(
                    '${ApiClient.baseUrl}${a.imageUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: AppTheme.surfaceLight, child: Icon(Icons.image)),
                  )
                : const ColoredBox(
                    color: AppTheme.surfaceLight,
                    child: Icon(Icons.image, color: AppTheme.textSecondary),
                  ),
          ),
        ),
        title: Text(a.name),
        subtitle: Text(
          '${_categories[a.categoryId] ?? a.categoryId}'
          '${a.hasVideo ? ' · видео' : ''}'
          '${a.difficulty > 1 ? ' · ${AppTheme.starsText(a.difficulty)}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.photo_outlined, color: AppTheme.accent),
              tooltip: 'Фото',
              onPressed: () => _uploadAsanaPhoto(a),
            ),
            IconButton(
              icon: const Icon(Icons.video_call_outlined, color: AppTheme.accentGreen),
              tooltip: 'Видео',
              onPressed: () => _uploadAsanaVideo(a),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
              tooltip: 'Редактировать',
              onPressed: () => _editAsana(a),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              tooltip: 'Удалить',
              onPressed: () => _deleteAsana(a),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sequenceCard(AdminSequence s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          s.isPremium ? Icons.workspace_premium : Icons.play_circle_outline,
          color: s.isPremium ? AppTheme.accent : AppTheme.accentGreen,
        ),
        title: Text(s.name),
        subtitle: Text(
          s.isPremium ? 'Premium' : 'Бесплатный',
          style: TextStyle(
            fontSize: 12,
            color: s.isPremium ? AppTheme.accent : AppTheme.accentGreen,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
              tooltip: 'Редактировать',
              onPressed: () => _editSequence(s),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              tooltip: 'Удалить',
              onPressed: () => _deleteSequence(s),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Асаны ----

  Future<void> _createAsana() async {
    final form = await _showAsanaForm();
    if (form == null) return;
    final name = form['name'] ?? '';
    final categoryId = form['categoryId'] ?? '';
    final description = form['description'] ?? '';
    try {
      await _api.createAsana(
        name: name,
        categoryId: categoryId,
        description: description,
      );
      _toast('Асана создана');
      await _loadAsanas();
    } catch (e) {
      _toast('Ошибка: $e', error: true);
    }
  }

  Future<void> _editAsana(AdminAsana a) async {
    // Prefill the current description from the public detail endpoint.
    String currentDescription = '';
    try {
      final resp = await _api.dio.get(
        '/asanas/${Uri.encodeComponent(a.name)}',
      );
      currentDescription = resp.data['description'] ?? '';
    } catch (_) {}
    final form = await _showAsanaForm(
      initialName: a.name,
      initialDescription: currentDescription,
    );
    if (form == null) return;
    final name = form['name'] ?? a.name;
    final description = form['description'] ?? '';
    try {
      await _api.updateAsanaInfo(name, description: description);
      _toast('Сохранено');
      await _loadAsanas();
    } catch (e) {
      _toast('Ошибка: $e', error: true);
    }
  }

  Future<Map<String, String>?> _showAsanaForm({
    String? initialName,
    String initialDescription = '',
  }) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final descCtrl = TextEditingController(text: initialDescription);
    String category = 'stay+';
    if (initialName != null) {
      final match = _asanas.where((x) => x.name == initialName);
      if (match.isNotEmpty && _categories.containsKey(match.first.categoryId)) {
        category = match.first.categoryId;
      }
    }
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text(initialName == null ? 'Новая асана' : 'Редактировать: $initialName'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Название'),
                      enabled: initialName == null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Категория'),
                      items: _categories.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: initialName == null
                          ? (v) => setDlgState(() => category = v ?? category)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Описание (для новой — сохранится)',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    {
                      'name': nameCtrl.text.trim(),
                      'categoryId': category,
                      'description': descCtrl.text.trim(),
                    },
                  ),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
    return result;
  }

  Future<void> _uploadAsanaPhoto(AdminAsana a) async {
    final path = await _pickImageFile();
    if (path == null) return;
    try {
      await _api.uploadAsanaPhoto(a.name, File(path));
      _toast('Фото обновлено');
      await _loadAsanas();
    } catch (e) {
      _toast('Ошибка: $e', error: true);
    }
  }

  Future<void> _uploadAsanaVideo(AdminAsana a) async {
    final path = await _pickVideoFile();
    if (path == null) return;
    try {
      await _api.uploadAsanaVideo(a.name, File(path));
      _toast('Видео загружено');
      await _loadAsanas();
    } catch (e) {
      _toast('Ошибка: $e', error: true);
    }
  }

  Future<void> _deleteAsana(AdminAsana a) async {
    final ok = await _confirm('Удалить асану «${a.name}»?', 'Будут удалены описание и фото, а также видео асаны.');
    if (!ok) return;
    final done = await _api.deleteAsana(a.name);
    if (done) {
      _toast('Асана удалена');
      await _loadAsanas();
    } else {
      _toast('Не удалось удалить', error: true);
    }
  }

  // ---- Комплексы ----

  Future<void> _addSequence() async {
    final videoPath = await _pickVideoFile();
    if (videoPath == null) return;
    final form = await _showSequenceForm();
    if (form == null) return;
    final name = form['name'] ?? '';
    final section = form['section'] ?? 'free';
    try {
      await _api.addSequenceVideo(
        name: name,
        section: section,
        video: File(videoPath),
      );
      _toast('Комплекс добавлен');
      await _loadSequences();
    } catch (e) {
      _toast('Ошибка: $e', error: true);
    }
  }

  Future<void> _editSequence(AdminSequence s) async {
    final form = await _showSequenceForm(
      initialName: s.name,
      initialPremium: s.isPremium,
    );
    if (form == null) return;
    final name = form['name'] ?? s.name;
    final section = form['section'] ?? (s.isPremium ? 'premium' : 'free');
    try {
      await _api.updateSequenceVideo(
        s.id,
        name: name,
        section: section,
      );
      _toast('Сохранено');
      await _loadSequences();
    } catch (e) {
      _toast('Ошибка: $e', error: true);
    }
  }

  Future<Map<String, String>?> _showSequenceForm({
    String? initialName,
    bool initialPremium = false,
  }) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    bool premium = initialPremium;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text(initialName == null ? 'Новый комплекс' : 'Редактировать: $initialName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Название'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: premium ? 'premium' : 'free',
                    decoration: const InputDecoration(labelText: 'Раздел'),
                    items: const [
                      DropdownMenuItem(value: 'free', child: Text('Бесплатный')),
                      DropdownMenuItem(value: 'premium', child: Text('Premium')),
                    ],
                    onChanged: (v) => setDlgState(
                      () => premium = v == 'premium',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    {'name': nameCtrl.text.trim(), 'section': premium ? 'premium' : 'free'},
                  ),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
    return result;
  }

  Future<void> _deleteSequence(AdminSequence s) async {
    final ok = await _confirm('Удалить комплекс «${s.name}»?', 'Видео будет удалено безвозвратно.');
    if (!ok) return;
    final done = await _api.deleteSequenceVideo(s.id);
    if (done) {
      _toast('Комплекс удалён');
      await _loadSequences();
    } else {
      _toast('Не удалось удалить', error: true);
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}
