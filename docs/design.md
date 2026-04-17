## Harness 进化日志

| 日期 | Agent 犯的错 | 根因 | Harness 响应 |
|---|---|---|---|
| 2026-04-16 | 目录 src/types/ 与 Python 标准库 types 模块同名 | Python 模块解析规则导致导入歧义 | 目录重命名为 schemas/，Linter 和 CLAUDE.md 同步更新 |

## Docker 部署设计决策

| 日期 | 决策 | 理由 |
|---|---|---|
| 2026-04-17 | 后端使用 python:3.12-alpine 多阶段构建 | 保持镜像小巧，非 root 用户运行 |
| 2026-04-17 | 前端使用 node:20-alpine + nginx:alpine 多阶段构建 | 前端构建依赖 Node.js，生产只运行 Nginx |
| 2026-04-17 | SQLite 持久化到 /app/data/finance.db | Docker 容器内数据不丢失，挂载 host 目录 |
| 2026-04-17 | /api/ 通过 nginx 反向代理到 backend:8000/api/ | 前后端分离，Nginx 统一入口 |
| 2026-04-17 | 后端 healthcheck 使用 /api/health 端点 | 避免与前端路由冲突 |
| 2026-04-17 | 暴露端口 8080 而非 80 | 本地端口 80 已被占用 |
