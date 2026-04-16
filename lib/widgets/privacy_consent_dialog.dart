import 'package:flutter/material.dart';
import 'package:life_companion_app/services/privacy_service.dart';

/// 首次启动时展示隐私政策，用户同意后才进入 App
class PrivacyConsentDialog extends StatelessWidget {
  final VoidCallback onAccepted;
  const PrivacyConsentDialog({super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 禁止返回键关闭
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.blue),
            SizedBox(width: 8),
            Text('隐私说明'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Life Companion 非常重视您的隐私。使用本应用前，请了解以下信息：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _PolicyItem(
                icon: Icons.storage,
                color: Colors.blue,
                title: '本地存储',
                body: '所有数据（目标、心情、日程、账单、运动、娱乐）仅保存在您设备的本地 SQLite 数据库中，不上传至任何服务器。',
              ),
              _PolicyItem(
                icon: Icons.camera_alt,
                color: Colors.orange,
                title: '相机与相册权限',
                body: '仅在您主动更换头像时请求，用于选取或拍摄头像图片，图片路径保存于设备本地。',
              ),
              _PolicyItem(
                icon: Icons.notifications,
                color: Colors.purple,
                title: '通知权限',
                body: '用于发送目标到期提醒和日程提醒，不会在您未主动设置提醒时发送通知。',
              ),
              _PolicyItem(
                icon: Icons.fingerprint,
                color: Colors.green,
                title: '生物识别权限',
                body: '仅在您开启"App 锁"功能时使用，指纹/面容数据由系统安全芯片管理，应用无法获取原始生物特征。',
              ),
              _PolicyItem(
                icon: Icons.share,
                color: Colors.teal,
                title: '数据分享',
                body: '导出与分享功能由您主动触发，数据通过系统分享面板发送，应用不会自动分享任何内容。',
              ),
              const SizedBox(height: 8),
              Text(
                '您可随时在"用户中心 → 隐私说明"中查看本说明，在"数据管理"中导出或清除所有数据。',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 不同意则退出 App
              Navigator.of(context).maybePop();
              // 实际退出行为由调用方处理
            },
            child: const Text('不同意', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await PrivacyService.markLaunchDone();
              Navigator.of(context).pop();
              onAccepted();
            },
            child: const Text('同意并继续'),
          ),
        ],
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _PolicyItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2, right: 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
