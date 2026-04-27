import 'dart:math';
import 'package:flutter/material.dart';
import 'package:life_companion_app/data/goal_dao.dart';
import 'package:life_companion_app/data/checkin_dao.dart';
import 'package:life_companion_app/models/goal.dart';

class AchievementWallPage extends StatefulWidget {
  const AchievementWallPage({super.key});
  @override
  State<AchievementWallPage> createState() => _AchievementWallPageState();
}

class _AchievementWallPageState extends State<AchievementWallPage> {
  List<Goal> _completed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await GoalDao.getCompletedGoals();
    if (mounted) setState(() { _completed = list; _loading = false; });
  }

  void _randomReview() {
    if (_completed.isEmpty) return;
    final g = _completed[Random().nextInt(_completed.length)];
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('🌟 随机回顾'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${g.title}」', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (g.description != null && g.description!.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text(g.description!)),
            if (g.meaning != null && g.meaning!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(child: Text(g.meaning!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              '完成于 ${_fmtDate(DateTime.fromMillisecondsSinceEpoch(g.createdAt ?? 0))}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text('这就是你一步步走过来的样子，真厉害 ✨', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('继续前行')),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('成就时光机 🏆'),
        actions: [
          if (_completed.isNotEmpty)
            IconButton(
              onPressed: _randomReview,
              icon: const Icon(Icons.shuffle),
              tooltip: '随机回顾',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _completed.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('还没有完成的目标', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('每一个小目标都值得被记录 🌱', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _completed.length,
                  itemBuilder: (ctx, i) {
                    final g = _completed[i];
                    return _buildTimelineTile(g, i == 0, i == _completed.length - 1);
                  },
                ),
    );
  }

  Widget _buildTimelineTile(Goal g, bool isFirst, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // timeline bar
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst) Container(width: 2, height: 12, color: Colors.amber.shade300),
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade700, width: 2),
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: Colors.amber.shade300)),
              ],
            ),
          ),
          // content
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (g.description != null && g.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(g.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ),
                    if (g.meaning != null && g.meaning!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('💡 ${g.meaning!}', style: TextStyle(fontSize: 11, color: Colors.amber.shade800, fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade400),
                        const SizedBox(width: 4),
                        Text(Goal.levelLabels[g.level] ?? g.level, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        if (g.startDate != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '坚持了 ${((DateTime.now().millisecondsSinceEpoch - g.startDate!) / 86400000).ceil()} 天',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
