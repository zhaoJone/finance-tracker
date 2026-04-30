# Finance Tracker 设计规范

## 概述

简洁高效的个人记账应用 UI/UX 设计规范，供 AI 编码助手（Claude Code 等）参考。

---

## 设计原则

1. **黑白为主**：主色调使用深灰（`gray-900`），避免蓝色/紫色/粉色等亮色系
2. **克制的卡片感**：依赖圆角 + 阴影营造层次，避免粗边框
3. **交互反馈**：按钮带点击反馈，hover 有阴影变化
4. **空状态引导**：空数据时显示图标 + 说明文案，而非纯文字

---

## 色彩系统

### 主色调（灰度色阶）

| Token | Hex | 用途 |
|-------|-----|------|
| `gray-900` | `#111827` | 主按钮、页面标题、深色文字 |
| `gray-800` | `#1F2937` | 按钮 hover |
| `gray-700` | `#374151` | 输入标签、标注文字 |
| `gray-600` | `#4B5563` | Ghost 按钮、类型标签 |
| `gray-500` | `#6B7280` | 次要文字、未激活导航、加载提示、空状态标题 |
| `gray-400` | `#9CA3AF` | 禁用/提示文字、次要说明、分类圆点fallback |
| `gray-300` | `#D1D5DB` | 输入框/选择框边框 |
| `gray-200` | `#E5E7EB` | 分类卡片边框、导航底部分割线 |
| `gray-100` | `#F3F4F6` | 卡片边框、次要按钮背景、空状态图标背景 |
| `gray-50` | `#F9FAFB` | 登录/注册页背景、分类类型标签背景 |

### 语义色

| 语境 | Hex | 用途 |
|------|-----|------|
| 收入 | `#16A34A` (green-600) / `#22C55E` (green-500) | 收入金额文字 / 收入强调条 |
| 支出 | `#EF4444` (red-500) / `#DC2626` (red-600) | 支出金额 / 危险按钮 |
| 结余（正） | `#2563EB` (blue-600) / `#3B82F6` (blue-500) | 余额文字 / 强调条 |
| 结余（负） | `#EF4444` (red-500) | 余额文字（赤字） |

### 标签变体色

| 变体 | 背景 | 文字 |
|------|------|------|
| default | `#F3F4F6` | `#1F2937` |
| success | `#DCFCE7` | `#166534` |
| warning | `#FEF9C3` | `#854D0E` |
| error | `#FEE2E2` | `#991B1B` |
| info | `#DBEAFE` | `#1E40AF` |

### 图表色

- 收入线：`#10B981`
- 支出线：`#EF4444`
- 结余线：`#3B82F6`
- 饼图8色调色板：`#3B82F6`, `#10B981`, `#F59E0B`, `#EF4444`, `#8B5CF6`, `#EC4899`, `#06B6D4`, `#84CC16`

### 分类预设色（12色）

```dart
const presetColors = [
  Color(0xFFFF6B6B), Color(0xFFFF8E53), Color(0xFFFFCD56), Color(0xFF4ECDC4),
  Color(0xFF45B7D1), Color(0xFF6C5CE7), Color(0xFFA29BFE), Color(0xFFFD79A8),
  Color(0xFFF8B500), Color(0xFF00B894), Color(0xFFE17055), Color(0xFF74B9FF),
];
```

---

## Web 前端规范

### Button

```tsx
// 基础样式
"inline-flex items-center justify-center font-medium rounded-lg transition-all duration-150
 focus:outline-none focus:ring-2 focus:ring-offset-2
 disabled:opacity-50 disabled:cursor-not-allowed
 active:scale-[0.98]"

// Primary
"bg-gray-900 text-white hover:bg-gray-800 focus:ring-gray-500 shadow-sm hover:shadow"

// Secondary / Outline / Ghost
"bg-gray-100 text-gray-900 hover:bg-gray-200 focus:ring-gray-500"
"border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus:ring-gray-500"
"text-gray-600 hover:bg-gray-100 focus:ring-gray-500"

// Danger
"bg-red-600 text-white hover:bg-red-700 focus:ring-red-500 shadow-sm hover:shadow"
```

