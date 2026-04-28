# Finance Tracker 设计规范

## 概述

简洁高效的个人记账应用 UI/UX 设计规范，供 AI 编码助手（Claude Code 等）参考。

---

## 设计原则

1. **黑白为主**：主色调使用深灰（`gray-900`），避免蓝色/紫色/粉色等亮色系
2. **克制的卡片感**：依赖圆角 + `shadow-sm` 营造层次，避免粗边框
3. **交互反馈**：按钮带 `active:scale-[0.98]` 点击反馈，hover 有阴影变化
4. **空状态引导**：空数据时显示图标 + 说明文案，而非纯文字

---

## 色彩系统

### 主色调
- **Primary**: `bg-gray-900` / `hover:bg-gray-800`
- **Focus Ring**: `focus:ring-gray-500`

### 辅助色
- 白色背景卡片：`bg-white`
- 边框：`border-gray-100`（卡片）/ `border-gray-200`（输入框）
- 文字：`text-gray-900`（深）/ `text-gray-600`（中）/ `text-gray-400`（浅）
- 成功/错误等语义色保留原色系（`green-*`、`red-*`）

### 收入/支出语义色
- 收入：`text-green-600`
- 支出：`text-gray-900`

---

## 组件规范

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

## 页面布局规范

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
| GET | /api/categories | 分类列表 |
| POST | /api/categories | 创建分类 |
| PUT | /api/categories/{id} | 更新分类 |
| DELETE | /api/categories/{id} | 删除分类 |
| GET | /api/transactions | 交易列表（支持 type, category_id, start_date, end_date 筛选） |
| POST | /api/transactions | 创建交易 |
| PUT | /api/transactions/{id} | 更新交易 |
| DELETE | /api/transactions/{id} | 删除交易 |
| GET | /api/stats/monthly?year=&month= | 月度统计（返回单对象） |
| GET | /api/stats/category?year=&month= | 分类统计 |

---

## 环境变量

```env
DATABASE_URL=postgresql+asyncpg://postgres:mysecretpassword@my-postgres:5432/finance_tracker
ALEMBIC_INI=/opt/data/home/finance-tracker/backend/alembic.ini
```
