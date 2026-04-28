# Finance Tracker — Agent 操作手册

## 项目概述
个人财务追踪器，支持记录收支、分类统计、图表展示。

| 端 | 技术栈 | 路径 |
|----|--------|------|
| 后端 | Python FastAPI + PostgreSQL + Alembic | `backend/` |
| Web 前端 | React + TypeScript + Vite | `frontend/` |
| 移动端 | Flutter + Dart + flutter_bloc | `mobile_app/` |

## 开始任务前必须做的事
1. 阅读 `docs/architecture.md`（层级规则，违反会被 CI 拒绝）
2. 阅读 `docs/design.md`（当前功能设计决策）
3. 阅读 `docs/quality.md`（了解哪些模块需要改善）
4. 查看已有代码，理解现有实现，不要重复造轮子

## 项目结构

```
finance-tracker/
├── backend/               # Python FastAPI 后端
│   └── src/
│       ├── schemas/       # Pydantic 模型（零依赖）
│       ├── repository/    # 数据库操作
│       ├── service/       # 业务逻辑
│       └── api/           # FastAPI 路由
├── frontend/              # React Web 前端
│   └── src/
│       ├── schemas/       # TypeScript interface
│       ├── hooks/         # React Query 数据获取
│       ├── components/    # UI 组件（ui/ + features/）
│       └── pages/         # 页面
├── mobile_app/            # Flutter 移动端
│   └── lib/
│       ├── core/          # API client、配置、依赖注入
│       └── features/      # 功能模块（auth/、home/、notifications/）
│           └── [feature]/
│               ├── data/          # Repository + Models
│               └── presentation/  # BLoC + Pages
├── docs/                  # 项目文档
│   ├── architecture.md    # 层级架构规范
│   ├── design.md          # UI/UX 设计规范
│   └── quality.md         # 模块质量状态
└── DESIGN.md             # 已废弃 → 移至 docs/design.md
```

## 后端层级规则（单向依赖，不可违反）
schemas/ → repository/ → service/ → api/

- `schemas/`：Pydantic 模型，纯数据结构，零依赖
- `repository/`：数据库操作，只能 import schemas/
- `service/`：业务逻辑，只能 import schemas/ 和 repository/
- `api/`：FastAPI 路由，可以 import 所有层

## Web 前端层级规则
schemas/ → hooks/ → components/ → pages/

- `schemas/`：TypeScript interface，零依赖
- `hooks/`：数据获取逻辑（React Query），只能 import schemas/
- `components/ui/`：纯展示组件，无业务逻辑
- `components/features/`：功能组件，可以 import hooks/ 和 ui/
- `pages/`：页面组合，可以 import 所有

## 移动端层级规则（Flutter BLoC 模式）

```
models/ → repositories/ → blocs/ → pages/
```

- `lib/core/`：API client（`ApiClient`）、配置文件、依赖注入（`injection.dart`）
- `lib/features/[name]/data/`：Dart Model + Repository，解析 API 响应
- `lib/features/[name]/presentation/`：BLoC（事件/状态）+ Page 页面组件
- **BLoC 内只做状态管理**，业务逻辑放在 Repository
- **禁止在 Page 内直接调用 ApiClient**，必须通过 BLoC

### 移动端目录规范
```
lib/
├── core/
│   ├── api_client.dart      # HTTP client，统一拦截 token
│   ├── api_config.dart      # API 域名、路径配置
│   └── injection.dart       # 依赖注入容器（get_it）
└── features/
    └── [feature_name]/
        ├── data/
        │   ├── [feature]_models.dart    # Dart data class
        │   └── [feature]_repository.dart # 数据操作
        └── presentation/
            ├── [feature]_bloc.dart       # BLoC 逻辑
            ├── [feature]_event.dart      # 事件定义
            ├── [feature]_state.dart      # 状态定义
            └── [feature]_page.dart       # 页面 UI
```

## 代码约束（违反会被 Linter 拒绝）

### 后端
- 每个文件不超过 300 行
- 所有函数必须有类型注解
- 禁止在 repository 层写业务逻辑