### Card（页面内容块）

```tsx
className="bg-white p-5 rounded-xl border border-gray-100 shadow-sm"
```

### 卡片 hover 效果

```tsx
className="... hover:shadow-md hover:border-gray-200 transition-all duration-150"
```

### Badge

```tsx
// 圆角药丸形
className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold tracking-wide"

// 变体
default: "bg-gray-100 text-gray-800"
success: "bg-green-100 text-green-800"
warning: "bg-yellow-100 text-yellow-800"
error: "bg-red-100 text-red-800"
info: "bg-blue-100 text-blue-800"
```

### Input / Select

```tsx
className="px-3 py-2 border border-gray-300 rounded-lg text-sm
 focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-gray-900
 transition-colors"
```

### 空状态组件

```tsx
<div className="flex flex-col items-center justify-center py-12 text-center
  bg-white rounded-xl border border-gray-100 shadow-sm">
  <div className="w-12 h-12 mb-4 rounded-full bg-gray-100 flex items-center justify-center">
    {/* Heroicons outline 图标，strokeWidth={1.5} */}
    <svg className="w-6 h-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="..." />
    </svg>
  </div>
  <p className="text-gray-500 font-medium">暂无XXX</p>
  <p className="text-gray-400 text-sm mt-1">引导说明文案</p>
</div>
```

---

## 页面布局规范（Web）

### TransactionsPage 筛选器

```tsx
<div className="grid grid-cols-1 md:grid-cols-3 gap-4
  bg-white p-5 rounded-xl border border-gray-100 shadow-sm">
  {/* Select + Select + Month Input */}
</div>
```

### 表单容器

```tsx
<div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
  <TransactionForm className="space-y-5" />
</div>
```

---

## 已知 Bug 与解决

### TransactionForm categoryId 初始为空

**问题**：首次打开表单时 `categoryId=""`，`!categoryId` 为 true 导致"创建"按钮永远禁用。

**原因**：当 `type="expense"` 时 `filteredCategories` 只有一个"支出"分类，但 `categoryId` 未自动同步。

**解法**：使用 `effectiveCategoryId` 计算属性，自动选中 `filteredCategories` 中唯一的分类。

```tsx
const effectiveCategoryId = (() => {
  if (categoryId && filteredCategories.some((c) => c.id === categoryId)) return categoryId;
  if (filteredCategories.length === 1) return filteredCategories[0].id;
  if (categoryId === "" && filteredCategories.length > 0) return filteredCategories[0].id;
  return categoryId;
})();
```

### MonthlyChart 数据结构

**问题**：`/api/stats/monthly` 返回单月对象 `{ year, month, income, expense }`，不是数组。

**解法**：Dashboard 中包装为数组传入：`data={[monthlyData]}`

### Vite Proxy 配置

**问题**：前端独立运行时 API 请求（`/api/*`）需要代理到后端。

**配置**（`vite.config.ts`）：

```ts
server: {
  proxy: {
    "/api": {
      target: "http://localhost:8000",
      changeOrigin: true,
    },
  },
},
```

---

## API 端点

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/health | 健康检查 |
| GET | /api/categories | 分类列表（返回 `{income: [], expense: []}`） |
| POST | /api/categories | 创建分类 |
| PUT | /api/categories/{id} | 更新分类 |
| DELETE | /api/categories/{id} | 删除分类（有交易的分类返回409） |
| GET | /api/transactions | 交易列表（支持 type, category_id, start_date, end_date 筛选） |
| POST | /api/transactions | 创建交易 |
| PUT | /api/transactions/{id} | 更新交易 |
| DELETE | /api/transactions/{id} | 删除交易 |
| GET | /api/stats/monthly?year=&month= | 月度统计（返回单对象） |
| GET | /api/stats/by-category?start_date=&end_date= | 分类统计 |
| POST | /api/auth/register | 注册（JSON: email, password） |
| POST | /api/auth/login | 登录（form-urlencoded: email, password） |
| GET | /api/auth/me | 当前用户 |

