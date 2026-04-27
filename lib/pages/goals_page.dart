import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:life_companion_app/data/goal_dao.dart';
import 'package:life_companion_app/data/checkin_dao.dart';
import 'package:life_companion_app/models/goal.dart';
import 'package:life_companion_app/models/checkin_record.dart';
import 'package:life_companion_app/pages/goal_detail.dart';
import 'package:life_companion_app/pages/focus_timer_page.dart';
import 'package:life_companion_app/pages/focus_stats_page.dart';
import 'package:life_companion_app/pages/achievement_wall_page.dart';
import 'package:life_companion_app/services/notification_service.dart';
import 'package:life_companion_app/services/session_manager.dart';
import 'package:life_companion_app/main.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});
  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with SingleTickerProviderStateMixin {
  List<Goal> _allGoals = [];
  String _viewLevel = 'daily';
  late TabController _tabCtrl;
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  static const _levels = ['vision', 'yearly', 'quarterly', 'weekly', 'daily'];
  static const _levelLabels = ['愿景', '年度', '季度', '周', '今日'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this, initialIndex: 4);
    _tabCtrl.addListener(() {
      setState(() => _viewLevel = _levels[_tabCtrl.index]);
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await GoalDao.getActiveGoals();
    if (mounted) setState(() => _allGoals = list);
  }

  List<Goal> get _filtered => _allGoals.where((g) => g.level == _viewLevel).toList();

  // ── 批量删除 ──
  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 个目标吗？'),
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
      await GoalDao.deleteGoal(id);
    }
    _selectedIds.clear();
    await _load();
    if (mounted) {
      setState(() => _multiSelect = false);
      globalCancelMultiSelect = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 个目标'), duration: const Duration(seconds: 2)),
      );
    }
  }

  // ── 温和话术 ──
  static const _warmMessages = [
    '你今天迈出的每一步都很重要 🌱',
    '慢慢来，比较快 ☀️',
    '专注当下，享受过程 🌿',
    '你已经做得很好了 🌸',
    '每一点进步都值得被看到 ✨',
  ];

  String get _todayMessage {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _warmMessages[dayOfYear % _warmMessages.length];
  }

  // ── 新增目标 ──
  Future<void> _showAddDialog() async {
    // 检查数量限制
    final limit = Goal.levelLimits[_viewLevel];
    if (limit != null) {
      final count = await GoalDao.countByLevel(_viewLevel);
      if (count >= limit) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('温馨提示'),
            content: Text(
              '同时处理太多目标会让你疲惫不堪 😊\n'
              '当前层级已有$count个活跃目标（上限$limit个）\n'
              '先专注最重要的几个吧！',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('我明白了'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    final meaningCtl = TextEditingController();
    double difficulty = 5;
    int checkinFreq = 5;
    DateTime? startDate;
    DateTime? endDate;
    String level = _viewLevel;
    int? parentId;
    final remindCtl = TextEditingController();
    TimeOfDay? remindTimeOfDay;
    List<String> microActions = ['', '', ''];
    final microCtls = [TextEditingController(), TextEditingController(), TextEditingController()];
    bool showSmartGuide = false;

    // 获取上层目标列表
    final parentLevelIdx = _levels.indexOf(level) - 1;
    List<Goal> parentOptions = [];
    if (parentLevelIdx >= 0) {
      parentOptions = await GoalDao.getByLevel(_levels[parentLevelIdx]);
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return AlertDialog(
            title: Text('新增${Goal.levelLabels[level] ?? "目标"}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 层级选择 ──
                    const Text('目标层级', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, children: List.generate(5, (i) {
                      return ChoiceChip(
                        label: Text(_levelLabels[i], style: const TextStyle(fontSize: 12)),
                        selected: level == _levels[i],
                        onSelected: (_) async {
                          final pIdx = i - 1;
                          List<Goal> pOpts = [];
                          if (pIdx >= 0) pOpts = await GoalDao.getByLevel(_levels[pIdx]);
                          setS(() {
                            level = _levels[i];
                            parentOptions = pOpts;
                            parentId = null;
                          });
                        },
                      );
                    })),
                    const SizedBox(height: 10),

                    // ── 关联上层目标 ──
                    if (parentOptions.isNotEmpty) ...[
                      const Text('关联上层目标', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      DropdownButton<int?>(
                        value: parentId,
                        isExpanded: true,
                        hint: const Text('选择上层目标（可选）'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('不关联')),
                          ...parentOptions.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title))),
                        ],
                        onChanged: (v) => setS(() => parentId = v),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // ── 标题 ──
                    TextField(
                      controller: titleCtl,
                      decoration: const InputDecoration(labelText: '目标标题', border: OutlineInputBorder(), isDense: true),
                      onChanged: (v) {
                        // SMART引导
                        if (v.length > 2 && !v.contains(RegExp(r'\d'))) {
                          setS(() => showSmartGuide = true);
                        } else {
                          setS(() => showSmartGuide = false);
                        }
                      },
                    ),

                    // ── SMART目标引导 ──
                    if (showSmartGuide)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 让目标更清晰', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            const Text('试试这样描述：', style: TextStyle(fontSize: 12)),
                            const Text('• 你希望多久内达成？', style: TextStyle(fontSize: 12)),
                            const Text('• 具体想达到什么程度？', style: TextStyle(fontSize: 12)),
                            const Text('• 每周愿意花多少时间？', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('清晰的目标完成率是模糊目标甄5倍哦 ✨', style: TextStyle(fontSize: 11, color: Theme.of(ctx).hintColor)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),

                    // ── 描述 ──
                    TextField(
                      controller: descCtl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: '描述（可选）', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 10),

                    // ── 目标意义锚定（P0必填） ──
                    const Text('🎯 这个目标对你意味着什么？', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('（当你想放弃时，这段话会提醒你为什么开始）', style: TextStyle(fontSize: 11, color: Theme.of(ctx).hintColor)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: meaningCtl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: '写下1-3句话...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── 难度滑块 ──
                    const Text('目标难度', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(children: [
                      Expanded(
                        child: Slider(
                          value: difficulty,
                          min: 1, max: 10, divisions: 9,
                          activeColor: difficulty >= 4 && difficulty <= 7
                              ? Colors.green
                              : difficulty > 7
                                  ? Colors.orange
                                  : Colors.blue,
                          onChanged: (v) => setS(() => difficulty = v),
                        ),
                      ),
                      Text('${difficulty.round()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    Text(
                      difficulty >= 4 && difficulty <= 7
                          ? '👍 跳一跳够得着，完成率最高！'
                          : difficulty > 7
                              ? '这个有点挑战，确保你准备好了 💪'
                              : '轻松达成，建议加点难度 🌱',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),

                    // ── 打卡频率 ──
                    if (level == 'daily' || level == 'weekly') ...[
                      const Text('打卡频率（每周几天）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('自主选择适合你的节奏，无需每天', style: TextStyle(fontSize: 11, color: Theme.of(ctx).hintColor)),
                      Row(children: [
                        Expanded(
                          child: Slider(
                            value: checkinFreq.toDouble(),
                            min: 1, max: 7, divisions: 6,
                            onChanged: (v) => setS(() => checkinFreq = v.round()),
                          ),
                        ),
                        Text('$checkinFreq天/周', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                      const SizedBox(height: 10),
                    ],

                    // ── 微行动（5分钟内完成） ──
                    const Text('✅ 微行动（5分钟就能完成的小事）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('行动越小阻力越小，先开始再说！', style: TextStyle(fontSize: 11, color: Theme.of(ctx).hintColor)),
                    const SizedBox(height: 4),
                    ...List.generate(3, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: TextField(
                        controller: microCtls[i],
                        decoration: InputDecoration(
                          hintText: '微行动 ${i + 1}（可选）',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          prefixIcon: const Icon(Icons.check_circle_outline, size: 18),
                        ),
                      ),
                    )),
                    const SizedBox(height: 10),

                    // ── 日期 ──
                    Row(children: [
                      Expanded(child: Text(startDate == null ? '开始：未设置' : '开始：${_fmtDate(startDate!)}')),
                      TextButton(onPressed: () async {
                        final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (d != null) {
                          setS(() {
                            startDate = d;
                            if (endDate != null && endDate!.isBefore(d)) endDate = null;
                          });
                        }
                      }, child: const Text('选择')),
                    ]),
                    Row(children: [
                      Expanded(child: Text(endDate == null ? '截止：未设置' : '截止：${_fmtDate(endDate!)}')),
                      TextButton(onPressed: () async {
                        final first = startDate ?? DateTime.now();
                        final d = await showDatePicker(context: ctx, initialDate: first, firstDate: first, lastDate: DateTime(2100));
                        if (d != null) setS(() => endDate = d);
                      }, child: const Text('选择')),
                    ]),

                    // ── 提醒 ──
                    Row(children: [
                      Expanded(child: Text(remindTimeOfDay == null ? '提醒：未设置' : '提醒：${remindTimeOfDay!.format(ctx)}')),
                      TextButton(onPressed: () async {
                        final t = await showTimePicker(context: ctx, initialTime: remindTimeOfDay ?? TimeOfDay.now(), initialEntryMode: TimePickerEntryMode.input);
                        if (t != null) setS(() => remindTimeOfDay = t);
                      }, child: const Text('设置提醒')),
                    ]),
                    // ── 快捷提醒时间 ──
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      _QuickTimeChip(label: '7:00', time: const TimeOfDay(hour: 7, minute: 0), selected: remindTimeOfDay, onTap: (t) => setS(() => remindTimeOfDay = t)),
                      _QuickTimeChip(label: '8:00', time: const TimeOfDay(hour: 8, minute: 0), selected: remindTimeOfDay, onTap: (t) => setS(() => remindTimeOfDay = t)),
                      _QuickTimeChip(label: '9:00', time: const TimeOfDay(hour: 9, minute: 0), selected: remindTimeOfDay, onTap: (t) => setS(() => remindTimeOfDay = t)),
                      _QuickTimeChip(label: '12:00', time: const TimeOfDay(hour: 12, minute: 0), selected: remindTimeOfDay, onTap: (t) => setS(() => remindTimeOfDay = t)),
                      _QuickTimeChip(label: '18:00', time: const TimeOfDay(hour: 18, minute: 0), selected: remindTimeOfDay, onTap: (t) => setS(() => remindTimeOfDay = t)),
                      _QuickTimeChip(label: '21:00', time: const TimeOfDay(hour: 21, minute: 0), selected: remindTimeOfDay, onTap: (t) => setS(() => remindTimeOfDay = t)),
                    ]),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtl.text.trim();
                  if (title.isEmpty) return;
                  final meaningText = meaningCtl.text.trim();
                  if (meaningText.isEmpty && level != 'vision') {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('写下目标的意义吧，这会帮助你坚持下去 🌱')),
                    );
                    return;
                  }
                  final micros = microCtls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
                  final goal = Goal(
                    title: title,
                    description: descCtl.text.trim(),
                    level: level,
                    parentId: parentId,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                    startDate: startDate?.millisecondsSinceEpoch,
                    endDate: endDate?.millisecondsSinceEpoch,
                    meaning: meaningText.isNotEmpty ? meaningText : null,
                    difficulty: difficulty.round(),
                    checkinFrequency: checkinFreq,
                    microActions: micros.isNotEmpty ? jsonEncode(micros) : null,
                    remindTime: remindTimeOfDay != null ? remindTimeOfDay!.hour * 60 + remindTimeOfDay!.minute : null,
                    repeatRule: checkinFreq > 0 ? 'daily' : null,
                  );
                  final id = await GoalDao.insertGoal(goal);
                  if (remindTimeOfDay != null) {
                    final now = DateTime.now();
                    final next = DateTime(now.year, now.month, now.day, remindTimeOfDay!.hour, remindTimeOfDay!.minute);
                    final firstInstance = next.isBefore(now) ? next.add(const Duration(days: 1)) : next;
                    await NotificationService.instance.scheduleRecurring(
                      id,
                      '今天还有一个小目标等着你哦 ☀️',
                      '5分钟就能完成：${title}',
                      firstInstance,
                      'daily',
                    );
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

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── 打卡 ──────────────
  Future<void> _checkin(Goal g) async {
    // 检查今天是否已打卡
    final todayCount = await CheckinDao.countByGoalToday(g.id!);
    if (todayCount > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('今天已经完成打卡了，好好休息吧 🌙')),
        );
      }
      return;
    }
    final record = CheckinRecord(
      goalId: g.id!,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await CheckinDao.insert(record);
    // 更新进度
    final checkins = await CheckinDao.getByGoalId(g.id!);
    // 计算进度：基于已打卡天数 / 预期总天数
    if (g.endDate != null && g.startDate != null) {
      final totalDays = ((g.endDate! - g.startDate!) / 86400000).ceil();
      final expectedCheckins = (totalDays * g.checkinFrequency / 7).ceil();
      g.progress = expectedCheckins > 0
          ? ((checkins.length / expectedCheckins) * 100).round().clamp(0, 100)
          : ((checkins.length / 30) * 100).round().clamp(0, 100);
    } else {
      g.progress = ((checkins.length / 30) * 100).round().clamp(0, 100);
    }
    await GoalDao.updateGoal(g);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('太棒了！已累计完成${checkins.length}次 🎉')),
      );
    }
    await _load();
  }

  // ── 暂停/恢复目标 ──
  Future<void> _togglePause(Goal g) async {
    g.status = g.status == 'paused' ? 'active' : 'paused';
    await GoalDao.updateGoal(g);
    await _load();
  }

  // ── 归档目标 ──
  Future<void> _archiveGoal(Goal g) async {
    g.status = 'archived';
    await GoalDao.updateGoal(g);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目标已归档，随时可以在成就墙中找到它 📦')),
      );
    }
    await _load();
  }

  // ── 完成目标（里程碑庆祝） ──
  Future<void> _completeGoal(Goal g) async {
    g.status = 'completed';
    g.progress = 100;
    await GoalDao.updateGoal(g);
    await _load();
    if (!mounted) return;
    // 里程碑庆祝
    final checkins = await CheckinDao.getByGoalId(g.id!);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('🎉 恭喜完成！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, color: Colors.amber, size: 48),
            const SizedBox(height: 12),
            Text('「${g.title}」完成了！', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('累计打卡：${checkins.length}次'),
            if (g.startDate != null)
              Text('坚持了 ${((DateTime.now().millisecondsSinceEpoch - g.startDate!) / 86400000).ceil()} 天'),
            const SizedBox(height: 12),
            Text('你想给自己一个奖励吗？', style: TextStyle(color: Theme.of(c).hintColor)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('记住这份成就感 ✨'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 温暖头部 ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(_todayMessage,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
        ),
        // ── 操作栏 ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Text('我的目标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementWallPage())),
                icon: const Icon(Icons.emoji_events_outlined, size: 22),
                tooltip: '成就墙',
              ),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusStatsPage())),
                icon: const Icon(Icons.pie_chart_outline, size: 22),
                tooltip: '专注统计',
              ),
              IconButton(
                icon: Icon(_multiSelect ? Icons.close : Icons.checklist, size: 22),
                tooltip: _multiSelect ? '退出多选' : '多选',
                onPressed: () => setState(() {
                  _multiSelect = !_multiSelect; _selectedIds.clear();
                  globalCancelMultiSelect = _multiSelect ? () => setState(() { _multiSelect = false; _selectedIds.clear(); globalCancelMultiSelect = null; }) : null;
                }),
              ),
              IconButton(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add_circle_outline, size: 22),
                tooltip: '新增',
              ),
            ],
          ),
        ),
        // ── 层级Tab ──
        TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: Colors.blue.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: List.generate(5, (i) => Tab(text: _levelLabels[i])),
        ),
        // ── 专注会话横幅 ──
        ListenableBuilder(
          listenable: FocusSessionManager.instance,
          builder: (context, _) {
            final mgr = FocusSessionManager.instance;
            if (!mgr.isActive) return const SizedBox.shrink();
            final h = mgr.elapsed.inHours;
            final m = mgr.elapsed.inMinutes % 60;
            final s = mgr.elapsed.inSeconds % 60;
            final timeStr = h > 0
                ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
                : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
            return InkWell(
              onTap: () async {
                // 找到对应 goal 导航回专注页
                if (mgr.goalId != null) {
                  final goal = await GoalDao.getById(mgr.goalId!);
                  if (goal != null && mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FocusTimerPage(goal: goal),
                      ),
                    );
                  }
                }
              },
              child: Container(
                color: mgr.isPaused ? Colors.orange.shade100 : Colors.amber.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.timer,
                        color: mgr.isPaused ? Colors.orange.shade700 : Colors.amber.shade700,
                        size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '「${mgr.goalTitle}」专注${mgr.isPaused ? '已暂停' : '进行中'}  $timeStr',
                        style: TextStyle(
                          color: mgr.isPaused
                              ? Colors.orange.shade800
                              : Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text('返回专注',
                        style: TextStyle(
                            color: mgr.isPaused
                                ? Colors.orange.shade700
                                : Colors.amber.shade700,
                            fontSize: 12)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        color: mgr.isPaused
                            ? Colors.orange.shade700
                            : Colors.amber.shade700,
                        size: 18),
                  ],
                ),
              ),
            );
          },
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
                    if (_selectedIds.length == _filtered.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(_filtered.where((g) => g.id != null).map((g) => g.id!));
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
        // ── 目标列表 ──
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('还没有${Goal.levelLabels[_viewLevel]}',
                          style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text('点击右上角 + 开始吧',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) {
                    final g = _filtered[i];
                    final isPaused = g.status == 'paused';
                    final isSelected = g.id != null && _selectedIds.contains(g.id);
                    final micros = g.microActions != null
                        ? (jsonDecode(g.microActions!) as List).cast<String>()
                        : <String>[];
                    return Card(
                      color: _multiSelect && isSelected ? Colors.blue.shade50 : (isPaused ? Colors.grey.shade100 : null),
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
                            // ── 标题行 ──
                            Row(children: [
                              if (_multiSelect)
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (v) {
                                    if (g.id == null) return;
                                    setState(() { if (v == true) _selectedIds.add(g.id!); else _selectedIds.remove(g.id); });
                                  },
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              Expanded(
                                child: Text(g.title,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isPaused ? Colors.grey : null)),
                              ),
                              if (isPaused)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('已暂停', style: TextStyle(fontSize: 10, color: Colors.orange)),
                                ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_horiz, size: 18),
                                onSelected: (v) async {
                                  if (v == 'focus') await Navigator.push(context, MaterialPageRoute(builder: (_) => FocusTimerPage(goal: g)));
                                  if (v == 'detail') {
                                    await Navigator.push(context, MaterialPageRoute(builder: (_) => GoalDetailPage(goal: g)));
                                    await _load();
                                  }
                                  if (v == 'pause') _togglePause(g);
                                  if (v == 'archive') _archiveGoal(g);
                                  if (v == 'complete') _completeGoal(g);
                                  if (v == 'delete' && g.id != null) {
                                    await GoalDao.deleteGoal(g.id!);
                                    await _load();
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'focus', child: Row(children: [Icon(Icons.timer_outlined, size: 18, color: Colors.amber), SizedBox(width: 8), Text('专注')])),
                                  const PopupMenuItem(value: 'detail', child: Row(children: [Icon(Icons.list_alt, size: 18), SizedBox(width: 8), Text('子任务')])),
                                  PopupMenuItem(value: 'pause', child: Row(children: [Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 18), const SizedBox(width: 8), Text(isPaused ? '继续' : '暂停')])),
                                  const PopupMenuItem(value: 'complete', child: Row(children: [Icon(Icons.check_circle, size: 18, color: Colors.green), SizedBox(width: 8), Text('标记完成')])),
                                  const PopupMenuItem(value: 'archive', child: Row(children: [Icon(Icons.archive_outlined, size: 18), SizedBox(width: 8), Text('归档')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('删除')])),
                                ],
                              ),
                            ]),
                            if (g.description != null && g.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(g.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ),
                            // ── 进度条（只显示已完成部分，温暖色） ──
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: g.progress / 100.0,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                      g.progress >= 80 ? Colors.green : Colors.blue.shade300,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${g.progress}%',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                      color: g.progress >= 80 ? Colors.green : Colors.blue.shade400)),
                            ]),
                            // ── 微行动快速完成 ──
                            if (micros.isNotEmpty && !isPaused) ...[
                              const SizedBox(height: 8),
                              ...micros.map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(children: [
                                  const Icon(Icons.radio_button_unchecked, size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(m, style: const TextStyle(fontSize: 12))),
                                ]),
                              )),
                            ],
                            // ── 打卡按钮 ──
                            if (!isPaused)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _checkin(g),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('今天完成了一点 ✨', style: TextStyle(fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green.shade600,
                                      side: BorderSide(color: Colors.green.shade200),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ));
                  },
                ),
        ),
      ],
    );
  }
}

class _QuickTimeChip extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final TimeOfDay? selected;
  final ValueChanged<TimeOfDay> onTap;
  const _QuickTimeChip({required this.label, required this.time, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = selected != null && selected!.hour == time.hour && selected!.minute == time.minute;
    return GestureDetector(
      onTap: () => onTap(time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? Colors.blue.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? Colors.blue : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
