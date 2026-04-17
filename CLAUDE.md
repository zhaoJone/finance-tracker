# Finance Tracker — Agent 操作手册

## 项目概述
个人财务追踪器，支持记录收支、分类统计、图表展示。
后端：Python FastAPI + SQLite
前端：React + TypeScript + Vite

## 开始任务前必须做的事
1. 阅读 docs/architecture.md（层级规则，违反会被 CI 拒绝）
2. 阅读 docs/design.md（当前功能设计决策）
3. 阅读 docs/quality.md（了解哪些模块需要改善）
4. 查看已有代码，理解现有实现，不要重复造轮子

## 后端层级规则（单向依赖，不可违反）
schemas/ → repository/ → service/ → api/

- schemas/：Pydantic 模型，纯数据结构，零依赖
- repository/：数据库操作，只能 import schemas/
- service/：业务逻辑，只能 import schemas/ 和 repository/
- api/：FastAPI 路由，可以 import 所有层

## 前端层级规则
schemas/ → hooks/ → components/ → pages/

- schemas/：TypeScript interface，零依赖
- hooks/：数据获取逻辑（React Query），只能 import schemas/
- components/ui/：纯展示组件，无业务逻辑
- components/features/：功能组件，可以 import hooks/ 和 ui/
- pages/：页面组合，可以 import 所有

## 代码约束（违反会被 Linter 拒绝）
- 后端每个文件不超过 300 行
- 前端每个组件不超过 200 行
- 后端所有函数必须有类型注解
- 前端所有 props 必须有 TypeScript interface
- API 错误必须用统一的 ErrorResponse 格式返回
- 禁止在 repository 层写业务逻辑
- 禁止在 component 层直接 fetch，必须通过 hooks/

## 完整任务交付流程（必须严格遵守，不得跳过）

### Step 1：本地验证
```bash
cd backend && make check
cd ../frontend && make frontend-check
```
两者都必须通过，否则继续修复，不得进入下一步。

### Step 2：更新文档
- 更新 docs/quality.md 对应模块的状态
- 如果新增了 API 端点，更新 docs/api.md
- 在 docs/design.md 记录本次实现的关键决策

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
研究（读文档）→ 制定计划（写在 docs/design.md）→ 实现 → 执行完整交付流程

## 操作授权
你被授权在本项目范围内自主完成以下操作，无需每步确认：
- 创建、读取、修改 backend/ 和 frontend/ 下的任何文件
- 在 backend/ 目录运行 make check、pytest、mypy、ruff
- 在 frontend/ 目录运行 npm 相关命令
- 读取 docs/ 下所有文档
- 运行 git add、git commit、git push
- 运行 gh run list、gh run watch、gh run view

每次任务只需在**开始前**和**完成后**向我汇报，中间步骤自主执行。
