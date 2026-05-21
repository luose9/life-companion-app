# Life Companion 🌿

一款注重**反焦虑设计**的个人生活管理 App，帮助你温柔地记录生活、管理目标、追踪情绪，在自我成长的路上不急不躁。本软件由本人借助ai制作

> 所有数据存储在本地，保护你的隐私。

---

## ✨ 功能模块

| 模块 | 说明 |
|------|------|
| **目标管理** | 5 级目标体系（愿景→年→季→周→日），打卡系统，微行动，专注计时器 |
| **爱好探索** | 发现/尝试/习惯化流程，多格式作品集（图片/视频/GIF/音频） |
| **心情记录** | 快速记录 + 5 步详细流程（身体→欲望→情绪→引导→触发），热力图 |
| **日程管理** | 能量标签，优先级限制（每日 3 重要 + 5 普通），自定义提醒 |
| **记账理财** | 收支记录 + 消费感受追踪，分类图表，预算参考 |
| **运动健身** | GPS 路线追踪，身体感受，运动前后心情对比 |
| **娱乐记录** | 搜索豆瓣/iTunes/OpenLibrary，状态追踪，感悟记录 |
| **身体档案** | 睡眠、饮食、健康笔记 |
| **人际关系** | 联系人管理，关系时刻记录 |
| **灵感收集** | 想法、金句、灵感随时捕捉 |
| **感恩日记** | 每日感恩记录，随机回顾 |
| **里程碑** | 人生重要时刻存档 |
| **统计总览** | 多维度数据可视化 |

## 🎨 设计理念

- **反焦虑**：温暖的提示语、任务数量限制、接纳负面情绪的引导
- **零压力模式**：可开启休假模式，暂停所有提醒
- **隐私优先**：数据全部本地存储，支持生物识别锁屏、截图保护
- **个性化**：底部导航栏可自定义 3-5 个模块

## 🛠 技术栈

- **Flutter** (SDK >=3.0.0) + Material Design
- **SQLite** (sqflite) — 本地数据持久化
- **flutter_local_notifications** — 定时提醒
- **flutter_map** + geolocator — 地图与 GPS 追踪
- **cached_network_image** + http — 媒体搜索（豆瓣/iTunes/OpenLibrary）
- **local_auth** — 生物识别应用锁
- **share_plus** / file_picker / image_picker — 分享与文件管理

## 📦 快速开始

### 环境要求
- Flutter SDK >= 3.0.0
- Android SDK (API 21+)
- 一台 Android 设备或模拟器

### 运行

```bash
# 获取依赖
flutter pub get

# 运行调试版
flutter run

# 构建 release APK
flutter build apk --release
```

## 📁 项目结构

```
lib/
├── main.dart              # 入口，主题配置，首页导航
├── models/                # 18 个数据模型
├── data/                  # DAO 层 + 数据库管理 (db_provider.dart)
├── pages/                 # 22 个页面
├── services/              # 7 个服务（设置/通知/隐私/导出/搜索等）
└── widgets/               # 通用组件（图表/应用锁/隐私弹窗）
```

## 📸 截图
<img width="300" src="https://github.com/user-attachments/assets/79caa996-ac94-4d9c-ba2a-e09d87a36b9d" />
<img width="300" src="https://github.com/user-attachments/assets/330b00c8-f906-4489-891e-93cf921d67e4" />




## 📄 License

本项目仅供个人使用和学习参考。
