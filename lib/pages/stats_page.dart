import 'package:flutter/material.dart';
import 'package:life_companion_app/data/goal_dao.dart';
import 'package:life_companion_app/data/mood_dao.dart';
import 'package:life_companion_app/data/workout_dao.dart';
import 'package:life_companion_app/data/transaction_dao.dart';
import 'package:life_companion_app/data/entertainment_dao.dart';
import 'package:life_companion_app/models/goal.dart';
import 'package:life_companion_app/models/mood.dart';
import 'package:life_companion_app/models/workout.dart';
import 'package:life_companion_app/models/transaction.dart';
import 'package:life_companion_app/models/entertainment.dart';
import 'package:life_companion_app/widgets/charts.dart';

// ── 心情标签排序（越靠前越"正面"，用于热图索引）──────────────
const List<String> _kMoodTags = [
  '开心', '非常高兴', '平静', '难过', '愤怒', '焦虑', '疲惫', '兴奋', '失落', '感动',
];

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _loading = true;

  // ── raw data ──────────────────────────────────────────────
  List<Goal> _goals = [];
  List<Mood> _moods = [];
  List<Workout> _workouts = [];
  List<TransactionEntry> _txAll = [];
  List<TransactionEntry> _txMonth = [];
  List<Entertainment> _ents = [];

  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      GoalDao.getAllGoals(),
      MoodDao.getAllMoods(),
      WorkoutDao.getAll(),
      TransactionDao.getAll(),
      TransactionDao.getByMonth(_viewMonth.year, _viewMonth.month),
      EntertainmentDao.getAll(),
    ]);
    setState(() {
      _goals = results[0] as List<Goal>;
      _moods = results[1] as List<Mood>;
      _workouts = results[2] as List<Workout>;
      _txAll = results[3] as List<TransactionEntry>;
      _txMonth = results[4] as List<TransactionEntry>;
      _ents = results[5] as List<Entertainment>;
      _loading = false;
    });
  }

  // ════════════════ GOALS ════════════════

  /// 进度分布：0-25 / 26-50 / 51-75 / 76-100
  Map<String, double> get _goalProgressDist {
    final m = {'0-25': 0.0, '26-50': 0.0, '51-75': 0.0, '76-100': 0.0};
    for (final g in _goals) {
      if (g.progress <= 25) m['0-25'] = (m['0-25'] ?? 0) + 1;
      else if (g.progress <= 50) m['26-50'] = (m['26-50'] ?? 0) + 1;
      else if (g.progress <= 75) m['51-75'] = (m['51-75'] ?? 0) + 1;
      else m['76-100'] = (m['76-100'] ?? 0) + 1;
    }
    return Map.fromEntries(m.entries.where((e) => e.value > 0));
  }

  // ════════════════ MOOD ════════════════

  /// 本月心情热图: day-key → moodTag index
  Map<String, int> get _moodHeatmap {
    final m = <String, int>{};
    for (final mood in _moods) {
      if (mood.timestamp == null) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(mood.timestamp!);
      if (dt.year != _viewMonth.year || dt.month != _viewMonth.month) continue;
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final idx = _kMoodTags.indexOf(mood.moodTag ?? '');
      m[key] = idx >= 0 ? idx : 0;
    }
    return m;
  }

  /// 心情频次统计（本月）
  Map<String, double> get _moodFreq {
    final m = <String, double>{};
    for (final mood in _moods) {
      if (mood.timestamp == null) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(mood.timestamp!);
      if (dt.year != _viewMonth.year || dt.month != _viewMonth.month) continue;
      final tag = mood.moodTag ?? '未知';
      m[tag] = (m[tag] ?? 0) + 1;
    }
    // top 6
    final sorted = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(6));
  }

  // ════════════════ WORKOUT ════════════════

  /// 近 7 天每天运动时长 (min)
  List<double> get _workoutLast7Days {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return _workouts
          .where((w) {
            if (w.startTime == null) return false;
            final d = DateTime.fromMillisecondsSinceEpoch(w.startTime!);
            return d.year == day.year &&
                d.month == day.month &&
                d.day == day.day;
          })
          .fold(0.0, (s, w) => s + w.durationMinutes);
    });
  }

  List<String> get _last7DayLabels {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return '${day.month}/${day.day}';
    });
  }

  /// 运动类型分布
  Map<String, double> get _workoutTypeDist {
    final m = <String, double>{};
    for (final w in _workouts) {
      m[w.type] = (m[w.type] ?? 0) + 1;
    }
    return m;
  }

  // ════════════════ FINANCE ════════════════

  /// 近 6 个月收入/支出
  List<double> get _monthlyIncome {
    return _buildMonthly('income');
  }

  List<double> get _monthlyExpense {
    return _buildMonthly('expense');
  }

  List<String> get _monthLabels {
    return List.generate(6, (i) {
      final m = DateTime(DateTime.now().year, DateTime.now().month - 5 + i);
      return '${m.month}月';
    });
  }

  List<double> _buildMonthly(String type) {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final y = DateTime(now.year, now.month - 5 + i).year;
      final mo = DateTime(now.year, now.month - 5 + i).month;
      return _txAll
          .where((t) {
            if (t.type != type || t.timestamp == null) return false;
            final d = DateTime.fromMillisecondsSinceEpoch(t.timestamp!);
            return d.year == y && d.month == mo;
          })
          .fold(0.0, (s, t) => s + t.amount);
    });
  }

  /// 本月支出分类
  Map<String, double> get _monthExpenseCat {
    final m = <String, double>{};
    for (final t in _txMonth.where((t) => t.type == 'expense')) {
      final cat = t.category ?? '其他';
      m[cat] = (m[cat] ?? 0) + t.amount;
    }
    final sorted = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(6));
  }

  double get _monthIncome =>
      _txMonth.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
  double get _monthExpense =>
      _txMonth.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);

  // ════════════════ ENTERTAINMENT ════════════════

  /// 媒体类型分布
  Map<String, double> get _entTypeDist {
    const labels = {
      'movie': '电影', 'tv': '电视剧', 'music': '音乐',
      'book': '书籍', 'game': '游戏', 'other': '其他',
    };
    final m = <String, double>{};
    for (final e in _ents) {
      final l = labels[e.mediaType] ?? e.mediaType;
      m[l] = (m[l] ?? 0) + 1;
    }
    return m;
  }

  /// 平均评分（按类型）
  Map<String, double> get _avgRatingByType {
    const labels = {
      'movie': '电影', 'tv': '电视剧', 'music': '音乐',
      'book': '书籍', 'game': '游戏', 'other': '其他',
    };
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final e in _ents.where((e) => e.rating != null)) {
      final l = labels[e.mediaType] ?? e.mediaType;
      sums[l] = (sums[l] ?? 0) + e.rating!;
      counts[l] = (counts[l] ?? 0) + 1;
    }
    return Map.fromEntries(
        counts.entries.map((e) => MapEntry(e.key, sums[e.key]! / e.value)));
  }

  // ════════════════ COLORS ════════════════
  static const List<Color> _kColors = [
    Color(0xFF4E79A7), Color(0xFFF28E2B), Color(0xFFE15759),
    Color(0xFF76B7B2), Color(0xFF59A14F), Color(0xFFEDC948),
    Color(0xFFB07AA1), Color(0xFFFF9DA7),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          // ── 月份切换 ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
                  });
                  _load();
                },
              ),
              Text(
                '${_viewMonth.year} 年 ${_viewMonth.month} 月',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final next =
                      DateTime(_viewMonth.year, _viewMonth.month + 1);
                  if (next.isAfter(DateTime.now())) return;
                  setState(() => _viewMonth = next);
                  _load();
                },
              ),
            ],
          ),

          // ══ 总览卡片 ══════════════════════════════════════
          _OverviewRow(
            items: [
              _OvItem('目标', '${_goals.length}', Icons.flag, Colors.indigo),
              _OvItem('运动次数', '${_workouts.length}', Icons.directions_run, Colors.green),
              _OvItem('心情记录', '${_moods.length}', Icons.mood, Colors.orange),
              _OvItem('娱乐记录', '${_ents.length}', Icons.movie, Colors.pink),
            ],
          ),

          // ══ 目标进度 ═════════════════════════════════════
          if (_goals.isNotEmpty) ...[
            _sectionTitle('🎯 目标进度分布'),
            ChartCard(
              title: '进度区间（共 ${_goals.length} 个目标）',
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: DonutChart(
                          data: _goalProgressDist,
                          colors: _kColors,
                          size: 130,
                          centerLabel: '目标',
                          centerValue: '${_goals.length}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // avg progress
                            Text(
                              '平均进度',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              '${(_goals.fold(0, (s, g) => s + g.progress) / _goals.length).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4E79A7)),
                            ),
                            const SizedBox(height: 8),
                            LegendRow(
                              labels: _goalProgressDist.keys.toList(),
                              colors: _kColors,
                            ),
                            const SizedBox(height: 8),
                            // completed
                            _MiniStat(
                                label: '已完成',
                                value: '${_goals.where((g) => g.progress >= 100).length}'),
                            _MiniStat(
                                label: '进行中',
                                value:
                                    '${_goals.where((g) => g.progress > 0 && g.progress < 100).length}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ══ 心情热图 ══════════════════════════════════════
          _sectionTitle('😊 心情日历'),
          ChartCard(
            title: '${_viewMonth.month} 月心情分布',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoodHeatmap(
                  dayMoodIndex: _moodHeatmap,
                  year: _viewMonth.year,
                  month: _viewMonth.month,
                ),
                if (_moodFreq.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('本月心情频次',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 6),
                  BarChart(
                    values: _moodFreq.values.toList(),
                    labels: _moodFreq.keys.toList(),
                    colors: _kColors,
                    height: 120,
                  ),
                ],
              ],
            ),
          ),

          // ══ 运动 ══════════════════════════════════════════
          if (_workouts.isNotEmpty) ...[
            _sectionTitle('🏃 运动统计'),
            ChartCard(
              title: '近 7 天运动时长（分钟）',
              child: LineChart(
                values: _workoutLast7Days,
                labels: _last7DayLabels,
                color: Colors.green.shade600,
                height: 150,
              ),
            ),
            ChartCard(
              title: '运动类型分布',
              child: Row(
                children: [
                  DonutChart(
                    data: _workoutTypeDist,
                    colors: _kColors,
                    size: 130,
                    centerLabel: '次',
                    centerValue: '${_workouts.length}',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LegendRow(
                      labels: _workoutTypeDist.keys.toList(),
                      colors: _kColors,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ══ 记账 ══════════════════════════════════════════
          _sectionTitle('💰 收支统计'),
          ChartCard(
            title: '近 6 个月收入 vs 支出',
            child: Column(
              children: [
                SizedBox(
                  height: 160,
                  child: _IncomeExpenseGroupBar(
                    income: _monthlyIncome,
                    expense: _monthlyExpense,
                    labels: _monthLabels,
                  ),
                ),
                const SizedBox(height: 6),
                LegendRow(
                  labels: const ['收入', '支出'],
                  colors: [Colors.green.shade400, Colors.red.shade400],
                ),
              ],
            ),
          ),
          if (_monthExpenseCat.isNotEmpty)
            ChartCard(
              title: '本月支出分类（¥${_monthExpense.toStringAsFixed(0)}）',
              child: Column(
                children: [
                  Row(
                    children: [
                      DonutChart(
                        data: _monthExpenseCat,
                        colors: _kColors,
                        size: 130,
                        centerLabel: '支出',
                        centerValue: '¥${_monthExpense >= 1000 ? '${(_monthExpense / 1000).toStringAsFixed(1)}k' : _monthExpense.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LegendRow(
                              labels: _monthExpenseCat.keys.toList(),
                              colors: _kColors,
                            ),
                            const SizedBox(height: 8),
                            _MiniStat(
                                label: '收入',
                                value: '¥${_monthIncome.toStringAsFixed(0)}'),
                            _MiniStat(
                                label: '结余',
                                value:
                                    '¥${(_monthIncome - _monthExpense).toStringAsFixed(0)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ══ 娱乐 ══════════════════════════════════════════
          if (_ents.isNotEmpty) ...[
            _sectionTitle('🎬 娱乐统计'),
            ChartCard(
              title: '媒体类型分布',
              child: Row(
                children: [
                  DonutChart(
                    data: _entTypeDist,
                    colors: _kColors,
                    size: 130,
                    centerLabel: '记录',
                    centerValue: '${_ents.length}',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LegendRow(
                      labels: _entTypeDist.keys.toList(),
                      colors: _kColors,
                    ),
                  ),
                ],
              ),
            ),
            if (_avgRatingByType.isNotEmpty)
              ChartCard(
                title: '各类型平均评分',
                child: BarChart(
                  values: _avgRatingByType.values.toList(),
                  labels: _avgRatingByType.keys.toList(),
                  colors: _kColors,
                  height: 140,
                  maxValue: 5,
                ),
              ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      );
}

// ── 收支双色柱状图 ─────────────────────────────────────────
class _IncomeExpenseGroupBar extends StatelessWidget {
  final List<double> income;
  final List<double> expense;
  final List<String> labels;

  const _IncomeExpenseGroupBar({
    required this.income,
    required this.expense,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    // merge for a single BarChart-like display using interleaved bars
    final zipped = <double>[];
    final zLabels = <String>[];
    final colors = <Color>[];
    for (int i = 0; i < labels.length; i++) {
      zipped.add(income[i]);
      zipped.add(expense[i]);
      zLabels.add(labels[i]);
      zLabels.add('');
      colors.add(Colors.green.shade400);
      colors.add(Colors.red.shade400);
    }
    return BarChart(
      values: zipped,
      labels: zLabels,
      colors: colors,
      height: 160,
    );
  }
}

// ── 总览行 ────────────────────────────────────────────────
class _OvItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _OvItem(this.label, this.value, this.icon, this.color);
}

class _OverviewRow extends StatelessWidget {
  final List<_OvItem> items;
  const _OverviewRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: items
            .map((it) => Expanded(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(it.icon, color: it.color, size: 22),
                          const SizedBox(height: 4),
                          Text(it.value,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: it.color)),
                          Text(it.label,
                              style: TextStyle(
                                  fontSize: 9, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text('$label：',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
