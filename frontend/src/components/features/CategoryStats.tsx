import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from "recharts";
import type { CategorySummary } from "@/schemas/stats";

export interface CategoryStatsProps {
  data: CategorySummary;
}

const COLORS = ["#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899", "#06B6D4", "#84CC16"];

function formatAmount(cents: number): string {
  return `¥${(cents / 100).toFixed(2)}`;
}

export function CategoryStats({ data }: CategoryStatsProps) {
  const chartData: { name: string; value: number; percentage: number }[] = data.categories.map((cat) => ({
    name: cat.category_name,
    value: cat.amount,
    percentage: cat.percentage,
  }));

  if (data.categories.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-center bg-white rounded-xl border border-gray-100 shadow-sm">
        <div className="w-12 h-12 mb-4 rounded-full bg-gray-100 flex items-center justify-center">
          <svg className="w-6 h-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z" />
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" />
          </svg>
        </div>
        <p className="text-gray-500 font-medium">暂无分类数据</p>
        <p className="text-gray-400 text-sm mt-1">添加交易后自动统计</p>
      </div>
    );
  }

  return (
    <div className="bg-white p-5 rounded-xl border border-gray-100 shadow-sm">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-sm font-medium text-gray-700">分类支出</h3>
        <span className="text-xs text-gray-400">单位: 元</span>
      </div>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={chartData}
              dataKey="value"
              nameKey="name"
              cx="50%"
              cy="50%"
              outerRadius={80}
              label={({ name }) => `${name}`}
            >
              {chartData.map((_, index) => (
                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
              ))}
            </Pie>
            <Tooltip formatter={(value) => formatAmount(value as number)} />
            <Legend />
          </PieChart>
        </ResponsiveContainer>
      </div>
      <div className="mt-4 space-y-2">
        {data.categories.map((cat, index) => (
          <div key={cat.category_id} className="flex items-center justify-between text-sm">
            <div className="flex items-center gap-2">
              <div
                className="w-3 h-3 rounded-full"
                style={{ backgroundColor: COLORS[index % COLORS.length] }}
              />
              <span className="text-gray-700">{cat.category_name}</span>
            </div>
            <span className="text-gray-500">{formatAmount(cat.amount)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
