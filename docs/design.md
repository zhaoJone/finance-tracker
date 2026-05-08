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

## API 端点

详见 `docs/api.md`。
