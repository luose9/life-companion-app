import 'dart:async';
import 'package:flutter/material.dart';
import 'package:life_companion_app/models/goal.dart';
import 'package:life_companion_app/models/focus_session.dart';
import 'package:life_companion_app/data/focus_session_dao.dart';

class FocusTimerPage extends StatefulWidget {
  final Goal goal;
  const FocusTimerPage({super.key, required this.goal});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  String _state = 'idle';
  DateTime? _startTime;

  @override
  void dispose() {
    _uiTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _start() {
    _startTime = DateTime.now();
    _stopwatch.start();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    setState(() => _state = 'running');
  }

  void _pause() {
    _stopwatch.stop();
    setState(() => _state = 'paused');
  }

  void _resume() {
    _stopwatch.start();
    setState(() => _state = 'running');
  }

  Future<void> _stop() async {
    _stopwatch.stop();
    _uiTimer?.cancel();
    final duration = _stopwatch.elapsed;

    if (duration.inSeconds < 10) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('专注时间太短，未保存')));
      }
      setState(() => _state = 'idle');
      _stopwatch.reset();
      return;
    }

    final session = FocusSession(
      goalId: widget.goal.id!,
      label: widget.goal.title,
      startTime: _startTime!.millisecondsSinceEpoch,
      endTime: DateTime.now().millisecondsSinceEpoch,
      durationSeconds: duration.inSeconds,
    );
    await FocusSessionDao.insert(session);

    if (mounted) {
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('专注完成！'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              Text('目标：${widget.goal.title}'),
              const SizedBox(height: 4),
              Text('专注时长：${_fmtDuration(duration)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(c);
                Navigator.pop(context, true);
              },
              child: const Text('完成'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _stopwatch.elapsed;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text('专注 · ${widget.goal.title}'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // 大环形计时器
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      _state == 'running' ? Colors.amber : Colors.white24,
                  width: 4,
                ),
                boxShadow: _state == 'running'
                    ? [
                        BoxShadow(
                            color: Colors.amber.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5)
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  _fmtDuration(elapsed),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.goal.title,
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            if (widget.goal.description != null &&
                widget.goal.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(widget.goal.description!,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 13)),
              ),
            const Spacer(flex: 3),
            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildControls(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildControls() {
    switch (_state) {
      case 'idle':
        return [
          _Btn(
              icon: Icons.play_arrow,
              label: '开始专注',
              color: Colors.amber,
              onTap: _start,
              size: 80),
        ];
      case 'running':
        return [
          _Btn(
              icon: Icons.pause,
              label: '暂停',
              color: Colors.orange,
              onTap: _pause,
              size: 60),
          const SizedBox(width: 40),
          _Btn(
              icon: Icons.stop,
              label: '结束',
              color: Colors.red,
              onTap: _stop,
              size: 60),
        ];
      case 'paused':
        return [
          _Btn(
              icon: Icons.play_arrow,
              label: '继续',
              color: Colors.amber,
              onTap: _resume,
              size: 60),
          const SizedBox(width: 40),
          _Btn(
              icon: Icons.stop,
              label: '结束',
              color: Colors.red,
              onTap: _stop,
              size: 60),
        ];
      default:
        return [];
    }
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double size;
  const _Btn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap,
      required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2)
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
