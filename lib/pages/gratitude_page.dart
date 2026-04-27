import 'dart:math';
import 'package:flutter/material.dart';
import 'package:life_companion_app/data/gratitude_dao.dart';
import 'package:life_companion_app/models/gratitude.dart';
import 'package:life_companion_app/main.dart';

class GratitudePage extends StatefulWidget {
  const GratitudePage({super.key});
  @override
  State<GratitudePage> createState() => _GratitudePageState();
}

class _GratitudePageState extends State<GratitudePage> with SingleTickerProviderStateMixin {
  List<Gratitude> _all = [];
  List<Gratitude> _today = [];
  Gratitude? _randomItem;
  late TabController _tabCtrl;
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

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
      await GratitudeDao.delete(id);
    }
    _selectedIds.clear();
    await _load();
    if (mounted) {
      setState(() => _multiSelect = false);
      globalCancelMultiSelect = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 条记录'), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _load() async {
    final all = await GratitudeDao.getAll();
    final today = await GratitudeDao.getToday();
    if (mounted) setState(() { _all = all; _today = today; });
  }

  Future<void> _showRandom() async {
    final item = await GratitudeDao.getRandom();
    if (item != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('回忆一个美好时刻 ✨'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(item.content ?? '', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Text(_fmtDate(item.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('谢谢'))],
        ),
      );
    }
  }

  Future<void> _addRecord(String type) async {
    final contentCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'joy' ? '记录小确幸' : '记录感恩'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type == 'joy' ? '今天有什么让你开心的小事？' : '今天有什么值得感恩的？',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            TextField(controller: contentCtl, maxLines: 3,
                decoration: const InputDecoration(labelText: '写下来...', border: OutlineInputBorder(), isDense: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            if (contentCtl.text.trim().isEmpty) return;
            await GratitudeDao.insert(Gratitude(
              recordType: type,
              content: contentCtl.text.trim(),
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ));
            Navigator.pop(ctx);
            await _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(type == 'joy' ? '小确幸已记录 🌟' : '感恩已记录 💛'), duration: const Duration(seconds: 1)),
              );
            }
          }, child: const Text('保存')),
        ],
      ),
    );
  }

  String _fmtDate(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── 今日小确幸提示 ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.amber.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('今日小确幸', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 6),
                  Text('${_today.length}/3', style: TextStyle(fontSize: 12, color: Colors.amber.shade700)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_multiSelect ? Icons.close : Icons.checklist, size: 20),
                    tooltip: _multiSelect ? '退出多选' : '多选',
                    onPressed: () => setState(() {
                      _multiSelect = !_multiSelect; _selectedIds.clear();
                      globalCancelMultiSelect = _multiSelect ? () => setState(() { _multiSelect = false; _selectedIds.clear(); globalCancelMultiSelect = null; }) : null;
                    }),
                  ),
                  if (_all.isNotEmpty)
                    TextButton.icon(
                      onPressed: _showRandom,
                      icon: const Icon(Icons.shuffle, size: 16),
                      label: const Text('随机回忆', style: TextStyle(fontSize: 12)),
                    ),
                ]),
                const Text('每天记录1-3件开心的小事，能带来真实的快乐', style: TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
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
                      if (_selectedIds.length == _all.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(_all.where((g) => g.id != null).map((g) => g.id!));
                      }
                    });
                  },
                  child: Text(_selectedIds.length == _all.length ? '取消全选' : '全选',
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
          TabBar(controller: _tabCtrl, labelColor: Colors.blue, unselectedLabelColor: Colors.grey,
              tabs: const [Tab(text: '🌟 小确幸'), Tab(text: '💛 感恩')]),

          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              _buildList(_all.where((g) => g.recordType == 'joy').toList(), 'joy'),
              _buildList(_all.where((g) => g.recordType == 'gratitude').toList(), 'gratitude'),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type = _tabCtrl.index == 0 ? 'joy' : 'gratitude';
          _addRecord(type);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<Gratitude> items, String type) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(type == 'joy' ? Icons.wb_sunny_outlined : Icons.favorite_border, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(type == 'joy' ? '还没有小确幸记录' : '还没有感恩记录', style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text('点击 + 开始记录生活中的美好', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final g = items[i];
        final isSelected = g.id != null && _selectedIds.contains(g.id);
        Widget card = Card(
          color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
          child: InkWell(
            onLongPress: () {
              if (!_multiSelect && g.id != null) {
                setState(() { _multiSelect = true; _selectedIds.add(g.id!); });
                globalCancelMultiSelect = () => setState(() { _multiSelect = false; _selectedIds.clear(); globalCancelMultiSelect = null; });
              }
            },
            onTap: _multiSelect ? () {
              if (g.id == null) return;
              setState(() {
                if (_selectedIds.contains(g.id)) _selectedIds.remove(g.id);
                else _selectedIds.add(g.id!);
              });
            } : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.content ?? '', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_fmtDate(g.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ),
        );
        if (_multiSelect) return card;
        return Dismissible(
          key: ValueKey(g.id), direction: DismissDirection.endToStart,
          background: Container(color: Colors.grey.shade300, alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.close, color: Colors.white)),
          onDismissed: (_) async { if (g.id != null) await GratitudeDao.delete(g.id!); await _load(); },
          child: card,
        );
      },
    );
  }
}
