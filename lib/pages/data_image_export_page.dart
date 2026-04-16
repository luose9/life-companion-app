import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataImageExportPage extends StatefulWidget {
  final Map<String, int> counts;
  final String userName;
  final String joinDate;
  const DataImageExportPage({
    super.key,
    required this.counts,
    required this.userName,
    required this.joinDate,
  });

  @override
  State<DataImageExportPage> createState() => _DataImageExportPageState();
}

class _DataImageExportPageState extends State<DataImageExportPage> {
  final _repaintKey = GlobalKey();
  int _styleIndex = 0;
  bool _sharing = false;

  static const _styleNames = ['卡片风格', '极简风格', '渐变风格'];

  static const Map<String, String> _labels = {
    'goals': '目标',
    'tasks': '子任务',
    'moods': '心情',
    'schedules': '日程',
    'transactions': '账单',
    'workouts': '运动',
    'entertainments': '娱乐',
  };

  int get _total => widget.counts.values.fold(0, (a, b) => a + b);

  Future<void> _shareImage() async {
    setState(() => _sharing = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/life_companion_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Life Companion 数据概览',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('分享失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生成数据图片'),
        actions: [
          _sharing
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                )
              : IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareImage,
                  tooltip: '分享',
                ),
        ],
      ),
      body: Column(
        children: [
          // 风格选择
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: List.generate(_styleNames.length, (i) {
                final selected = _styleIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_styleNames[i]),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _styleIndex = i),
                  ),
                );
              }),
            ),
          ),
          // 预览
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    switch (_styleIndex) {
      case 1:
        return _buildMinimalCard();
      case 2:
        return _buildGradientCard();
      default:
        return _buildClassicCard();
    }
  }

  // ── 风格 1：经典卡片 ──
  Widget _buildClassicCard() {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部
          Row(children: [
            const Icon(Icons.self_improvement, size: 28, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Life Companion',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
          ]),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${widget.userName} · ${widget.joinDate}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ),
          const SizedBox(height: 16),
          // 总计
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$_total',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                const SizedBox(width: 6),
                Text('条记录',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 各项
          ..._labels.entries.map((e) {
            final count = widget.counts[e.key] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.value,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade700)),
                  Text('$count',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 4),
          Text('数据仅存储于本设备',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ── 风格 2：极简白 ──
  Widget _buildMinimalCard() {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.userName,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2)),
          const SizedBox(height: 2),
          Text(widget.joinDate,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          const SizedBox(height: 20),
          Text('$_total',
              style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  color: Colors.black87)),
          Text('总记录',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: _labels.entries.map((e) {
              final count = widget.counts[e.key] ?? 0;
              return SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$count',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w300)),
                    Text(e.value,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Life Companion',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade300,
                  letterSpacing: 3)),
        ],
      ),
    );
  }

  // ── 风格 3：渐变 ──
  Widget _buildGradientCard() {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Icon(Icons.self_improvement, color: Colors.white70, size: 24),
            const SizedBox(width: 8),
            Text(widget.userName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.joinDate,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 11)),
          ),
          const SizedBox(height: 20),
          Text('$_total',
              style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const Text('条生活记录',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          // 网格
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: _labels.entries.map((e) {
              final count = widget.counts[e.key] ?? 0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$count',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(e.value,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white60)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text('Life Companion',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.3),
                  letterSpacing: 3)),
        ],
      ),
    );
  }
}
