import 'package:flutter/material.dart';
import 'package:life_companion_app/data/mood_dao.dart';
import 'package:life_companion_app/models/mood.dart';
import 'package:life_companion_app/widgets/charts.dart';

// ── 基础情绪（P0一键记录） ──
const List<Map<String, String>> _kQuickMoods = [
  {'emoji': '😊', 'tag': '开心', 'color': '0xFFFFD700'},
  {'emoji': '😌', 'tag': '平静', 'color': '0xFF90EE90'},
  {'emoji': '😴', 'tag': '疲惫', 'color': '0xFF87CEEB'},
  {'emoji': '😤', 'tag': '烦躁', 'color': '0xFFFFA07A'},
  {'emoji': '😢', 'tag': '难过', 'color': '0xFF6495ED'},
  {'emoji': '🤷', 'tag': '说不清', 'color': '0xFFD3D3D3'},
];

// ── 扩展情绪库 ──
const List<Map<String, String>> _kAllMoods = [
  {'emoji': '😊', 'tag': '开心'},
  {'emoji': '😌', 'tag': '平静'},
  {'emoji': '😴', 'tag': '疲惫'},
  {'emoji': '😤', 'tag': '烦躁'},
  {'emoji': '😢', 'tag': '难过'},
  {'emoji': '😰', 'tag': '焦虑'},
  {'emoji': '🤩', 'tag': '兴奋'},
  {'emoji': '😔', 'tag': '失落'},
  {'emoji': '🥰', 'tag': '感动'},
  {'emoji': '😄', 'tag': '非常高兴'},
  {'emoji': '🤔', 'tag': '困惑'},
  {'emoji': '😶', 'tag': '无感'},
  {'emoji': '🤷', 'tag': '说不清'},
];

// ── 身体感受选项 ──
const List<Map<String, String>> _kBodyFeelings = [
  {'icon': '🫠', 'label': '轻松'},
  {'icon': '🪨', 'label': '沉重'},
  {'icon': '😬', 'label': '紧绷'},
  {'icon': '🔥', 'label': '发热'},
  {'icon': '🥶', 'label': '发冷'},
  {'icon': '💓', 'label': '心跳快'},
  {'icon': '🤕', 'label': '头痛'},
  {'icon': '🤢', 'label': '胃不舒服'},
  {'icon': '🙂', 'label': '无特殊感觉'},
];

// ── 想做什么选项 ──
const List<Map<String, String>> _kDesires = [
  {'icon': '😴', 'label': '想睡觉'},
  {'icon': '🍜', 'label': '想吃饭'},
  {'icon': '🏃', 'label': '想运动'},
  {'icon': '🧘', 'label': '想独处'},
  {'icon': '💬', 'label': '想找人说话'},
  {'icon': '🫥', 'label': '什么都不想做'},
];

// ── 引导提问（情绪低落或说不清时弹出） ──
const List<String> _kGuidingQuestions = [
  '今天发生了什么特别的事情吗？',
  '这种感觉以前有过吗？当时是什么情况？',
  '你现在最需要什么？',
  '如果你的好朋友现在有这种感觉，你会对他说什么？',
];

