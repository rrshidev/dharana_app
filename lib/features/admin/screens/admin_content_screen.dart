import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

const _categories = <String, String>{
  'sit_lie+': 'sit_lie+',
  'stay+': 'stay+',
  'hand+': 'hand+',
  'coup+': 'coup+',
  'sag+': 'sag+',
  'power+': 'power+',
};

String _categoryLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'sit_lie+':
      return l10n.filterCategorySitLie;
    case 'stay+':
      return l10n.filterCategoryStand;
    case 'hand+':
      return l10n.filterCategoryHands;
    case 'coup+':
      return l10n.filterCategoryBends;
    case 'sag+':
      return l10n.filterCategoryBackbends;
    case 'power+':
      return l10n.filterCategoryPower;
    default:
      return id;
  }
}

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
        backgroundColor: error ? AppTheme.Danger : AppTheme.SurfaceLight,
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminContentTitle),
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
              segments: [
                ButtonSegment(value: 0, label: Text(l10n.adminTabAsanas)),
                ButtonSegment(value: 1, label: Text(l10n.adminTabSequences)),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppTheme.AccentInk))
                : _tab == 0
                    ? _asanasView()
                    : _sequencesView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.Accent,
        foregroundColor: AppTheme.AccentOn,
        onPressed: _tab == 0 ? _createAsana : _addSequence,
        icon: const Icon(Icons.add),
        label: Text(_tab == 0 ? l10n.adminNewAsana : l10n.adminAddSequence),
      ),
    );
  }

  Widget _asanasView() {
    if (_asanas.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.adminAsanasEmpty));
    }
    return RefreshIndicator(
      onRefresh: _loadAsanas,
      color: AppTheme.AccentInk,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        itemCount: _asanas.length,
        itemBuilder: (context, i) => _asanaCard(_asanas[i]),
      ),
    );
  }

  Widget _sequencesView() {
    if (_sequences.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.adminSequencesEmpty));
    }
    return RefreshIndicator(
      onRefresh: _loadSequences,
      color: AppTheme.AccentInk,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        itemCount: _sequences.length,
        itemBuilder: (context, i) => _sequenceCard(_sequences[i]),
      ),
    );
  }

  Widget _asanaCard(AdminAsana a) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: a.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: '${ApiClient.baseUrl}${a.imageUrl}',
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        ColoredBox(color: AppTheme.SurfaceLight, child: Icon(Icons.image)),
                  )
                : ColoredBox(
                    color: AppTheme.SurfaceLight,
                    child: Icon(Icons.image, color: AppTheme.TextSecondary),
                  ),
          ),
        ),
        title: Text(a.name),
        subtitle: Text(
          '${_categoryLabel(l10n, a.categoryId)}'
          '${a.hasVideo ? ' · ${l10n.adminVideoTag}' : ''}'
          '${a.difficulty > 1 ? ' · ${AppTheme.starsText(a.difficulty)}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.photo_outlined, color: AppTheme.AccentInk),
              tooltip: l10n.adminTooltipPhoto,
              onPressed: () => _uploadAsanaPhoto(a),
            ),
            IconButton(
              icon: Icon(Icons.video_call_outlined, color: AppTheme.AccentGreenInk),
              tooltip: l10n.adminTooltipVideo,
              onPressed: () => _uploadAsanaVideo(a),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: AppTheme.TextSecondary),
              tooltip: l10n.adminTooltipEdit,
              onPressed: () => _editAsana(a),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppTheme.Danger),
              tooltip: l10n.adminTooltipDelete,
              onPressed: () => _deleteAsana(a),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sequenceCard(AdminSequence s) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          s.isPremium ? Icons.workspace_premium : Icons.play_circle_outline,
          color: s.isPremium ? AppTheme.AccentInk : AppTheme.AccentGreenInk,
        ),
        title: Text(s.name),
        subtitle: Text(
          s.isPremium ? 'Premium' : l10n.adminSequenceFree,
          style: TextStyle(
            fontSize: 12,
            color: s.isPremium ? AppTheme.AccentInk : AppTheme.AccentGreenInk,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: AppTheme.TextSecondary),
              tooltip: l10n.adminTooltipEdit,
              onPressed: () => _editSequence(s),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppTheme.Danger),
              tooltip: l10n.adminTooltipDelete,
              onPressed: () => _deleteSequence(s),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Асаны ----

  Future<void> _createAsana() async {
    final l10n = AppLocalizations.of(context)!;
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
      _toast(l10n.adminAsanaCreated);
      await _loadAsanas();
    } catch (e) {
      _toast(l10n.errorMessage('$e'), error: true);
    }
  }

  Future<void> _editAsana(AdminAsana a) async {
    final l10n = AppLocalizations.of(context)!;
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
      _toast(l10n.adminSaved);
      await _loadAsanas();
    } catch (e) {
      _toast(l10n.errorMessage('$e'), error: true);
    }
  }

  Future<Map<String, String>?> _showAsanaForm({
    String? initialName,
    String initialDescription = '',
  }) async {
    final l10n = AppLocalizations.of(context)!;
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
              title: Text(initialName == null
                  ? l10n.adminNewAsana
                  : l10n.adminEditTitle(initialName)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: l10n.name),
                      enabled: initialName == null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration:
                          InputDecoration(labelText: l10n.adminFieldCategory),
                      items: _categories.keys
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(_categoryLabel(l10n, e))))
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
                      decoration: InputDecoration(
                        labelText: l10n.adminFieldDescriptionHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    {
                      'name': nameCtrl.text.trim(),
                      'categoryId': category,
                      'description': descCtrl.text.trim(),
                    },
                  ),
                  child: Text(l10n.save),
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
    final l10n = AppLocalizations.of(context)!;
    final path = await _pickImageFile();
    if (path == null) return;
    try {
      await _api.uploadAsanaPhoto(a.name, File(path));
      _toast(l10n.adminPhotoUpdated);
      await _loadAsanas();
    } catch (e) {
      _toast(l10n.errorMessage('$e'), error: true);
    }
  }

  Future<void> _uploadAsanaVideo(AdminAsana a) async {
    final l10n = AppLocalizations.of(context)!;
    final path = await _pickVideoFile();
    if (path == null) return;
    try {
      await _api.uploadAsanaVideo(a.name, File(path));
      _toast(l10n.adminVideoUploaded);
      await _loadAsanas();
    } catch (e) {
      _toast(l10n.errorMessage('$e'), error: true);
    }
  }

  Future<void> _deleteAsana(AdminAsana a) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await _confirm(l10n.adminDeleteAsanaTitle(a.name),
        l10n.adminDeleteAsanaBody);
    if (!ok) return;
    final done = await _api.deleteAsana(a.name);
    if (done) {
      _toast(l10n.adminAsanaDeleted);
      await _loadAsanas();
    } else {
      _toast(l10n.adminDeleteFailed, error: true);
    }
  }

  // ---- Комплексы ----

  Future<void> _addSequence() async {
    final l10n = AppLocalizations.of(context)!;
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
      _toast(l10n.adminSequenceAdded);
      await _loadSequences();
    } catch (e) {
      _toast(l10n.errorMessage('$e'), error: true);
    }
  }

  Future<void> _editSequence(AdminSequence s) async {
    final l10n = AppLocalizations.of(context)!;
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
      _toast(l10n.adminSaved);
      await _loadSequences();
    } catch (e) {
      _toast(l10n.errorMessage('$e'), error: true);
    }
  }

  Future<Map<String, String>?> _showSequenceForm({
    String? initialName,
    bool initialPremium = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: initialName ?? '');
    bool premium = initialPremium;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text(initialName == null
                  ? l10n.adminNewSequenceTitle
                  : l10n.adminEditTitle(initialName)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: l10n.name),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: premium ? 'premium' : 'free',
                    decoration:
                        InputDecoration(labelText: l10n.adminFieldSection),
                    items: [
                      DropdownMenuItem(
                          value: 'free', child: Text(l10n.adminSequenceFree)),
                      const DropdownMenuItem(
                          value: 'premium', child: Text('Premium')),
                    ],
                    onChanged: (v) => setDlgState(
                      () => premium = v == 'premium',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    {'name': nameCtrl.text.trim(), 'section': premium ? 'premium' : 'free'},
                  ),
                  child: Text(l10n.save),
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
    final l10n = AppLocalizations.of(context)!;
    final ok = await _confirm(l10n.adminDeleteSequenceTitle(s.name),
        l10n.adminDeleteSequenceBody);
    if (!ok) return;
    final done = await _api.deleteSequenceVideo(s.id);
    if (done) {
      _toast(l10n.adminSequenceDeleted);
      await _loadSequences();
    } else {
      _toast(l10n.adminDeleteFailed, error: true);
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final l10n = AppLocalizations.of(context)!;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.Danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminDelete),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}
