# 质量追踪

每次 Agent 完成功能后更新。

## 后端
| 模块 | 测试覆盖率 | 类型完整 | 状态 | 最后更新 |
|---|---|---|---|---|
| schemas/ | 100% | ✅ | ✅ 已建立 | 2026-04-16 |
| repository/ | 100% | ✅ | ✅ 已建立（SQLAlchemy ORM） | 2026-04-17 |
| parsers/（通知解析） | 95% | ✅ | ✅ 已建立（支付宝/微信/银行策略模式） | 2026-04-28 |
| service/ | 95% | ✅ | ✅ 已建立 | 2026-04-16 |
| api/ | 95% | ✅ | ✅ 已建立（含完整 CRUD + 409 错误处理，auth 路径已修复） | 2026-04-27 |
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
|| auth/（登录/注册） | - | ✅ | ✅ 已建立，UI 升级—使用 AppInput/AppButton 设计系统，支持注册（邮箱+密码+确认密码校验） | 2026-04-30 |
| notifications/（通知导入） | ✅ 9/9 | ✅ | ✅ 已建立（支持支付宝/微信/银行解析）→ 新增: Android NotificationListenerService 原生监听器、EventChannel 桥接、自动捕获支付通知 | 2026-04-30 |
| theme/（设计系统） | - | ✅ | ✅ 黑白灰设计系统 | 2026-04-29 |
| widgets/（通用组件） | - | ✅ | ✅ AppCard/Button/Input/Badge/EmptyState/BottomNav（中文标签，Android 系统导航栏自适应 padding） | 2026-04-30 |
| home/（首页仪表盘） | - | ✅ | ✅ 左色条卡片 + 下拉刷新 + 月份导航 | 2026-04-30 |
| bills/（交易列表） | - | ✅ | ✅ 新增编辑功能：点击交易项弹出编辑 Sheet，支持修改分类和备注 | 2026-04-30 |
| categories/（分类管理） | - | ✅ | ✅ Tab切换+网格+CRUD Sheet → 升级: 名称字数上限10字+计数器、颜色选择动画 | 2026-04-30 |
| profile/（个人中心） | - | ✅ | ✅ 用户信息+退出 | 2026-04-29 |
