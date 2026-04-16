import 'package:flutter/material.dart';
import 'package:life_companion_app/data/person_dao.dart';
import 'package:life_companion_app/models/person.dart';

class RelationshipPage extends StatefulWidget {
  const RelationshipPage({super.key});
  @override
  State<RelationshipPage> createState() => _RelationshipPageState();
}

class _RelationshipPageState extends State<RelationshipPage> {
  List<Person> _persons = [];
  Map<int, List<RelationshipMoment>> _moments = {};
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final persons = await PersonDao.getAll();
    final moments = <int, List<RelationshipMoment>>{};
    for (final p in persons) {
      if (p.id != null) {
        moments[p.id!] = await RelationshipMomentDao.getByPerson(p.id!);
      }
    }
    if (mounted) setState(() { _persons = persons; _moments = moments; });
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 个人吗？\n相关的美好时光记录也会一并删除'),
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
      await PersonDao.delete(id);
    }
    _selectedIds.clear();
    await _load();
    if (mounted) {
      setState(() => _multiSelect = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 个人'), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _addPerson() async {
    final nameCtl = TextEditingController();
    final prefCtl = TextEditingController();
    final noteCtl = TextEditingController();
    String relationship = 'friend';
    final birthdayCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('添加重要的人'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtl,
                    decoration: const InputDecoration(labelText: '名字', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 10),
                const Text('关系', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 4, children: Person.relationshipLabels.entries.map((e) =>
                  ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 12)),
                    selected: relationship == e.key,
                    onSelected: (_) => setS(() => relationship = e.key),
                  ),
                ).toList()),
                const SizedBox(height: 10),
                TextField(controller: birthdayCtl,
                    decoration: const InputDecoration(labelText: '生日（如 03-15，可选）', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: prefCtl, maxLines: 2,
                    decoration: const InputDecoration(labelText: '喜好/重要细节（可选）', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: noteCtl, maxLines: 2,
                    decoration: const InputDecoration(labelText: '备注（可选）', border: OutlineInputBorder(), isDense: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(onPressed: () async {
              if (nameCtl.text.trim().isEmpty) return;
              await PersonDao.insert(Person(
                name: nameCtl.text.trim(),
                relationship: relationship,
                birthday: birthdayCtl.text.trim().isEmpty ? null : birthdayCtl.text.trim(),
                preferences: prefCtl.text.trim().isEmpty ? null : prefCtl.text.trim(),
                note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ));
              Navigator.pop(ctx);
              await _load();
            }, child: const Text('保存')),
          ],
        ),
      ),
    );
  }

  Future<void> _addMoment(Person p) async {
    final contentCtl = TextEditingController();
    final noteCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('记录和${p.name}的美好时光'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: contentCtl, maxLines: 2,
                  decoration: const InputDecoration(labelText: '一起做了什么', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: noteCtl, maxLines: 3,
                  decoration: const InputDecoration(labelText: '感想（可选）', border: OutlineInputBorder(), isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            await RelationshipMomentDao.insert(RelationshipMoment(
              personId: p.id,
              content: contentCtl.text.trim().isEmpty ? null : contentCtl.text.trim(),
              note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ));
            Navigator.pop(ctx);
            await _load();
          }, child: const Text('保存')),
        ],
      ),
    );
  }

  String _fmtDate(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              const Text('重要的人', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: Icon(_multiSelect ? Icons.close : Icons.checklist, size: 20),
                tooltip: _multiSelect ? '退出多选' : '多选',
                onPressed: () => setState(() { _multiSelect = !_multiSelect; _selectedIds.clear(); }),
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
                      if (_selectedIds.length == _persons.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(_persons.where((p) => p.id != null).map((p) => p.id!));
                      }
                    });
                  },
                  child: Text(_selectedIds.length == _persons.length ? '取消全选' : '全选',
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
            child: _persons.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text('还没有添加重要的人', style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text('记住那些重要的人和美好的时光', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _persons.length,
              itemBuilder: (ctx, i) {
                final p = _persons[i];
                final moments = _moments[p.id] ?? [];
                final relLabel = Person.relationshipLabels[p.relationship] ?? p.relationship ?? '';
                final isSelected = p.id != null && _selectedIds.contains(p.id);
                return Card(
                  color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
                  child: InkWell(
                    onLongPress: () {
                      if (!_multiSelect && p.id != null) {
                        setState(() { _multiSelect = true; _selectedIds.add(p.id!); });
                      }
                    },
                    onTap: _multiSelect ? () {
                      if (p.id == null) return;
                      setState(() {
                        if (_selectedIds.contains(p.id)) _selectedIds.remove(p.id);
                        else _selectedIds.add(p.id!);
                      });
                    } : null,
                    child: ExpansionTile(
                    leading: _multiSelect
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (v) {
                              if (p.id == null) return;
                              setState(() { if (v == true) _selectedIds.add(p.id!); else _selectedIds.remove(p.id); });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          )
                        : CircleAvatar(
                      backgroundColor: Colors.pink.shade50,
                      child: Text(p.name.characters.first, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink.shade700)),
                    ),
                    title: Row(children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text(relLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ]),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (p.birthday != null) Text('🎂 ${p.birthday}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      if (p.preferences != null) Text(p.preferences!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                    trailing: _multiSelect ? null : IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () => _addMoment(p),
                      tooltip: '记录美好时光',
                    ),
                    children: [
                      if (moments.isEmpty)
                        Padding(padding: const EdgeInsets.all(12),
                          child: Text('还没有记录和${p.name}的美好时光', style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
                      ...moments.take(5).map((m) => ListTile(
                        dense: true,
                        title: Text(m.content ?? '', style: const TextStyle(fontSize: 13)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (m.note != null) Text(m.note!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text(_fmtDate(m.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                        ]),
                      )),
                      if (moments.length > 5)
                        Padding(padding: const EdgeInsets.only(bottom: 8),
                          child: Text('还有 ${moments.length - 5} 条记录...', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))),
                    ],
                  ),
                ));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPerson,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
