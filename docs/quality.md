# 质量追踪

每次 Agent 完成功能后更新。

## 后端
| 模块 | 测试覆盖率 | 类型完整 | 状态 | 最后更新 |
|---|---|---|---|---|
| schemas/ | 100% | ✅ | ✅ 已建立 | 2026-04-16 |
| repository/ | 100% | ✅ | ✅ 已建立（SQLAlchemy ORM） | 2026-04-17 |
| parsers/（通知解析） | 95% | ✅ | ✅ P0: 新增 BankParser（6种银行格式），统一 facade 入口 | 2026-05-09 |
| service/ | 95% | ✅ | ✅ 已建立 | 2026-04-16 |
| service/category_matcher.py | 100% | ✅ | ✅ 新增：商户关键词→分类自动匹配 | 2026-05-01 |
| api/ | 95% | ✅ | ✅ 已建立（含完整 CRUD + 409 错误处理，auth 路径已修复） | 2026-04-27 |
| api/imports.py | 65% | ✅ | 🆕 新增：导入端点重构，支持按条指定分类 | 2026-05-01 |
| api/rules.py | 70% | ✅ | 🆕 新增：匹配规则 CRUD | 2026-05-01 |
| api/notifications.py | 85% | ✅ | 🆕 P0: raw-parse 端点，后端统一解析 | 2026-05-09 |
| repository/category_match_rule.py | 100% | ✅ | 🆕 新增：匹配规则持久化 | 2026-05-01 |
| schemas/category_match_rule.py | 100% | ✅ | 🆕 新增：匹配规则 Pydantic 模型 | 2026-05-01 |
| schemas/raw_parse.py | 100% | ✅ | 🆕 P0: raw-parse 请求/响应 Schema | 2026-05-09 |
| config/ | - | ✅ | ✅ 已建立（database, migrations） | 2026-04-17 |
| Docker | - | ✅ | ✅ 已建立（PostgreSQL） | 2026-04-17 |
| Alembic Migration | - | ✅ | ✅ 已建立 | 2026-04-17 |

## 前端
| 模块 | 测试 | TS 严格 | 状态 | 最后更新 |
|---|---|---|---|---|
| schemas/ | ✅ | ✅ | ✅ 已建立 | 2026-04-16 |
| hooks/ | ✅ | ✅ | ✅ 已建立（含 Category CRUD + Transaction update/delete hooks） | 2026-04-30 |
| components/ | - | ✅ | ✅ 已建立（含 CategoryForm） | 2026-04-17 |
| pages/ | - | ✅ | ✅ 已建立（含 CategoriesPage + TransactionsPage 接入编辑/删除） | 2026-04-30 |
| Docker | - | ✅ | ✅ 已建立 | 2026-04-17 |

## 移动端
| 模块 | 测试 | Dart 分析 | 状态 | 最后更新 |
|---|---|---|---|---|
| core/（ApiClient、injection） | - | ✅ | ✅ 已建立 | 2026-04-16 |
| auth/（登录/注册） | - | ✅ | ✅ 已建立，UI 升级—使用 AppInput/AppButton 设计系统，支持注册（邮箱+密码+确认密码校验） | 2026-04-30 |
|| notifications/（通知导入） | ✅ 5/5 | ✅ | ✅ v1.4.4: 安全加固 — EncryptedSharedPreferences、Log.d 脱敏、SHA-256、Queue+Set 淘汰、规则缓存、类型安全错误处理 | 2026-05-09 |
| theme/（设计系统） | - | ✅ | ✅ 黑白灰设计系统 | 2026-04-29 |
| widgets/（通用组件） | - | ✅ | ✅ AppCard/Button/Input/Badge/EmptyState/BottomNav（中文标签，Android 系统导航栏自适应 padding） | 2026-04-30 |
| home/（首页仪表盘） | - | ✅ | ✅ 左色条卡片 + 下拉刷新 + 月份导航 | 2026-04-30 |
| bills/（交易列表） | - | ✅ | ✅ 新增编辑功能：点击交易项弹出编辑 Sheet，支持修改分类和备注 | 2026-04-30 |
| categories/（分类管理） | - | ✅ | ✅ Tab切换+网格+CRUD Sheet → 升级: 名称字数上限10字+计数器、颜色选择动画 | 2026-04-30 |
| profile/（个人中心） | - | ✅ | ✅ 用户信息+退出 | 2026-04-29 |
