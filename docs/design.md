## Harness 进化日志

| 日期 | Agent 犯的错 | 根因 | Harness 响应 |
|---|---|---|---|
| 2026-04-16 | 目录 src/types/ 与 Python 标准库 types 模块同名 | Python 模块解析规则导致导入歧义 | 目录重命名为 schemas/，Linter 和 CLAUDE.md 同步更新 |
