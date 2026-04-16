import 'package:flutter/material.dart';
import 'package:life_companion_app/data/entertainment_dao.dart';
import 'package:life_companion_app/models/entertainment.dart';
import 'package:life_companion_app/services/share_service.dart';

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
    String mediaType = existing?.mediaType ?? 'movie';
    final titleCtl = TextEditingController(text: existing?.title ?? '');
    final creatorCtl = TextEditingController(text: existing?.creator ?? '');
    final feelingCtl = TextEditingController(text: existing?.feeling ?? '');
    final tagsCtl = TextEditingController(text: existing?.tags ?? '');
    double rating = existing?.rating ?? 3.0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? '记录娱乐/音乐' : '编辑记录'),
          content: SingleChildScrollView(
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
                      onSelected: (_) => setS(() => mediaType = m['type'] as String),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // ── 标题 / 作者 ──
                TextField(
                    controller: titleCtl,
                    decoration: const InputDecoration(
                        labelText: '名称（片名/歌名/书名）',
                        border: OutlineInputBorder(),
                        isDense: true)),
                const SizedBox(height: 8),
                TextField(
                    controller: creatorCtl,
                    decoration: const InputDecoration(
                        labelText: '创作者（导演/歌手/作者）',
                        border: OutlineInputBorder(),
                        isDense: true)),
                const SizedBox(height: 10),

                // ── 评分 ──
                const Text('评分', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: rating,
                        min: 1,
                        max: 5,
                        divisions: 8,
                        onChanged: (v) => setS(() => rating = v),
                      ),
                    ),
                    Text(rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    // 星形展示
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        final filled = i < rating.floor();
                        final half = !filled && i < rating;
                        return Icon(
                          half ? Icons.star_half : filled ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
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
                const SizedBox(height: 8),

                // ── 感受 ──
                TextField(
                    controller: feelingCtl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: '感受 / 评论',
                        border: OutlineInputBorder(),
                        isDense: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
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
                  feeling: feelingCtl.text.trim().isEmpty ? null : feelingCtl.text.trim(),
                  tags: tagsCtl.text.trim().isEmpty ? null : tagsCtl.text.trim(),
                  timestamp: existing?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
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
        ),
      ),
    );
  }

  String _labelOf(String type) =>
      (_kMediaTypes.firstWhere((m) => m['type'] == type,
          orElse: () => {'label': type})['label'] as String);

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
              const Text('娱乐/音乐记录',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

          // ── 列表 ─────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('暂无记录\n点击右上角添加', textAlign: TextAlign.center))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final e = _filtered[i];
                      return Dismissible(
                        key: ValueKey(e.id ?? i),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('确认删除'),
                              content: Text('确定要删除《${e.title}》吗？'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
                                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (_) async {
                          if (e.id != null) await EntertainmentDao.delete(e.id!);
                          await _load();
                        },
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _colorOf(e.mediaType),
                              child: Icon(_iconOf(e.mediaType),
                                  color: Colors.white, size: 20),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                    child: Text(e.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold))),
                                // 星级
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
                                          label: Text(t.trim(),
                                              style: const TextStyle(fontSize: 10)),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        )).toList(),
                                  ),
                                if (e.feeling != null && e.feeling!.isNotEmpty)
                                  Text(e.feeling!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54)),
                                Text(_fmtDate(e.timestamp),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 18),
                              onSelected: (v) async {
                                if (v == 'edit') _showDialog(existing: e);
                                if (v == 'delete') {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('确认删除'),
                                      content: Text('确定要删除《${e.title}》吗？'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
                                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (ok == true && e.id != null) {
                                    await EntertainmentDao.delete(e.id!);
                                    await _load();
                                  }
                                }
                                if (v == 'share') ShareService.shareEntertainment(e);
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('编辑'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete, color: Colors.red),
                                    title: Text('删除', style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'share',
                                  child: ListTile(
                                    leading: Icon(Icons.share),
                                    title: Text('分享'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
