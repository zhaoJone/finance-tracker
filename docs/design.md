### Phase 6：用户认证模块

#### 6.1 需求
- 用户使用邮箱 + 密码注册/登录
- 所有账单(Transaction)和分类(Category)必须属于某个用户
- JWT Token 认证，Token 通过 HTTP Bearer 头传递

#### 6.2 数据库改造
**新增表：** `users`
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | PK |
| email | VARCHAR(255) | 唯一索引 |
| password_hash | VARCHAR(255) | bcrypt 哈希 |
| created_at | DATETIME | 创建时间 |

**修改表：** `categories` → 新增 `user_id` 列（外键 → users.id）
**修改表：** `transactions` → 新增 `user_id` 列（外键 → users.id）

#### 6.3 后端模块

| 文件 | 说明 |
|------|------|
| `schemas/user.py` | User, UserCreate, UserLogin, Token, TokenData |
| `repository/user.py` | create, get_by_email, get_by_id |
| `service/auth.py` | hash_password, verify_password, create_access_token |
| `api/auth.py` | POST /auth/register, POST /auth/login, GET /auth/me |
| `api/dependencies.py` | get_current_user 依赖（从 JWT 提取 user_id）|
| `alembic/` | 新迁移文件 |

**认证流程：**
1. `/auth/register` → 验证邮箱唯一 → 哈希密码 → 创建用户 → 返回 JWT
2. `/auth/login` → 验证邮箱存在 → 验证密码 → 返回 JWT
3. 所有业务 API → `get_current_user` 提取 Bearer Token → 注入 `user_id` 到请求

#### 6.4 前端模块

| 文件 | 说明 |
|------|------|
| `schemas/user.ts` | TS interfaces |
| `hooks/useAuth.ts` | login, logout, currentUser 状态 |
| `pages/LoginPage.tsx` | 登录/注册表单 |
| `App.tsx` | /login 路由 + ProtectedRoute |
| `api/client.ts` | axios 拦截器注入 Token |

#### 6.5 影响范围

|| 文件 | 改动类型 |
||------|----------|
|| `backend/src/schemas/user.py` | 新建 |
|| `backend/src/repository/user.py` | 新建 |
|| `backend/src/service/auth.py` | 新建 |
|| `backend/src/api/auth.py` | 新建 |
|| `backend/src/api/dependencies.py` | 修改 |
|| `backend/src/repository/models.py` | 修改（加 user_id 外键）|
|| `backend/src/api/categories.py` | 修改（加 user_id 过滤）|
|| `backend/src/api/transactions.py` | 修改（加 user_id 过滤）|
|| `backend/src/api/stats.py` | 修改（加 user_id 过滤）|
|| `backend/alembic/versions/` | 新迁移文件 |
|| `frontend/src/schemas/user.ts` | 新建 |
|| `frontend/src/hooks/useAuth.ts` | 新建 |
|| `frontend/src/pages/LoginPage.tsx` | 新建 |
|| `frontend/src/api/client.ts` | 新建 |
|| `frontend/src/App.tsx` | 修改 |
|| `frontend/src/pages/*.tsx` | 修改（添加登录校验）|

## Harness 进化日志

| 日期 | Agent 犯的错 | 根因 | Harness 响应 |
|---|---|---|---|
| 2026-04-16 | 目录 src/types/ 与 Python 标准库 types 模块同名 | Python 模块解析规则导致导入歧义 | 目录重命名为 schemas/，Linter 和 CLAUDE.md 同步更新 |

## PostgreSQL 迁移实施计划

| 日期 | 决策 | 理由 |
|---|---|---|
| 2026-04-17 | 后端使用 python:3.12-alpine 多阶段构建 | 保持镜像小巧，非 root 用户运行 |
| 2026-04-17 | 前端使用 node:20-alpine + nginx:alpine 多阶段构建 | 前端构建依赖 Node.js，生产只运行 Nginx |
| 2026-04-17 | SQLite 持久化到 /app/data/finance.db | Docker 容器内数据不丢失，挂载 host 目录 |
| 2026-04-17 | /api/ 通过 nginx 反向代理到 backend:8000/api/ | 前后端分离，Nginx 统一入口 |
| 2026-04-17 | 后端 healthcheck 使用 /api/health 端点 | 避免与前端路由冲突 |
| 2026-04-17 | 暴露端口 8080 而非 80 | 本地端口 80 已被占用 |
| 2026-04-17 | 数据库迁移至 PostgreSQL + Alembic | 支持生产环境部署，版本化管理数据库结构 |
| 2026-04-17 | 单元测试保留 SQLite+aiosqlite | CI 环境不依赖真实 PostgreSQL |

### 子任务 1.1：依赖更新
**文件：** `backend/pyproject.toml`
- 添加：`asyncpg`、`alembic`、`sqlalchemy[asyncio]`
- 保留测试依赖：`aiosqlite`（用于测试环境 SQLite 内存库）

### 子任务 1.2：数据库连接层
**新建文件：** `backend/src/config/database.py`
- 通过环境变量 `DATABASE_URL` 读取连接字符串
- 默认值：`postgresql+asyncpg://postgres:mysecretpassword@127.0.0.1:5432/finance_tracker`
- 提供 `get_db()` 依赖注入函数供 FastAPI 使用

