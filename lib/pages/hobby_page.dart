import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:life_companion_app/data/hobby_dao.dart';
import 'package:life_companion_app/data/hobby_work_dao.dart';
import 'package:life_companion_app/models/hobby.dart';
import 'package:life_companion_app/models/hobby_work.dart';

class HobbyPage extends StatefulWidget {
  const HobbyPage({super.key});
  @override
  State<HobbyPage> createState() => _HobbyPageState();
}

class _HobbyPageState extends State<HobbyPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Hobby> _hobbies = [];
  String _filterStatus = 'all';
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  static const _statusFilters = [
    {'key': 'all', 'label': '全部'},
    {'key': 'want_try', 'label': '想尝试'},
    {'key': 'playing', 'label': '正在玩'},
    {'key': 'habit', 'label': '已成为习惯'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await HobbyDao.getAll();
    if (mounted) setState(() => _hobbies = list);
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 个爱好吗？'),
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
      await HobbyDao.delete(id);
    }
    _selectedIds.clear();
    await _load();
    if (mounted) {
      setState(() => _multiSelect = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 个爱好'), duration: const Duration(seconds: 2)),
      );
    }
  }

  List<Hobby> get _filtered {
    if (_filterStatus == 'all') return _hobbies.where((h) => h.status != 'abandoned').toList();
    return _hobbies.where((h) => h.status == _filterStatus).toList();
  }

  // ── 发现推荐 ──
  static const _recommendations = [
    // ── 艺术 art ──
    {'name': '水彩画', 'category': 'art', 'desc': '5分钟就能画一幅小风景'},
    {'name': '手写字', 'category': 'art', 'desc': '在屏幕时代的一点仪式感'},
    {'name': '拍照记录', 'category': 'art', 'desc': '用手机拍下一天中最美的瞬间'},
    {'name': '素描速写', 'category': 'art', 'desc': '一支铅笔就能开始的艺术'},
    {'name': '禅绕画', 'category': 'art', 'desc': '重复简单图案，进入心流状态'},
    {'name': '手账装饰', 'category': 'art', 'desc': '用贴纸和画笔记录生活'},
    {'name': '数字绘画', 'category': 'art', 'desc': '用平板画出你的想象'},
    {'name': '彩铅画', 'category': 'art', 'desc': '色彩叠加的治愈过程'},
    {'name': '油画棒', 'category': 'art', 'desc': '厚涂的质感很有趣'},
    {'name': '剪纸艺术', 'category': 'art', 'desc': '一把剪刀创造的对称之美'},
    {'name': '漫画创作', 'category': 'art', 'desc': '用几格画面讲一个小故事'},
    {'name': '手机摄影', 'category': 'art', 'desc': '学会构图，普通场景也能很美'},
    {'name': '街拍', 'category': 'art', 'desc': '记录城市里有趣的瞬间'},
    // ── 运动 sport ──
    {'name': '城市漫步', 'category': 'sport', 'desc': '重新发现你所在的城市'},
    {'name': '晨跑', 'category': 'sport', 'desc': '早起跑步，唤醒一整天'},
    {'name': '瑜伽', 'category': 'sport', 'desc': '柔韧与力量的平衡'},
    {'name': '跳绳', 'category': 'sport', 'desc': '最简单有效的全身运动'},
    {'name': '游泳', 'category': 'sport', 'desc': '水中的自由与放松'},
    {'name': '骑行探索', 'category': 'sport', 'desc': '骑车去一个没去过的地方'},
    {'name': '羽毛球', 'category': 'sport', 'desc': '找个朋友打一局'},
    {'name': '爬山徒步', 'category': 'sport', 'desc': '山顶的风景值得每一步'},
    {'name': '太极拳', 'category': 'sport', 'desc': '慢下来，感受身体的流动'},
    {'name': '滑板', 'category': 'sport', 'desc': '学会滑行的自由感'},
    {'name': '攀岩', 'category': 'sport', 'desc': '每一步都是对自己的突破'},
    {'name': '拉伸放松', 'category': 'sport', 'desc': '睡前10分钟拉伸，告别僵硬'},
    {'name': '飞盘', 'category': 'sport', 'desc': '和朋友一起在公园跑起来'},
    // ── 手工 craft ──
    {'name': '折纸', 'category': 'craft', 'desc': '很解压，从一只纸鹤开始'},
    {'name': '微型积木', 'category': 'craft', 'desc': '自由拼搭的快乐'},
    {'name': '编织', 'category': 'craft', 'desc': '织一条围巾送给自己'},
    {'name': '陶艺', 'category': 'craft', 'desc': '双手塑造的独一无二'},
    {'name': '皮具制作', 'category': 'craft', 'desc': '做一个属于自己的小钱包'},
    {'name': '串珠', 'category': 'craft', 'desc': '设计独一无二的手链'},
    {'name': 'DIY蜡烛', 'category': 'craft', 'desc': '自制香薰蜡烛，温暖小屋'},
    {'name': '刺绣', 'category': 'craft', 'desc': '一针一线的耐心之美'},
    {'name': '拼图', 'category': 'craft', 'desc': '1000片的成就感'},
    {'name': '模型制作', 'category': 'craft', 'desc': '精细打磨的沉浸感'},
    {'name': '木工入门', 'category': 'craft', 'desc': '做一个小木盒或手机架'},
    {'name': '干花制作', 'category': 'craft', 'desc': '把鲜花的美留住'},
    // ── 音乐 music ──
    {'name': '尤克里里', 'category': 'music', 'desc': '可能是最容易上手的弦乐器'},
    {'name': '口琴', 'category': 'music', 'desc': '放在口袋里的乐器'},
    {'name': '吉他', 'category': 'music', 'desc': '学会三个和弦就能弹唱'},
    {'name': '电子音乐', 'category': 'music', 'desc': '用手机APP创作节拍'},
    {'name': '唱歌', 'category': 'music', 'desc': '不需要唱得好，唱得开心就行'},
    {'name': '拇指琴', 'category': 'music', 'desc': '清脆的音色像小溪流水'},
    {'name': '钢琴入门', 'category': 'music', 'desc': '从一首简单曲子开始'},
    {'name': '节奏练习', 'category': 'music', 'desc': '拍拍桌子也能玩出花样'},
    {'name': '听音乐写感受', 'category': 'music', 'desc': '每天认真听一首新歌'},
    {'name': '非洲鼓', 'category': 'music', 'desc': '原始的节奏感，释放压力'},
    // ── 阅读 reading ──
    {'name': '播客', 'category': 'reading', 'desc': '找一两个喜欢的节目，通勤时听'},
    {'name': '每日阅读', 'category': 'reading', 'desc': '哪怕只读10页，也是进步'},
    {'name': '写日记', 'category': 'reading', 'desc': '每天几行，记录真实的自己'},
    {'name': '诗歌', 'category': 'reading', 'desc': '读一首诗，或者写一首'},
    {'name': '短篇小说', 'category': 'reading', 'desc': '半小时就能读完一个好故事'},
    {'name': '学一门新语言', 'category': 'reading', 'desc': '从"你好"开始'},
    {'name': '读传记', 'category': 'reading', 'desc': '看看别人的人生是怎样的'},
    {'name': '写信', 'category': 'reading', 'desc': '给朋友或未来的自己写封信'},
    {'name': '读漫画', 'category': 'reading', 'desc': '图文并茂的轻松阅读'},
    {'name': '听有声书', 'category': 'reading', 'desc': '闭上眼睛，让故事流进来'},
    {'name': '摘抄好句', 'category': 'reading', 'desc': '把触动你的文字记录下来'},
    {'name': '哲学入门', 'category': 'reading', 'desc': '思考那些大问题，很有趣'},
    // ── 美食 cooking ──
    {'name': '手冲咖啡', 'category': 'cooking', 'desc': '早晨的仪式感'},
    {'name': '烘焙', 'category': 'cooking', 'desc': '烤一个蛋糕犒劳自己'},
    {'name': '学做一道菜', 'category': 'cooking', 'desc': '今天尝试一个新食谱'},
    {'name': '泡茶', 'category': 'cooking', 'desc': '慢下来，品一杯好茶'},
    {'name': '做寿司', 'category': 'cooking', 'desc': '卷出属于你的创意'},
    {'name': '调一杯饮品', 'category': 'cooking', 'desc': '水果+气泡水=快乐'},
    {'name': '做甜品', 'category': 'cooking', 'desc': '布丁、果冻、提拉米苏'},
    {'name': '做三明治', 'category': 'cooking', 'desc': '把冰箱里的食材叠在一起'},
    {'name': '腌制泡菜', 'category': 'cooking', 'desc': '等待发酵的耐心和惊喜'},
    {'name': '拉花咖啡', 'category': 'cooking', 'desc': '在咖啡上画一颗心'},
    // ── 科技 tech ──
    {'name': '编程', 'category': 'tech', 'desc': '做一个自己的小工具'},
    {'name': '3D建模', 'category': 'tech', 'desc': '在虚拟世界里造东西'},
    {'name': '电子DIY', 'category': 'tech', 'desc': 'LED灯带+Arduino=无限可能'},
    {'name': '学AI画图', 'category': 'tech', 'desc': '用文字让AI帮你画'},
    {'name': '做个小网站', 'category': 'tech', 'desc': '搭建属于自己的线上空间'},
    {'name': '视频剪辑', 'category': 'tech', 'desc': '把日常剪成一个小短片'},
    {'name': '学用快捷键', 'category': 'tech', 'desc': '效率翻倍的小技巧'},
    {'name': '写博客', 'category': 'tech', 'desc': '分享你的想法和经验'},
    // ── 其他 other ──
    {'name': '阳台种菜', 'category': 'other', 'desc': '看着种子发芽的感觉很奇妙'},
    {'name': '观星', 'category': 'other', 'desc': '抬头看看，宇宙很大'},
    {'name': '养绿植', 'category': 'other', 'desc': '照顾一盆植物，看它慢慢长大'},
    {'name': '冥想', 'category': 'other', 'desc': '闭上眼睛5分钟，什么都不想'},
    {'name': '逛博物馆', 'category': 'other', 'desc': '换个角度看世界'},
    {'name': '整理房间', 'category': 'other', 'desc': '断舍离之后的清爽'},
    {'name': '看日出日落', 'category': 'other', 'desc': '大自然最美的灯光秀'},
    {'name': '露营', 'category': 'other', 'desc': '在星空下睡一晚'},
    {'name': '收集', 'category': 'other', 'desc': '邮票、贝壳、书签…拥有小确幸'},
    {'name': '学魔术', 'category': 'other', 'desc': '一个小魔术逗乐朋友'},
    {'name': '做志愿者', 'category': 'other', 'desc': '帮助别人也是一种快乐'},
    {'name': '天台野餐', 'category': 'other', 'desc': '带上零食和好心情'},
    {'name': '逛花市', 'category': 'other', 'desc': '给自己买束花'},
    {'name': '学下棋', 'category': 'other', 'desc': '象棋、围棋或五子棋都行'},
    {'name': '放风筝', 'category': 'other', 'desc': '看着它飞起来，烦恼也飞走了'},
    // ── 零成本即刻能做 other ──
    {'name': '倒着散步', 'category': 'other', 'desc': '换个方向走路，大脑会突然清醒'},
    {'name': '闭眼听环境音', 'category': 'other', 'desc': '闭上眼30秒，数一数你能听到几种声音'},
    {'name': '用左手做事', 'category': 'other', 'desc': '用非惯用手刷牙/吃饭，激活另一半大脑'},
    {'name': '给陌生人微笑', 'category': 'other', 'desc': '今天对3个陌生人笑一下，看看会发生什么'},
    {'name': '记录云的形状', 'category': 'other', 'desc': '抬头看云，它像什么？给它起个名字'},
    {'name': '赤脚踩地面', 'category': 'other', 'desc': '脱掉鞋子感受草地/泥土/地板的温度'},
    {'name': '数呼吸100次', 'category': 'other', 'desc': '专注数到100，中途走神就重来'},
    {'name': '假装是游客', 'category': 'other', 'desc': '用游客视角重新看你每天走的路'},
    {'name': '编一个故事', 'category': 'other', 'desc': '看到一个路人，想象他的一天'},
    {'name': '模仿动物走路', 'category': 'other', 'desc': '在家学螃蟹横走、企鹅摇摆，很好笑'},
    {'name': '跟影子互动', 'category': 'other', 'desc': '在阳光下做各种姿势，和影子玩'},
    {'name': '用鼻子画字', 'category': 'other', 'desc': '闭眼用鼻尖在空气中写字，放松颈椎'},
    {'name': '一分钟站桩', 'category': 'other', 'desc': '站着不动一分钟，感受身体的微小晃动'},
    {'name': '回忆一个味道', 'category': 'other', 'desc': '闭眼回忆童年最喜欢的一种食物的味道'},
    {'name': '盯一个东西看2分钟', 'category': 'other', 'desc': '认真观察一片树叶/你的手掌，发现新细节'},
    {'name': '走路数台阶', 'category': 'other', 'desc': '今天经过的所有台阶，全部数一遍'},
    {'name': '给物品取名字', 'category': 'other', 'desc': '给你的杯子、椅子起个名字，和它对话'},
    {'name': '即兴哼一段旋律', 'category': 'other', 'desc': '随口哼一段没听过的旋律，你就是作曲家'},
    {'name': '单脚站立计时', 'category': 'other', 'desc': '看你能单脚站多久，明天打破今天的纪录'},
    {'name': '描述你现在的感觉', 'category': 'other', 'desc': '用5个词描述此刻的身体感受'},
    {'name': '换条路回家', 'category': 'other', 'desc': '今天走一条从没走过的路回家'},
    {'name': '给自己写三个优点', 'category': 'other', 'desc': '写下今天你做得好的三件小事'},
    {'name': '看看头顶的天花板', 'category': 'other', 'desc': '你每天待的地方，你认真看过天花板吗'},
    {'name': '想象自己80岁', 'category': 'other', 'desc': '80岁的你会对现在的你说什么'},
    {'name': '用脚趾夹东西', 'category': 'other', 'desc': '训练脚趾的灵活度，试试夹起一支笔'},
    {'name': '感受风的方向', 'category': 'other', 'desc': '闭上眼，感受风从哪里来，往哪里去'},
    {'name': '对镜子做鬼脸', 'category': 'other', 'desc': '认真地给自己做20个鬼脸，会笑出来'},
    {'name': '慢动作吃饭', 'category': 'other', 'desc': '下一口饭嚼30下再咽，感受每种味道'},
    {'name': '写下10个感谢', 'category': 'other', 'desc': '快速写出10个你感谢的人或事'},
    {'name': '学一种鸟叫', 'category': 'other', 'desc': '听窗外的鸟叫，试着模仿它'},
    {'name': '发现身边的对称', 'category': 'other', 'desc': '找找你周围有多少对称的图形'},
    {'name': '闭眼走10步', 'category': 'other', 'desc': '在安全的地方闭眼走，感受空间感'},
    {'name': '数今天看到的颜色', 'category': 'other', 'desc': '你今天见到了几种不同的颜色？'},
    {'name': '和植物说话', 'category': 'other', 'desc': '对一棵树或一朵花说几句话，不会有人笑你'},
    {'name': '用3个词造一个句子', 'category': 'other', 'desc': '随便说3个词，用它们造一个有趣的句子'},
    {'name': '原地转圈', 'category': 'other', 'desc': '像小时候一样转圈，然后感受晕眩'},
    {'name': '盯着镜子里的眼睛', 'category': 'other', 'desc': '看着自己的眼睛一分钟，你会看到不一样的自己'},
    {'name': '设计一个仪式', 'category': 'other', 'desc': '为今天创造一个小仪式，比如出门前深呼吸3次'},
    {'name': '触摸5种不同质感', 'category': 'other', 'desc': '摸摸木头、布料、金属、纸、皮肤，感受区别'},
    {'name': '回忆一个梦', 'category': 'other', 'desc': '闭眼回想你最近的一个梦，写下来'},
    {'name': '即兴演讲1分钟', 'category': 'other', 'desc': '随便一个话题，对自己讲1分钟'},
    {'name': '试试完全安静5分钟', 'category': 'other', 'desc': '不看手机不说话，和安静相处'},
    {'name': '观察一个人3分钟', 'category': 'other', 'desc': '在咖啡馆或公园默默观察一个人的动作'},
    {'name': '用手指弹节奏', 'category': 'other', 'desc': '在桌上弹出一段节奏，越复杂越好玩'},
    {'name': '画你的手', 'category': 'other', 'desc': '认真看着自己的手，在纸上或空气中画出来'},
    {'name': '做一组表情包', 'category': 'other', 'desc': '自拍6个不同的表情，给朋友发'},
    {'name': '发明一个新手势', 'category': 'other', 'desc': '创造一个属于你的打招呼方式'},
    {'name': '倒计时做决定', 'category': 'other', 'desc': '纠结的事情，倒数5秒直接选'},
    {'name': '听一首歌想画面', 'category': 'other', 'desc': '听一首歌，想象它是哪部电影的配乐'},
    {'name': '给未来的自己留言', 'category': 'other', 'desc': '写一段话，设定一个月后再看'},
    {'name': '挑战不说"我"', 'category': 'other', 'desc': '试试一小时内说话不用"我"字'},
    {'name': '找找身边的数学', 'category': 'other', 'desc': '树叶的脉络、花瓣的数量…自然里全是数学'},
    {'name': '深呼吸走100步', 'category': 'other', 'desc': '每走一步配一次呼吸，像行走的冥想'},
    {'name': '猜路人的职业', 'category': 'other', 'desc': '看穿着和神态，猜猜他们是做什么的'},
    {'name': '回忆今天的第一句话', 'category': 'other', 'desc': '你今天醒来说的第一句话是什么？'},
    {'name': '试着不眨眼', 'category': 'other', 'desc': '看看你能坚持不眨眼多久'},
    {'name': '拍一张倒影', 'category': 'other', 'desc': '找找水洼、玻璃里的倒影世界'},
    {'name': '重新认识一个字', 'category': 'other', 'desc': '选一个常用字盯着看，它会变得很陌生'},
    {'name': '手指操', 'category': 'other', 'desc': '两只手做不同动作，挑战大脑协调'},
  ];

  List<Map<String, String>> get _todayRecommendations {
    final day = DateTime.now().difference(DateTime(2024)).inDays;
    final shuffled = List<Map<String, String>>.from(_recommendations);
    shuffled.shuffle(Random(day));
    return shuffled.take(4).toList();
  }

  // ── 新增爱好 ──
  Future<void> _showAddDialog({String? prefillName, String? prefillCategory}) async {
    final nameCtl = TextEditingController(text: prefillName);
    final noteCtl = TextEditingController();
    String cat = prefillCategory ?? 'other';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('探索新爱好 🌈'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: '爱好名称', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                const Text('类别', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 4, children: Hobby.categoryLabels.entries.map((e) {
                  return ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 12)),
                    selected: cat == e.key,
                    onSelected: (_) => setS(() => cat = e.key),
                  );
                }).toList()),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '写点什么（可选）', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 8),
                Text('没有压力，先标记为"想尝试"', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtl.text.trim();
                if (name.isEmpty) return;
                await HobbyDao.insert(Hobby(
                  name: name,
                  category: cat,
                  status: 'want_try',
                  totalSeconds: 0,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  note: noteCtl.text.trim().isNotEmpty ? noteCtl.text.trim() : null,
                ));
                Navigator.pop(ctx);
                await _load();
              },
              child: const Text('加入清单'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 更新爱好状态 ──
  Future<void> _updateStatus(Hobby h, String newStatus) async {
    if (newStatus == 'abandoned') {
      final reasonCtl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('暂时放下 🌿'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('放下不是放弃，而是把精力留给更适合你的事情'),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtl,
                decoration: const InputDecoration(labelText: '原因（可选）', border: OutlineInputBorder(), isDense: true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('再想想')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('确定放下')),
          ],
        ),
      );
      if (confirmed != true) return;
      h.abandonReason = reasonCtl.text.trim().isNotEmpty ? reasonCtl.text.trim() : null;
    }
    h.status = newStatus;
    await HobbyDao.update(h);
    if (newStatus == 'habit' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恭喜！「${h.name}」已经成为你的一部分了 🎉')),
      );
    }
    await _load();
  }

  // ── 保存作品 ──
  Future<void> _addWork(Hobby h) async {
    final titleCtl = TextEditingController();
    final noteCtl = TextEditingController();
    String? filePath;
    String? mediaType;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('记录「${h.name}」的作品'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtl, decoration: const InputDecoration(labelText: '作品标题', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: noteCtl, maxLines: 2, decoration: const InputDecoration(labelText: '感受/笔记', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 8),
                if (filePath != null) ...[
                  _buildMediaPreview(filePath!, mediaType ?? 'file', height: 120),
                  const SizedBox(height: 4),
                  Text(mediaType ?? '', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                ],
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final pick = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (pick != null) {
                        final type = HobbyWork.detectMediaType(pick.path);
                        setS(() { filePath = pick.path; mediaType = type; });
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('图片'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final pick = await ImagePicker().pickVideo(source: ImageSource.gallery);
                      if (pick != null) {
                        setS(() { filePath = pick.path; mediaType = 'video'; });
                      }
                    },
                    icon: const Icon(Icons.videocam_outlined, size: 18),
                    label: const Text('视频'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null && result.files.single.path != null) {
                        final path = result.files.single.path!;
                        final type = HobbyWork.detectMediaType(path);
                        setS(() { filePath = path; mediaType = type; });
                      }
                    },
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: const Text('其他文件'),
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtl.text.trim().isEmpty) return;
                await HobbyWorkDao.insert(HobbyWork(
                  hobbyId: h.id!,
                  title: titleCtl.text.trim(),
                  imagePath: filePath,
                  mediaType: mediaType ?? (filePath != null ? HobbyWork.detectMediaType(filePath!) : null),
                  note: noteCtl.text.trim().isNotEmpty ? noteCtl.text.trim() : null,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                ));
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('作品已保存，你的成长会被记住 ✨')),
                  );
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建媒体预览组件
  static Widget _buildMediaPreview(String path, String type, {double? height}) {
    final h = height ?? 120.0;
    switch (type) {
      case 'image':
      case 'gif':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(File(path), height: h, fit: BoxFit.cover),
        );
      case 'video':
        return Container(
          height: h, width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.play_circle_outline, size: 40, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(path.split(Platform.pathSeparator).last,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
          ]),
        );
      case 'audio':
        return Container(
          height: h, width: double.infinity,
          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.audiotrack, size: 36, color: Colors.purple.shade300),
            const SizedBox(height: 4),
            Text(path.split(Platform.pathSeparator).last,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
          ]),
        );
      default:
        return Container(
          height: h, width: double.infinity,
          decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.insert_drive_file_outlined, size: 36, color: Colors.blueGrey.shade300),
            const SizedBox(height: 4),
            Text(path.split(Platform.pathSeparator).last,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
          ]),
        );
    }
  }

  // ── 作品画廊 ──
  void _showWorks(Hobby h) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _HobbyWorksPage(hobby: h)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab栏 ──
        TabBar(
          controller: _tabCtrl,
          labelColor: Colors.blue.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: '探索'),
            Tab(text: '我的爱好'),
            Tab(text: '作品集'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildDiscoverTab(),
              _buildMyHobbiesTab(),
              _buildWorksTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── 探索页 ──
  Widget _buildDiscoverTab() {
    final recs = _todayRecommendations;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今日灵感 💡',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('没有压力，纯粹好玩就行',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          ...recs.map((r) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _categoryColor(r['category']!),
                    child: Text(Hobby.categoryLabels[r['category']] ?? '?',
                        style: const TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                  title: Text(r['name']!),
                  subtitle: Text(r['desc']!),
                  trailing: TextButton(
                    onPressed: () => _showAddDialog(prefillName: r['name'], prefillCategory: r['category']),
                    child: const Text('想试试', style: TextStyle(fontSize: 12)),
                  ),
                ),
              )),
          const SizedBox(height: 16),
          // ── 自由探索 ──
          const Text('按类别探索', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: Hobby.categoryLabels.entries.map((e) {
            return ActionChip(
              avatar: CircleAvatar(backgroundColor: _categoryColor(e.key), radius: 10,
                  child: Text(e.value[0], style: const TextStyle(fontSize: 10, color: Colors.white))),
              label: Text(e.value),
              onPressed: () => _showAddDialog(prefillCategory: e.key),
            );
          }).toList()),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _showAddDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('自由添加你的爱好'),
            ),
          ),
        ],
      ),
    );
  }

  // ── 我的爱好列表 ──
  Widget _buildMyHobbiesTab() {
    return Column(
      children: [
        // 多选按钮 + 状态过滤
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              ..._statusFilters.map((f) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(f['label']!, style: const TextStyle(fontSize: 12)),
                  selected: _filterStatus == f['key'],
                  onSelected: (_) => setState(() => _filterStatus = f['key']!),
                ),
              );
            }),
              const Spacer(),
              IconButton(
                icon: Icon(_multiSelect ? Icons.close : Icons.checklist, size: 20),
                tooltip: _multiSelect ? '退出多选' : '多选',
                onPressed: () => setState(() { _multiSelect = !_multiSelect; _selectedIds.clear(); }),
              ),
            ],
          ),
        ),
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
                    if (_selectedIds.length == _filtered.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(_filtered.where((h) => h.id != null).map((h) => h.id!));
                    }
                  });
                },
                child: Text(_selectedIds.length == _filtered.length ? '取消全选' : '全选',
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
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.palette_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('还没有爱好', style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text('去"探索"页面找找灵感吧 🌈', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) {
                    final h = _filtered[i];
                    final isSelected = h.id != null && _selectedIds.contains(h.id);
                    return Card(
                      color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
                      child: InkWell(
                        onLongPress: () {
                          if (!_multiSelect && h.id != null) {
                            setState(() { _multiSelect = true; _selectedIds.add(h.id!); });
                          }
                        },
                        onTap: _multiSelect ? () {
                          if (h.id == null) return;
                          setState(() {
                            if (_selectedIds.contains(h.id)) _selectedIds.remove(h.id);
                            else _selectedIds.add(h.id!);
                          });
                        } : null,
                        child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _categoryColor(h.category),
                                  child: Text(Hobby.categoryLabels[h.category]?[0] ?? '?',
                                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(h.status).withAlpha(30),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(Hobby.statusLabels[h.status] ?? h.status,
                                      style: TextStyle(fontSize: 11, color: _statusColor(h.status))),
                                ),
                              ],
                            ),
                            if (h.note != null && h.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(h.note!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ),
                            if (h.totalSeconds > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('累计专注 ${(h.totalSeconds / 3600).toStringAsFixed(1)} 小时',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (h.status == 'want_try')
                                  _actionBtn('开始尝试 🌿', () => _updateStatus(h, 'playing')),
                                if (h.status == 'playing') ...[
                                  _actionBtn('记录作品', () => _addWork(h)),
                                  const SizedBox(width: 8),
                                  _actionBtn('已成习惯 🎉', () => _updateStatus(h, 'habit')),
                                ],
                                const Spacer(),
                                if (h.status != 'abandoned')
                                  TextButton(
                                    onPressed: () => _updateStatus(h, 'abandoned'),
                                    child: Text('放下', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ));
                  },
                ),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  // ── 作品集总览 ──
  Widget _buildWorksTab() {
    final withStatus = _hobbies.where((h) => h.status == 'playing' || h.status == 'habit').toList();
    if (withStatus.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.collections_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('开始玩一个爱好后就可以记录作品了', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: withStatus.length,
      itemBuilder: (ctx, i) {
        final h = withStatus[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _categoryColor(h.category),
              child: Text(Hobby.categoryLabels[h.category]?[0] ?? '?',
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
            title: Text(h.name),
            subtitle: Text('${Hobby.statusLabels[h.status]}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showWorks(h),
          ),
        );
      },
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'art': return Colors.pink.shade300;
      case 'sport': return Colors.green.shade400;
      case 'craft': return Colors.orange.shade300;
      case 'tech': return Colors.blue.shade400;
      case 'music': return Colors.purple.shade300;
      case 'reading': return Colors.teal.shade300;
      case 'cooking': return Colors.red.shade300;
      default: return Colors.grey.shade400;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'want_try': return Colors.blue;
      case 'playing': return Colors.green;
      case 'habit': return Colors.amber.shade700;
      default: return Colors.grey;
    }
  }
}

// ── 作品集详情页（支持删除 + 多选删除） ──
class _HobbyWorksPage extends StatefulWidget {
  final Hobby hobby;
  const _HobbyWorksPage({required this.hobby});
  @override
  State<_HobbyWorksPage> createState() => _HobbyWorksPageState();
}

class _HobbyWorksPageState extends State<_HobbyWorksPage> {
  List<HobbyWork> _works = [];
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final works = await HobbyWorkDao.getByHobbyId(widget.hobby.id!);
    if (mounted) setState(() => _works = works);
  }

  Future<void> _deleteWork(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除作品'),
        content: const Text('确定要删除这个作品吗？'),
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
    await HobbyWorkDao.delete(id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('作品已删除'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 个作品吗？'),
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
      await HobbyWorkDao.delete(id);
    }
    _selectedIds.clear();
    await _load();
    if (mounted) {
      setState(() => _multiSelect = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 个作品'), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.hobby.name} · 作品集'),
        actions: [
          IconButton(
            icon: Icon(_multiSelect ? Icons.close : Icons.checklist, size: 20),
            tooltip: _multiSelect ? '退出多选' : '多选',
            onPressed: () => setState(() { _multiSelect = !_multiSelect; _selectedIds.clear(); }),
          ),
        ],
      ),
      body: Column(
        children: [
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
                      if (_selectedIds.length == _works.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(_works.where((w) => w.id != null).map((w) => w.id!));
                      }
                    });
                  },
                  child: Text(_selectedIds.length == _works.length ? '取消全选' : '全选',
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
          Expanded(
            child: _works.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('还没有作品', style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text('享受过程，作品会自然而来 🌱', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.8,
                    ),
                    itemCount: _works.length,
                    itemBuilder: (ctx, i) {
                      final w = _works[i];
                      final isSelected = w.id != null && _selectedIds.contains(w.id);
                      final type = w.mediaType ?? (w.imagePath != null ? HobbyWork.detectMediaType(w.imagePath!) : 'image');
                      return GestureDetector(
                        onLongPress: () {
                          if (!_multiSelect && w.id != null) {
                            setState(() { _multiSelect = true; _selectedIds.add(w.id!); });
                          }
                        },
                        onTap: _multiSelect
                            ? () {
                                if (w.id == null) return;
                                setState(() {
                                  if (_selectedIds.contains(w.id)) _selectedIds.remove(w.id);
                                  else _selectedIds.add(w.id!);
                                });
                              }
                            : () { if (w.imagePath != null) _openFile(w.imagePath!); },
                        child: Stack(
                          children: [
                            Card(
                              clipBehavior: Clip.antiAlias,
                              color: _multiSelect && isSelected ? Colors.blue.shade50 : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildWorkPreview(w, type)),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Icon(_mediaIcon(type), size: 12, color: Colors.grey.shade400),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(w.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                        ]),
                                        if (w.note != null)
                                          Text(w.note!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 2),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_multiSelect)
                              Positioned(
                                top: 4, left: 4,
                                child: Icon(
                                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                                  size: 22,
                                ),
                              ),
                            if (!_multiSelect)
                              Positioned(
                                top: 0, right: 0,
                                child: IconButton(
                                  icon: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                                  onPressed: () { if (w.id != null) _deleteWork(w.id!); },
                                  tooltip: '删除',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkPreview(HobbyWork w, String type) {
    if (w.imagePath == null) {
      return Center(child: Icon(Icons.image_outlined, size: 32, color: Colors.grey.shade300));
    }
    switch (type) {
      case 'image':
      case 'gif':
        return Image.file(File(w.imagePath!), fit: BoxFit.cover, width: double.infinity);
      case 'video':
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.play_circle_filled, size: 40, color: Colors.grey.shade600),
              const SizedBox(height: 4),
              const Text('视频', style: TextStyle(fontSize: 10, color: Colors.black54)),
            ]),
          ),
        );
      case 'audio':
        return Container(
          color: Colors.purple.shade50,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.audiotrack, size: 36, color: Colors.purple.shade300),
              const SizedBox(height: 4),
              const Text('音频', style: TextStyle(fontSize: 10, color: Colors.black54)),
            ]),
          ),
        );
      default:
        return Container(
          color: Colors.blueGrey.shade50,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.insert_drive_file_outlined, size: 36, color: Colors.blueGrey.shade300),
              const SizedBox(height: 4),
              Text(w.imagePath!.split('.').last.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade500)),
            ]),
          ),
        );
    }
  }

  IconData _mediaIcon(String type) {
    switch (type) {
      case 'image': return Icons.image_outlined;
      case 'gif': return Icons.gif_box_outlined;
      case 'video': return Icons.videocam_outlined;
      case 'audio': return Icons.audiotrack_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _openFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件不存在或已被移动')),
        );
      }
      return;
    }
    // Use share_plus to open with system handler
    final type = HobbyWork.detectMediaType(path);
    if (type == 'image' || type == 'gif') {
      // Show full-screen image preview
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
          body: Center(child: InteractiveViewer(child: Image.file(file))),
        ),
      ));
    } else {
      // For video/audio/file, open via share intent as a workaround
      // (since we don't have a video_player dependency)
      try {
        await Share.shareXFiles([XFile(path)]);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开此文件')),
          );
        }
      }
    }
  }
}
