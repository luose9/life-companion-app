import 'package:flutter/material.dart';
import 'package:life_companion_app/data/body_record_dao.dart';
import 'package:life_companion_app/models/body_record.dart';

class BodyPage extends StatefulWidget {
  const BodyPage({super.key});
  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> with SingleTickerProviderStateMixin {
  List<BodyRecord> _sleeps = [];
  List<BodyRecord> _diets = [];
  List<BodyRecord> _health = [];
  late TabController _tabCtrl;
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final s = await BodyRecordDao.getByType('sleep');
    final d = await BodyRecordDao.getByType('diet');
    final h = await BodyRecordDao.getByType('health');
    if (mounted) setState(() { _sleeps = s; _diets = d; _health = h; });
  }

  List<BodyRecord> get _currentList {
    if (_tabCtrl.index == 0) return _sleeps;
    if (_tabCtrl.index == 1) return _diets;
    return _health;
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
      await BodyRecordDao.delete(id);
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

  String _fmtTime(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _fmtDate(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.month}/${dt.day}';
  }

  // ── 睡眠记录 ──
  Future<void> _addSleep() async {
    TimeOfDay? sleepTime;
    TimeOfDay? wakeTime;
    double quality = 5;
    final noteCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('记录睡眠'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(sleepTime == null ? '入睡时间：未设置' : '入睡：${sleepTime!.format(ctx)}')),
                  TextButton(onPressed: () async {
                    final t = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 23, minute: 0), initialEntryMode: TimePickerEntryMode.input);
                    if (t != null) setS(() => sleepTime = t);
                  }, child: const Text('选择')),
                ]),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  for (final qt in const [TimeOfDay(hour: 21, minute: 0), TimeOfDay(hour: 22, minute: 0), TimeOfDay(hour: 22, minute: 30), TimeOfDay(hour: 23, minute: 0), TimeOfDay(hour: 23, minute: 30), TimeOfDay(hour: 0, minute: 0)])
                    GestureDetector(
                      onTap: () => setS(() => sleepTime = qt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sleepTime != null && sleepTime!.hour == qt.hour && sleepTime!.minute == qt.minute ? Colors.blue.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: sleepTime != null && sleepTime!.hour == qt.hour && sleepTime!.minute == qt.minute ? Colors.blue : Colors.transparent),
                        ),
                        child: Text('${qt.hour.toString().padLeft(2, '0')}:${qt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: Text(wakeTime == null ? '起床时间：未设置' : '起床：${wakeTime!.format(ctx)}')),
                  TextButton(onPressed: () async {
                    final t = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 7, minute: 0), initialEntryMode: TimePickerEntryMode.input);
                    if (t != null) setS(() => wakeTime = t);
                  }, child: const Text('选择')),
                ]),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  for (final qt in const [TimeOfDay(hour: 5, minute: 30), TimeOfDay(hour: 6, minute: 0), TimeOfDay(hour: 6, minute: 30), TimeOfDay(hour: 7, minute: 0), TimeOfDay(hour: 7, minute: 30), TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 8, minute: 30)])
                    GestureDetector(
                      onTap: () => setS(() => wakeTime = qt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: wakeTime != null && wakeTime!.hour == qt.hour && wakeTime!.minute == qt.minute ? Colors.blue.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: wakeTime != null && wakeTime!.hour == qt.hour && wakeTime!.minute == qt.minute ? Colors.blue : Colors.transparent),
                        ),
                        child: Text('${qt.hour.toString().padLeft(2, '0')}:${qt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                ]),
                const SizedBox(height: 10),
                const Text('睡眠质量', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Text('只是你的主观感受，不需要精确', style: TextStyle(fontSize: 11, color: Colors.black54)),
                Row(children: [
                  const Text('😴', style: TextStyle(fontSize: 16)),
                  Expanded(child: Slider(value: quality, min: 1, max: 10, divisions: 9,
                      onChanged: (v) => setS(() => quality = v))),
                  const Text('😊', style: TextStyle(fontSize: 16)),
                  Text(' ${quality.round()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                TextField(controller: noteCtl, maxLines: 2,
                    decoration: const InputDecoration(labelText: '睡眠笔记（可选，如做了什么梦）', border: OutlineInputBorder(), isDense: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(onPressed: () async {
              final now = DateTime.now();
              int? sleepMs;
              int? wakeMs;
              if (sleepTime != null) {
                sleepMs = DateTime(now.year, now.month, now.day, sleepTime!.hour, sleepTime!.minute).millisecondsSinceEpoch;
              }
              if (wakeTime != null) {
                wakeMs = DateTime(now.year, now.month, now.day, wakeTime!.hour, wakeTime!.minute).millisecondsSinceEpoch;
              }
              await BodyRecordDao.insert(BodyRecord(
                recordType: 'sleep',
                timestamp: now.millisecondsSinceEpoch,
                sleepTime: sleepMs,
                wakeTime: wakeMs,
                sleepQuality: quality.round(),
                note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
              ));
              Navigator.pop(ctx);
              await _load();
            }, child: const Text('保存')),
          ],
        ),
      ),
    );
  }

  // ── 饮食记录 ──
  Future<void> _addDiet() async {
    final contentCtl = TextEditingController();
    String? feeling;
    final noteCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('记录饮食'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: contentCtl,
                    decoration: const InputDecoration(labelText: '吃了什么', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 10),
                const Text('吃完的感受', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['happy', 'neutral', 'uncomfortable'].map((f) {
                  final sel = feeling == f;
                  return GestureDetector(
                    onTap: () => setS(() => feeling = sel ? null : f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? Colors.blue.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? Colors.blue.shade200 : Colors.transparent),
                      ),
                      child: Text(BodyRecord.dietFeelingLabels[f] ?? f, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 10),
                TextField(controller: noteCtl, maxLines: 2,
                    decoration: const InputDecoration(labelText: '备注（可选）', border: OutlineInputBorder(), isDense: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(onPressed: () async {
              await BodyRecordDao.insert(BodyRecord(
                recordType: 'diet',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                dietContent: contentCtl.text.trim().isEmpty ? null : contentCtl.text.trim(),
                dietFeeling: feeling,
                note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
              ));
              Navigator.pop(ctx);
              await _load();
            }, child: const Text('保存')),
          ],
        ),
      ),
    );
  }

  // ── 健康记录 ──
  Future<void> _addHealth() async {
    final healthCtl = TextEditingController();
    final noteCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('记录身体状况'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: healthCtl, maxLines: 2,
                  decoration: const InputDecoration(labelText: '身体状况', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: noteCtl, maxLines: 2,
                  decoration: const InputDecoration(labelText: '备注（医嘱/用药等，可选）', border: OutlineInputBorder(), isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            await BodyRecordDao.insert(BodyRecord(
              recordType: 'health',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              healthNote: healthCtl.text.trim().isEmpty ? null : healthCtl.text.trim(),
              note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
            ));
            Navigator.pop(ctx);
            await _load();
          }, child: const Text('保存')),
        ],
      ),
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
              const Text('身体记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      final list = _currentList;
                      if (_selectedIds.length == list.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(list.where((r) => r.id != null).map((r) => r.id!));
                      }
                    });
                  },
                  child: Text(_selectedIds.length == _currentList.length ? '取消全选' : '全选',
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
              tabs: const [Tab(text: '😴 睡眠'), Tab(text: '🍽️ 饮食'), Tab(text: '💊 健康')]),
          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              _buildSleepList(),
              _buildDietList(),
              _buildHealthList(),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final idx = _tabCtrl.index;
          if (idx == 0) _addSleep();
          else if (idx == 1) _addDiet();
          else _addHealth();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSleepList() {
    if (_sleeps.isEmpty) return _emptyState('还没有睡眠记录', '点击 + 开始记录你的睡眠');
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _sleeps.length,
      itemBuilder: (ctx, i) {
        final r = _sleeps[i];
        final isSelected = r.id != null && _selectedIds.contains(r.id);
        return Card(
          color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
          child: InkWell(
            onLongPress: () { if (!_multiSelect && r.id != null) setState(() { _multiSelect = true; _selectedIds.add(r.id!); }); },
            onTap: _multiSelect ? () { if (r.id == null) return; setState(() { if (_selectedIds.contains(r.id)) _selectedIds.remove(r.id); else _selectedIds.add(r.id!); }); } : null,
            child: ListTile(
              leading: _multiSelect ? Checkbox(value: isSelected, onChanged: (v) { if (r.id == null) return; setState(() { if (v == true) _selectedIds.add(r.id!); else _selectedIds.remove(r.id); }); }, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact)
                  : CircleAvatar(backgroundColor: Colors.indigo.shade50, child: Text('${r.sleepQuality ?? 0}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700))),
              title: Row(children: [
                if (r.sleepTime != null) Text('${_fmtTime(r.sleepTime)} → ', style: const TextStyle(fontSize: 13)),
                if (r.wakeTime != null) Text(_fmtTime(r.wakeTime), style: const TextStyle(fontSize: 13)),
              ]),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_fmtDate(r.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                if (r.note != null) Text(r.note!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
              trailing: _multiSelect ? null : IconButton(
                icon: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                onPressed: () async { if (r.id != null) { await BodyRecordDao.delete(r.id!); await _load(); } },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDietList() {
    if (_diets.isEmpty) return _emptyState('还没有饮食记录', '记录让你开心和不舒服的食物');
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _diets.length,
      itemBuilder: (ctx, i) {
        final r = _diets[i];
        final isSelected = r.id != null && _selectedIds.contains(r.id);
        return Card(
          color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
          child: InkWell(
            onLongPress: () { if (!_multiSelect && r.id != null) setState(() { _multiSelect = true; _selectedIds.add(r.id!); }); },
            onTap: _multiSelect ? () { if (r.id == null) return; setState(() { if (_selectedIds.contains(r.id)) _selectedIds.remove(r.id); else _selectedIds.add(r.id!); }); } : null,
            child: ListTile(
              leading: _multiSelect ? Checkbox(value: isSelected, onChanged: (v) { if (r.id == null) return; setState(() { if (v == true) _selectedIds.add(r.id!); else _selectedIds.remove(r.id); }); }, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact)
                  : CircleAvatar(backgroundColor: Colors.orange.shade50, child: Text(r.dietFeeling != null ? (BodyRecord.dietFeelingLabels[r.dietFeeling]?.substring(0, 2) ?? '🍽️') : '🍽️')),
              title: Text(r.dietContent ?? '未记录', style: const TextStyle(fontSize: 14)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_fmtDate(r.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                if (r.note != null) Text(r.note!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
              trailing: _multiSelect ? null : IconButton(
                icon: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                onPressed: () async { if (r.id != null) { await BodyRecordDao.delete(r.id!); await _load(); } },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthList() {
    if (_health.isEmpty) return _emptyState('还没有健康记录', '记录你的身体状况');
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _health.length,
      itemBuilder: (ctx, i) {
        final r = _health[i];
        final isSelected = r.id != null && _selectedIds.contains(r.id);
        return Card(
          color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
          child: InkWell(
            onLongPress: () { if (!_multiSelect && r.id != null) setState(() { _multiSelect = true; _selectedIds.add(r.id!); }); },
            onTap: _multiSelect ? () { if (r.id == null) return; setState(() { if (_selectedIds.contains(r.id)) _selectedIds.remove(r.id); else _selectedIds.add(r.id!); }); } : null,
            child: ListTile(
              leading: _multiSelect ? Checkbox(value: isSelected, onChanged: (v) { if (r.id == null) return; setState(() { if (v == true) _selectedIds.add(r.id!); else _selectedIds.remove(r.id); }); }, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact)
                  : CircleAvatar(backgroundColor: Colors.teal.shade50, child: const Text('💊')),
              title: Text(r.healthNote ?? '健康记录', style: const TextStyle(fontSize: 14)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_fmtDate(r.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                if (r.note != null) Text(r.note!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
              trailing: _multiSelect ? null : IconButton(
                icon: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                onPressed: () async { if (r.id != null) { await BodyRecordDao.delete(r.id!); await _load(); } },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(String title, String sub) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.favorite_border, size: 48, color: Colors.grey.shade300),
      const SizedBox(height: 8),
      Text(title, style: TextStyle(color: Colors.grey.shade500)),
      const SizedBox(height: 4),
      Text(sub, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
    ]),
  );
}
