import 'package:flutter/material.dart';
import 'package:life_companion_app/data/focus_session_dao.dart';
import 'package:life_companion_app/models/focus_session.dart';
import 'package:life_companion_app/widgets/charts.dart';

class FocusStatsPage extends StatefulWidget {
  const FocusStatsPage({super.key});

  @override
  State<FocusStatsPage> createState() => _FocusStatsPageState();
}

class _FocusStatsPageState extends State<FocusStatsPage> {
  List<FocusSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await FocusSessionDao.getAll();
    setState(() => _sessions = list);
  }

  int get _totalCount => _sessions.length;
  int get _totalSeconds =>
      _sessions.fold(0, (s, e) => s + e.durationSeconds);

  String _fmtTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h小时${m}分钟';
    return '$m分钟';
  }

  List<FocusSession> get _todaySessions {
    final now = DateTime.now();
    return _sessions.where((s) {
      final d = DateTime.fromMillisecondsSinceEpoch(s.startTime);
      return d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).toList();
  }

  int get _todayCount => _todaySessions.length;
  int get _todaySeconds =>
      _todaySessions.fold(0, (s, e) => s + e.durationSeconds);

  Map<String, double> get _distribution {
    final map = <String, double>{};
    for (final s in _sessions) {
      map[s.label] = (map[s.label] ?? 0) + s.durationSeconds / 60.0;
    }
    // 按时长降序
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  String get _dailyAvg {
    if (_sessions.isEmpty) return '0分钟';
    final first = _sessions.last.startTime;
    final days = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(first))
            .inDays +
        1;
    return _fmtTime(_totalSeconds ~/ days);
  }

  static const _colors = [
    Color(0xFF4E79A7),
    Color(0xFFF28E2B),
    Color(0xFFE15759),
    Color(0xFF76B7B2),
    Color(0xFF59A14F),
    Color(0xFFEDC948),
    Color(0xFFB07AA1),
    Color(0xFFFF9DA7),
    Color(0xFF9C755F),
  ];

  @override
  Widget build(BuildContext context) {
    final todayStr =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final dist = _distribution;
    final total = dist.values.fold(0.0, (s, v) => s + v);

    return Scaffold(
      appBar: AppBar(title: const Text('专注统计')),
      body: _sessions.isEmpty
          ? const Center(
              child: Text('暂无专注记录\n在目标卡片中点击专注开始',
                  textAlign: TextAlign.center))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 累计统计 ──
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('累计专注',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _StatCol('$_totalCount', '次'),
                              _StatCol(
                                  _fmtTime(_totalSeconds), '总时长'),
                              _StatCol(_dailyAvg, '日均'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 当日 ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('当日专注  $todayStr',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                              '$_todayCount次  ${_fmtTime(_todaySeconds)}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 分布饼图 ──
                  if (dist.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('专注时长分布',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Center(
                              child: DonutChart(
                                data: dist,
                                size: 180,
                                centerValue:
                                    _fmtTime(_totalSeconds),
                                centerLabel: '总时长',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...dist.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                              final i = entry.key;
                              final e = entry.value;
                              final pct = total > 0
                                  ? (e.value / total * 100)
                                      .toStringAsFixed(1)
                                  : '0.0';
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _colors[
                                            i % _colors.length],
                                        borderRadius:
                                            BorderRadius.circular(
                                                2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(e.key,
                                            style:
                                                const TextStyle(
                                                    fontSize:
                                                        13))),
                                    Text(
                                        _fmtTime(
                                            (e.value * 60)
                                                .round()),
                                        style: const TextStyle(
                                            fontSize: 13)),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 48,
                                      child: Text('$pct%',
                                          textAlign:
                                              TextAlign.right,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey
                                                  .shade600)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  const _StatCol(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.amber)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
