# Life Companion (MVP)

轻量 Flutter 项目骨架，包含目标管理、情感记录+地图、日程提醒与记账模块占位（MVP）。

快速开始：

1. 安装 Flutter（https://flutter.dev/docs/get-started/install）并配置 Android 环境。
2. 进入项目目录并获取依赖：

```bash
cd "d:\软件\life_companion_app"
flutter pub get
flutter run
```

推荐依赖与说明：
- `sqflite` + `path`：本地 SQLite 存储

下一步计划：
- 设计数据模型并实现本地存储（`sqflite`）
- 实现目标管理与日程提醒的本地通知逻辑
