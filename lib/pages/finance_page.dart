import 'package:flutter/material.dart';
import 'package:life_companion_app/data/transaction_dao.dart';
import 'package:life_companion_app/models/transaction.dart';
import 'package:life_companion_app/widgets/charts.dart';
import 'package:life_companion_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── 分类定义 ──
const Map<String, List<Map<String, dynamic>>> _kCategories = {
  'expense': [
    {'label': '餐饮', 'icon': Icons.restaurant},
    {'label': '交通', 'icon': Icons.directions_bus},
    {'label': '购物', 'icon': Icons.shopping_bag},
    {'label': '娱乐', 'icon': Icons.movie},
    {'label': '医疗', 'icon': Icons.local_hospital},
    {'label': '住房', 'icon': Icons.home},
    {'label': '教育', 'icon': Icons.school},
    {'label': '通讯', 'icon': Icons.phone},
    {'label': '其他', 'icon': Icons.more_horiz},
  ],
  'income': [
    {'label': '工资', 'icon': Icons.work},
    {'label': '兼职', 'icon': Icons.handshake},
    {'label': '投资', 'icon': Icons.trending_up},
    {'label': '红包', 'icon': Icons.card_giftcard},
    {'label': '其他', 'icon': Icons.more_horiz},
  ],
};

IconData _categoryIcon(String type, String? category) {
  final list = _kCategories[type] ?? [];
  final match = list.firstWhere((c) => c['label'] == category,
      orElse: () => {'icon': Icons.receipt});
  return match['icon'] as IconData;
}

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});
  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  List<TransactionEntry> _month = [];
  late DateTime _viewMonth;
  late TabController _tabCtrl;
  double _monthlyBudget = 0;
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 条记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    for (final id in _selectedIds.toList()) {
      await TransactionDao.delete(id);
    }
    _selectedIds.clear();
    await _load();
    if (mounted) {
      setState(() => _multiSelect = false);
      globalCancelMultiSelect = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 条记录'), duration: const Duration(seconds: 2)),
      );
    }
  }

  // ── 月度统计 ──
  double get _monthIncome => _month.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
  double get _monthExpense => _month.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
  double get _monthBalance => _monthIncome - _monthExpense;

  Map<String, double> get _expenseByCategory {
    final m = <String, double>{};
    for (final t in _month.where((t) => t.type == 'expense')) {
      final cat = t.category ?? '其他';
      m[cat] = (m[cat] ?? 0) + t.amount;
    }
    return Map.fromEntries(m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  // ── 消费心情统计 ──
  Map<String, double> get _expenseByFeeling {
    final m = <String, double>{};
    for (final t in _month.where((t) => t.type == 'expense')) {
      final f = t.feeling ?? 'neutral';
      m[f] = (m[f] ?? 0) + t.amount;
    }
    return m;
  }

  int get _expenseCount => _month.where((t) => t.type == 'expense').length;
  int _feelingCount(String f) => _month.where((t) => t.type == 'expense' && t.feeling == f).length;

  // ── 月份切换 ──
  void _prevMonth() { setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1)); _load(); }
  void _nextMonth() {
    final next = DateTime(_viewMonth.year, _viewMonth.month + 1);
    if (next.isAfter(DateTime.now())) return;
    setState(() => _viewMonth = next); _load();
  }

  Future<void> _load() async {
    final month = await TransactionDao.getByMonth(_viewMonth.year, _viewMonth.month);
    if (mounted) setState(() => _month = month);
  }

  String _fmtDate(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _fmtDateShort(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtDateKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  // ── 关键词自动分类（保留供将来使用） ──
  static String _autoCategory(String merchant) {
    final m = merchant.toLowerCase();
    const Map<String, List<String>> _keywords = {
      '餐饮': ['麦当劳','肯德基','华莱士','星巴克','瑞幸','luckin','饿了么','美团外卖','外卖',
               '餐厅','食堂','饭店','火锅','烧烤','烤肉','咖啡','奶茶','茶颜','蜜雪',
               '面包','蛋糕','早餐','午餐','晚餐','小吃','包子','饺子','拉面','米粉'],
      '交通': ['滴滴','高铁','地铁','公交','加油','停车','出租','顺风车','飞机','机票',
               '航班','中石化','中石油','铁路','动车','快车','bus'],
      '购物': ['淘宝','京东','拼多多','天猫','超市','便利店','沃尔玛','永辉','家乐福',
               '711','全家','罗森','好市多','costco','商场','百货','电商'],
      '娱乐': ['电影','游戏','ktv','唱歌','演唱会','演出','票务','大麦','网易','腾讯游戏',
               '王者','和平精英','steam','网吧','台球','保龄'],
      '医疗': ['药店','医院','诊所','大药房','健康','药房','卫生院','口腔','牙科','眼科'],
      '住房': ['房租','物业','水电','燃气','租房','电费','水费','宽带','网费'],
      '教育': ['课程','培训','学费','书店','新华书店','当当','学而思','新东方','教育'],
      '通讯': ['话费','流量','电话','充值','联通','移动','电信'],
    };
    for (final entry in _keywords.entries) {
      if (entry.value.any((kw) => m.contains(kw))) return entry.key;
    }
    return '其他';
  }

  // ── 日期区间消费报告 ──
  Future<void> _showDateRangeReport() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      helpText: '选择查看日期范围',
      saveText: '查看',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (range == null || !mounted) return;

    // 查询该区间交易（包含末日整天，所以 end +1 天）
    final txns = await TransactionDao.getByDateRange(
      range.start,
      range.end.add(const Duration(days: 1)),
    );

    final expenses = txns.where((t) => t.type == 'expense').toList();
    final incomes  = txns.where((t) => t.type == 'income').toList();
    final totalExp = expenses.fold(0.0, (s, t) => s + t.amount);
    final totalInc = incomes.fold(0.0, (s, t) => s + t.amount);

    // 按分类归组并按总金额倒序
    final Map<String, List<TransactionEntry>> byCat = {};
    for (final t in expenses) {
      (byCat[t.category ?? '其他'] ??= []).add(t);
    }
    final sortedCats = byCat.entries.toList()
      ..sort((a, b) {
        final sa = a.value.fold(0.0, (s, t) => s + t.amount);
        final sb = b.value.fold(0.0, (s, t) => s + t.amount);
        return sb.compareTo(sa);
      });

    // 加载已保存的感受备注
    final noteKey =
        'period_note_${_fmtDateKey(range.start)}_${_fmtDateKey(range.end)}';
    final prefs = await SharedPreferences.getInstance();
    final savedNote = prefs.getString(noteKey) ?? '';
    if (!mounted) return;

    final noteCtl = TextEditingController(text: savedNote);

    Widget sumChip(String label, double amount, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color)),
            Text(
              '¥${amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      );
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: Column(
            children: [
              // ── 顶部标题 + 汇总 ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart, color: Colors.purple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '消费报告  ${_fmtDateShort(range.start)} — ${_fmtDateShort(range.end)}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        sumChip('支出', totalExp, Colors.red),
                        const SizedBox(width: 8),
                        sumChip('收入', totalInc, Colors.green),
                        const SizedBox(width: 8),
                        sumChip('结余', totalInc - totalExp,
                            totalInc >= totalExp ? Colors.teal : Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── 滚动内容区 ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 支出分类
                      if (sortedCats.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('该时间段内无支出记录',
                                style: TextStyle(color: Colors.grey.shade500)),
                          ),
                        )
                      else ...[
                        Text('支出分类',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                                fontSize: 12)),
                        const SizedBox(height: 6),
                        ...sortedCats.map((entry) {
                          final catTotal = entry.value
                              .fold(0.0, (s, t) => s + t.amount);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ExpansionTile(
                              leading: Icon(
                                _categoryIcon('expense', entry.key),
                                size: 20,
                                color: Colors.blue,
                              ),
                              title: Text(entry.key,
                                  style: const TextStyle(fontSize: 14)),
                              trailing: Text(
                                '¥${catTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                              children: entry.value.map((t) {
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    t.note?.isNotEmpty == true
                                        ? t.note!
                                        : '无备注',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: t.note?.isNotEmpty == true
                                            ? null
                                            : Colors.grey),
                                  ),
                                  subtitle: Text(_fmtDate(t.timestamp),
                                      style: const TextStyle(fontSize: 11)),
                                  trailing: Text(
                                    '-¥${t.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ],

                      // 收入明细
                      if (incomes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('收入明细',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                                fontSize: 12)),
                        const SizedBox(height: 6),
                        ...incomes.map((t) => Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                dense: true,
                                leading: Icon(
                                    _categoryIcon('income', t.category),
                                    size: 20,
                                    color: Colors.green),
                                title: Text(
                                  '${t.category ?? '收入'}'
                                  '${t.note?.isNotEmpty == true ? '  ${t.note}' : ''}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle: Text(_fmtDate(t.timestamp),
                                    style: const TextStyle(fontSize: 11)),
                                trailing: Text(
                                  '+¥${t.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: Colors.green, fontSize: 13),
                                ),
                              ),
                            )),
                      ],

                      // 情绪感受区域
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('这段时间的感受',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteCtl,
                        decoration: const InputDecoration(
                          hintText: '记录这段时间的消费感受、反思...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await prefs.setString(
                              noteKey, noteCtl.text.trim());
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('感受已保存'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('保存感受'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    noteCtl.dispose();
  }

  // ── 新增/编辑 ──
  Future<void> _showDialog({
    TransactionEntry? existing,
    double? prefillAmount,
    String? prefillNote,
  }) async {
    String type = existing?.type ?? 'expense';
    String category = existing?.category ?? (_kCategories['expense']![0]['label'] as String);
    String? feeling = existing?.feeling;
    final amountCtl = TextEditingController(
        text: existing?.amount.toStringAsFixed(2) ??
            (prefillAmount != null ? prefillAmount.toStringAsFixed(2) : ''));
    final noteCtl = TextEditingController(text: existing?.note ?? prefillNote ?? '');
    DateTime selectedDt = existing?.timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(existing!.timestamp!) : DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final cats = _kCategories[type]!;
          if (!cats.any((c) => c['label'] == category)) {
            category = cats[0]['label'] as String;
          }
          return AlertDialog(
            title: Text(existing == null ? '记一笔' : '编辑'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 收支切换 ──
                    Row(children: [
                      Expanded(child: _TypeBtn(
                        label: '支出', icon: Icons.arrow_upward,
                        color: Colors.orange, selected: type == 'expense',
                        onTap: () => setS(() { type = 'expense'; category = _kCategories['expense']![0]['label'] as String; }),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _TypeBtn(
                        label: '收入', icon: Icons.arrow_downward,
                        color: Colors.teal, selected: type == 'income',
                        onTap: () => setS(() { type = 'income'; category = _kCategories['income']![0]['label'] as String; }),
                      )),
                    ]),
                    const SizedBox(height: 12),

                    // ── 金额 ──
                    TextField(
                      controller: amountCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '金额（元）', prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(), isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── 分类 ──
                    const Text('分类', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: cats.map((c) {
                        final sel = category == c['label'];
                        final selColor = type == 'expense'
                            ? Colors.orange.shade700
                            : Colors.teal.shade700;
                        return ChoiceChip(
                          showCheckmark: false,
                          avatar: sel
                              ? null
                              : Icon(c['icon'] as IconData, size: 14),
                          label: Text(c['label'] as String, style: const TextStyle(fontSize: 12)),
                          selected: sel,
                          selectedColor: selColor,
                          labelStyle: TextStyle(
                            color: sel
                                ? Colors.white
                                : Theme.of(ctx).colorScheme.onSurface,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setS(() => category = c['label'] as String),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // ── 消费心情（仅支出） ──
                    if (type == 'expense') ...[
                      const Text('这笔消费的感受', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('没有好坏之分，只是记录此刻的感觉',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['happy', 'neutral', 'regret'].map((f) {
                          final sel = feeling == f;
                          final isDark = Theme.of(ctx).brightness == Brightness.dark;
                          return GestureDetector(
                            onTap: () => setS(() => feeling = sel ? null : f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel
                                    ? (isDark ? Colors.blue.shade800 : Colors.blue.shade100)
                                    : (isDark ? const Color(0xFF404040) : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: sel ? Colors.blue.shade400 : Colors.transparent),
                              ),
                              child: Text(
                                TransactionEntry.feelingLabels[f] ?? f,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                    color: Theme.of(ctx).colorScheme.onSurface),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── 日期 ──
                    Row(children: [
                      Expanded(child: Text('日期：${selectedDt.year}-${selectedDt.month.toString().padLeft(2, '0')}-${selectedDt.day.toString().padLeft(2, '0')}')),
                      TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(context: ctx, initialDate: selectedDt,
                              firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (d != null) setS(() => selectedDt = d);
                        },
                        child: const Text('选择日期'),
                      ),
                    ]),
                    const SizedBox(height: 8),

                    // ── 备注 ──
                    TextField(
                      controller: noteCtl, maxLines: 2,
                      decoration: const InputDecoration(labelText: '备注（可选）', border: OutlineInputBorder(), isDense: true),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(amountCtl.text.trim());
                  if (amt == null || amt <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
                    return;
                  }
                  final entry = TransactionEntry(
                    id: existing?.id, amount: amt, type: type,
                    category: category,
                    note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
                    timestamp: selectedDt.millisecondsSinceEpoch,
                    feeling: type == 'expense' ? feeling : null,
                  );
                  if (existing == null) {
                    await TransactionDao.insert(entry);
                  } else {
                    await TransactionDao.update(entry);
                  }
                  Navigator.pop(ctx);
                  await _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已记录 ✨'), duration: Duration(seconds: 1)),
                    );
                  }
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── 预算设置 ──
  Future<void> _showBudgetDialog() async {
    final ctl = TextEditingController(text: _monthlyBudget > 0 ? _monthlyBudget.toStringAsFixed(0) : '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置月度参考额度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Text('这只是一个参考，不会给你任何压力', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(
              controller: ctl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '每月参考额度（元）', prefixIcon: Icon(Icons.savings), border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () { setState(() => _monthlyBudget = double.tryParse(ctl.text.trim()) ?? 0); Navigator.pop(ctx); },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── 月份切换 & 汇总 ──
          Container(
            color: Colors.blue.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: _prevMonth),
                  Text('${_viewMonth.year} 年 ${_viewMonth.month} 月',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(children: [
                    IconButton(
                      icon: Icon(_multiSelect ? Icons.close : Icons.checklist, color: Colors.white, size: 20),
                      tooltip: _multiSelect ? '退出多选' : '多选',
                      onPressed: () => setState(() {
                        _multiSelect = !_multiSelect; _selectedIds.clear();
                        globalCancelMultiSelect = _multiSelect ? () => setState(() { _multiSelect = false; _selectedIds.clear(); globalCancelMultiSelect = null; }) : null;
                      }),
                    ),
                    IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: _nextMonth),
                  ]),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryChip(label: '收入', value: '¥${_monthIncome.toStringAsFixed(2)}', color: Colors.greenAccent),
                  _SummaryChip(label: '支出', value: '¥${_monthExpense.toStringAsFixed(2)}', color: Colors.white),
                  _SummaryChip(label: '结余', value: '¥${_monthBalance.toStringAsFixed(2)}', color: Colors.greenAccent),
                ],
              ),
              // ── 预算参考（无压力） ──
              if (_monthlyBudget > 0) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.savings, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_monthExpense / _monthlyBudget).clamp(0.0, 1.0),
                      backgroundColor: Colors.white24,
                      color: Colors.greenAccent,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '已用 ¥${_monthExpense.toStringAsFixed(0)} / ¥${_monthlyBudget.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ]),
              ],
            ]),
          ),

          // ── 多选操作栏 ──
          if (_multiSelect)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.red.shade50,
              child: Row(children: [
                Text('已选 ${_selectedIds.length} 项', style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == _month.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(_month.where((t) => t.id != null).map((t) => t.id!));
                      }
                    });
                  },
                  child: Text(_selectedIds.length == _month.length ? '取消全选' : '全选',
                      style: const TextStyle(fontSize: 12)),
                ),
                ElevatedButton.icon(
                  onPressed: _selectedIds.isEmpty ? null : _batchDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('删除', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ]),
            ),
          // ── 三个Tab ──
          TabBar(
            controller: _tabCtrl,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: const [Tab(text: '明细'), Tab(text: '分类'), Tab(text: '消费感受')],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildDetailTab(),
                _buildCategoryTab(),
                _buildFeelingTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'report',
            backgroundColor: Colors.purple.shade400,
            onPressed: _showDateRangeReport,
            tooltip: '消费报告',
            child: const Icon(Icons.bar_chart, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'budget',
            backgroundColor: Colors.orange.shade300,
            onPressed: _showBudgetDialog,
            tooltip: '设置参考额度',
            child: const Icon(Icons.savings, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_tx',
            onPressed: () => _showDialog(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  // ── Tab1: 明细 ──
  Widget _buildDetailTab() {
    if (_month.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('本月暂无记录', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text('点击右下角 + 开始记录', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _month.length,
      itemBuilder: (ctx, i) {
        final t = _month[i];
        final isExpense = t.type == 'expense';
        final isSelected = t.id != null && _selectedIds.contains(t.id);
        Widget tile = Card(
          color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: InkWell(
            onLongPress: () {
              if (!_multiSelect && t.id != null) {
                setState(() { _multiSelect = true; _selectedIds.add(t.id!); });
                globalCancelMultiSelect = () => setState(() { _multiSelect = false; _selectedIds.clear(); globalCancelMultiSelect = null; });
              }
            },
            onTap: _multiSelect ? () {
              if (t.id == null) return;
              setState(() {
                if (_selectedIds.contains(t.id)) _selectedIds.remove(t.id);
                else _selectedIds.add(t.id!);
              });
            } : null,
            child: ListTile(
            dense: true,
            leading: _multiSelect
                ? Checkbox(
                    value: isSelected,
                    onChanged: (v) {
                      if (t.id == null) return;
                      setState(() { if (v == true) _selectedIds.add(t.id!); else _selectedIds.remove(t.id); });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )
                : CircleAvatar(
                    backgroundColor: isExpense ? Colors.orange.shade50 : Colors.teal.shade50,
                    child: Icon(_categoryIcon(t.type, t.category),
                        color: isExpense ? Colors.orange : Colors.teal, size: 20),
                  ),
            title: Row(children: [
              Expanded(child: Row(children: [
                Text(t.category ?? (isExpense ? '支出' : '收入'), style: const TextStyle(fontSize: 14)),
                if (t.feeling != null) ...[
                  const SizedBox(width: 4),
                  Text(TransactionEntry.feelingEmoji[t.feeling] ?? '', style: const TextStyle(fontSize: 12)),
                ],
              ])),
              Text(
                '${isExpense ? '-' : '+'}¥${t.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isExpense ? Colors.black87 : Colors.teal,
                ),
              ),
            ]),
            subtitle: Text(
              '${_fmtDate(t.timestamp)}${t.note != null ? '  ${t.note}' : ''}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: _multiSelect ? null : IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
              onPressed: () => _showDialog(existing: t),
            ),
          ),
        ));
        if (_multiSelect) return tile;
        return Dismissible(
          key: ValueKey(t.id ?? i),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.grey.shade300,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.close, color: Colors.white),
          ),
          onDismissed: (_) async {
            if (t.id != null) await TransactionDao.delete(t.id!);
            await _load();
          },
          child: tile,
        );
      },
    );
  }

  // ── Tab2: 分类统计 ──
  Widget _buildCategoryTab() {
    if (_expenseByCategory.isEmpty) {
      return const Center(child: Text('本月暂无支出记录', style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DonutChart(
              data: _expenseByCategory, size: 140,
              centerLabel: '支出',
              centerValue: '¥${_monthExpense >= 1000 ? '${(_monthExpense / 1000).toStringAsFixed(1)}k' : _monthExpense.toStringAsFixed(0)}',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LegendRow(
                labels: _expenseByCategory.keys.toList(),
                colors: const [
                  Color(0xFF4E79A7), Color(0xFFF28E2B), Color(0xFFE15759),
                  Color(0xFF76B7B2), Color(0xFF59A14F), Color(0xFFEDC948),
                  Color(0xFFB07AA1), Color(0xFFFF9DA7), Color(0xFF9C755F),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('各分类金额', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        BarChart(
          values: _expenseByCategory.values.toList(),
          labels: _expenseByCategory.keys.toList(),
          colors: const [
            Color(0xFF4E79A7), Color(0xFFF28E2B), Color(0xFFE15759),
            Color(0xFF76B7B2), Color(0xFF59A14F), Color(0xFFEDC948),
            Color(0xFFB07AA1), Color(0xFFFF9DA7), Color(0xFF9C755F),
          ],
          height: 150,
        ),
        const SizedBox(height: 12),
        // 消费概况（纯事实）
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('本月消费概况', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              if (_expenseByCategory.isNotEmpty)
                Text('花费最多的类别：${_expenseByCategory.keys.first}（¥${_expenseByCategory.values.first.toStringAsFixed(0)}）',
                    style: const TextStyle(fontSize: 12)),
              Text('共 $_expenseCount 笔支出', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab3: 消费感受分析 ──
  Widget _buildFeelingTab() {
    final expenses = _month.where((t) => t.type == 'expense').toList();
    if (expenses.isEmpty) {
      return const Center(child: Text('本月暂无支出记录', style: TextStyle(color: Colors.grey)));
    }

    final happyCount = _feelingCount('happy');
    final neutralCount = _feelingCount('neutral');
    final regretCount = _feelingCount('regret');
    final happyAmount = _expenseByFeeling['happy'] ?? 0;
    final regretAmount = _expenseByFeeling['regret'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ── 感受分布 ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('消费感受分布', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('了解自己的消费感受，没有好坏之分', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 10),
              _FeelingBar(emoji: '😊', label: '开心', count: happyCount, total: _expenseCount, color: Colors.green.shade300),
              const SizedBox(height: 6),
              _FeelingBar(emoji: '😐', label: '一般', count: neutralCount, total: _expenseCount, color: Colors.grey.shade400),
              const SizedBox(height: 6),
              _FeelingBar(emoji: '😕', label: '后悔', count: regretCount, total: _expenseCount, color: Colors.orange.shade300),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── 让你开心的消费 ──
        if (happyCount > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('😊 让你开心的消费', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Text('共 $happyCount 笔，合计 ¥${happyAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                ...expenses.where((t) => t.feeling == 'happy').take(5).map((t) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Text(t.category ?? '', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.note ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
                      Text('¥${t.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── 让你后悔的消费（无指责） ──
        if (regretCount > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('😕 让你有些后悔的消费', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('觉察到后悔本身就是进步，不需要自责', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Text('共 $regretCount 笔，合计 ¥${regretAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                ...expenses.where((t) => t.feeling == 'regret').take(5).map((t) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Text(t.category ?? '', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.note ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
                      Text('¥${t.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── 消费建议（纯事实，无指责） ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡 小小观察', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              if (happyCount > regretCount)
                const Text('这个月大部分消费都让你感到开心，很棒', style: TextStyle(fontSize: 12))
              else if (regretCount > happyCount && regretCount > 0)
                const Text('这个月有一些让你后悔的消费，也许下次可以给自己一个"冷静期"', style: TextStyle(fontSize: 12))
              else
                const Text('记录消费感受可以帮助你更了解自己的消费习惯', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 辅助 Widget ──
class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.15)
              : (isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected
                    ? color
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                size: 18),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: selected
                        ? color
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _FeelingBar extends StatelessWidget {
  final String emoji, label;
  final int count, total;
  final Color color;
  const _FeelingBar({required this.emoji, required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Row(children: [
      Text('$emoji $label', style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 8),
      Expanded(
        child: LinearProgressIndicator(value: ratio, backgroundColor: Colors.grey.shade200, color: color, minHeight: 8),
      ),
      const SizedBox(width: 8),
      Text('$count 笔', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
    ]);
  }
}
