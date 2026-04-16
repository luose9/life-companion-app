import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:life_companion_app/models/workout.dart';

class WorkoutResultPage extends StatelessWidget {
  final Workout workout;
  const WorkoutResultPage({super.key, required this.workout});

  List<LatLng> get _route {
    if (workout.routeJson == null || workout.routeJson!.isEmpty) return [];
    try {
      final list = jsonDecode(workout.routeJson!) as List;
      return list
          .map((p) => LatLng(
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  LatLng get _center {
    final route = _route;
    if (route.isEmpty) return const LatLng(39.9, 116.4);
    double lat = 0, lng = 0;
    for (final p in route) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / route.length, lng / route.length);
  }

  LatLngBounds? get _bounds {
    final route = _route;
    if (route.length < 2) return null;
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final p in route) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  String _fmtDuration(int? startMs, int? endMs) {
    if (startMs == null || endMs == null) return '--:--:--';
    final d = Duration(milliseconds: endMs - startMs);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _pacePerKm(int? startMs, int? endMs, double? distKm) {
    if (startMs == null ||
        endMs == null ||
        distKm == null ||
        distKm <= 0) {
      return "--'--\"";
    }
    final totalMin = (endMs - startMs) / 60000.0;
    final paceMin = totalMin / distKm;
    final min = paceMin.floor();
    final sec = ((paceMin - min) * 60).round();
    return "${min.toString().padLeft(2, '0')}'${sec.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final hasRoute = route.length >= 2;
    final bounds = _bounds;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(workout.type),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── 距离头部 ──
            Container(
              width: double.infinity,
              color: Colors.green,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (workout.distanceKm ?? 0).toStringAsFixed(2),
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Text('公里',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

            // ── 地图 ──
            if (hasRoute)
              SizedBox(
                height: 260,
                child: FlutterMap(
                  options: bounds != null
                      ? MapOptions(
                          initialCameraFit: CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(50),
                            maxZoom: 18,
                          ),
                        )
                      : MapOptions(
                          initialCenter: _center,
                          initialZoom: 15,
                        ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.life_companion_app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: route,
                          strokeWidth: 4,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: route.first,
                          width: 20,
                          height: 20,
                          child: const Icon(Icons.circle,
                              color: Colors.green, size: 14),
                        ),
                        Marker(
                          point: route.last,
                          width: 20,
                          height: 20,
                          child: const Icon(Icons.flag,
                              color: Colors.red, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 120,
                color: Colors.grey.shade200,
                child: const Center(
                    child: Text('无GPS轨迹数据',
                        style: TextStyle(color: Colors.grey))),
              ),

            // ── 运动数据 ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('运动数据',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatTile(
                          '训练时长',
                          _fmtDuration(
                              workout.startTime, workout.endTime),
                          Icons.timer),
                      _StatTile(
                          '平均配速',
                          _pacePerKm(workout.startTime, workout.endTime,
                              workout.distanceKm),
                          Icons.speed),
                      _StatTile(
                          '运动消耗',
                          '${workout.calories ?? 0}千卡',
                          Icons.local_fire_department),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatTile(
                          '距离',
                          '${(workout.distanceKm ?? 0).toStringAsFixed(2)}km',
                          Icons.straighten),
                      _StatTile('步数', '${workout.steps ?? '--'}',
                          Icons.directions_walk),
                      _StatTile(
                          '类型', workout.type, Icons.fitness_center),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 20, color: Colors.green),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
