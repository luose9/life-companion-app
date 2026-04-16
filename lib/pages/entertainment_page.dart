import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:life_companion_app/data/entertainment_dao.dart';
import 'package:life_companion_app/models/entertainment.dart';
import 'package:life_companion_app/services/media_search_service.dart';

const List<Map<String, dynamic>> _kMediaTypes = [
  {'type': 'movie', 'label': '电影', 'icon': Icons.movie},
  {'type': 'tv', 'label': '电视剧', 'icon': Icons.tv},
  {'type': 'music', 'label': '音乐', 'icon': Icons.music_note},
  {'type': 'book', 'label': '书籍', 'icon': Icons.menu_book},
  {'type': 'game', 'label': '游戏', 'icon': Icons.sports_esports},
  {'type': 'other', 'label': '其他', 'icon': Icons.star},
];

class EntertainmentPage extends StatefulWidget {
  const EntertainmentPage({super.key});

  @override
  State<EntertainmentPage> createState() => _EntertainmentPageState();
}

class _EntertainmentPageState extends State<EntertainmentPage> {
  List<Entertainment> _items = [];
  String _filterType = 'all';
  final Set<int> _expandedIds = {};
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await EntertainmentDao.getAll();
    setState(() => _items = list);
  }

  List<Entertainment> get _filtered =>
      _filterType == 'all' ? _items : _items.where((e) => e.mediaType == _filterType).toList();

  // ── 新增 / 编辑 ─────────────────────────────────────────
  Future<void> _showDialog({Entertainment? existing}) async {
    String mediaType = existing?.mediaType ?? (_filterType != 'all' ? _filterType : 'movie');
    final titleCtl = TextEditingController(text: existing?.title ?? '');
    final creatorCtl = TextEditingController(text: existing?.creator ?? '');
    final tagsCtl = TextEditingController(text: existing?.tags ?? '');
    final progressCtl = TextEditingController(text: existing?.progress ?? '');
    final momentCtl = TextEditingController(text: existing?.memorableMoment ?? '');
    final insightCtl = TextEditingController(text: existing?.personalInsight ?? '');
    double rating = existing?.rating ?? 3.0;
    String? imageUrl = existing?.imageUrl;
    String? status = existing?.status;
    String? moodAfter = existing?.moodAfter;
    List<MediaResult> _searchResults = [];
    bool _searching = false;
    Timer? _debounce;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // 搜索函数
          void doSearch(String query) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 600), () async {
              if (query.trim().length < 2) {
                setS(() => _searchResults = []);
                return;
              }
              setS(() => _searching = true);
              final results = await MediaSearchService.search(mediaType, query);
              setS(() {
                _searchResults = results;
                _searching = false;
              });
            });
          }

          return AlertDialog(
            title: Text(existing == null ? '记录娱乐/音乐' : '编辑记录'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 媒体类型 ──
                    const Text('类型', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: _kMediaTypes.map((m) {
                        final sel = mediaType == m['type'];
                        return ChoiceChip(
                          avatar: Icon(m['icon'] as IconData, size: 15),
                          label: Text(m['label'] as String),
                          selected: sel,
                          showCheckmark: false,
                          onSelected: (_) => setS(() {
                            mediaType = m['type'] as String;
                            _searchResults = [];
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // ── 封面预览 ──
                    if (imageUrl != null && imageUrl!.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _CoverImage(
                            url: imageUrl!,
                            width: 100, height: 140, fit: BoxFit.cover,
                            placeholder: const SizedBox(width: 100, height: 140, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            errorWidget: const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    if (imageUrl != null && imageUrl!.isNotEmpty) const SizedBox(height: 8),

                    // ── 标题（带搜索） ──
                    TextField(
                      controller: titleCtl,
                      decoration: InputDecoration(
                        labelText: _titleLabel(mediaType),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: _searching
                            ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                            : const Icon(Icons.search, size: 18),
                      ),
                      onChanged: (v) => doSearch(v),
                    ),

                    // ── 搜索结果列表 ──
                    if (_searchResults.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (_, i) {
                            final r = _searchResults[i];
                            return ListTile(
                              dense: true,
                              leading: r.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: _CoverImage(
                                        url: r.imageUrl,
                                        width: 36, height: 50, fit: BoxFit.cover,
                                        errorWidget: const Icon(Icons.image, size: 36),
                                      ),
                                    )
                                  : const Icon(Icons.image, size: 36),
                              title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                              subtitle: Text(r.creator, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                              onTap: () {
                                setS(() {
                                  titleCtl.text = r.title;
                                  if (r.creator.isNotEmpty) creatorCtl.text = r.creator;
                                  if (r.imageUrl.isNotEmpty) imageUrl = r.imageUrl;
                                  if (r.tags.isNotEmpty && tagsCtl.text.isEmpty) tagsCtl.text = r.tags;
                                  _searchResults = [];
                                });
                              },
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 8),
                    // ── 创作者（带反向搜索） ──
                    TextField(
                      controller: creatorCtl,
                      decoration: InputDecoration(
                        labelText: _creatorLabel(mediaType),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => doSearch(v),
                    ),
                    const SizedBox(height: 10),

                    // ── 评分（0.1精度） ──
                    const Text('评分', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: rating,
                            min: 1,
                            max: 5,
                            divisions: 40,
                            onChanged: (v) => setS(() => rating = v),
                          ),
                        ),
                        Text(rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            final filled = i < rating.floor();
                            final half = !filled && i < rating;
                            return Icon(
                              half ? Icons.star_half : filled ? Icons.star : Icons.star_border,
                              color: Colors.amber, size: 18,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ── 标签 ──
                    TextField(
                        controller: tagsCtl,
                        decoration: const InputDecoration(
                            labelText: '标签（逗号分隔，如：治愈,推荐）',
                            border: OutlineInputBorder(),
                            isDense: true)),
                    const SizedBox(height: 10),

                    // ── 状态 ──
                    const Text('状态', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 6,
                      children: Entertainment.statusLabelsFor(mediaType).entries.map((e) => ChoiceChip(
                        label: Text(e.value, style: const TextStyle(fontSize: 11)),
                        selected: status == e.key,
                        showCheckmark: false,
                        onSelected: (v) => setS(() => status = v ? e.key : null),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),

                    // ── 进度 ──
                    _buildProgressPicker(mediaType, progressCtl, setS),
                    const SizedBox(height: 10),

                    // ── 体验后心情 ──
                    const Text('体验后心情', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 6,
                      children: Entertainment.moodLabels.entries.map((e) => ChoiceChip(
                        label: Text(e.value, style: const TextStyle(fontSize: 11)),
                        selected: moodAfter == e.key,
                        showCheckmark: false,
                        onSelected: (v) => setS(() => moodAfter = v ? e.key : null),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),

                    // ── 印象深刻的时刻 ──
                    TextField(
                        controller: momentCtl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: '印象深刻的台词/场景',
                            hintText: '记录触动你的瞬间...',
                            border: OutlineInputBorder(),
                            isDense: true)),
                    const SizedBox(height: 8),

                    // ── 个人感悟 ──
                    TextField(
                        controller: insightCtl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: '个人感悟',
                            hintText: '这部作品让你想到了什么？',
                            border: OutlineInputBorder(),
                            isDense: true)),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () { _debounce?.cancel(); Navigator.pop(ctx); }, child: const Text('取消')),
              ElevatedButton(
                onPressed: () async {
                  _debounce?.cancel();
                  final title = titleCtl.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(const SnackBar(content: Text('名称不能为空')));
                    return;
                  }
                  final e = Entertainment(
                    id: existing?.id,
                    mediaType: mediaType,
                    title: title,
                    creator: creatorCtl.text.trim().isEmpty ? null : creatorCtl.text.trim(),
                    rating: rating,
                    feeling: existing?.feeling,
                    tags: tagsCtl.text.trim().isEmpty ? null : tagsCtl.text.trim(),
                    timestamp: existing?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
                    imageUrl: imageUrl,
                    status: status,
                    progress: progressCtl.text.trim().isEmpty ? null : progressCtl.text.trim(),
                    moodAfter: moodAfter,
                    memorableMoment: momentCtl.text.trim().isEmpty ? null : momentCtl.text.trim(),
                    personalInsight: insightCtl.text.trim().isEmpty ? null : insightCtl.text.trim(),
                  );
                  if (existing == null) {
                    await EntertainmentDao.insert(e);
                  } else {
                    await EntertainmentDao.update(e);
                  }
                  Navigator.pop(ctx);
                  await _load();
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteItem(Entertainment e) async {
    if (e.id != null) {
      await EntertainmentDao.delete(e.id!);
      await _load();
    }
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 条记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    for (final id in _selectedIds.toList()) {
      await EntertainmentDao.delete(id);
    }
    _selectedIds.clear();
    await _load();
    if (mounted) {
      setState(() => _multiSelect = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 条记录'), duration: const Duration(seconds: 2)),
      );
    }
  }

  String _labelOf(String type) =>
      (_kMediaTypes.firstWhere((m) => m['type'] == type,
          orElse: () => {'label': type})['label'] as String);

  String _titleLabel(String type) {
    const m = {'movie': '片名', 'tv': '剧名', 'music': '歌名', 'book': '书名', 'game': '游戏名'};
    return m[type] ?? '名称';
  }

  String _creatorLabel(String type) {
    const m = {'movie': '导演', 'tv': '导演', 'music': '歌手 / 乐队', 'book': '作者', 'game': '开发商'};
    return m[type] ?? '创作者';
  }

  /// 根据媒体类型构建进度选择器
  Widget _buildProgressPicker(String mediaType, TextEditingController ctl, void Function(void Function()) setS) {
    // 解析当前进度值中的数字
    int _parseNum(String s) {
      final match = RegExp(r'\d+').firstMatch(s);
      return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
    }

    // 电影: 时:分
    if (mediaType == 'movie') {
      final parts = ctl.text.split(':');
      int hours = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
      int mins = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('观看进度', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 70,
                child: DropdownButtonFormField<int>(
                  value: hours.clamp(0, 10),
                  decoration: const InputDecoration(
                    isDense: true, border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: List.generate(11, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                  onChanged: (v) {
                    hours = v ?? 0;
                    ctl.text = '$hours:${mins.toString().padLeft(2, '0')}';
                    setS(() {});
                  },
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('时', style: TextStyle(fontSize: 13))),
              SizedBox(
                width: 80,
                child: DropdownButtonFormField<int>(
                  value: mins.clamp(0, 59),
                  decoration: const InputDecoration(
                    isDense: true, border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: List.generate(60, (i) => DropdownMenuItem(value: i, child: Text(i.toString().padLeft(2, '0')))),
                  onChanged: (v) {
                    mins = v ?? 0;
                    ctl.text = '$hours:${mins.toString().padLeft(2, '0')}';
                    setS(() {});
                  },
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('分', style: TextStyle(fontSize: 13))),
            ],
          ),
        ],
      );
    }

    // 游戏: 自由文本描述进度（剧情游戏、开放世界等）
    if (mediaType == 'game') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('游戏进度', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: ctl.text,
            decoration: const InputDecoration(
              isDense: true, border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              hintText: '例：主线第3章 / 打到了最终Boss / 探索了60%地图',
            ),
            onChanged: (v) => ctl.text = v,
          ),
        ],
      );
    }

    // 书/电视剧/音乐: 滑动数字
    String prefix, suffix;
    int maxVal;
    switch (mediaType) {
      case 'book':
        prefix = '第'; suffix = '章'; maxVal = 999;
      case 'tv':
        prefix = '第'; suffix = '集'; maxVal = 999;
      case 'music':
        prefix = '循环'; suffix = '次'; maxVal = 999;
      default:
        prefix = ''; suffix = ''; maxVal = 999;
    }
    final label = mediaType == 'music' ? '循环次数' : '进度';
    int curVal = _parseNum(ctl.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (prefix.isNotEmpty) Text(prefix, style: const TextStyle(fontSize: 14)),
            if (prefix.isNotEmpty) const SizedBox(width: 6),
            SizedBox(
              width: 90,
              child: TextFormField(
                initialValue: curVal > 0 ? '$curVal' : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true, border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  hintText: '0',
                ),
                onChanged: (v) {
                  final n = int.tryParse(v) ?? 0;
                  if (mediaType == 'music') {
                    ctl.text = '循环${n}次';
                  } else {
                    ctl.text = '第${n}$suffix';
                  }
                },
              ),
            ),
            const SizedBox(width: 6),
            if (suffix.isNotEmpty) Text(suffix, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  /// 点击条目后展开的详情面板
  Widget _buildDetailPanel(Entertainment e) {
    final statusText = Entertainment.statusLabelsFor(e.mediaType)[e.status];
    final moodText = e.moodAfter != null ? Entertainment.moodLabels[e.moodAfter] : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 评分
          if (e.rating != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Text('评分  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ...List.generate(5, (i) {
                  final filled = i < e.rating!.floor();
                  final half = !filled && i < e.rating!;
                  return Icon(
                    half ? Icons.star_half : filled ? Icons.star : Icons.star_border,
                    color: Colors.amber, size: 16,
                  );
                }),
                const SizedBox(width: 4),
                Text(e.rating!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
            ),
          // 状态
          if (statusText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Text('状态  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(statusText, style: const TextStyle(fontSize: 13)),
              ]),
            ),
          // 进度
          if (e.progress != null && e.progress!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Text('进度  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(e.progress!, style: const TextStyle(fontSize: 13)),
              ]),
            ),
          // 体验后心情
          if (moodText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Text('心情  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(moodText, style: const TextStyle(fontSize: 13)),
              ]),
            ),
          // 印象深刻
          if (e.memorableMoment != null && e.memorableMoment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('印象深刻', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(e.memorableMoment!, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          // 个人感悟
          if (e.personalInsight != null && e.personalInsight!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('感悟', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(e.personalInsight!, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          // 日期
          Text(_fmtDate(e.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  String _progressLabel(String type) {
    const m = {
      'movie': '观看进度',
      'tv': '看到第几集',
      'music': '循环次数',
      'book': '看到第几章',
      'game': '游戏进度（如：第3关）',
    };
    return m[type] ?? '进度';
  }

  IconData _iconOf(String type) =>
      (_kMediaTypes.firstWhere((m) => m['type'] == type,
          orElse: () => {'icon': Icons.star})['icon'] as IconData);

  Color _colorOf(String type) {
    const colors = {
      'movie': Colors.deepPurple,
      'tv': Colors.indigo,
      'music': Colors.pink,
      'book': Colors.teal,
      'game': Colors.orange,
      'other': Colors.grey,
    };
    return colors[type] ?? Colors.grey;
  }

  String _fmtDate(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // ── 头部 ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('体验珍藏',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(_multiSelect ? Icons.close : Icons.checklist, size: 20),
                tooltip: _multiSelect ? '退出多选' : '多选',
                onPressed: () => setState(() { _multiSelect = !_multiSelect; _selectedIds.clear(); }),
              ),
              ElevatedButton.icon(
                  onPressed: () => _showDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('记录')),
            ],
          ),
          const SizedBox(height: 6),

          // ── 类型过滤 chip ────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                    label: '全部',
                    icon: Icons.all_inclusive,
                    selected: _filterType == 'all',
                    color: Colors.blueGrey,
                    onTap: () => setState(() => _filterType = 'all')),
                ..._kMediaTypes.map((m) => _FilterChip(
                      label: m['label'] as String,
                      icon: m['icon'] as IconData,
                      selected: _filterType == m['type'],
                      color: _colorOf(m['type'] as String),
                      onTap: () => setState(() => _filterType = m['type'] as String),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── 多选操作栏 ──
          if (_multiSelect)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.red.shade50,
              child: Row(children: [
                Text('已选 ${_selectedIds.length} 项', style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == _filtered.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(_filtered.where((e) => e.id != null).map((e) => e.id!));
                      }
                    });
                  },
                  child: Text(_selectedIds.length == _filtered.length ? '取消全选' : '全选',
                      style: const TextStyle(fontSize: 12)),
                ),
                ElevatedButton.icon(
                  onPressed: _selectedIds.isEmpty ? null : _batchDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('删除', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ]),
            ),
          // ── 列表 ─────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.movie_filter_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('还没有娱乐记录', style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text('每一次体验都值得被珍藏', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ]))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final e = _filtered[i];
                      final isSelected = e.id != null && _selectedIds.contains(e.id);
                      Widget cardWidget = GestureDetector(
                        onLongPress: () {
                          if (!_multiSelect && e.id != null) {
                            setState(() { _multiSelect = true; _selectedIds.add(e.id!); });
                          }
                        },
                        onTap: _multiSelect ? () {
                          if (e.id == null) return;
                          setState(() {
                            if (_selectedIds.contains(e.id)) _selectedIds.remove(e.id);
                            else _selectedIds.add(e.id!);
                          });
                        } : () {
                          setState(() {
                            final id = e.id ?? i;
                            if (_expandedIds.contains(id)) {
                              _expandedIds.remove(id);
                            } else {
                              _expandedIds.add(id);
                            }
                          });
                        },
                        child: Card(
                          color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
                          clipBehavior: Clip.antiAlias,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                              ? SizedBox(
                                  height: 140,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      _CoverImage(
                                        url: e.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorWidget: Container(
                                            color: _colorOf(e.mediaType).withOpacity(0.2)),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.black.withOpacity(0.85),
                                              Colors.black.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(12, 10, 40, 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Icon(_iconOf(e.mediaType), color: Colors.white60, size: 13),
                                              const SizedBox(width: 4),
                                              Text(_labelOf(e.mediaType),
                                                  style: const TextStyle(color: Colors.white60, fontSize: 10)),
                                              if (e.status != null) ...[
                                                const SizedBox(width: 6),
                                                Text(Entertainment.statusLabelsFor(e.mediaType)[e.status] ?? '',
                                                    style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                              ],
                                            ]),
                                            const SizedBox(height: 4),
                                            Text(e.title,
                                                style: const TextStyle(
                                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                            if (e.creator != null)
                                              Text(e.creator!,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis),
                                            const Spacer(),
                                            if (e.rating != null)
                                              Row(mainAxisSize: MainAxisSize.min, children: [
                                                ...List.generate(5, (i) {
                                                  final filled = i < e.rating!.floor();
                                                  final half = !filled && i < e.rating!;
                                                  return Icon(
                                                      half
                                                          ? Icons.star_half
                                                          : filled
                                                              ? Icons.star
                                                              : Icons.star_border,
                                                      color: Colors.amber,
                                                      size: 14);
                                                }),
                                                const SizedBox(width: 4),
                                                Text(e.rating!.toStringAsFixed(1),
                                                    style: const TextStyle(color: Colors.amber, fontSize: 12)),
                                              ]),
                                            if (e.tags != null && e.tags!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Wrap(
                                                  spacing: 4,
                                                  children: e.tags!.split(',').take(3).map((t) => Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                        decoration: BoxDecoration(
                                                            color: Colors.white24,
                                                            borderRadius: BorderRadius.circular(8)),
                                                        child: Text(t.trim(),
                                                            style: const TextStyle(
                                                                fontSize: 9, color: Colors.white70)),
                                                      )).toList(),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, color: Colors.white70, size: 18),
                                          onSelected: (v) async {
                                            if (v == 'edit') _showDialog(existing: e);
                                            if (v == 'delete') _deleteItem(e);
                                          },
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: ListTile(leading: Icon(Icons.edit), title: Text('编辑')),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: ListTile(
                                                  leading: Icon(Icons.close, color: Colors.grey),
                                                  title: Text('删除')),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _colorOf(e.mediaType),
                                    child: Icon(_iconOf(e.mediaType), color: Colors.white, size: 20),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                          child: Text(e.title,
                                              style: const TextStyle(fontWeight: FontWeight.bold))),
                                      if (e.rating != null)
                                        Row(mainAxisSize: MainAxisSize.min, children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 14),
                                          Text(e.rating!.toStringAsFixed(1),
                                              style: const TextStyle(fontSize: 12)),
                                        ]),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (e.creator != null) Text(e.creator!),
                                      if (e.tags != null && e.tags!.isNotEmpty)
                                        Wrap(
                                          spacing: 4,
                                          children: e.tags!.split(',').map((t) => Chip(
                                                label: Text(t.trim(), style: const TextStyle(fontSize: 10)),
                                                padding: EdgeInsets.zero,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                visualDensity: VisualDensity.compact,
                                              )).toList(),
                                        ),
                                      Text(_fmtDate(e.timestamp),
                                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 18),
                                    onSelected: (v) async {
                                      if (v == 'edit') _showDialog(existing: e);
                                      if (v == 'delete') _deleteItem(e);
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(leading: Icon(Icons.edit), title: Text('编辑')),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                            leading: Icon(Icons.close, color: Colors.grey),
                                            title: Text('删除')),
                                      ),
                                    ],
                                  ),
                                ),
                          // ── 展开详情 ──
                          if (_expandedIds.contains(e.id ?? i))
                            _buildDetailPanel(e),
                            ],
                          ),
                        ),
                      );
                      if (_multiSelect) return cardWidget;
                      return Dismissible(
                        key: ValueKey(e.id ?? i),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.grey.shade300,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          if (e.id != null) await EntertainmentDao.delete(e.id!);
                          await _load();
                        },
                        child: cardWidget,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: selected ? Colors.white : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

/// 自带请求头的图片组件，自动缓存到本地文件
/// 解决豆瓣/网易等需要 Referer 的图片源
class _CoverImage extends StatefulWidget {
  final String url;
  final double? width, height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  const _CoverImage({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<_CoverImage> {
  File? _file;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _CoverImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _file = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final dir = await getTemporaryDirectory();
      final name = 'cover_${widget.url.hashCode.abs().toRadixString(36)}.img';
      final f = File('${dir.path}/$name');

      // 已缓存
      if (f.existsSync() && f.lengthSync() > 100) {
        if (mounted) setState(() => _file = f);
        return;
      }

      // 下载（带合适的请求头）
      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14)',
      };
      if (widget.url.contains('doubanio.com')) {
        headers['Referer'] = 'https://www.douban.com/';
      } else if (widget.url.contains('music.126.net')) {
        headers['Referer'] = 'https://music.163.com/';
      }

      final resp = await http
          .get(Uri.parse(widget.url), headers: headers)
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200 && resp.bodyBytes.length > 100) {
        await f.writeAsBytes(resp.bodyBytes);
        if (mounted) setState(() => _file = f);
      } else {
        if (mounted) setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_file != null) {
      return Image.file(
        _file!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) =>
            widget.errorWidget ?? SizedBox(width: widget.width, height: widget.height),
      );
    }
    if (_failed) {
      return widget.errorWidget ??
          SizedBox(width: widget.width, height: widget.height);
    }
    return widget.placeholder ??
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
  }
}