所有 API 响应格式：`{ data: T, message: string }`

---

## 移动端设计规范（Flutter）

> 以下为移动端专用的 UI/UX 设计规范，继承同上的黑白灰设计哲学。

### M.1 导航架构

使用 **Bottom Navigation Bar（底部导航）**，固定4个主Tab：

```
┌─────────────────────┐
│   [页面内容区]       │
│                     │
│                     │
├─────────────────────┤
│ 📊  🧾  📁  👤    │  ← BottomNavigationBar
│ 首页  账单  分类  我的  │
└─────────────────────┘
```

各 Tab 功能：
| Tab | 页面 | 说明 |
|-----|------|------|
| 📊 首页 | DashboardPage | 本月收支概览 + 图表 |
| 🧾 账单 | BillsPage / TransactionList | 交易列表 + 筛选 + 添加 |
| 📁 分类 | CategoriesPage | 分类管理 |
| 👤 我的 | ProfilePage / Settings | 用户信息 + 设置 + 退出 |

### M.2 首页（Dashboard）

```
┌──────────────────────┐
│ 🔙 仪表盘    4月     │  ← AppBar（标题+月份标签）
├──────────────────────┤
│ ┌────┐ ┌────┐ ┌────┐│  ← 三张统计卡片（水平滚动）
│ │收入 │ │支出 │ │结余 ││
│ │¥***│ │¥***│ │¥***││
│ └────┘ └────┘ └────┘│
│                      │
│ ┌ 月度趋势 ────────┐ │  ← 折线图卡片
│ │   📈             │ │
│ └──────────────────┘ │
│                      │
│ ┌ 分类统计 ────────┐ │  ← 饼图卡片
│ │   🥧             │ │
│ │ 餐饮 40%         │ │
│ └──────────────────┘ │
│                      │
│ ┌ 最近交易 ────────┐ │  ← 最近5条交易（列表）
│ │ 🍜 午餐  -¥30   │ │
│ │ 🚌 公交  -¥2    │ │
│ └──────────────────┘ │
└──────────────────────┘
```

**交互行为：**
- 统计卡片：水平滑动切换月份（左滑=上月，右滑=下月）
- 下拉刷新：重新加载所有数据
- 点击交易项 → 跳转到详情/编辑
- 点击图表区域 → 跳转到完整报表

### M.3 账单/交易列表（Transactions）

```
┌──────────────────────┐
│ 🔙 账单      [+添加]│  ← AppBar（标题+添加按钮）
├──────────────────────┤
│ 筛选栏（可折叠）      │
│ [全部类型 ▾] [本月 ▾] │  ← FilterChips 或 Segmented
├──────────────────────┤
│ 2026年04月28日       │  ← 日期分组标题
│ ┌ 🍜 麦当劳  -¥128 │ │
│ │        午餐  ¥128│ │
│ ├──────────────────┤ │
│ │ 🚌 公交卡  -¥2   │ │  ← 交易项：图标+名称+金额
│ │        交通      │ │
│ └──────────────────┘ │
│                      │
│ 2026年04月27日       │
│ ┌ 💼 工资   +¥5000 │ │
│ │        收入      │ │
│ └──────────────────┘ │
└──────────────────────┘
```

**交互行为：**
- 下拉刷新：重新加载交易列表
- 点击交易项 → 底部弹出详情 Sheet（Edit/Delete）
- 滑动删除 → 左滑显示红色"删除"按钮
- 点击"+添加" → 打开添加交易表单（全屏或底部 Sheet）
- 筛选栏支持：类型（全部/收入/支出）、分类、日期范围
- 空状态：显示收据图标 + "暂无交易记录" + "点击右上角 + 添加第一笔交易"

### M.4 添加/编辑交易

