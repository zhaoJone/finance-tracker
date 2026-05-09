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
- **保留：** 缓存回放（`flushCached`）、指纹去重、requestRebind 自动重连（无副作用）、broad package 检测（不限于支付宝/微信）、updateCallback 修复页面重建回掉泄漏
- **附加修复：**
  - BLoC `_applyMatchRules()` 异步漏发射 Bug（缺少 `await` 导致 emit 后规则才应用、UI 不更新）
  - 关键词检测范围从 `title + text` 恢复为 `fullContent`（`title + text + bigText`），防止 EXTRA_BIG_TEXT 中的关键词被漏检

## API 端点

详见 `docs/api.md`。
