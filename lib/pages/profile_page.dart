import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_companion_app/services/user_profile_service.dart';
import 'package:life_companion_app/services/data_export_service.dart';
import 'package:life_companion_app/services/privacy_service.dart';
import 'package:life_companion_app/services/app_settings_service.dart';
import 'package:life_companion_app/widgets/privacy_consent_dialog.dart';
import 'package:life_companion_app/pages/data_image_export_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '用户';
  String _bio = '';
  String? _avatarPath;
  String _theme = 'system';
  bool _appLockEnabled = false;
  bool _screenshotProtected = false;
  bool _biometricsAvailable = false;
  Map<String, int> _counts = {};
  int _createdAt = 0;
  bool _loading = true;
  bool _exporting = false;

  // ── 新设置项 ──
  double _fontScale = 1.0;
  bool _notifyGlobal = true;
  bool _use24h = true;
  String _dateFormat = 'ymd';
  String _weekStart = 'mon';
  bool _vibration = true;
  bool _soundFeedback = true;
  bool _minimalMode = false;
  bool _hideNumbers = false;
  bool _noReminder = false;
  bool _failFriendly = false;
  bool _vacationMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      UserProfileService.getName(),
      UserProfileService.getBio(),
      UserProfileService.getAvatarPath(),
      UserProfileService.getTheme(),
      DataExportService.getTableCounts(),
      UserProfileService.getCreatedAt().then((v) => v as Object),
      PrivacyService.isAppLockEnabled().then((v) => v as Object),
      PrivacyService.isScreenshotProtected().then((v) => v as Object),
      PrivacyService.canUseBiometrics().then((v) => v as Object),
      AppSettingsService.getFontScale().then((v) => v as Object),
      AppSettingsService.isNotifyGlobal().then((v) => v as Object),
      AppSettingsService.use24h().then((v) => v as Object),
      AppSettingsService.getDateFormat(),
      AppSettingsService.getWeekStart(),
      AppSettingsService.isVibrationEnabled().then((v) => v as Object),
      AppSettingsService.isSoundFeedbackEnabled().then((v) => v as Object),
      AppSettingsService.isMinimalMode().then((v) => v as Object),
      AppSettingsService.isHideNumbers().then((v) => v as Object),
      AppSettingsService.isNoReminderMode().then((v) => v as Object),
      AppSettingsService.isFailFriendlyMode().then((v) => v as Object),
      AppSettingsService.isVacationMode().then((v) => v as Object),
    ]);
    setState(() {
      _name = results[0] as String;
      _bio = results[1] as String;
      _avatarPath = results[2] as String?;
      _theme = results[3] as String;
      _counts = results[4] as Map<String, int>;
      _createdAt = results[5] as int;
      _appLockEnabled = results[6] as bool;
      _screenshotProtected = results[7] as bool;
      _biometricsAvailable = results[8] as bool;
      _fontScale = results[9] as double;
      _notifyGlobal = results[10] as bool;
      _use24h = results[11] as bool;
      _dateFormat = results[12] as String;
      _weekStart = results[13] as String;
      _vibration = results[14] as bool;
      _soundFeedback = results[15] as bool;
      _minimalMode = results[16] as bool;
      _hideNumbers = results[17] as bool;
      _noReminder = results[18] as bool;
      _failFriendly = results[19] as bool;
      _vacationMode = results[20] as bool;
      _loading = false;
    });
  }

  // ── 选择头像 ──────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('从相册选择'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('拍照'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          if (_avatarPath != null)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除头像', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(ctx, null),
            ),
        ]),
      ),
    );

    if (source == null && _avatarPath != null) {
      // 删除头像
      await UserProfileService.setAvatarPath(null);
      setState(() => _avatarPath = null);
      return;
    }
    if (source == null) return;

    final file = await picker.pickImage(
      source: source,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (file != null) {
      await UserProfileService.setAvatarPath(file.path);
      setState(() => _avatarPath = file.path);
    }
  }

  // ── 编辑姓名/简介 ─────────────────────────────────────────
  Future<void> _showEditDialog() async {
    final nameCtl = TextEditingController(text: _name);
    final bioCtl = TextEditingController(text: _bio);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑资料'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: '昵称',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtl,
              maxLines: 3,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: '个性签名',
                prefixIcon: Icon(Icons.edit_note),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              await UserProfileService.setName(nameCtl.text);
              await UserProfileService.setBio(bioCtl.text);
              Navigator.pop(ctx);
              await _load();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // ── 导出数据 ──────────────────────────────────────────────
  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      await DataExportService.exportAllAsJson();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导出失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── 清除所有数据 ──────────────────────────────────────────
  Future<void> _showClearConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 8),
          Text('清除所有数据'),
        ]),
        content: const Text(
          '将删除所有目标、心情、日程、记账、运动、娱乐记录。\n此操作不可撤销，请先备份数据！',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认清除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DataExportService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ 数据已清除')));
        await _load();
      }
    }
  }

  // ── 主题选择 ──────────────────────────────────────────────
  Future<void> _showThemeDialog() async {
    final options = [
      ('system', '跟随系统', Icons.brightness_auto),
      ('light', '浅色模式', Icons.light_mode),
      ('dark', '深色模式', Icons.dark_mode),
    ];
    await showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('外观主题'),
        children: options.map((o) {
          final (val, label, icon) = o;
          return RadioListTile<String>(
            value: val,
            groupValue: _theme,
            secondary: Icon(icon),
            title: Text(label),
            onChanged: (v) async {
              if (v != null) {
                await UserProfileService.setTheme(v);
                setState(() => _theme = v);
              }
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  // ── 关于 ──────────────────────────────────────────────────
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Life Companion',
      applicationVersion: '1.0.0',
      applicationIcon:
          const Icon(Icons.self_improvement, size: 48, color: Colors.blue),
      children: const [
        Text('一款专为个人生活管理设计的 App，支持目标追踪、情感记录、日程提醒、运动追踪、娱乐记录与记账。'),
        SizedBox(height: 8),
        Text('本地存储，数据完全私密。', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // ── 格式化创建日期 ────────────────────────────────────────
  String get _joinDate {
    final dt = DateTime.fromMillisecondsSinceEpoch(_createdAt);
    return '${dt.year} 年 ${dt.month} 月 ${dt.day} 日加入';
  }

  // ── 各表中文名 ────────────────────────────────────────────
  static const Map<String, String> _tableLabels = {
    'goals': '目标',
    'tasks': '子任务',
    'moods': '心情',
    'schedules': '日程',
    'transactions': '账单',
    'workouts': '运动',
    'entertainments': '娱乐',
  };

  int get _totalRecords => _counts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // ── 头部 SliverAppBar ─────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade800, Colors.indigo.shade600],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // ── 头像 ──
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: _avatarPath != null &&
                                    File(_avatarPath!).existsSync()
                                ? FileImage(File(_avatarPath!))
                                : null,
                            child: (_avatarPath == null ||
                                    !File(_avatarPath!).existsSync())
                                ? Text(
                                    _name.isNotEmpty
                                        ? _name.characters.first.toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                        fontSize: 36,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt,
                                size: 14, color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    if (_bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(_bio,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12)),
                      ),
                    const SizedBox(height: 4),
                    Text(_joinDate,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _showEditDialog,
                tooltip: '编辑资料',
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 数据概览卡片 ──────────────────────────
                  _sectionLabel('📊 数据概览'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _hideNumbers ? '***' : '$_totalRecords',
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
                              ),
                              const SizedBox(width: 6),
                              Text('条总记录',
                                  style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                          if (!_minimalMode) ...[
                            const Divider(height: 20),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: _tableLabels.entries.map((e) {
                                final count = _counts[e.key] ?? 0;
                                return _CountChip(
                                    label: e.value,
                                    count: _hideNumbers ? -1 : count);
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── 数据管理 ──────────────────────────────
                  _sectionLabel('🗂 数据管理'),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: _exporting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.upload_file,
                                  color: Colors.blue),
                          title: const Text('导出全部数据'),
                          subtitle: const Text('生成 JSON 文件并分享'),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: _exporting ? null : _exportData,
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.image_outlined,
                              color: Colors.teal),
                          title: const Text('生成数据图片'),
                          subtitle: const Text('以图片形式分享数据概览'),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DataImageExportPage(
                                  counts: _counts,
                                  userName: _name,
                                  joinDate: _joinDate,
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.delete_forever,
                              color: Colors.red),
                          title: const Text('清除所有数据',
                              style: TextStyle(color: Colors.red)),
                          subtitle: const Text('删除全部记录（不可恢复）'),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: _showClearConfirm,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── 外观设置 ──────────────────────────────
                  _sectionLabel('🎨 外观'),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.brightness_6, color: Colors.orange),
                          title: const Text('主题模式'),
                          subtitle: Text(_themeLabel(_theme)),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: _showThemeDialog,
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.text_fields, color: Colors.deepPurple),
                          title: const Text('字体大小'),
                          subtitle: Text(_fontScaleLabel(_fontScale)),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: _showFontScaleDialog,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── 通知设置 ──────────────────────────────
                  _sectionLabel('🔔 通知'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: Icon(
                            _notifyGlobal
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            color: _notifyGlobal ? Colors.orange : Colors.grey,
                          ),
                          title: const Text('全局通知'),
                          subtitle: const Text('关闭后将停止所有提醒'),
                          value: _notifyGlobal,
                          onChanged: (v) async {
                            await AppSettingsService.setNotifyGlobal(v);
                            setState(() => _notifyGlobal = v);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── 时间与格式 ────────────────────────────
                  _sectionLabel('⏰ 时间与格式'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.access_time, color: Colors.blue),
                          title: const Text('24 小时制'),
                          subtitle: Text(_use24h ? '14:30' : '2:30 PM'),
                          value: _use24h,
                          onChanged: (v) async {
                            await AppSettingsService.setUse24h(v);
                            setState(() => _use24h = v);
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.date_range, color: Colors.green),
                          title: const Text('日期格式'),
                          subtitle: Text(_dateFormat == 'ymd'
                              ? '2025-01-31'
                              : '01-31-2025'),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: () async {
                            final options = [
                              ('ymd', '年-月-日 (2025-01-31)'),
                              ('mdy', '月-日-年 (01-31-2025)'),
                            ];
                            await showDialog(
                              context: context,
                              builder: (ctx) => SimpleDialog(
                                title: const Text('日期格式'),
                                children: options.map((o) {
                                  final (val, label) = o;
                                  return RadioListTile<String>(
                                    value: val,
                                    groupValue: _dateFormat,
                                    title: Text(label),
                                    onChanged: (v) async {
                                      if (v != null) {
                                        await AppSettingsService.setDateFormat(v);
                                        setState(() => _dateFormat = v);
                                      }
                                      Navigator.pop(ctx);
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.calendar_view_week,
                              color: Colors.indigo),
                          title: const Text('每周起始日'),
                          subtitle: Text(_weekStart == 'mon' ? '周一' : '周日'),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: () async {
                            final options = [
                              ('mon', '周一'),
                              ('sun', '周日'),
                            ];
                            await showDialog(
                              context: context,
                              builder: (ctx) => SimpleDialog(
                                title: const Text('每周起始日'),
                                children: options.map((o) {
                                  final (val, label) = o;
                                  return RadioListTile<String>(
                                    value: val,
                                    groupValue: _weekStart,
                                    title: Text(label),
                                    onChanged: (v) async {
                                      if (v != null) {
                                        await AppSettingsService.setWeekStart(v);
                                        setState(() => _weekStart = v);
                                      }
                                      Navigator.pop(ctx);
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── 反馈 ──────────────────────────────────
                  _sectionLabel('📳 反馈'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: Icon(
                            Icons.vibration,
                            color: _vibration ? Colors.deepOrange : Colors.grey,
                          ),
                          title: const Text('振动反馈'),
                          subtitle: const Text('操作时振动'),
                          value: _vibration,
                          onChanged: (v) async {
                            await AppSettingsService.setVibration(v);
                            setState(() => _vibration = v);
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        SwitchListTile(
                          secondary: Icon(
                            _soundFeedback
                                ? Icons.volume_up
                                : Icons.volume_off,
                            color: _soundFeedback ? Colors.blue : Colors.grey,
                          ),
                          title: const Text('声音反馈'),
                          subtitle: const Text('操作完成时播放提示音'),
                          value: _soundFeedback,
                          onChanged: (v) async {
                            await AppSettingsService.setSoundFeedback(v);
                            setState(() => _soundFeedback = v);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  // ── 隐私与安全 ────────────────────────────
                  _sectionLabel('🔒 隐私与安全'),
                  Card(
                    child: Column(
                      children: [
                        // App 锁
                        SwitchListTile(
                          secondary: Icon(
                            _appLockEnabled ? Icons.lock : Icons.lock_open,
                            color: _appLockEnabled ? Colors.blue : Colors.grey,
                          ),
                          title: const Text('App 锁'),
                          subtitle: Text(_biometricsAvailable
                              ? '启动和切回前台时需身份验证'
                              : '设备不支持生物识别'),
                          value: _appLockEnabled,
                          onChanged: _biometricsAvailable
                              ? (v) async {
                                  if (v) {
                                    // 开启前先验证一次
                                    final ok = await PrivacyService.authenticate(
                                        reason: '请验证身份以开启 App 锁');
                                    if (!ok) return;
                                  }
                                  await PrivacyService.setAppLockEnabled(v);
                                  setState(() => _appLockEnabled = v);
                                }
                              : null,
                        ),
                        const Divider(height: 1, indent: 56),
                        // 截图保护
                        SwitchListTile(
                          secondary: Icon(
                            _screenshotProtected
                                ? Icons.screenshot_monitor
                                : Icons.no_photography,
                            color: _screenshotProtected
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          title: const Text('截图保护'),
                          subtitle: const Text('禁止截屏和录屏（FLAG_SECURE）'),
                          value: _screenshotProtected,
                          onChanged: (v) async {
                            await PrivacyService.setScreenshotProtection(v);
                            setState(() => _screenshotProtected = v);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(v
                                    ? '截图保护已开启，重启应用生效'
                                    : '截图保护已关闭'),
                              ));
                            }
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        // 隐私政策入口
                        ListTile(
                          leading: const Icon(Icons.policy_outlined,
                              color: Colors.indigo),
                          title: const Text('隐私政策'),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => PrivacyConsentDialog(
                                onAccepted: () {/* 已同意，无需跳转 */},
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  // ── 关于 ──────────────────────────────────
                  _sectionLabel('ℹ️ 关于'),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline,
                              color: Colors.blue),
                          title: const Text('关于 Life Companion'),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: _showAboutDialog,
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading:
                              const Icon(Icons.privacy_tip_outlined, color: Colors.green),
                          title: const Text('隐私说明'),
                          subtitle: const Text('所有数据仅存储于本设备'),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => PrivacyConsentDialog(
                                onAccepted: () {/* 重读并同意 */},
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── 反焦虑模式 ────────────────────────────
                  _sectionLabel('🧘 反焦虑模式'),
                  // ── 休假模式（顶部突出） ──
                  Card(
                    color: _vacationMode ? Colors.teal.shade50 : null,
                    child: SwitchListTile(
                      secondary: Icon(
                        Icons.beach_access,
                        color: _vacationMode ? Colors.teal : Colors.grey,
                        size: 28,
                      ),
                      title: const Text('休假模式',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_vacationMode
                          ? '好好休息，我在这里等你回来 🌿'
                          : '关闭所有提醒，隐藏统计'),
                      value: _vacationMode,
                      onChanged: (v) async {
                        await AppSettingsService.setVacationMode(v);
                        if (v) {
                          // 开启休假 = 开启所有反焦虑
                          await AppSettingsService.applyZeroPressure();
                        }
                        await _load();
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.spa, color: Colors.teal),
                          title: const Text('极简模式'),
                          subtitle: const Text('隐藏统计和进度条，回归纯记录'),
                          value: _minimalMode,
                          onChanged: (v) async {
                            await AppSettingsService.setMinimalMode(v);
                            setState(() => _minimalMode = v);
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        SwitchListTile(
                          secondary: const Icon(Icons.visibility_off,
                              color: Colors.blueGrey),
                          title: const Text('数字隐藏模式'),
                          subtitle: const Text('所有数字统计显示为 ***'),
                          value: _hideNumbers,
                          onChanged: (v) async {
                            await AppSettingsService.setHideNumbers(v);
                            setState(() => _hideNumbers = v);
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        SwitchListTile(
                          secondary: Icon(
                            Icons.do_not_disturb_on,
                            color: _noReminder ? Colors.red : Colors.grey,
                          ),
                          title: const Text('无提醒模式'),
                          subtitle: const Text('关闭一切推送通知'),
                          value: _noReminder,
                          onChanged: (v) async {
                            await AppSettingsService.setNoReminderMode(v);
                            setState(() => _noReminder = v);
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        SwitchListTile(
                          secondary: const Icon(Icons.sentiment_satisfied_alt,
                              color: Colors.amber),
                          title: const Text('失败友好模式'),
                          subtitle: const Text('不标记未完成任务为失败'),
                          value: _failFriendly,
                          onChanged: (v) async {
                            await AppSettingsService.setFailFriendlyMode(v);
                            setState(() => _failFriendly = v);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── 一键无压力模式 ────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: const BorderSide(color: Colors.teal),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.self_improvement),
                          label: const Text('开启无压力模式'),
                          onPressed: () async {
                            await AppSettingsService.applyZeroPressure();
                            await _load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('🧘 已进入无压力模式')),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('恢复默认'),
                          onPressed: () async {
                            await AppSettingsService.resetZeroPressure();
                            await _load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('已恢复默认设置')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text('Life Companion v1.0.0',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700)),
      );

  String _themeLabel(String t) {
    switch (t) {
      case 'light':
        return '浅色模式';
      case 'dark':
        return '深色模式';
      default:
        return '跟随系统';
    }
  }

  String _fontScaleLabel(double s) {
    if (s <= 0.85) return '小';
    if (s <= 1.0) return '标准';
    if (s <= 1.15) return '大';
    return '超大';
  }

  Future<void> _showFontScaleDialog() async {
    final options = [
      (0.85, '小'),
      (1.0, '标准'),
      (1.15, '大'),
      (1.3, '超大'),
    ];
    await showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('字体大小'),
        children: options.map((o) {
          final (val, label) = o;
          return RadioListTile<double>(
            value: val,
            groupValue: _fontScale,
            title: Text(label, style: TextStyle(fontSize: 14 * val)),
            onChanged: (v) async {
              if (v != null) {
                await AppSettingsService.setFontScale(v);
                setState(() => _fontScale = v);
              }
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}

// ── 辅助 Widget ──────────────────────────────────────────────
class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  const _CountChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count < 0 ? '***' : '$count',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
