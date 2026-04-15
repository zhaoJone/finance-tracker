# 架构文档

## 后端层级
types/ → repository/ → service/ → api/

| 层 | 文件位置 | 职责 |
|---|---|---|
| types | backend/src/types/ | Pydantic 模型：Transaction, Category, User |
| repository | backend/src/repository/ | SQLite CRUD，返回 domain 对象 |
| service | backend/src/service/ | 业务逻辑：统计、分类汇总、余额计算 |
| api | backend/src/api/ | FastAPI 路由，请求验证，响应格式化 |

## 前端层级
types/ → hooks/ → components/ → pages/

## 核心领域模型
- Transaction：id, amount, category_id, note, date, type(income/expense)
- Category：id, name, color, icon, type(income/expense)

## API 约定
- 所有成功响应：{ data: T, message: string }
- 所有错误响应：{ error: string, code: string, detail?: string }
- 日期格式：ISO 8601（YYYY-MM-DD）
- 金额单位：分（整数），前端显示时除以 100
