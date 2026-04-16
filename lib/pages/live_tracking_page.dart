import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:life_companion_app/data/workout_dao.dart';
import 'package:life_companion_app/models/workout.dart';
import 'package:life_companion_app/pages/workout_result_page.dart';

class LiveTrackingPage extends StatefulWidget {
  final String workoutType;
  const LiveTrackingPage({super.key, required this.workoutType});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  // 状态：idle / running / paused / finished
  String _state = 'idle';

  // 计时
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;

  // GPS
  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;
  double _totalDistanceM = 0;
  double _currentSpeedKmh = 0;
  double _maxSpeedKmh = 0;
  final List<double> _speedSamples = [];
  final List<Map<String, dynamic>> _routePoints = [];

  // 起止时间
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void dispose() {
    _uiTimer?.cancel();
    _positionSub?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  // ── MET 近似值 ──
  double get _met {
    switch (widget.workoutType) {
      case '跑步': return 9.8;
      case '步行': return 3.5;
      case '骑行': return 7.5;
      case '游泳': return 8.0;
      case '健身': return 6.0;
      default: return 5.0;
    }
  }

  double get _durationMinutes => _stopwatch.elapsed.inSeconds / 60.0;
  double get _distanceKm => _totalDistanceM / 1000.0;
  double get _avgSpeedKmh => _durationMinutes > 0 ? _distanceKm / (_durationMinutes / 60.0) : 0;
  int get _caloriesBurned => (_met * 65.0 * _durationMinutes / 60.0).round();

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请开启位置服务')));
      }
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('需要位置权限以记录运动')));
        }
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('位置权限被永久拒绝，请在设置中开启')));
      }
      return false;
    }
    return true;
  }

  // ── 开始运动 ──
  Future<void> _start() async {
    final ok = await _checkPermission();
    if (!ok) return;

    _startTime = DateTime.now();
    _stopwatch.start();
    setState(() => _state = 'running');

    // UI 每秒刷新
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // GPS 监听
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, // 每移动3米更新
    );
    _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((pos) {
      if (_state != 'running') return;

      // 记录轨迹点
      _routePoints.add({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });

      // 瞬时速度 (m/s -> km/h)
      final speedKmh = (pos.speed > 0 ? pos.speed : 0.0) * 3.6;
      _currentSpeedKmh = speedKmh;
      if (speedKmh > _maxSpeedKmh) _maxSpeedKmh = speedKmh;
      if (speedKmh > 0) _speedSamples.add(speedKmh);

      // 累计距离
      if (_lastPosition != null) {
        final d = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );
        if (d < 200) { // 过滤GPS跳变
          _totalDistanceM += d;
        }
      }
      _lastPosition = pos;
      if (mounted) setState(() {});
    });
  }

  // ── 暂停 ──
  void _pause() {
    _stopwatch.stop();
    setState(() => _state = 'paused');
  }

  // ── 恢复 ──
  void _resume() {
    _stopwatch.start();
    setState(() => _state = 'running');
  }

  // ── 结束并保存 ──
  Future<void> _finish() async {
    _stopwatch.stop();
    _uiTimer?.cancel();
    _positionSub?.cancel();
    _endTime = DateTime.now();
    setState(() => _state = 'finished');

    final w = Workout(
      type: widget.workoutType,
      startTime: _startTime?.millisecondsSinceEpoch,
      endTime: _endTime?.millisecondsSinceEpoch,
      distanceKm: _distanceKm > 0 ? _distanceKm : null,
      calories: _caloriesBurned > 0 ? _caloriesBurned : null,
      routeJson: _routePoints.isNotEmpty ? jsonEncode(_routePoints) : null,
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
    final elapsed = _stopwatch.elapsed;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.workoutType} 实时追踪'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // ── 大计时器 ──
            Text(
              _fmtDuration(elapsed),
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
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
                    value: _currentSpeedKmh.toStringAsFixed(1),
                    unit: 'km/h',
                    color: Colors.blue,
                    icon: Icons.speed,
                  ),
                  _DataCard(
                    label: '平均速度',
                    value: _avgSpeedKmh.toStringAsFixed(1),
                    unit: 'km/h',
                    color: Colors.orange,
                    icon: Icons.trending_up,
                  ),
                  _DataCard(
                    label: '距离',
                    value: _distanceKm.toStringAsFixed(2),
                    unit: 'km',
                    color: Colors.green,
                    icon: Icons.straighten,
                  ),
                  _DataCard(
                    label: '卡路里',
                    value: '$_caloriesBurned',
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
                    '最大速度  ${_maxSpeedKmh.toStringAsFixed(1)} km/h',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                children: _buildControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildControls() {
    switch (_state) {
      case 'idle':
        return [
          _ControlBtn(
            icon: Icons.play_arrow,
            label: '开始',
            color: Colors.green,
            onTap: _start,
            size: 80,
          ),
        ];
      case 'running':
        return [
          _ControlBtn(icon: Icons.pause, label: '暂停', color: Colors.orange, onTap: _pause, size: 60),
          const SizedBox(width: 30),
          _ControlBtn(icon: Icons.stop, label: '结束', color: Colors.red, onTap: _finish, size: 60),
        ];
      case 'paused':
        return [
          _ControlBtn(icon: Icons.play_arrow, label: '继续', color: Colors.green, onTap: _resume, size: 60),
          const SizedBox(width: 30),
          _ControlBtn(icon: Icons.stop, label: '结束', color: Colors.red, onTap: _finish, size: 60),
        ];
      default:
        return [];
    }
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
