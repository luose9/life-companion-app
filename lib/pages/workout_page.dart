import 'package:flutter/material.dart';
import 'package:life_companion_app/data/workout_dao.dart';
import 'package:life_companion_app/models/workout.dart';
import 'package:life_companion_app/widgets/charts.dart';
import 'package:life_companion_app/pages/live_tracking_page.dart';
import 'package:life_companion_app/pages/workout_result_page.dart';

const List<String> _kWorkoutTypes = ['跑步', '步行', '骑行', '游泳', '健身', '其他'];
const List<IconData> _kWorkoutIcons = [
  Icons.directions_run,
  Icons.directions_walk,
  Icons.directions_bike,
  Icons.pool,
  Icons.fitness_center,
  Icons.sports,
];

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  List<Workout> _workouts = [];
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await WorkoutDao.getAll();
    setState(() => _workouts = list);
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 条运动记录吗？'),
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
      await WorkoutDao.delete(id);
    }
    _selectedIds.clear();
    await _load();
    if (mounted) {
      setState(() => _multiSelect = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 条运动记录'), duration: const Duration(seconds: 2)),
      );
    }
  }

  // ── 汇总统计（去掉卡路里，改为身体感受） ──
  double get _totalKm => _workouts.fold(0.0, (s, w) => s + (w.distanceKm ?? 0));
  int get _totalMin => _workouts.fold(0, (s, w) => s + w.durationMinutes);
  int get _totalCount => _workouts.length;

  String get _moodInsight {
    final withMood = _workouts.where((w) => w.moodBefore != null && w.moodAfter != null).toList();
    if (withMood.isEmpty) return '';
    int improved = 0;
    for (final w in withMood) {
      final beforeIdx = Workout.moodLabels.keys.toList().indexOf(w.moodBefore!);
      final afterIdx = Workout.moodLabels.keys.toList().indexOf(w.moodAfter!);
      if (afterIdx < beforeIdx) improved++;
    }
    if (improved > withMood.length / 2) return '运动之后心情通常会变好 🌈';
    return '';
  }

  // ── 近 7 天每天时长 ──
  List<double> get _last7DayMin {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return _workouts
          .where((w) {
            if (w.startTime == null) return false;
            final d = DateTime.fromMillisecondsSinceEpoch(w.startTime!);
            return d.year == day.year && d.month == day.month && d.day == day.day;
          })
          .fold(0.0, (s, w) => s + w.durationMinutes);
    });
  }

  List<String> get _last7Labels {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return '${d.month}/${d.day}';
    });
  }

  // ── 实时运动追踪 ──
  static const _kLiveTypes = ['跑步', '步行'];
  static const _kLiveIcons = [Icons.directions_run, Icons.directions_walk];

  Future<void> _startLiveTracking() async {
    String selectedType = '跑步';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('选择运动类型'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_kLiveTypes.length, (i) {
              final sel = selectedType == _kLiveTypes[i];
              return ChoiceChip(
                avatar: Icon(_kLiveIcons[i], size: 16),
                label: Text(_kLiveTypes[i]),
                selected: sel,
                onSelected: (_) => setS(() => selectedType = _kLiveTypes[i]),
              );
            }),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('开始')),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LiveTrackingPage(workoutType: selectedType)),
      );
      await _load();
    }
  }

  // ── 记录对话框（身体对话版） ──
  Future<void> _showDialog({Workout? existing}) async {
    String type = existing?.type ?? '跑步';
    final noteCtl = TextEditingController(text: existing?.note ?? '');
    final tagsCtl = TextEditingController(text: existing?.customTags ?? '');
    String? bodyFeeling = existing?.bodyFeeling;
    String? moodBefore = existing?.moodBefore;
    String? moodAfter = existing?.moodAfter;
    DateTime? startDt = existing?.startTime != null
        ? DateTime.fromMillisecondsSinceEpoch(existing!.startTime!)
        : null;
    TimeOfDay? startTod =
        startDt != null ? TimeOfDay(hour: startDt.hour, minute: startDt.minute) : null;
    DateTime? endDt = existing?.endTime != null
        ? DateTime.fromMillisecondsSinceEpoch(existing!.endTime!)
        : null;
    TimeOfDay? endTod =
        endDt != null ? TimeOfDay(hour: endDt.hour, minute: endDt.minute) : null;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? '和身体对话' : '编辑运动'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('运动类型', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: List.generate(_kWorkoutTypes.length, (i) {
                    final sel = type == _kWorkoutTypes[i];
                    return ChoiceChip(
                      avatar: Icon(_kWorkoutIcons[i], size: 16),
                      label: Text(_kWorkoutTypes[i]),
                      selected: sel,
                      onSelected: (_) => setS(() => type = _kWorkoutTypes[i]),
                    );
                  }),
                ),
                const SizedBox(height: 10),

                // ── 运动前心情 ──
                const Text('运动前心情', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6,
                  children: Workout.moodLabels.entries.map((e) => ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 11)),
                    selected: moodBefore == e.key,
                    onSelected: (v) => setS(() => moodBefore = v ? e.key : null),
                  )).toList(),
                ),
                const SizedBox(height: 10),

                // ── 开始时间 ──
                const Text('开始时间', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Row(children: [
                  Expanded(child: Text(startDt == null ? '未选择' : _fmtDt(startDt!),
                      style: TextStyle(color: startDt == null ? Colors.grey : Colors.black, fontSize: 13))),
                  TextButton(onPressed: () async {
                    final d = await showDatePicker(context: ctx, initialDate: startDt ?? DateTime.now(),
                        firstDate: DateTime(2000), lastDate: DateTime.now());
                    if (d == null) return;
                    final t = await showTimePicker(context: ctx, initialTime: startTod ?? TimeOfDay.now(), initialEntryMode: TimePickerEntryMode.input);
                    if (t != null) setS(() { startTod = t; startDt = DateTime(d.year, d.month, d.day, t.hour, t.minute); });
                  }, child: const Text('选择')),
                ]),

                // ── 结束时间 ──
                const Text('结束时间', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Row(children: [
                  Expanded(child: Text(endDt == null ? '未选择' : _fmtDt(endDt!),
                      style: TextStyle(color: endDt == null ? Colors.grey : Colors.black, fontSize: 13))),
                  TextButton(onPressed: () async {
                    final firstDate = startDt ?? DateTime.now();
                    final d = await showDatePicker(context: ctx, initialDate: endDt ?? firstDate,
                        firstDate: DateTime(firstDate.year, firstDate.month, firstDate.day), lastDate: DateTime.now());
                    if (d == null) return;
                    final t = await showTimePicker(context: ctx, initialTime: endTod ?? TimeOfDay.now(), initialEntryMode: TimePickerEntryMode.input);
                    if (t != null) setS(() { endTod = t; endDt = DateTime(d.year, d.month, d.day, t.hour, t.minute); });
                  }, child: const Text('选择')),
                ]),
                const SizedBox(height: 8),

                // ── 身体感受 ──
                const Text('身体感受', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6,
                  children: Workout.bodyFeelingLabels.entries.map((e) => ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 11)),
                    selected: bodyFeeling == e.key,
                    onSelected: (v) => setS(() => bodyFeeling = v ? e.key : null),
                  )).toList(),
                ),
                const SizedBox(height: 10),

                // ── 运动后心情 ──
                const Text('运动后心情', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6,
                  children: Workout.moodLabels.entries.map((e) => ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 11)),
                    selected: moodAfter == e.key,
                    onSelected: (v) => setS(() => moodAfter = v ? e.key : null),
                  )).toList(),
                ),
                const SizedBox(height: 10),

                // ── 标签 ──
                TextField(controller: tagsCtl, decoration: const InputDecoration(
                    labelText: '标签（逗号分隔，如：晨跑,公园）', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 8),

                // ── 备注 ──
                TextField(controller: noteCtl, maxLines: 2, decoration: const InputDecoration(
                    labelText: '感受 / 备注', hintText: '身体告诉你了什么？', border: OutlineInputBorder(), isDense: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                final w = Workout(
                  id: existing?.id,
                  type: type,
                  startTime: startDt?.millisecondsSinceEpoch,
                  endTime: endDt?.millisecondsSinceEpoch,
                  distanceKm: existing?.distanceKm,
                  steps: existing?.steps,
                  calories: existing?.calories,
                  note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
                  bodyFeeling: bodyFeeling,
                  moodBefore: moodBefore,
                  moodAfter: moodAfter,
                  customTags: tagsCtl.text.trim().isEmpty ? null : tagsCtl.text.trim(),
                );
                if (existing == null) {
                  await WorkoutDao.insert(w);
                } else {
                  await WorkoutDao.update(w);
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

  String _fmtDt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtDate(int? ms) {
    if (ms == null) return '';
    return _fmtDt(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  IconData _iconFor(String type) {
    final idx = _kWorkoutTypes.indexOf(type);
    return idx >= 0 ? _kWorkoutIcons[idx] : Icons.sports;
  }

  @override
  Widget build(BuildContext context) {
    final insight = _moodInsight;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // ── 汇总卡片（温暖版） ──
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(label: '总时长', value: '$_totalMin 分'),
                    _StatChip(label: '运动次数', value: '$_totalCount 次'),
                  ],
                ),
                if (insight.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(insight, style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                ],
                if (_totalMin > 0) ...[
                  const SizedBox(height: 2),
                  Text('你已经和身体对话了 $_totalMin 分钟', style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
                ],
              ]),
            ),
          ),
          // ── 近 7 天折线图 ──
          if (_last7DayMin.any((v) => v > 0))
            ChartCard(
              title: '近 7 天运动时长（分钟）',
              child: LineChart(
                values: _last7DayMin,
                labels: _last7Labels,
                color: Colors.green.shade600,
                height: 120,
              ),
            ),
          const SizedBox(height: 4),

          // ── 标题栏 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('身体对话', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(children: [
                IconButton(
                  icon: Icon(_multiSelect ? Icons.close : Icons.checklist, size: 20),
                  tooltip: _multiSelect ? '退出多选' : '多选',
                  onPressed: () => setState(() { _multiSelect = !_multiSelect; _selectedIds.clear(); }),
                ),
                ElevatedButton.icon(
                  onPressed: () => _startLiveTracking(),
                  icon: const Icon(Icons.gps_fixed, size: 16),
                  label: const Text('实时运动'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                    onPressed: () => _showDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('记录')),
              ]),
            ],
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
                      if (_selectedIds.length == _workouts.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(_workouts.where((w) => w.id != null).map((w) => w.id!));
                      }
                    });
                  },
                  child: Text(_selectedIds.length == _workouts.length ? '取消全选' : '全选',
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
          // ── 列表 ──
          Expanded(
            child: _workouts.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.self_improvement, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('还没有运动记录', style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text('运动不是任务，是和身体的一次对话', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ]))
                : ListView.builder(
                    itemCount: _workouts.length,
                    itemBuilder: (ctx, i) {
                      final w = _workouts[i];
                      final isSelected = w.id != null && _selectedIds.contains(w.id);
                      Widget card = Card(
                        color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
                        child: InkWell(
                          onLongPress: () {
                            if (!_multiSelect && w.id != null) {
                              setState(() { _multiSelect = true; _selectedIds.add(w.id!); });
                            }
                          },
                          onTap: _multiSelect ? () {
                            if (w.id == null) return;
                            setState(() {
                              if (_selectedIds.contains(w.id)) _selectedIds.remove(w.id);
                              else _selectedIds.add(w.id!);
                            });
                          } : () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (_) => WorkoutResultPage(workout: w)),
                            );
                          },
                          child: ListTile(
                            leading: _multiSelect
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (v) {
                                      if (w.id == null) return;
                                      setState(() { if (v == true) _selectedIds.add(w.id!); else _selectedIds.remove(w.id); });
                                    },
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  )
                                : CircleAvatar(
                                    backgroundColor: Colors.green.shade400,
                                    child: Icon(_iconFor(w.type), color: Colors.white, size: 20),
                                  ),
                            title: Text(w.type,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_fmtDate(w.startTime), style: const TextStyle(fontSize: 12)),
                                Wrap(spacing: 4, runSpacing: 2, children: [
                                  if (w.durationMinutes > 0)
                                    _Pill('${w.durationMinutes} 分钟', Colors.blue),
                                  if (w.distanceKm != null)
                                    _Pill('${w.distanceKm!.toStringAsFixed(2)} km', Colors.orange),
                                  if (w.steps != null) _Pill('${w.steps} 步', Colors.purple),
                                  if (w.bodyFeeling != null)
                                    _Pill(Workout.bodyFeelingLabels[w.bodyFeeling] ?? w.bodyFeeling!, Colors.teal),
                                  if (w.moodBefore != null)
                                    _Pill('前:${Workout.moodLabels[w.moodBefore] ?? w.moodBefore!}', Colors.blueGrey),
                                  if (w.moodAfter != null)
                                    _Pill('后:${Workout.moodLabels[w.moodAfter] ?? w.moodAfter!}', Colors.green),
                                ]),
                                if (w.customTags != null && w.customTags!.isNotEmpty)
                                  Wrap(spacing: 4, children: w.customTags!.split(',').map((t) =>
                                    _Pill('#${t.trim()}', Colors.indigo)).toList()),
                                if (w.note != null && w.note!.isNotEmpty)
                                  Text(w.note!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: _multiSelect ? null : IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showDialog(existing: w),
                            ),
                          ),
                        ),
                      );
                      if (_multiSelect) return card;
                      return Dismissible(
                        key: ValueKey(w.id ?? i),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.grey.shade300,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          if (w.id != null) await WorkoutDao.delete(w.id!);
                          await _load();
                        },
                        child: card,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
