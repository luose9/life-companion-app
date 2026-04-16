import 'package:flutter/material.dart';
import 'package:life_companion_app/services/privacy_service.dart';

/// 包裹 HomeScreen：启动时或从后台恢复时触发生物识别验证
class AppLockGuard extends StatefulWidget {
  final Widget child;
  const AppLockGuard({super.key, required this.child});

  @override
  State<AppLockGuard> createState() => _AppLockGuardState();
}

class _AppLockGuardState extends State<AppLockGuard>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 前后台切换：切到后台再返回时重新锁定
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _checkAndLock();
    } else if (state == AppLifecycleState.resumed && _locked) {
      _authenticate();
    }
  }

  Future<void> _init() async {
    final enabled = await PrivacyService.isAppLockEnabled();
    if (enabled) {
      setState(() { _locked = true; _checking = false; });
      await _authenticate();
    } else {
      setState(() { _locked = false; _checking = false; });
    }
  }

  Future<void> _checkAndLock() async {
    final enabled = await PrivacyService.isAppLockEnabled();
    if (enabled) setState(() => _locked = true);
  }

  Future<void> _authenticate() async {
    final ok = await PrivacyService.authenticate();
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    if (_locked) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.blue.shade900,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                const Text('Life Companion',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('应用已锁定',
                    style: TextStyle(color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade900),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('验证身份'),
                  onPressed: _authenticate,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
