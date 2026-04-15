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
types/ → repository/ → service/ → api/

- types/：Pydantic 模型，纯数据结构，零依赖
- repository/：数据库操作，只能 import types/
- service/：业务逻辑，只能 import types/ 和 repository/
- api/：FastAPI 路由，可以 import 所有层

## 前端层级规则
types/ → hooks/ → components/ → pages/

- types/：TypeScript interface，零依赖
- hooks/：数据获取逻辑（React Query），只能 import types/
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

## 完成任务后必须做的事
1. 运行 make check（后端）和 make frontend-check（前端）
2. 确认全部通过后才算完成
3. 更新 docs/quality.md 对应模块的状态
4. 如果新增了 API 端点，更新 docs/api.md

## 接到任务时的标准流程
研究（读文档）→ 制定计划（写在 docs/design.md 里）→ 实现 → 验证 → 更新质量文档