### 子任务 1.3：SQLAlchemy ORM 模型
**新建文件：** `backend/src/repository/models.py`
- Table：`transactions`、`categories`
- 与现有 Pydantic schemas 字段一致
- **注意：** Category 表当前无 icon 字段（与 schema 定义不一致），迁移时保持现状

### 子任务 1.4：Repository 层改造
**改造文件：** `backend/src/repository/transaction.py`、`backend/src/repository/category.py`
- 内部实现从 aiosqlite raw SQL 切换至 SQLAlchemy async session
- **接口（方法签名）保持不变**，service 层零改动

### 子任务 2： Alembic Migration
**新建目录：** `backend/migrations/`
- `alembic.ini`：sqlalchemy.url 从环境变量读取
- `migrations/env.py`：导入 SQLAlchemy models，支持 autogenerate
- `migrations/script.py.mako`：标准模板

**Makefile 新增命令：**
```makefile
migrate:          # alembic upgrade head
migrate-new:      # alembic revision --autogenerate -m "$(msg)"
migrate-down:     # alembic downgrade -1
migrate-history:  # alembic history
```

**FastAPI lifespan 改造：**
```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    run_migrations()  # 启动时自动 upgrade head
    yield
```

### 子任务 3：Docker Compose 更新
**文件：** `docker-compose.yml`
- 新增 `postgres` service（postgres:16-alpine）
- 移除 `./data` volume，改用 `postgres_data` named volume
- backend depends_on postgres healthcheck
- backend 环境变量注入 DATABASE_URL

### 子任务 4：前端全面汉化
**汉化范围：** 所有用户可见文字
- 页面标题、导航菜单
- 表单 label、placeholder、按钮文字
- 错误提示、空状态提示、加载状态
- 图表坐标轴标签、图例
- 金额格式：¥X,XXX.XX（替换 $）
- 日期格式：YYYY年MM月DD日

**不汉化：** 代码变量名、函数名、console.log、API 路径

### 子任务 5：Category 管理功能

#### 5.1 后端 API 补全
**文件：** `backend/src/api/categories.py`

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/categories` | GET | 按 type 分组返回 |
| `/api/categories` | POST | 创建分类 |
| `/api/categories/{id}` | PUT | 更新名称/颜色 |
| `/api/categories/{id}` | DELETE | 删除（有关联交易返回 409）|

**DELETE 409 场景：** 查询 `transactions` 表中是否有 `category_id = target_id`，有则返回冲突错误。

#### 5.2 前端页面
**新建：** `frontend/src/pages/CategoriesPage.tsx`
**新建：** `frontend/src/components/features/CategoryForm.tsx`（Drawer/Modal）

**UI 规格：**
- Tab 分组：收入类 / 支出类
- 分类卡片：色块 + 名称 + 关联交易数量 + 编辑/删除图标
- 新增按钮：页面右上角「+ 新增分类」
- 空状态：插画 + 文字「暂无分类，点击右上角添加」

**CategoryForm 字段：**
1. 分类名称（必填，最多 10 字，实时字数）
2. 类型（收入/支出，编辑时不可更改）
3. 颜色选择器：12 个预设色块，选中态高亮 + 实时预览卡片

**删除确认逻辑：**
- 有关联交易：Toast 提示「该分类下有 X 笔交易，无法删除」
- 无关联交易：二次确认弹窗

**TransactionForm 改造：**
- 分类下拉框末尾加「+ 管理分类」入口

#### 5.3 导航入口
**文件：** `frontend/src/App.tsx`
- 新增「分类管理」菜单项（图标用标签图标）

### 影响范围分析

| 文件 | 改动类型 | 说明 |
|------|----------|------|
| `backend/pyproject.toml` | 修改 | 新增 3 个依赖 |
| `backend/src/config/database.py` | 新建 | 数据库连接层 |
| `backend/src/repository/models.py` | 新建 | SQLAlchemy ORM 模型 |
| `backend/src/repository/transaction.py` | 重写 | 内部实现换 SQLAlchemy |
| `backend/src/repository/category.py` | 重写 | 内部实现换 SQLAlchemy |
| `backend/src/api/categories.py` | 扩展 | 补全 POST/PUT/DELETE |
| `backend/src/api/main.py` | 修改 | lifespan 改用 Alembic |
| `backend/alembic.ini` | 新建 | Alembic 配置 |
| `backend/migrations/` | 新建 | Alembic 迁移脚本 |
| `backend/Makefile` | 修改 | 新增 migrate 命令 |
| `docker-compose.yml` | 修改 | 新增 postgres service |
| `frontend/src/App.tsx` | 修改 | 新增导航入口 |
| `frontend/src/pages/CategoriesPage.tsx` | 新建 | 分类管理页面 |
| `frontend/src/components/features/CategoryForm.tsx` | 新建 | 分类表单组件 |
| `frontend/src/pages/TransactionsPage.tsx` | 修改 | 分类下拉增加管理入口 |
| `frontend/src/pages/DashboardPage.tsx` | 修改 | 汉化 |
| `frontend/src/components/features/*.tsx` | 修改 | 汉化 |
