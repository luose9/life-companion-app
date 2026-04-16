import 'package:share_plus/share_plus.dart';
import 'package:life_companion_app/models/goal.dart';
import 'package:life_companion_app/models/workout.dart';
import 'package:life_companion_app/models/entertainment.dart';
import 'package:life_companion_app/models/mood.dart';

class ShareService {
  // ── 目标 ────────────────────────────────────────────────
  static Future<void> shareGoal(Goal g) async {
    final buf = StringBuffer();
    buf.writeln('🎯 我的目标：${g.title}');
    if (g.description != null && g.description!.isNotEmpty) {
      buf.writeln('📝 ${g.description}');
    }
    buf.writeln('📊 完成进度：${g.progress}%');
    if (g.endDate != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(g.endDate!);
      buf.writeln(
          '⏰ 目标截止：${dt.year}-${_p(dt.month)}-${_p(dt.day)}');
    }
    buf.writeln('\n来自 Life Companion ✨');
    await Share.share(buf.toString(), subject: '我的目标：${g.title}');
  }

  // ── 运动 ────────────────────────────────────────────────
  static Future<void> shareWorkout(Workout w) async {
    final buf = StringBuffer();
    buf.writeln('🏃 我刚完成了一次${w.type}！');
    if (w.startTime != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(w.startTime!);
      buf.writeln(
          '📅 ${dt.year}-${_p(dt.month)}-${_p(dt.day)}');
    }
    if (w.durationMinutes > 0) buf.writeln('⏱ 时长：${w.durationMinutes} 分钟');
    if (w.distanceKm != null) {
      buf.writeln('📏 距离：${w.distanceKm!.toStringAsFixed(2)} km');
    }
    if (w.steps != null) buf.writeln('👣 步数：${w.steps} 步');
    if (w.calories != null) buf.writeln('🔥 消耗：${w.calories} kcal');
    if (w.note != null && w.note!.isNotEmpty) buf.writeln('💬 ${w.note}');
    buf.writeln('\n来自 Life Companion ✨');
    await Share.share(buf.toString(), subject: '我的${w.type}记录');
  }

  // ── 娱乐 ────────────────────────────────────────────────
  static Future<void> shareEntertainment(Entertainment e) async {
    final typeLabel = _mediaLabel(e.mediaType);
    final buf = StringBuffer();
    buf.writeln('${_mediaEmoji(e.mediaType)} $typeLabel推荐：《${e.title}》');
    if (e.creator != null && e.creator!.isNotEmpty) {
      buf.writeln('👤 ${e.creator}');
    }
    if (e.rating != null) {
      final stars = '⭐' * e.rating!.round();
      buf.writeln('$stars ${e.rating!.toStringAsFixed(1)}/5');
    }
    if (e.tags != null && e.tags!.isNotEmpty) {
      buf.writeln('🏷 ${e.tags}');
    }
    if (e.feeling != null && e.feeling!.isNotEmpty) {
      buf.writeln('💭 ${e.feeling}');
    }
    buf.writeln('\n来自 Life Companion ✨');
    await Share.share(buf.toString(), subject: '推荐$typeLabel：《${e.title}》');
  }

  // ── 心情 ────────────────────────────────────────────────
  static Future<void> shareMood(Mood m) async {
    final buf = StringBuffer();
    buf.writeln('${m.emoji ?? '🙂'} 今天的心情：${m.moodTag ?? ''}');
    if (m.note != null && m.note!.isNotEmpty) buf.writeln('📖 ${m.note}');
    if (m.timestamp != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(m.timestamp!);
      buf.writeln(
          '🕐 ${dt.year}-${_p(dt.month)}-${_p(dt.day)} ${_p(dt.hour)}:${_p(dt.minute)}');
    }
    buf.writeln('\n来自 Life Companion ✨');
    await Share.share(buf.toString(), subject: '今日心情');
  }

  // ── 记账月度汇总 ─────────────────────────────────────────
  static Future<void> shareFinanceSummary({
    required int year,
    required int month,
    required double income,
    required double expense,
    required double balance,
  }) async {
    final buf = StringBuffer();
    buf.writeln('💰 $year 年 $month 月账单');
    buf.writeln('💚 收入：¥${income.toStringAsFixed(2)}');
    buf.writeln('❤️ 支出：¥${expense.toStringAsFixed(2)}');
    buf.writeln('${balance >= 0 ? '✅' : '⚠️'} 结余：¥${balance.toStringAsFixed(2)}');
    buf.writeln('\n来自 Life Companion ✨');
    await Share.share(buf.toString(), subject: '$year 年 $month 月账单');
  }

  // ── 工具 ─────────────────────────────────────────────────
  static String _p(int n) => n.toString().padLeft(2, '0');

  static String _mediaLabel(String type) {
    const m = {
      'movie': '电影', 'tv': '电视剧', 'music': '音乐',
      'book': '书籍', 'game': '游戏', 'other': '娱乐',
    };
    return m[type] ?? '娱乐';
  }

  static String _mediaEmoji(String type) {
    const m = {
      'movie': '🎬', 'tv': '📺', 'music': '🎵',
      'book': '📚', 'game': '🎮', 'other': '🎭',
    };
    return m[type] ?? '🎭';
  }
}
