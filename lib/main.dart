import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/db_provider.dart';
import 'pages/goals_page.dart';
import 'pages/hobby_page.dart';
import 'pages/mood_page.dart';
import 'pages/schedule_page.dart';
import 'pages/workout_page.dart';
import 'pages/entertainment_page.dart';
import 'pages/finance_page.dart';
import 'pages/stats_page.dart';
import 'pages/profile_page.dart';
import 'pages/body_page.dart';
import 'pages/relationship_page.dart';
import 'pages/inspiration_page.dart';
import 'pages/gratitude_page.dart';
import 'pages/milestone_page.dart';
import 'services/notification_service.dart';
import 'services/user_profile_service.dart';
import 'services/privacy_service.dart';
import 'services/app_settings_service.dart';
import 'widgets/app_lock_guard.dart';
import 'widgets/privacy_consent_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 限制内存图片缓存：最多50张 / 50MB
  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;
  await initNotificationPlugin();
  runApp(const AppLockGuard(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _theme = 'system';
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await UserProfileService.getTheme();
    final scale = await AppSettingsService.getFontScale();
    if (mounted) setState(() { _theme = theme; _fontScale = scale; });
  }

  ThemeMode get _themeMode {
    switch (_theme) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Companion',
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: Colors.blue.shade300),
      ),
      themeMode: _themeMode,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(_fontScale),
          ),
          child: child!,
        );
      },
      home: HomeScreen(onSettingsChanged: _loadSettings),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  const HomeScreen({super.key, this.onSettingsChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  String _userName = '用户';
  String? _avatarPath;
  List<int> _bottomNavModules = [0, 2, 3, 5, 10]; // 默认底部导航模块
  bool _vacationMode = false;

  static const _navPrefsKey = 'bottom_nav_modules';

  static const _modules = <_ModuleInfo>[
    _ModuleInfo('目标', Icons.flag, GoalsPage()),
    _ModuleInfo('爱好', Icons.palette, HobbyPage()),
    _ModuleInfo('心情', Icons.mood, MoodPage()),
    _ModuleInfo('日程', Icons.calendar_today, SchedulePage()),
    _ModuleInfo('记账', Icons.account_balance_wallet, FinancePage()),
    _ModuleInfo('运动', Icons.self_improvement, WorkoutPage()),
    _ModuleInfo('娱乐', Icons.movie_filter, EntertainmentPage()),
    _ModuleInfo('身体', Icons.nightlight_round, BodyPage()),
    _ModuleInfo('人际', Icons.people_outline, RelationshipPage()),
    _ModuleInfo('灵感', Icons.lightbulb_outline, InspirationPage()),
    _ModuleInfo('感恩', Icons.wb_sunny_outlined, GratitudePage()),
    _ModuleInfo('里程碑', Icons.timeline, MilestonePage()),
    _ModuleInfo('统计', Icons.bar_chart, StatsPage()),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _bottomNavModules.first;
    _loadProfile();
    _loadNavConfig();
    _loadVacation();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final first = await PrivacyService.isFirstLaunch();
      if (first && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => PrivacyConsentDialog(onAccepted: () {}),
        );
      }
    });
  }

  Future<void> _loadNavConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_navPrefsKey);
    if (json != null) {
      try {
        final list = (jsonDecode(json) as List).cast<int>();
        if (list.length >= 3 && list.length <= 5 &&
            list.every((i) => i >= 0 && i < _modules.length)) {
          if (mounted) setState(() {
            _bottomNavModules = list;
            // 确保初始选中页是导航栏的第一个模块
            if (!_bottomNavModules.contains(_selectedIndex)) {
              _selectedIndex = _bottomNavModules.first;
            }
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _saveNavConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_navPrefsKey, jsonEncode(_bottomNavModules));
  }

  Future<void> _loadProfile() async {
    final name = await UserProfileService.getName();
    final avatar = await UserProfileService.getAvatarPath();
    if (mounted) setState(() { _userName = name; _avatarPath = avatar; });
  }

  Future<void> _loadVacation() async {
    final v = await AppSettingsService.isVacationMode();
    if (mounted) setState(() => _vacationMode = v);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showNavSettingsDialog() {
    final selected = List<int>.from(_bottomNavModules);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            title: const Text('自定义导航栏'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('选择 3~5 个模块显示在底部导航栏',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _modules.length,
                      itemBuilder: (_, i) {
                        final m = _modules[i];
                        final checked = selected.contains(i);
                        return CheckboxListTile(
                          value: checked,
                          title: Row(children: [
                            Icon(m.icon, size: 20, color: checked ? Colors.blue : Colors.grey),
                            const SizedBox(width: 8),
                            Text(m.label),
                          ]),
                          dense: true,
                          onChanged: (v) {
                            setDlgState(() {
                              if (v == true && !checked && selected.length < 5) {
                                selected.add(i);
                              } else if (v == false && checked && selected.length > 3) {
                                selected.remove(i);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('已选 ${selected.length}/5',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  selected.sort();
                  setState(() => _bottomNavModules = selected);
                  _saveNavConfig();
                  Navigator.pop(ctx);
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modules[_selectedIndex].label),
        actions: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
              _loadProfile();
              _loadVacation();
              widget.onSettingsChanged?.call();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade200,
                backgroundImage: _avatarPath != null
                    ? FileImage(File(_avatarPath!))
                    : null,
                child: _avatarPath == null
                    ? Text(
                        _userName.isNotEmpty
                            ? _userName.characters.first.toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade200,
                    backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                    child: _avatarPath == null
                        ? Text(_userName.isNotEmpty ? _userName.characters.first.toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(_userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _modules.length,
                  itemBuilder: (ctx, i) {
                    final m = _modules[i];
                    final selected = _selectedIndex == i;
                    final defaultColor = Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.white70;
                    return ListTile(
                      leading: Icon(m.icon, color: selected ? Colors.blue : defaultColor.withOpacity(0.6)),
                      title: Text(m.label, style: TextStyle(
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          color: selected ? Colors.blue : defaultColor)),
                      selected: selected,
                      onTap: () {
                        Navigator.pop(ctx);
                        _onItemTapped(i);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.dashboard_customize_outlined, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5)),
                title: const Text('自定义导航栏'),
                dense: true,
                onTap: () {
                  Navigator.pop(context);
                  _showNavSettingsDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.cleaning_services_outlined, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5)),
                title: const Text('清理缓存'),
                dense: true,
                onTap: () async {
                  Navigator.pop(context);
                  PaintingBinding.instance.imageCache.clear();
                  PaintingBinding.instance.imageCache.clearLiveImages();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('缓存已清理')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _vacationMode
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.spa, size: 64, color: Colors.teal),
                    const SizedBox(height: 16),
                    const Text('好好休息',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('我在这里等你回来 🌿',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('关闭休假模式'),
                      onPressed: () async {
                        await AppSettingsService.setVacationMode(false);
                        await AppSettingsService.resetZeroPressure();
                        _loadVacation();
                      },
                    ),
                  ],
                ),
              ),
            )
          : _modules[_selectedIndex].page,
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavModules.map((i) {
          final m = _modules[i];
          return BottomNavigationBarItem(icon: Icon(m.icon), label: m.label);
        }).toList(),
        currentIndex: _bottomNavIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          _onItemTapped(_bottomNavModules[i]);
        },
      ),
    );
  }

  int get _bottomNavIndex {
    final idx = _bottomNavModules.indexOf(_selectedIndex);
    return idx >= 0 ? idx : 0;
  }
}

class _ModuleInfo {
  final String label;
  final IconData icon;
  final Widget page;
  const _ModuleInfo(this.label, this.icon, this.page);
}
