import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:life_companion_app/services/session_manager.dart';
import 'package:life_companion_app/data/workout_dao.dart';
import 'package:life_companion_app/models/workout.dart';
import 'package:life_companion_app/pages/workout_result_page.dart';

class LiveTrackingPage extends StatefulWidget {
  final String workoutType;
  const LiveTrackingPage({super.key, required this.workoutType});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

// 会话状态由 WorkoutSessionManager 单例管理，返回上级页面后会话继续运行
class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final _mgr = WorkoutSessionManager.instance;

  // 所有状态均由 WorkoutSessionManager 单例管理

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── 权限检查 ──
  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('请开启位置服务')));
      }
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('需要位置权限以记录运动')));
        }
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('位置权限被永久拒绝，请在设置中开启')));
      }
      return false;
    }
    return true;
  }

  // ── 开始：委托给单例管理器 ──
  Future<void> _start() async {
    final ok = await _checkPermission();
    if (!ok) return;
    await _mgr.startSession(widget.workoutType);
  }

  void _pause() => _mgr.pauseSession();
  void _resume() => _mgr.resumeSession();

  // ── 结束并保存 ──
  Future<void> _finish() async {
    // 先读取数据，再停止（stopSession 会清空数据）
    final startTime = _mgr.startTime;
    final distanceKm = _mgr.distanceKm;
    final calories = _mgr.caloriesBurned;
    final routePoints = List<Map<String, dynamic>>.from(_mgr.routePoints);
    final type = _mgr.workoutType;

    _mgr.stopSession();

    final w = Workout(
      type: type,
      startTime: startTime?.millisecondsSinceEpoch,
      endTime: DateTime.now().millisecondsSinceEpoch,
      distanceKm: distanceKm > 0 ? distanceKm : null,
      calories: calories > 0 ? calories : null,
      routeJson: routePoints.isNotEmpty ? jsonEncode(routePoints) : null,
    );
    final id = await WorkoutDao.insert(w);
    w.id = id;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WorkoutResultPage(workout: w)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _mgr,
      builder: (context, _) {
        final isMySession =
            _mgr.isActive && _mgr.workoutType == widget.workoutType;
        final isOtherSession =
            _mgr.isActive && _mgr.workoutType != widget.workoutType;
        final elapsed = isMySession ? _mgr.elapsed : Duration.zero;

        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.workoutType} 实时追踪'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: isMySession ? '返回（运动在后台继续）' : '返回',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          backgroundColor: Colors.grey.shade900,
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
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),

                // ── 其他运动进行中 ──
                if (isOtherSession)
                  Container(
                    color: Colors.amber.shade800,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      '当前有「${_mgr.workoutType}」正在进行，请先结束',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 20),

                // ── 大计时器 ──
                Text(
                  _fmtDuration(elapsed),
                  style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'monospace'),
                ),
                const SizedBox(height: 30),

                // ── 四宫格数据 ──
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _DataCard(
                        label: '瞬时速度',
                        value: (isMySession ? _mgr.currentSpeedKmh : 0.0)
                            .toStringAsFixed(1),
                        unit: 'km/h',
                        color: Colors.blue,
                        icon: Icons.speed,
                      ),
                      _DataCard(
                        label: '平均速度',
                        value: (isMySession ? _mgr.avgSpeedKmh : 0.0)
                            .toStringAsFixed(1),
                        unit: 'km/h',
                        color: Colors.orange,
                        icon: Icons.trending_up,
                      ),
                      _DataCard(
                        label: '距离',
                        value:
                            (isMySession ? _mgr.distanceKm : 0.0).toStringAsFixed(2),
                        unit: 'km',
                        color: Colors.green,
                        icon: Icons.straighten,
                      ),
                      _DataCard(
                        label: '卡路里',
                        value: isMySession ? '${_mgr.caloriesBurned}' : '0',
                        unit: 'kcal',
                        color: Colors.red,
                        icon: Icons.local_fire_department,
                      ),
                    ],
                  ),
                ),

                // ── 最大速度 ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '最大速度  ${isMySession ? _mgr.maxSpeedKmh.toStringAsFixed(1) : '0.0'} km/h',
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── 控制按钮 ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildControls(isMySession, isOtherSession),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildControls(bool isMySession, bool isOtherSession) {
    if (isOtherSession) {
      return [
        _ControlBtn(
          icon: Icons.arrow_back,
          label: '返回结束',
          color: Colors.amber,
          onTap: () => Navigator.pop(context),
          size: 70,
        ),
      ];
    }
    if (!isMySession) {
      return [
        _ControlBtn(
          icon: Icons.play_arrow,
          label: '开始',
          color: Colors.green,
          onTap: _start,
          size: 80,
        ),
      ];
    }
    if (_mgr.isPaused) {
      return [
        _ControlBtn(
            icon: Icons.play_arrow,
            label: '继续',
            color: Colors.green,
            onTap: _resume,
            size: 60),
        const SizedBox(width: 30),
        _ControlBtn(
            icon: Icons.stop,
            label: '结束',
            color: Colors.red,
            onTap: _finish,
            size: 60),
      ];
    }
    return [
      _ControlBtn(
          icon: Icons.pause,
          label: '暂停',
          color: Colors.orange,
          onTap: _pause,
          size: 60),
      const SizedBox(width: 30),
      _ControlBtn(
          icon: Icons.stop,
          label: '结束',
          color: Colors.red,
          onTap: _finish,
          size: 60),
    ];
  }
}

class _DataCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  const _DataCard({required this.label, required this.value, required this.unit, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          Text(unit, style: TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double size;
  const _ControlBtn({required this.icon, required this.label, required this.color, required this.onTap, required this.size});

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
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
