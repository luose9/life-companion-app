import 'package:flutter/material.dart';
import 'package:life_companion_app/data/inspiration_dao.dart';
import 'package:life_companion_app/models/inspiration.dart';

class InspirationPage extends StatefulWidget {
  const InspirationPage({super.key});
  @override
  State<InspirationPage> createState() => _InspirationPageState();
}

class _InspirationPageState extends State<InspirationPage> with SingleTickerProviderStateMixin {
  List<Inspiration> _all = [];
  List<Inspiration> _filtered = [];
  late TabController _tabCtrl;
  String _searchQuery = '';
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() { if (!_tabCtrl.indexIsChanging) _applyFilter(); });
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final all = await InspirationDao.getAll();
    if (mounted) setState(() { _all = all; _applyFilter(); });
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 条灵感吗？'),
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
      await InspirationDao.delete(id);
    }
    _selectedIds.clear();
    await _load();
    if (mounted) {
      setState(() => _multiSelect = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 条灵感'), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _applyFilter() {
    final types = ['all', 'idea', 'book_note', 'thought'];
    final t = types[_tabCtrl.index];
    setState(() {
      _filtered = t == 'all' ? _all : _all.where((i) => i.recordType == t).toList();
      if (_searchQuery.isNotEmpty) {
        _filtered = _filtered.where((i) =>
          (i.content ?? '').contains(_searchQuery) ||
          (i.tags ?? '').contains(_searchQuery) ||
          (i.source ?? '').contains(_searchQuery)).toList();
      }
    });
  }

  Future<void> _addInspiration({String? type}) async {
    String recordType = type ?? 'idea';
    final contentCtl = TextEditingController();
    final sourceCtl = TextEditingController();
    final tagsCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('记录灵感'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('类型', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: Inspiration.typeLabels.entries.map((e) =>
                    ChoiceChip(
                      label: Text(e.value, style: const TextStyle(fontSize: 12)),
                      selected: recordType == e.key,
                      onSelected: (_) => setS(() => recordType = e.key),
                    ),
                  ).toList()),
                  const SizedBox(height: 10),
                  TextField(controller: contentCtl, maxLines: 5,
                      decoration: const InputDecoration(labelText: '写下你的想法...', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  if (recordType == 'book_note')
                    TextField(controller: sourceCtl,
                        decoration: const InputDecoration(labelText: '书名/来源', border: OutlineInputBorder(), isDense: true))
                  else
                    TextField(controller: sourceCtl,
                        decoration: const InputDecoration(labelText: '来源/场景（可选）', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: tagsCtl,
                      decoration: const InputDecoration(labelText: '标签（逗号分隔，可选）', border: OutlineInputBorder(), isDense: true)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(onPressed: () async {
              if (contentCtl.text.trim().isEmpty) return;
              await InspirationDao.insert(Inspiration(
                recordType: recordType,
                content: contentCtl.text.trim(),
                source: sourceCtl.text.trim().isEmpty ? null : sourceCtl.text.trim(),
                tags: tagsCtl.text.trim().isEmpty ? null : tagsCtl.text.trim(),
                timestamp: DateTime.now().millisecondsSinceEpoch,
              ));
              Navigator.pop(ctx);
              await _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('灵感已捕捉 ✨'), duration: Duration(seconds: 1)),
                );
              }
            }, child: const Text('保存')),
          ],
        ),
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
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索灵感...', prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) { _searchQuery = v; _applyFilter(); },
            ),
          ),
          Row(children: [
            const Spacer(),
            IconButton(
              icon: Icon(_multiSelect ? Icons.close : Icons.checklist, size: 20),
              tooltip: _multiSelect ? '退出多选' : '多选',
              onPressed: () => setState(() { _multiSelect = !_multiSelect; _selectedIds.clear(); }),
            ),
          ]),
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
          TabBar(controller: _tabCtrl, labelColor: Colors.blue, unselectedLabelColor: Colors.grey,
              isScrollable: true,
              tabs: const [Tab(text: '全部'), Tab(text: '💡 灵感'), Tab(text: '📖 读书'), Tab(text: '🤔 思考')]),
          Expanded(
            child: _filtered.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('还没有灵感记录', style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text('灵感稍纵即逝，随时记录下来', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = _filtered[i];
                      final typeLabel = Inspiration.typeLabels[item.recordType] ?? '';
                      final isSelected = item.id != null && _selectedIds.contains(item.id);
                      Widget card = Card(
                        color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
                        child: InkWell(
                          onLongPress: () {
                            if (!_multiSelect && item.id != null) {
                              setState(() { _multiSelect = true; _selectedIds.add(item.id!); });
                            }
                          },
                          onTap: _multiSelect ? () {
                            if (item.id == null) return;
                            setState(() {
                              if (_selectedIds.contains(item.id)) _selectedIds.remove(item.id);
                              else _selectedIds.add(item.id!);
                            });
                          } : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(typeLabel, style: const TextStyle(fontSize: 11)),
                                  const Spacer(),
                                  Text(_fmtDate(item.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                                ]),
                                const SizedBox(height: 6),
                                Text(item.content ?? '', style: const TextStyle(fontSize: 14)),
                                if (item.source != null) ...[
                                  const SizedBox(height: 4),
                                  Text('📎 ${item.source}', style: TextStyle(fontSize: 11, color: Colors.blue.shade400)),
                                ],
                                if (item.tags != null) ...[
                                  const SizedBox(height: 4),
                                  Wrap(spacing: 4, children: item.tags!.split(',').map((t) =>
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text(t.trim(), style: TextStyle(fontSize: 10, color: Colors.blue.shade600)),
                                    ),
                                  ).toList()),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                      if (_multiSelect) return card;
                      return Dismissible(
                        key: ValueKey(item.id), direction: DismissDirection.endToStart,
                        background: Container(color: Colors.grey.shade300, alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.close, color: Colors.white)),
                        onDismissed: (_) async { if (item.id != null) await InspirationDao.delete(item.id!); await _load(); },
                        child: card,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addInspiration(),
        child: const Icon(Icons.edit),
      ),
    );
  }
}