```
┌──────────────────────┐
│ 🔙 添加交易    [保存]│  ← AppBar
├──────────────────────┤
│                      │
│    ┌──────────────┐  │
│    │   ¥ 0.00     │  │  ← 金额输入（大号，数字键盘）
│    └──────────────┘  │
│                      │
│ 类型                  │
│ [支出 🔴]  [收入 🟢]  │  ← SegmentedButton
│                      │
│ 分类                  │
│ ┌────┬────┬────┬────┐│  ← 分类网格（2行×4列）
│ │🍜  │🚌  │🛒  │💊 ││
│ │餐饮 │交通 │购物 │医疗││
│ ├────┼────┼────┼────┤│
│ │🎮  │📦  │💰  │📄 ││
│ │娱乐 │日用 │投资 │其他││
│ └────┴────┴────┴────┘│
│                      │
│ 日期                  │
│ [2026年04月28日 ▾]    │  ← 日期选择器
│                      │
│ 备注                  │
│ [________________]    │  ← 文本输入（可选）
└──────────────────────┘
```

**交互行为：**
- 金额输入：聚焦即弹出数字键盘（仅数字、小数点）
- 类型切换：切换后自动过滤对应类型的分类
- 分类选择：点击选中，高亮边框
- 日期选择：底部弹出 DatePicker
- 备注：可选字段
- 保存：验证金额>0、分类已选 → 提交 → 关闭并刷新列表
- 编辑模式：预填现有数据

### M.5 分类管理

```
┌──────────────────────┐
│ 🔙 分类管理  [+新增] │  ← AppBar
├──────────────────────┤
│ [支出]  [收入]        │  ← TabBar
├──────────────────────┤
│ ┌──────┬──────┬──────┐│  ← 分类网格（3列）
│ │ 🍜   │ 🚌   │ 🛒   ││
│ │ 餐饮  │ 交通  │ 购物 ││
│ │  ¥***│  ¥***│  ¥***││
│ ├──────┼──────┼──────┤│
│ │ 💊   │ 🎮   │ 📄   ││
│ │ 医疗  │ 娱乐  │ 其他 ││
│ │  ¥***│  ¥***│  ¥***││
│ └──────┴──────┴──────┘│
└──────────────────────┘
```

**交互行为：**
- Tab 切换：支出 / 收入
- 长按分类 → 进入编辑模式（编辑/删除）
- 点击"+新增" → 弹出新增分类底部 Sheet
  - 名称输入（最多10字，显示字数）
  - 颜色选择（预设12色圆点网格）
- 删除分类：弹出确认对话框
  - 如有关联交易 → 提示无法删除（返回409）
- 分类卡片显示该分类本月总金额

### M.6 登录/注册

```
┌──────────────────────┐
│                      │
│                      │
│     Finance Tracker   │  ← Logo/标题
│                      │
│  ┌─────────────────┐ │
│  │ ✉️ example@...  │ │  ← 邮箱输入
│  └─────────────────┘ │
│                      │
│  ┌─────────────────┐ │
│  │ 🔒 ********      │ │  ← 密码输入（可切换可见）
│  └─────────────────┘ │
│                      │
│  ┌─────────────────┐ │
│  │     登 录        │ │  ← Primary 按钮（全宽）
│  └─────────────────┘ │
│                      │
│  没有账号？[注册]      │  ← 注册链接
│                      │
└──────────────────────┘
```

**交互行为：**
- 表单居中布局
- 输入验证：邮箱格式、密码非空
- 错误提示：红色 SnackBar（"邮箱或密码错误"）
- 登录成功 → 自动跳转到首页
- 点击"注册" → 切换到注册页面

### M.7 交互与反馈规范

| 交互 | 行为 |
|------|------|
| 按钮点击 | `scale(0.98)` 缩放动画，150ms duration |
| 页面切换 | 默认 Material PageRoute（滑动进入） |
| 加载中 | 居中 CircularProgressIndicator |
| 下拉刷新 | RefreshIndicator |
| 滑动删除 | Dismissible 组件，红色背景 + 删除图标 |
| 空状态 | 48px 圆形容器 + 24px 图标 + 标题 + 说明文字 |
| 错误提示 | SnackBar，红色背景，3秒自动消失 |
| 成功提示 | SnackBar，绿色背景，1.5秒自动消失 |
| 日期选择 | showDatePicker（系统原生） |
| 确认删除 | AlertDialog：标题 + 说明 + 取消/删除按钮 |