### Web 前端
- 每个组件不超过 200 行
- 所有 props 必须有 TypeScript interface
- 禁止在 component 层直接 fetch，必须通过 hooks/

### 移动端
- 每个 Dart 文件不超过 300 行
- 所有函数/方法必须有类型注解
- 所有 BLoC Event 和 State 必须有完整的类型定义
- 禁止在 Page 内直接调用 `ApiClient`，必须通过 BLoC
- 金额单位统一使用**分**（整数），与后端保持一致
- 解析器（Parser）与交易创建器（TransactionCreator）必须解耦

## 完整任务交付流程（必须严格遵守，不得跳过）

### Step 1：本地验证
```bash
# 后端
cd backend && make check

# Web 前端
cd ../frontend && make frontend-check

# 移动端（需先配置 Android SDK / XCode）
cd ../mobile_app && flutter analyze
```

三者都必须通过，否则继续修复，不得进入下一步。

### Step 2：更新文档
- 更新 `docs/quality.md` 对应模块的状态
- 如果新增了 API 端点，更新 `docs/api.md`
- 在 `docs/design.md` 记录本次实现的关键决策

### Step 3：提交代码
```bash
git add -A
git commit -m "feat: <一句话描述本次任务内容>"
git push origin main
```

### Step 4：监控 CI 直到结果明确
```bash
# 等待 CI 启动
sleep 15

# 查看最新运行状态
gh run list --limit 1

# 实时等待并显示结果
gh run watch
```

### Step 5：处理 CI 结果

**CI 通过时：**
向我汇报，格式如下：
```
✅ 任务完成
本地检查：通过
CI 状态：通过
CI 链接：https://github.com/<repo>/actions/runs/<id>
```

**CI 失败时：**
```bash
# 获取失败日志
gh run view --log-failed
```
- 分析第一个 ERROR（忽略后续连锁错误）
- 本地复现并修复
- 重新从 Step 1 开始，直到 CI 绿色
- 不得在 CI 失败状态下向我汇报完成
- 严禁通过降低覆盖率要求或跳过测试来让 CI 通过

## 接到任务时的标准流程
研究（读文档）→ 制定计划（写在 `docs/design.md`）→ 实现 → 执行完整交付流程

## 操作授权
你被授权在本项目范围内自主完成以下操作，无需每步确认：
- 创建、读取、修改 `backend/`、`frontend/`、`mobile_app/` 下的任何文件
- 在 `backend/` 目录运行 `make check`、`pytest`、`mypy`、`ruff`
- 在 `frontend/` 目录运行 npm 相关命令
- 在 `mobile_app/` 目录运行 `flutter analyze`、`flutter test`
- 读取 `docs/` 下所有文档
- 运行 `git add`、`git commit`、`git push`
- 运行 `gh run list`、`gh run watch`、`gh run view`

每次任务只需在**开始前**和**完成后**向我汇报，中间步骤自主执行。

## 移动端开发注意事项

### 环境要求
- Flutter SDK 3.24.5 stable（`/opt/data/home/flutter/bin/flutter`）
- Android SDK（平台工具、platforms;android-34、build-tools;34.0.0）
- Java 17（JDK）

### 构建 APK
```bash
cd mobile_app
flutter pub get
flutter build apk --debug

# APK 输出路径
# mobile_app/build/app/outputs/flutter-apk/app-debug.apk
```

### API 认证
- 登录后后端返回 JWT token
- 移动端通过 `ApiClient` 自动注入 `Authorization: Bearer <token>` 请求头
- Token 过期时跳转到登录页

### 通知解析策略模式
支持支付宝、微信、银行三种通知来源，通过 `NotificationType` enum 统一标识：
```dart
enum NotificationType { alipay, wechat, bank }
```
新增通知类型时：
1. 在 `notification_models.dart` 的 `NotificationType` 中添加枚举值
2. 在 `notification_import_repository.dart` 中添加对应的解析方法
3. 在 `notification_import_bloc.dart` 中添加对应的事件处理
4. 单元测试覆盖新增解析逻辑
