# Finance Tracker 设计文档

## 架构概述

本系统采用前后端分离架构：
- **后端**：Python FastAPI + PostgreSQL + SQLAlchemy ORM
- **移动端**：Flutter + BLoC 模式
- **数据库迁移**：Alembic

## 关键设计决策

### 1. 金额单位
所有金额以**分**（整数）存储，避免浮点数精度问题。

### 2. 通知导入
- 通知来源：支付宝、微信、银行
- 策略模式解析通知内容
- 匹配规则表 (`category_match_rules`) 实现自动分类

### 3. 数据库迁移
- 使用 Alembic 管理 schema 变更
- 迁移文件位于 `backend/migrations/versions/`
- 迁移链：`1336ca897ff4` → `add_user_id_columns` → `add_trade_no` → `add_category_match_rules`

### 4. 分类匹配规则
- 表 `category_match_rules` 存储用户自定义的关键词→分类映射
- 匹配优先级：通知指定分类 > 规则匹配 > 默认分类
- 迁移 `add_category_match_rules` 创建该表

### 5. 后端统一通知解析（P0 - 2026-05-09）
- 手机端**去除所有本地正则解析器**（`parseAlipayNotification`、`parseWechatNotification`、`parseBankNotification` 共 ~200 行 Dart 代码）
- 通知原始文本通过 `POST /api/notifications/raw-parse` 发往后端统一解析
- 后端运行 AlipayParser + WeChatParser + BankParser 3 个解析器
- 新增 BankParser（从 Dart 移植，覆盖 6 种银行通知格式）
- 解析失败 → `isUnparsed: true` 标记，显示在列表中等待用户手动处理
- 动机：新增银行格式只需修改后端代码，无需客户端发版
- 新增文件：`backend/src/parsers/bank.py`、`backend/src/parsers/facade.py`、`backend/src/schemas/raw_parse.py`、`backend/src/api/notifications.py`
- 移动端新增：`CloudParseResult` 模型、`parseViaCloud` API 调用
- 后端 `NotificationService` 复用 `parsers.facade.parse_notification()`

### 6. 通知监听架构简化 — 移除前台 Service 保活（2026-05-09）
- **问题：** 前台 Service (`startForeground`) 在 Android 14+ 上不稳定，多次修复（3+ 次）后仍有闪退和监听失效问题
- **方案：** 回退持续监听功能，去掉前台 Service 保活机制，回到简单的 EventChannel + 缓存回放架构
- **变更内容：**
  - `NotificationListener.kt`：移除 `onStartCommand`、`START_STICKY`、`startForegroundService`、`startForeground`、前台通知渠道
  - `notification_listener_bridge.dart`：移除 `_serviceChannel` MethodChannel
  - `MainActivity.kt`：移除 `SERVICE_CHANNEL` MethodChannel 注册
  - `AndroidManifest.xml`：移除 `foregroundServiceType="dataSync"`、`FOREGROUND_SERVICE` 权限
- **保留：** 缓存回放（`flushCached`）、指纹去重、requestRebind 自动重连、broad package 检测、updateCallback
- **附加修复：** BLoC `_applyMatchRules()` await 缺失、关键词检测范围恢复为 `fullContent`

### 7. 通知监听安全加固与代码质量提升（2026-05-09）
- **加密缓存（P0）：** 使用 `EncryptedSharedPreferences`（AES256-GCM）加密存储通知原文，阻止 root 设备或恶意 App 读取明文金融数据
- **日志脱敏（P0）：** `Log.d` 只输出前 16 字符，不暴露完整交易信息（商户名、金额等）
- **静态泄露修复（P0）：** `_MerchantGroup._allNotifications` 静态字段 → 改为方法参数传入
- **指纹淘汰修复（P1）：** `Set.first` → `Queue<String>` + `Set<String>` 双结构，确保淘汰最早指纹
- **Service 销毁保护（P1）：** `onDestroy` 中关闭 `IO_EXECUTOR.shutdownNow()`
- **指纹升级（P2）：** MD5 → SHA-256
- **匹配规则缓存（P2）：** 规则列表缓存到 BLoC，避免每条通知都重新请求
- **类型安全错误处理（P2）：** `_extractError` 从字符串模式匹配改为 `DioException` 类型检查

## API 端点

详见 `docs/api.md`。
