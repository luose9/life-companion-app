import 'package:flutter/material.dart';
import 'package:life_companion_app/models/goal.dart';
import 'package:life_companion_app/models/focus_session.dart';
import 'package:life_companion_app/data/focus_session_dao.dart';
import 'package:life_companion_app/services/session_manager.dart';

class FocusTimerPage extends StatefulWidget {
  final Goal goal;
  const FocusTimerPage({super.key, required this.goal});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

// 会话状态由 FocusSessionManager 单例管理，返回上级页面后会话继续运行
class _FocusTimerPageState extends State<FocusTimerPage> {
  final _mgr = FocusSessionManager.instance;

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _start() {
    if (widget.goal.id == null) return;
    _mgr.startSession(gId: widget.goal.id!, title: widget.goal.title);
  }

  void _pause() => _mgr.pauseSession();
  void _resume() => _mgr.resumeSession();

  Future<void> _stop() async {
    final elapsed = _mgr.elapsed;
    final startTime = _mgr.startTime;
    final goalId = _mgr.goalId;
    final goalTitle = _mgr.goalTitle;

    if (elapsed.inSeconds < 10) {
      _mgr.stopSession();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('专注时间太短，未保存')));
      }
      return;
    }

    final session = FocusSession(
      goalId: goalId!,
      label: goalTitle,
      startTime: startTime!.millisecondsSinceEpoch,
      endTime: DateTime.now().millisecondsSinceEpoch,
      durationSeconds: elapsed.inSeconds,
    );
    await FocusSessionDao.insert(session);
    _mgr.stopSession();

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
              Text('目标：$goalTitle'),
              const SizedBox(height: 4),
              Text('专注时长：${_fmtDuration(elapsed)}',
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

  /// 结束另一个目标的专注会话并保存
  Future<void> _stopOtherAndSwitch() async {
    final elapsed = _mgr.elapsed;
    final startTime = _mgr.startTime;
    final goalId = _mgr.goalId;
    final goalTitle = _mgr.goalTitle;

    if (elapsed.inSeconds >= 10 && goalId != null && startTime != null) {
      final session = FocusSession(
        goalId: goalId,
        label: goalTitle,
        startTime: startTime.millisecondsSinceEpoch,
        endTime: DateTime.now().millisecondsSinceEpoch,
        durationSeconds: elapsed.inSeconds,
      );
      await FocusSessionDao.insert(session);
    }
    _mgr.stopSession();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _mgr,
      builder: (context, _) {
        final isMySession =
            _mgr.isActive && _mgr.goalId == widget.goal.id;
        final isOtherSession =
            _mgr.isActive && _mgr.goalId != widget.goal.id;
        final elapsed = isMySession ? _mgr.elapsed : Duration.zero;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            title: Text('专注 · ${widget.goal.title}'),
            backgroundColor: const Color(0xFF16213E),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: isMySession ? '返回（专注在后台继续）' : '返回',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // ── 暂停提示条 ──
                if (isMySession && _mgr.isPaused)
                  Container(
                    color: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pause, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('已暂停',
                            style: TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),

                // ── 其他目标专注中提示 ──
                if (isOtherSession)
                  Container(
                    color: Colors.amber.shade800,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          '「${_mgr.goalTitle}」专注进行中（${_fmtDuration(_mgr.elapsed)}）',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _stopOtherAndSwitch,
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.amber.shade900,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4)),
                          child: const Text('保存并开始此目标',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                const Spacer(flex: 2),

                // ── 大环形计时器 ──
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isMySession && !_mgr.isPaused)
                          ? Colors.amber
                          : Colors.white24,
                      width: 4,
                    ),
                    boxShadow: (isMySession && !_mgr.isPaused)
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
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16)),
                if (widget.goal.description != null &&
                    widget.goal.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(widget.goal.description!,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 13)),
                  ),
                const Spacer(flex: 3),

                // ── 控制按钮 ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildControls(isMySession, isOtherSession),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildControls(bool isMySession, bool isOtherSession) {
    if (isOtherSession) {
      // 不可开始新会话，引导用户保存并切换
      return [];
    }
    if (!isMySession) {
      return [
        _Btn(
            icon: Icons.play_arrow,
            label: '开始专注',
            color: Colors.amber,
            onTap: _start,
            size: 80),
      ];
    }
    if (_mgr.isPaused) {
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
    }
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
