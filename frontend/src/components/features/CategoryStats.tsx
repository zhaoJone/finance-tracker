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
      <div className="text-center py-8 text-gray-500">
        暂无数据
      </div>
    );
  }

  return (
    <div className="bg-white p-4 rounded-lg border border-gray-200">
      <h3 className="text-sm font-medium text-gray-700 mb-4">分类支出</h3>
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