// ── 情绪接纳提示 ──
const Map<String, List<String>> _acceptanceMessages = {
  '疲惫': ['感到疲惫很正常，你的身体在告诉你需要休息 🌙', '今天辛苦了，给自己放个假吧'],
  '烦躁': ['烦躁说明你在乎，先做一次深呼吸吧 🌿', '允许自己烦躁一会儿，这很正常'],
  '难过': ['感到难过是很正常的，给自己一点时间 💙', '难过说明你是一个有感情的人'],
  '焦虑': ['焦虑只是身体的一个信号，你是安全的 🤗', '试着关注当下，一步一步来'],
  '失落': ['失落是暂时的，你的感受是被允许的 🌸', '今天不顺利没关系，明天又是新的一天'],
  '说不清': ['没关系，很多时候我们都不知道自己是什么感受 💜', '说不清也是一种真实的记录，你做得很好'],
};

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});
  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> with SingleTickerProviderStateMixin {
  List<Mood> _moods = [];
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
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await MoodDao.getAllMoods();
    if (mounted) setState(() => _moods = list);
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 条心情记录吗？'),
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
      await MoodDao.deleteMood(id);
    }
    _selectedIds.clear();
    await _load();
    if (mounted) {
      setState(() => _multiSelect = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 条心情记录'), duration: const Duration(seconds: 2)),
      );
    }
  }

  // ── 一键快速记录 ──
  Future<void> _quickRecord(Map<String, String> mood) async {
    final m = Mood(
      emoji: mood['emoji'],
      moodTag: mood['tag'],
      timestamp: DateTime.now().millisecondsSinceEpoch,
      intensity: 5,
    );
    await MoodDao.insertMood(m);
    await _load();

    if (!mounted) return;

    // 负面情绪接纳提示
    final messages = _acceptanceMessages[mood['tag']];
    if (messages != null) {
      final msg = messages[DateTime.now().second % messages.length];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已记录 ✨'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── 详细记录（身体感受优先流程） ──
  Future<void> _showDetailDialog() async {
    String? bodyFeeling;
    String? desire;
    int selectedIdx = 12; // 默认"说不清"
    double intensity = 5;
    String? trigger;
    final triggerNoteCtl = TextEditingController();
    final noteCtl = TextEditingController();
    int step = 0; // 0=身体, 1=想做什么, 2=情绪, 3=详细

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          Widget content;
          List<Widget> actions;

          if (step == 0) {
            // ── 第一步：身体感受 ──
            content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('你现在的身体感觉怎么样？',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('情绪往往藏在身体里', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: _kBodyFeelings.map((bf) {
                  final selected = bodyFeeling == bf['label'];
                  return GestureDetector(
                    onTap: () => setS(() => bodyFeeling = bf['label']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? Colors.teal.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? Colors.teal : Colors.transparent, width: 1.5),
                      ),
                      child: Text('${bf['icon']} ${bf['label']}', style: const TextStyle(fontSize: 13)),
                    ),
                  );
                }).toList()),
              ],
            );
            actions = [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              TextButton(
                onPressed: () => setS(() => step = 2), // 跳过直接到情绪
                child: const Text('跳过'),
              ),
              ElevatedButton(
                onPressed: () => setS(() => step = 1),
                child: const Text('下一步'),
              ),
            ];
          } else if (step == 1) {
            // ── 第二步：想做什么 ──
            content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('这种感觉让你想做什么？',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: _kDesires.map((d) {
                  final selected = desire == d['label'];
                  return GestureDetector(
                    onTap: () => setS(() => desire = d['label']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? Colors.indigo.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? Colors.indigo : Colors.transparent, width: 1.5),
                      ),
                      child: Text('${d['icon']} ${d['label']}', style: const TextStyle(fontSize: 13)),
                    ),
                  );
                }).toList()),
              ],
            );
            actions = [
              TextButton(onPressed: () => setS(() => step = 0), child: const Text('上一步')),
              TextButton(
                  onPressed: () => setS(() => step = 2),
                  child: const Text('跳过')),
              ElevatedButton(
                onPressed: () => setS(() => step = 2),
                child: const Text('下一步'),
              ),
            ];
          } else if (step == 2) {
            // ── 第三步：情绪选择（可选） ──
            content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('你觉得这可能是什么情绪？',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('选不出来也没关系，"说不清"也是一种真实',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Wrap(spacing: 6, runSpacing: 6, children: List.generate(_kAllMoods.length, (i) {
                  final opt = _kAllMoods[i];
                  final sel = selectedIdx == i;
                  return GestureDetector(
                    onTap: () => setS(() => selectedIdx = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? Colors.blue.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? Colors.blue : Colors.transparent, width: 1.5),
                      ),
                      child: Text('${opt['emoji']} ${opt['tag']}', style: const TextStyle(fontSize: 13)),
                    ),
                  );
                })),
                const SizedBox(height: 14),
                // ── 情绪强度 ──
                const Text('感受强度', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('情绪没有好坏，只有强弱', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Row(children: [
                  const Text('轻微', style: TextStyle(fontSize: 11)),
                  Expanded(
                    child: Slider(
                      value: intensity,
                      min: 1, max: 10, divisions: 9,
                      onChanged: (v) => setS(() => intensity = v),
                    ),
                  ),
                  const Text('强烈', style: TextStyle(fontSize: 11)),
                  Text(' ${intensity.round()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
              ],
            );
            actions = [
              TextButton(onPressed: () => setS(() => step = 1), child: const Text('上一步')),
              ElevatedButton(
                onPressed: () {
                  // 负面情绪或"说不清"时进入引导提问
                  final tag = _kAllMoods[selectedIdx]['tag']!;
                  final needsGuide = ['烦躁', '难过', '焦虑', '失落', '说不清'].contains(tag);
                  setS(() => step = needsGuide ? 3 : 4);
                },
                child: const Text('下一步'),
              ),
            ];
          } else if (step == 3) {
            // ── 引导提问（负面情绪/说不清时） ──
            content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💜 温柔提醒',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('这些问题不需要回答，只是帮助你梳理思绪。可以在下方写几句，也可以直接跳过。',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._kGuidingQuestions.map((q) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $q', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                )),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '想写点什么都可以，也可以留空...',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                ),
              ],
            );
            actions = [
              TextButton(onPressed: () => setS(() => step = 2), child: const Text('上一步')),
              TextButton(
                onPressed: () => setS(() => step = 4), // 跳过笔记
                child: const Text('跳过'),
              ),
              ElevatedButton(
                onPressed: () => setS(() => step = 4),
                child: const Text('下一步'),
              ),
            ];
          } else {
            // ── step 4：触发事件 + 保存 ──
            content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('什么引起了这种感受？（可选）',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: Mood.triggerLabels.entries.map((e) {
                  return ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 12)),
                    selected: trigger == e.key,
                    onSelected: (_) => setS(() => trigger = trigger == e.key ? null : e.key),
                  );
                }).toList()),
                const SizedBox(height: 8),
                TextField(
                  controller: triggerNoteCtl,
                  decoration: const InputDecoration(
                    labelText: '简单描述（可选）',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                  maxLines: 2,
                ),
                if (noteCtl.text.isEmpty) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '想写点什么都可以...',
                      border: OutlineInputBorder(), isDense: true,
                    ),
                  ),
                ],
              ],
            );
            actions = [
              TextButton(onPressed: () => setS(() => step = 2), child: const Text('上一步')),
              ElevatedButton(
                onPressed: () async {
                  final opt = _kAllMoods[selectedIdx];
                  final mood = Mood(
                    emoji: opt['emoji'],
                    moodTag: opt['tag'],
                    note: noteCtl.text.trim().isNotEmpty ? noteCtl.text.trim() : null,
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    intensity: intensity.round(),
                    trigger: trigger,
                    triggerNote: triggerNoteCtl.text.trim().isNotEmpty ? triggerNoteCtl.text.trim() : null,
                    bodyFeeling: bodyFeeling,
                    desire: desire,
                  );
                  await MoodDao.insertMood(mood);
                  Navigator.pop(ctx);
                  await _load();

                  final messages = _acceptanceMessages[opt['tag']];
                  if (messages != null && mounted) {
                    final msg = messages[DateTime.now().second % messages.length];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg), duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
                child: const Text('保存'),
              ),
            ];
          }

          return AlertDialog(
            title: Row(children: [
              const Expanded(child: Text('记录感受')),
              Text('${step + 1}/5', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(child: content),
            ),
            actions: actions,
          );
        },
      ),
    );
  }

  // ── 批量补录 ──
  Future<void> _showBatchBackfill() async {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: i)));

    await showDialog(
      context: context,
      builder: (ctx) {
        DateTime? selectedDay;
        int moodIdx = 0;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: const Text('补录过去的心情'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('选择日期，然后选择当天的主要情绪',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 10),
                    // 日期选择
                    Wrap(spacing: 6, runSpacing: 6, children: days.map((d) {
                      final selected = selectedDay != null &&
                          d.year == selectedDay!.year &&
                          d.month == selectedDay!.month &&
                          d.day == selectedDay!.day;
                      final isToday = d.day == today.day && d.month == today.month;
                      return GestureDetector(
                        onTap: () => setS(() => selectedDay = d),
                        child: Container(
                          width: 70,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? Colors.blue.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? Colors.blue : Colors.transparent, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Text(isToday ? '今天' : _weekdayName(d.weekday),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              Text('${d.month}/${d.day}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }).toList()),
                    const SizedBox(height: 14),

                    if (selectedDay != null) ...[
                      const Text('当天的主要情绪',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 6, children: List.generate(_kAllMoods.length, (i) {
                        final opt = _kAllMoods[i];
                        final sel = moodIdx == i;
                        return GestureDetector(
                          onTap: () => setS(() => moodIdx = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel ? Colors.blue.shade100 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? Colors.blue : Colors.transparent, width: 1.5),
                            ),
                            child: Text('${opt['emoji']} ${opt['tag']}', style: const TextStyle(fontSize: 13)),
                          ),
                        );
                      })),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              if (selectedDay != null)
                ElevatedButton(
                  onPressed: () async {
                    final opt = _kAllMoods[moodIdx];
                    // 时间设为当天中午12:00
                    final ts = DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day, 12);
                    final mood = Mood(
                      emoji: opt['emoji'],
                      moodTag: opt['tag'],
                      timestamp: ts.millisecondsSinceEpoch,
                      intensity: 5,
                    );
                    await MoodDao.insertMood(mood);
                    Navigator.pop(ctx);
                    await _load();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已补录 ${selectedDay!.month}/${selectedDay!.day} 的心情 ✨'),
                            duration: const Duration(seconds: 2)),
                      );
                    }
                  },
                  child: const Text('保存'),
                ),
            ],
          ),
        );
      },
    );
  }

  String _weekdayName(int wd) {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[wd];
  }

  String _formatTime(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDay(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 一键快速记录区 ──
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('此刻的心情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_multiSelect ? Icons.close : Icons.checklist, size: 20),
                    tooltip: _multiSelect ? '退出多选' : '多选',
                    onPressed: () => setState(() { _multiSelect = !_multiSelect; _selectedIds.clear(); }),
                  ),
                  TextButton.icon(
                    onPressed: _showBatchBackfill,
                    icon: const Icon(Icons.date_range, size: 16),
                    label: const Text('补录', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: _showDetailDialog,
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('详细记录', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              Text('点击即可记录，无需思考', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _kQuickMoods.map((m) {
                  return GestureDetector(
                    onTap: () => _quickRecord(m),
                    child: Column(
                      children: [
                        Text(m['emoji']!, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 2),
                        Text(m['tag']!, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

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
                    if (_selectedIds.length == _moods.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(_moods.where((m) => m.id != null).map((m) => m.id!));
                    }
                  });
                },
                child: Text(_selectedIds.length == _moods.length ? '取消全选' : '全选',
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
        // ── Tab栏 ──
        TabBar(
          controller: _tabCtrl,
          labelColor: Colors.blue.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: '记录'),
            Tab(text: '时间线'),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildRecordList(),
              _buildTimeline(),
            ],
          ),
        ),
      ],
    );
  }

  // ── 记录列表 ──
  Widget _buildRecordList() {
    if (_moods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_emotions_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('还没有记录', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text('点击上方表情开始记录你的感受', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _moods.length,
      itemBuilder: (ctx, i) {
        final m = _moods[i];
        final isSelected = m.id != null && _selectedIds.contains(m.id);
        return Card(
          color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
          child: InkWell(
            onLongPress: () {
              if (!_multiSelect && m.id != null) {
                setState(() { _multiSelect = true; _selectedIds.add(m.id!); });
              }
            },
            onTap: _multiSelect ? () {
              if (m.id == null) return;
              setState(() {
                if (_selectedIds.contains(m.id)) _selectedIds.remove(m.id);
                else _selectedIds.add(m.id!);
              });
            } : null,
            child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_multiSelect)
                  Checkbox(
                    value: isSelected,
                    onChanged: (v) {
                      if (m.id == null) return;
                      setState(() { if (v == true) _selectedIds.add(m.id!); else _selectedIds.remove(m.id); });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                Text(m.emoji ?? '🙂', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(m.moodTag ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        if (m.intensity > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('强度 ${m.intensity}', style: TextStyle(fontSize: 10, color: Colors.blue.shade600)),
                          ),
                      ]),
                      if (m.trigger != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('触发：${Mood.triggerLabels[m.trigger] ?? m.trigger}${m.triggerNote != null ? " · ${m.triggerNote}" : ""}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ),
                      if (m.bodyFeeling != null || m.desire != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            [
                              if (m.bodyFeeling != null) '身体：${m.bodyFeeling}',
                              if (m.desire != null) '想${m.desire}',
                            ].join(' · '),
                            style: TextStyle(fontSize: 11, color: Colors.teal.shade400),
                          ),
                        ),
                      if (m.note != null && m.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(m.note!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700), maxLines: 2),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_formatTime(m.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                      ),
                    ],
                  ),
                ),
                if (!_multiSelect)
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                    onPressed: () async {
                      if (m.id != null) {
                        await MoodDao.deleteMood(m.id!);
                        await _load();
                      }
                    },
                  ),
              ],
            ),
          ),
        ));
      },
    );
  }

  // ── 情绪时间线 ──
  Widget _buildTimeline() {
    if (_moods.isEmpty) {
      return const Center(child: Text('记录一些心情后就能看到时间线了 🌈'));
    }

    // 按天分组最近30天
    final recent30 = _moods.where((m) {
      if (m.timestamp == null) return false;
      return DateTime.now().millisecondsSinceEpoch - m.timestamp! < 30 * 86400000;
    }).toList();

    if (recent30.isEmpty) {
      return const Center(child: Text('最近30天没有记录'));
    }

    // 频次统计
    final freq = <String, int>{};
    for (final m in recent30) {
      final tag = m.moodTag ?? '未知';
      freq[tag] = (freq[tag] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // 找到让你开心的事
    final happyTriggers = <String, int>{};
    final sadTriggers = <String, int>{};
    for (final m in recent30) {
      if (m.trigger == null) continue;
      final label = Mood.triggerLabels[m.trigger] ?? m.trigger!;
      if (['开心', '非常高兴', '兴奋', '感动', '平静'].contains(m.moodTag)) {
        happyTriggers[label] = (happyTriggers[label] ?? 0) + 1;
      }
      if (['烦躁', '难过', '焦虑', '失落', '疲惫'].contains(m.moodTag)) {
        sadTriggers[label] = (sadTriggers[label] ?? 0) + 1;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 30天情绪频次 ──
          if (sorted.isNotEmpty) ...[
            const Text('最近30天的情绪分布', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Text('只是事实，不做评判', style: TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 8),
            ChartCard(
              title: '',
              child: BarChart(
                values: sorted.take(6).map((e) => e.value.toDouble()).toList(),
                labels: sorted.take(6).map((e) => e.key).toList(),
                colors: const [
                  Color(0xFFFFD700), Color(0xFF90EE90), Color(0xFF87CEEB),
                  Color(0xFFFFA07A), Color(0xFF6495ED), Color(0xFFDDA0DD),
                ],
                height: 120,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ── 关联分析 ──
          if (happyTriggers.isNotEmpty) ...[
            const Text('💛 让你感到积极的事', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            ...happyTriggers.entries.take(3).map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${e.key}（${e.value}次）', style: const TextStyle(fontSize: 13)),
                )),
            const SizedBox(height: 12),
          ],

          if (sadTriggers.isNotEmpty) ...[
            const Text('🔵 容易带来低落感的事', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Text('了解它们，就是照顾自己的第一步', style: TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 4),
            ...sadTriggers.entries.take(3).map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${e.key}（${e.value}次）', style: const TextStyle(fontSize: 13)),
                )),
            const SizedBox(height: 12),
          ],

          // ── 日期时间线 ──
          const Text('时间线', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...recent30.take(20).map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60,
                  child: Text(_formatTime(m.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ),
                Text(m.emoji ?? '🙂', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${m.moodTag ?? ""} · 强度${m.intensity}', style: const TextStyle(fontSize: 12)),
                      if (m.trigger != null)
                        Text(Mood.triggerLabels[m.trigger] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
