import 'package:flutter/material.dart';
import 'package:life_companion_app/models/goal.dart';
import 'package:life_companion_app/models/task.dart';
import 'package:life_companion_app/data/task_dao.dart';
import 'package:life_companion_app/data/goal_dao.dart';

class GoalDetailPage extends StatefulWidget {
  final Goal goal;
  const GoalDetailPage({super.key, required this.goal});

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  List<TaskItem> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (widget.goal.id == null) return;
    final t = await TaskDao.getTasksByGoal(widget.goal.id!);
    setState(() {
      _tasks = t;
    });
    _recomputeProgress();
  }

  Future<void> _addTask() async {
    final ctl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增子任务'),
        content: TextField(controller: ctl, decoration: const InputDecoration(labelText: '任务内容')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final text = ctl.text.trim();
              if (text.isEmpty) return;
              final task = TaskItem(goalId: widget.goal.id, title: text);
              await TaskDao.insertTask(task);
              Navigator.pop(context);
              await _loadTasks();
            },
            child: const Text('保存'),
          )
        ],
      ),
    );
  }

  Future<void> _toggleDone(TaskItem t) async {
    await TaskDao.toggleDone(t);
    await _loadTasks();
  }

  Future<void> _deleteTask(TaskItem t) async {
    if (t.id != null) await TaskDao.deleteTask(t.id!);
    await _loadTasks();
  }

  Future<void> _recomputeProgress() async {
    if (widget.goal.id == null) return;
    final total = _tasks.length;
    final done = _tasks.where((e) => e.done == 1).length;
    final progress = total == 0 ? widget.goal.progress : ((done / total) * 100).round();
    widget.goal.progress = progress;
    await GoalDao.updateGoal(widget.goal);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.goal.title)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.goal.description ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('进度: ${widget.goal.progress}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(onPressed: _addTask, icon: const Icon(Icons.add), label: const Text('新增子任务')),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(child: Text('暂无子任务'))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, idx) {
                        final t = _tasks[idx];
                        return Dismissible(
                          key: ValueKey(t.id ?? idx),
                          direction: DismissDirection.endToStart,
                          background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                          onDismissed: (_) async {
                            await _deleteTask(t);
                          },
                          child: CheckboxListTile(
                            value: t.done == 1,
                            title: Text(t.title),
                            onChanged: (_) async {
                              await _toggleDone(t);
                            },
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