### M.8 布局参数

| 元素 | 规格 |
|------|------|
| AppBar 高度 | 56px |
| BottomNavigationBar 高度 | 56px（含 safe area） |
| 页面左右边距 | 16px |
| 卡片圆角 | 12px (rounded-xl) |
| 卡片内边距 | 16-20px |
| 卡片阴影 | blurRadius=2, color=black 5% opacity |
| 按钮圆角 | 8px (rounded-lg) |
| 按钮内边距 | sm: 12/6px, md: 16/10px, lg: 24/14px |
| 输入框圆角 | 8px |
| 输入框内边距 | horizontal 12px, vertical 10px |
| 列表项高度 | 64-72px |
| 空状态内边距 | vertical 48px |
| 分类网格间距 | 12px |
| 颜色圆点大小 | 12px（列表），16px（分类卡片），32px（颜色选择器） |

### M.9 数据格式化

| 数据 | 格式 |
|------|------|
| 金额 | 分转元：`amount / 100`，显示 `¥1,234.56` |
| 收入显示 | `+¥100.00`（绿色） |
| 支出显示 | `-¥100.00`（红色） |
| 日期显示 | `2026年04月28日` |
| 月份标签 | `4月` |
| 输入日期 | `YYYY-MM-DD` |

### M.10 字体（Typography）

| 层级 | 字号 | 字重 | 用途 |
|------|------|------|------|
| h1 | 24px | Bold(700) | 页面标题、仪表盘金额 |
| h2 | 18px | Semibold(600) | 卡片标题、section标题 |
| body | 14px | Regular(400) | 正文、列表项文字 |
| body-small | 12px | Regular(400) | 日期、次要信息、帮助文字 |
| label | 14px | Medium(500) | 表单标签 |
| badge | 12px | Semibold(600) + 0.025em | 标签文字 |
| amount-large | 24px | Bold(700) | Dashboard 金额数字 |

### M.11 卡片视觉强化（左色条模式）🔴 新增

> 参考 Web 前端 Dashboard 设计：使用左置竖条色块替代纯文字标签，增强金额类型辨识度。

```dart
┌───────────────────────────┐
│ ▌ 本月收入               │  ← 左色条 + 标签
│ ▌ ¥12,345.00             │  ← 金额（对应语义色）
└───────────────────────────┘
```

**各类别卡片色条配置：**

| 卡片类型 | 色条颜色 | 金额文字色 |
|----------|---------|-----------|
| 收入 | `incomeGreen500` | `incomeGreen600` |
| 支出 | `expenseRed500` | `expenseRed500` |
| 结余（正） | `balanceBlue500` | `balanceBlue600` |
| 结余（负） | `expenseRed500` | `expenseRed500` |

**色条规格：**
- 宽度：4px（`w-1`），高度：20px（5倍于宽度）
- 圆角：full（完全圆角）
- 与卡片左内边距对齐

**Flutter 实现示例：**
```dart
Row(
  children: [
    Container(
      width: 4, height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    const SizedBox(width: 12),
    // 内容区域
  ],
)
```

### M.12 完善交互反馈（参考 Web 前端规范）

| 交互 | 行为 |
|------|------|
| 卡片 hover/按下 | `scale(0.98)` 150ms 缩放动画 |
| 交易项点击 | 底部弹出详情 Sheet（编辑/删除） |
| 交易滑动删除 | Dismissible 组件，红色背景 + `delete_outline` 图标 |
| 下拉刷新 | RefreshIndicator 包裹所有列表页 |
| 空状态引导 | 48px 灰色圆形容器 + 24px 图标 + 标题 + 说明副文本 |
| FAB 点击 | 底部弹出 BottomSheet，含完整表单 |

---

## 环境变量

```env
DATABASE_URL=postgresql+asyncpg://postgres:mysecretpassword@my-postgres:5432/finance_tracker
ALEMBIC_INI=/opt/data/home/finance-tracker/backend/alembic.ini
```
