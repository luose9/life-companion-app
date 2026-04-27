import 'package:flutter/material.dart';
import 'package:life_companion_app/data/schedule_dao.dart';
import 'package:life_companion_app/models/schedule.dart';
import 'package:life_companion_app/services/notification_service.dart';
import 'package:life_companion_app/main.dart';

const int _kScheduleNotifyOffset = 10000;

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Schedule> _today = [];
  List<Schedule> _all = [];
  DateTime _viewDate = DateTime.now();
  bool _showAll = false;
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = await ScheduleDao.getByDate(_viewDate);
    today.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
    List<Schedule> all = _all;
    if (_showAll) {
      all = await ScheduleDao.getAllSchedules();
      all.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
    }
    if (mounted) setState(() { _today = today; _all = all; });
  }

  // ── 任务数量检查 ──
  int get _todayImportantCount => _today.where((s) => s.priority == 'important' && s.status != 'done').length;
  int get _todayNormalCount => _today.where((s) => s.priority == 'normal' && s.status != 'done').length;

  // ── 调度通知 ──
  Future<void> _scheduleNotify(Schedule s) async {
    if (s.id == null || s.startTime == null) return;
    try {
      final nId = _kScheduleNotifyOffset + s.id!;
      final nIdEarly = _kScheduleNotifyOffset + 50000 + s.id!;
      await NotificationService.instance.cancel(nId);
      await NotificationService.instance.cancel(nIdEarly);
      final startAt = DateTime.fromMillisecondsSinceEpoch(s.startTime!);
      final vibOn = s.vibrate != 2;
      final rule = s.repeatRule;
      // 始终在开始时间发送通知
      if (rule == null || rule == 'none') {
        await NotificationService.instance.scheduleNotification(nId, '📋 ${s.title}', '这个任务该开始了，慢慢来 ☀️', startAt, soundPath: s.soundPath, enableVibration: vibOn);
      } else {
        await NotificationService.instance.scheduleRecurring(nId, '📋 ${s.title}', '这个任务该开始了，慢慢来 ☀️', startAt, rule, soundPath: s.soundPath, enableVibration: vibOn);
      }
      // 提前提醒
      final remind = s.remindMinutes ?? 0;
      if (remind > 0) {
        final earlyAt = startAt.subtract(Duration(minutes: remind));
        if (rule == null || rule == 'none') {
          await NotificationService.instance.scheduleNotification(nIdEarly, '⏰ 还有${remind}分钟', s.title, earlyAt, soundPath: s.soundPath, enableVibration: vibOn);
        } else {
          await NotificationService.instance.scheduleRecurring(nIdEarly, '⏰ 还有${remind}分钟', s.title, earlyAt, rule, soundPath: s.soundPath, enableVibration: vibOn);
        }
      }
    } catch (e) {
      debugPrint('_scheduleNotify error: $e');
    }
  }

  Future<void> _cancelNotify(Schedule s) async {
    if (s.id == null) return;
    await NotificationService.instance.cancel(_kScheduleNotifyOffset + s.id!);
    await NotificationService.instance.cancel(_kScheduleNotifyOffset + 50000 + s.id!);
  }

  // ── 新增/编辑 ──
  Future<void> _showDialog({Schedule? existing}) async {
    // 任务限制检查
    if (existing == null) {
      final importantCount = _todayImportantCount;
      final normalCount = _todayNormalCount;
      if (importantCount >= 3 && normalCount >= 5) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('温馨提示'),
              content: const Text('一天只有24小时 ☀️\n'
                  '重要任务已有3个，普通任务已有5个\n'
                  '先做最重要的事吧，其他的可以明天再说'),
              actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('我明白了'))],
            ),
          );
        }
        return;
      }
    }

    final titleCtl = TextEditingController(text: existing?.title ?? '');
    final descCtl = TextEditingController(text: existing?.description ?? '');
    final remindCtl = TextEditingController(
        text: (existing?.remindMinutes ?? 0) > 0 ? '${existing!.remindMinutes}' : '');
    String repeatRule = existing?.repeatRule ?? 'none';
    String energy = existing?.energy ?? 'medium';
    String priority = existing?.priority ?? 'normal';
    String? soundPath = existing?.soundPath;
    int vibrate = existing?.vibrate ?? 1;
    DateTime? startDt = existing?.startTime != null
        ? DateTime.fromMillisecondsSinceEpoch(existing!.startTime!) : null;
    TimeOfDay? startTime = startDt != null
        ? TimeOfDay(hour: startDt.hour, minute: startDt.minute) : null;
    DateTime? endDt = existing?.endTime != null
        ? DateTime.fromMillisecondsSinceEpoch(existing!.endTime!) : null;
    TimeOfDay? endTime = endDt != null
        ? TimeOfDay(hour: endDt.hour, minute: endDt.minute) : null;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // 任务限制提示
          String? limitWarning;
          if (existing == null) {
            if (priority == 'important' && _todayImportantCount >= 3) {
              limitWarning = '今天的重要任务已经有3个了，建议安排到明天 🌿';
            } else if (priority == 'normal' && _todayNormalCount >= 5) {
              limitWarning = '今天的普通任务已经有5个了，不着急 ☀️';
            }
          }
          return AlertDialog(
            title: Text(existing == null ? '新增任务' : '编辑任务'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 限制提示
                    if (limitWarning != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(limitWarning, style: TextStyle(fontSize: 12, color: Colors.amber.shade800)),
                      ),

                    // 标题
                    TextField(controller: titleCtl,
                        decoration: const InputDecoration(labelText: '任务内容', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),

                    // 描述
                    TextField(controller: descCtl, maxLines: 2,
                        decoration: const InputDecoration(labelText: '备注（可选）', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),

                    // ── 优先级 ──
                    const Text('优先级', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(child: ChoiceChip(
                        label: const Text('⭐ 重要（≤3个/天）', style: TextStyle(fontSize: 12)),
                        selected: priority == 'important',
                        onSelected: (_) => setS(() => priority = 'important'),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: ChoiceChip(
                        label: const Text('📋 普通（≤5个/天）', style: TextStyle(fontSize: 12)),
                        selected: priority == 'normal',
                        onSelected: (_) => setS(() => priority = 'normal'),
                      )),
                    ]),
                    const SizedBox(height: 10),

                    // ── 精力标签 ──
                    const Text('精力消耗', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text('高精力任务适合安排在上午', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _EnergyChip(label: '🔥 高', value: 'high', selected: energy, onTap: () => setS(() => energy = 'high')),
                      const SizedBox(width: 6),
                      _EnergyChip(label: '⚡ 中', value: 'medium', selected: energy, onTap: () => setS(() => energy = 'medium')),
                      const SizedBox(width: 6),
                      _EnergyChip(label: '🌿 低', value: 'low', selected: energy, onTap: () => setS(() => energy = 'low')),
                    ]),
                    const SizedBox(height: 10),

                    // ── 日期时间 ──
                    Row(children: [
                      Expanded(child: Text(startDt == null ? '日期：今天' :
                          '${startDt!.month}/${startDt!.day}')),
                      TextButton(onPressed: () async {
                        final d = await showDatePicker(context: ctx,
                            initialDate: startDt ?? DateTime.now(),
                            firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (d != null) setS(() {
                          startDt = DateTime(d.year, d.month, d.day,
                              startTime?.hour ?? 9, startTime?.minute ?? 0);
                        });
                      }, child: const Text('选择日期')),
                    ]),
                    Row(children: [
                      Expanded(child: Text(startTime == null ? '开始：未设置' :
                          '开始：${startTime!.format(ctx)}')),
                      TextButton(onPressed: () async {
                        final t = await showTimePicker(context: ctx, initialTime: startTime ?? TimeOfDay.now(), initialEntryMode: TimePickerEntryMode.input);
                        if (t != null) setS(() {
                          startTime = t;
                          final base = startDt ?? DateTime.now();
                          startDt = DateTime(base.year, base.month, base.day, t.hour, t.minute);
                          // 如果结束时间早于开始时间，清除结束时间
                          if (endTime != null && (endTime!.hour < t.hour || (endTime!.hour == t.hour && endTime!.minute <= t.minute))) {
                            endTime = null;
                            endDt = null;
                          }
                        });
                      }, child: const Text('选择')),
                    ]),
                    // ── 快捷开始时间 ──
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      for (final qt in const [TimeOfDay(hour: 7, minute: 0), TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 13, minute: 0), TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 18, minute: 0), TimeOfDay(hour: 20, minute: 0)])
                        _ScheduleQuickTime(
                          time: qt,
                          selected: startTime != null && startTime!.hour == qt.hour && startTime!.minute == qt.minute,
                          onTap: () => setS(() {
                            startTime = qt;
                            final base = startDt ?? DateTime.now();
                            startDt = DateTime(base.year, base.month, base.day, qt.hour, qt.minute);
                          }),
                        ),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: Text(endTime == null ? '结束：未设置' :
                          '结束：${endTime!.format(ctx)}')),
                      TextButton(onPressed: () async {
                        final t = await showTimePicker(context: ctx, initialTime: endTime ?? TimeOfDay.now(), initialEntryMode: TimePickerEntryMode.input);
                        if (t != null) {
                          // 结束时间必须在开始时间之后
                          if (startTime != null && (t.hour < startTime!.hour || (t.hour == startTime!.hour && t.minute <= startTime!.minute))) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('结束时间必须晚于开始时间 ☔')));
                            return;
                          }
                          setS(() {
                            endTime = t;
                            final base = startDt ?? DateTime.now();
                            endDt = DateTime(base.year, base.month, base.day, t.hour, t.minute);
                          });
                        }
                      }, child: const Text('选择')),
                    ]),
                    // ── 快捷结束时间 ──
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      for (final qt in const [TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 11, minute: 30), TimeOfDay(hour: 12, minute: 0), TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 17, minute: 0), TimeOfDay(hour: 18, minute: 0), TimeOfDay(hour: 21, minute: 0), TimeOfDay(hour: 22, minute: 0)])
                        _ScheduleQuickTime(
                          time: qt,
                          selected: endTime != null && endTime!.hour == qt.hour && endTime!.minute == qt.minute,
                          onTap: () {
                            if (startTime != null && (qt.hour < startTime!.hour || (qt.hour == startTime!.hour && qt.minute <= startTime!.minute))) return;
                            setS(() {
                              endTime = qt;
                              final base = startDt ?? DateTime.now();
                              endDt = DateTime(base.year, base.month, base.day, qt.hour, qt.minute);
                            });
                          },
                        ),
                    ]),
                    const SizedBox(height: 8),

                    // ── 提醒 ──
                    TextField(controller: remindCtl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '提前提醒（分钟）', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),

                    // ── 重复 ──
                    DropdownButtonFormField<String>(
                      value: repeatRule,
                      decoration: const InputDecoration(labelText: '重复', border: OutlineInputBorder(), isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('不重复')),
                        DropdownMenuItem(value: 'daily', child: Text('每天')),
                        DropdownMenuItem(value: 'weekly', child: Text('每周')),
                      ],
                      onChanged: (v) { if (v != null) setS(() => repeatRule = v); },
                    ),
                    const SizedBox(height: 10),

                    // ── 提示音 ──
                    const Text('提示音', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      ChoiceChip(label: const Text('🔔 默认通知音', style: TextStyle(fontSize: 12)),
                          selected: soundPath == null,
                          onSelected: (_) => setS(() => soundPath = null)),
                      ChoiceChip(label: const Text('🎵 系统铃声', style: TextStyle(fontSize: 12)),
                          selected: soundPath == 'ringtone',
                          onSelected: (_) => setS(() => soundPath = 'ringtone')),
                      ChoiceChip(label: const Text('⏰ 闹钟铃声', style: TextStyle(fontSize: 12)),
                          selected: soundPath == 'alarm',
                          onSelected: (_) => setS(() => soundPath = 'alarm')),
                      ChoiceChip(label: const Text('🔇 静音', style: TextStyle(fontSize: 12)),
                          selected: soundPath == 'silent',
                          onSelected: (_) => setS(() => soundPath = 'silent')),
                    ]),
                    const SizedBox(height: 10),

                    // ── 振动模式 ──
                    const Text('振动模式', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      ChoiceChip(label: const Text('📳 振动', style: TextStyle(fontSize: 12)),
                          selected: vibrate == 1,
                          onSelected: (_) => setS(() => vibrate = 1)),
                      ChoiceChip(label: const Text('📴 无振动', style: TextStyle(fontSize: 12)),
                          selected: vibrate == 2,
                          onSelected: (_) => setS(() => vibrate = 2)),
                      ChoiceChip(label: const Text('📱 跟随系统', style: TextStyle(fontSize: 12)),
                          selected: vibrate == 0,
                          onSelected: (_) => setS(() => vibrate = 0)),
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
                  final remind = int.tryParse(remindCtl.text.trim()) ?? 0;
                  // 如果没选日期，默认用今天 + 开始时间
                  if (startDt == null) {
                    final now = DateTime.now();
                    startDt = DateTime(now.year, now.month, now.day,
                        startTime?.hour ?? now.hour, startTime?.minute ?? now.minute);
                  }
                  final s = Schedule(
                    id: existing?.id,
                    title: title,
                    description: descCtl.text.trim().isEmpty ? null : descCtl.text.trim(),
                    startTime: startDt?.millisecondsSinceEpoch,
                    endTime: endDt?.millisecondsSinceEpoch,
                    repeatRule: repeatRule == 'none' ? null : repeatRule,
                    remindMinutes: remind,
                    energy: energy,
                    priority: priority,
                    status: existing?.status ?? 'pending',
                    soundPath: soundPath,
                    vibrate: vibrate,
                  );
                  if (existing == null) {
                    final newId = await ScheduleDao.insertSchedule(s);
                    s.id = newId;
                  } else {
                    await ScheduleDao.updateSchedule(s);
                  }
                  // 先关闭弹窗 + 刷新列表，再后台处理通知
                  Navigator.pop(ctx);
                  await _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(existing == null ? '已添加「$title」 ✅' : '已更新「$title」 ✅'), duration: const Duration(seconds: 2)),
                    );
                  }
                  // 通知调度放在最后，不阻塞UI
                  try {
                    await _scheduleNotify(s);
                  } catch (e) {
                    debugPrint('通知调度失败: $e');
                  }
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── 标记完成 ──
  Future<void> _markDone(Schedule s) async {
    s.status = 'done';
    await ScheduleDao.updateSchedule(s);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('完成了一件事，做得很好 ✨'), duration: Duration(seconds: 2)),
      );
    }
    await _load();
  }

  // ── 推迟到明天 ──
  Future<void> _postpone(Schedule s) async {
    await ScheduleDao.postponeToTomorrow(s);
    await _cancelNotify(s);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已移到明天，不着急 🌿'), duration: Duration(seconds: 2)),
      );
    }
    await _load();
  }

  // ── 删除 ──
  Future<void> _deleteSchedule(Schedule s) async {
    await _cancelNotify(s);
    if (s.id != null) await ScheduleDao.deleteSchedule(s.id!);
    // 同步删除内存列表，避免 Dismissible 后 rebuild 找不到
    if (s.id != null) {
      _today.removeWhere((e) => e.id == s.id);
      _all.removeWhere((e) => e.id == s.id);
    }
    await _load();
  }

  // ── 批量删除 ──
  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定删除选中的 $count 个日程吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    for (final id in _selectedIds.toList()) {
      await NotificationService.instance.cancel(_kScheduleNotifyOffset + id);
      await NotificationService.instance.cancel(_kScheduleNotifyOffset + 50000 + id);
      await ScheduleDao.deleteSchedule(id);
    }
    _selectedIds.clear();
    // 强制刷新全部列表
    final wasShowAll = _showAll;
    _showAll = true; // 确保 _load 同时刷新 _all
    await _load();
    if (mounted) {
      setState(() { _multiSelect = false; _showAll = wasShowAll; });
      globalCancelMultiSelect = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 个日程'), duration: const Duration(seconds: 2)),
      );
    }
  }

  // ── 切换日期 ──
  void _prevDay() { setState(() => _viewDate = _viewDate.subtract(const Duration(days: 1))); _load(); }
  void _nextDay() { setState(() => _viewDate = _viewDate.add(const Duration(days: 1))); _load(); }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _fmtTime(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String get _weekday {
    final wk = ['一', '二', '三', '四', '五', '六', '日'][_viewDate.weekday - 1];
    return '周$wk';
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _showAll ? _all : _today;
    final pending = _today.where((s) => s.status != 'done').length;

    return Scaffold(
      body: Column(
        children: [
          // ── 日期导航栏 ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevDay),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                          context: context, initialDate: _viewDate,
                          firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) { setState(() => _viewDate = d); _load(); }
                    },
                    child: Column(
                      children: [
                        Text(
                          _isToday(_viewDate) ? '今天' : _fmtDate(_viewDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(_weekday, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextDay),
                TextButton(
                  onPressed: () { setState(() => _showAll = !_showAll); _load(); },
                  child: Text(_showAll ? '今日' : '全部', style: const TextStyle(fontSize: 12)),
                ),
                IconButton(
                  icon: Icon(_multiSelect ? Icons.close : Icons.checklist, size: 20),
                  tooltip: _multiSelect ? '退出多选' : '多选',
                  onPressed: () => setState(() {
                    _multiSelect = !_multiSelect; _selectedIds.clear();
                    globalCancelMultiSelect = _multiSelect ? () => setState(() { _multiSelect = false; _selectedIds.clear(); globalCancelMultiSelect = null; }) : null;
                  }),
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
                    final displayList = _showAll ? _all : _today;
                    setState(() {
                      if (_selectedIds.length == displayList.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(displayList.where((s) => s.id != null).map((s) => s.id!));
                      }
                    });
                  },
                  child: Text(_selectedIds.length == (_showAll ? _all : _today).length ? '取消全选' : '全选',
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

          // ── 精力提示 ──
          if (_isToday(_viewDate) && pending > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getEnergyTip(),
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ),
            ),

          // ── 任务列表 ──
          Expanded(
            child: displayList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(_isToday(_viewDate) ? '今天还没有安排' : '这天没有任务',
                            style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text('点击右下角 + 添加', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: displayList.length,
                    itemBuilder: (ctx, i) => _buildScheduleCard(displayList[i]),
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getEnergyTip() {
    final hour = DateTime.now().hour;
    final highTasks = _today.where((s) => s.energy == 'high' && s.status != 'done').length;
    if (hour < 12 && highTasks > 0) {
      return '上午精力最好，适合先做 $highTasks 个高精力任务 💪';
    }
    if (hour >= 12 && hour < 17) {
      return '下午适合处理常规任务，别忘了休息一下 ☕';
    }
    return '晚上适合做些轻松的事，别给自己太大压力 🌙';
  }

  Widget _buildScheduleCard(Schedule s) {
    final isDone = s.status == 'done';
    final isPostponed = s.status == 'postponed';
    final isSelected = s.id != null && _selectedIds.contains(s.id);

    Widget card = Card(
        color: _multiSelect && isSelected ? Colors.blue.shade50 : (isDone ? Colors.grey.shade50 : null),
        child: InkWell(
          onLongPress: () {
            if (!_multiSelect && s.id != null) {
              setState(() { _multiSelect = true; _selectedIds.add(s.id!); });
              globalCancelMultiSelect = () => setState(() { _multiSelect = false; _selectedIds.clear(); globalCancelMultiSelect = null; });
            }
          },
          onTap: _multiSelect ? () {
            if (s.id == null) return;
            setState(() {
              if (_selectedIds.contains(s.id)) { _selectedIds.remove(s.id); }
              else { _selectedIds.add(s.id!); }
            });
          } : null,
          child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (_multiSelect)
                  Checkbox(
                    value: isSelected,
                    onChanged: (v) {
                      if (s.id == null) return;
                      setState(() { if (v == true) _selectedIds.add(s.id!); else _selectedIds.remove(s.id); });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                // 精力指示
                Container(
                  width: 4, height: 28,
                  decoration: BoxDecoration(
                    color: _energyColor(s.energy),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey : null,
                        ),
                      ),
                      Row(children: [
                        if (s.startTime != null)
                          Text(_fmtTime(s.startTime), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        if (s.endTime != null)
                          Text(' - ${_fmtTime(s.endTime)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(width: 6),
                        Text(Schedule.energyLabels[s.energy] ?? '', style: TextStyle(fontSize: 10, color: _energyColor(s.energy))),
                        if (s.priority == 'important')
                          const Padding(padding: EdgeInsets.only(left: 4), child: Text('⭐', style: TextStyle(fontSize: 10))),
                        if (isPostponed)
                          Padding(padding: const EdgeInsets.only(left: 4),
                            child: Text('已推迟', style: TextStyle(fontSize: 10, color: Colors.orange.shade300))),
                      ]),
                    ],
                  ),
                ),
                if (!isDone) ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 22, color: Colors.green),
                    onPressed: () => _markDone(s),
                    tooltip: '完成',
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, size: 18),
                    onSelected: (v) async {
                      if (v == 'edit') _showDialog(existing: s);
                      if (v == 'postpone') _postpone(s);
                      if (v == 'delete') _deleteSchedule(s);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('编辑')])),
                      const PopupMenuItem(value: 'postpone', child: Row(children: [Icon(Icons.arrow_forward, size: 16), SizedBox(width: 8), Text('推迟到明天')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.close, size: 16, color: Colors.grey), SizedBox(width: 8), Text('删除')])),
                    ],
                  ),
                ],
                if (isDone) ...[
                  Icon(Icons.check_circle, size: 20, color: Colors.green.shade300),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade400),
                    onPressed: () => _deleteSchedule(s),
                    tooltip: '删除',
                  ),
                ],
              ]),
              if (s.description != null && s.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(s.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ),
            ],
          ),
        ),
      ),
    );

    if (_multiSelect) return KeyedSubtree(key: ValueKey(s.id), child: card);

    return Dismissible(
      key: ValueKey(s.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.grey.shade300,
        child: const Icon(Icons.close, color: Colors.white),
      ),
      onDismissed: (_) => _deleteSchedule(s),
      child: card,
    );
  }

  Color _energyColor(String energy) {
    switch (energy) {
      case 'high': return Colors.red.shade400;
      case 'medium': return Colors.orange.shade400;
      case 'low': return Colors.green.shade400;
      default: return Colors.grey;
    }
  }
}

class _EnergyChip extends StatelessWidget {
  final String label, value, selected;
  final VoidCallback onTap;
  const _EnergyChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? Colors.blue : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

class _ScheduleQuickTime extends StatelessWidget {
  final TimeOfDay time;
  final bool selected;
  final VoidCallback onTap;
  const _ScheduleQuickTime({required this.time, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.blue : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
