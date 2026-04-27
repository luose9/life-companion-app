import 'package:flutter/material.dart';
import 'package:life_companion_app/data/milestone_dao.dart';
import 'package:life_companion_app/models/milestone.dart';
import 'package:life_companion_app/main.dart';

class MilestonePage extends StatefulWidget {
  const MilestonePage({super.key});
  @override
  State<MilestonePage> createState() => _MilestonePageState();
}

class _MilestonePageState extends State<MilestonePage> {
  List<Milestone> _milestones = [];
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final list = await MilestoneDao.getAll();
    if (mounted) setState(() => _milestones = list);
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 个里程碑吗？'),
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
      await MilestoneDao.delete(id);
    }
    _selectedIds.clear();
    await _load();
    if (mounted) {
      setState(() => _multiSelect = false);
      globalCancelMultiSelect = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 个里程碑'), duration: const Duration(seconds: 2)),
      );
    }
  }

  String _fmtDate(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}年${dt.month}月${dt.day}日';
  }

  Color _categoryColor(String? cat) {
    switch (cat) {
      case 'career': return Colors.blue;
      case 'education': return Colors.green;
      case 'travel': return Colors.orange;
      case 'love': return Colors.pink;
      case 'achievement': return Colors.purple;
      default: return Colors.teal;
    }
  }

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case 'career': return Icons.work_outline;
      case 'education': return Icons.school_outlined;
      case 'travel': return Icons.explore_outlined;
      case 'love': return Icons.favorite_border;
      case 'achievement': return Icons.emoji_events_outlined;
      default: return Icons.star_border;
    }
  }

  Future<void> _addMilestone() async {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    String selectedCategory = 'achievement';
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        title: const Text('记录人生里程碑'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('每个重要时刻都值得被铭记', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 10),
            TextField(controller: titleCtl, decoration: const InputDecoration(
                labelText: '标题', hintText: '如：拿到第一份offer', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6,
              children: Milestone.categoryLabels.entries.map((e) => ChoiceChip(
                label: Text(e.value, style: const TextStyle(fontSize: 12)),
                selected: selectedCategory == e.key,
                selectedColor: _categoryColor(e.key).withOpacity(0.2),
                onSelected: (v) { if (v) setS(() => selectedCategory = e.key); },
              )).toList(),
            ),
            const SizedBox(height: 10),
            ListTile(
              dense: true, contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, size: 18),
              title: Text('${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日', style: const TextStyle(fontSize: 13)),
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: selectedDate,
                    firstDate: DateTime(1950), lastDate: DateTime(2100));
                if (picked != null) setS(() => selectedDate = picked);
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: descCtl, maxLines: 3, decoration: const InputDecoration(
                labelText: '描述（可选）', hintText: '当时的心情、故事...', border: OutlineInputBorder(), isDense: true)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            if (titleCtl.text.trim().isEmpty) return;
            await MilestoneDao.insert(Milestone(
              title: titleCtl.text.trim(),
              description: descCtl.text.trim().isEmpty ? null : descCtl.text.trim(),
              category: selectedCategory,
              eventDate: selectedDate.millisecondsSinceEpoch,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ));
            Navigator.pop(ctx);
            await _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('里程碑已铭记 🏆'), duration: Duration(seconds: 1)),
              );
            }
          }, child: const Text('铭记')),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              const Text('人生里程碑', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: Icon(_multiSelect ? Icons.close : Icons.checklist, size: 20),
                tooltip: _multiSelect ? '退出多选' : '多选',
                onPressed: () => setState(() {
                  _multiSelect = !_multiSelect; _selectedIds.clear();
                  globalCancelMultiSelect = _multiSelect ? () => setState(() { _multiSelect = false; _selectedIds.clear(); globalCancelMultiSelect = null; }) : null;
                }),
              ),
            ]),
          ),
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
                      if (_selectedIds.length == _milestones.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(_milestones.where((m) => m.id != null).map((m) => m.id!));
                      }
                    });
                  },
                  child: Text(_selectedIds.length == _milestones.length ? '取消全选' : '全选',
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
          Expanded(
            child: _milestones.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timeline_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text('还没有里程碑记录', style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text('人生的每个重要时刻都值得被铭记', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _milestones.length,
              itemBuilder: (ctx, i) {
                final m = _milestones[i];
                final color = _categoryColor(m.category);
                final isSelected = m.id != null && _selectedIds.contains(m.id);
                Widget card = InkWell(
                  onLongPress: () {
                    if (!_multiSelect && m.id != null) {
                      setState(() { _multiSelect = true; _selectedIds.add(m.id!); });
                      globalCancelMultiSelect = () => setState(() { _multiSelect = false; _selectedIds.clear(); globalCancelMultiSelect = null; });
                    }
                  },
                  onTap: _multiSelect ? () {
                    if (m.id == null) return;
                    setState(() {
                      if (_selectedIds.contains(m.id)) _selectedIds.remove(m.id);
                      else _selectedIds.add(m.id!);
                    });
                  } : null,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 时间线
                        Column(children: [
                          Container(width: 2, height: 12, color: i == 0 ? Colors.transparent : color.withOpacity(0.3)),
                          Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                              child: Icon(_categoryIcon(m.category), size: 14, color: color)),
                          Expanded(child: Container(width: 2, color: i == _milestones.length - 1 ? Colors.transparent : color.withOpacity(0.3))),
                        ]),
                        const SizedBox(width: 12),
                        // 内容卡片
                        Expanded(
                          child: Card(
                            color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text(Milestone.categoryLabels[m.category] ?? m.category ?? '',
                                            style: TextStyle(fontSize: 10, color: color))),
                                    const Spacer(),
                                    Text(_fmtDate(m.eventDate), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(m.title ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  if (m.description != null && m.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(m.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                if (_multiSelect) return card;
                return Dismissible(
                  key: ValueKey(m.id), direction: DismissDirection.endToStart,
                  background: Container(color: Colors.grey.shade300, alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.close, color: Colors.white)),
                  onDismissed: (_) async { if (m.id != null) await MilestoneDao.delete(m.id!); await _load(); },
                  child: card,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addMilestone, child: const Icon(Icons.add)),
    );
  }
}
