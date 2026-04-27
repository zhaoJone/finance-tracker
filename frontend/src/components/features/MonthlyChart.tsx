import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from "recharts";
import type { MonthlySummary } from "@/schemas/stats";

export interface MonthlyChartProps {
  data: MonthlySummary[];
}

function formatAmount(cents: number): string {
  return `¥${(cents / 100).toFixed(0)}`;
}

const MONTHS = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"];

export function MonthlyChart({ data }: MonthlyChartProps) {
  const chartData = data.map((item) => ({
    name: `${item.year}年${MONTHS[item.month - 1]}`,
    income: item.income / 100,
    expense: item.expense / 100,
    balance: item.balance / 100,
  }));

  if (data.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-center bg-white rounded-xl border border-gray-100 shadow-sm">
        <div className="w-12 h-12 mb-4 rounded-full bg-gray-100 flex items-center justify-center">
          <svg className="w-6 h-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z" />
          </svg>
        </div>
        <p className="text-gray-500 font-medium">暂无月度数据</p>
        <p className="text-gray-400 text-sm mt-1">开始记录交易后自动生成趋势图</p>
      </div>
    );
  }

  return (
    <div className="bg-white p-5 rounded-xl border border-gray-100 shadow-sm">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-sm font-medium text-gray-700">月度趋势</h3>
        <span className="text-xs text-gray-400">单位: 元</span>
      </div>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
            <XAxis dataKey="name" tick={{ fontSize: 12 }} stroke="#9CA3AF" />
            <YAxis tick={{ fontSize: 12 }} stroke="#9CA3AF" tickFormatter={(v) => `¥${v}`} />
            <Tooltip formatter={(value) => formatAmount((value as number) * 100)} />
            <Legend />
            <Line
              type="monotone"
              dataKey="income"
              stroke="#10B981"
              strokeWidth={2}
              dot={false}
              name="收入"
            />
            <Line
              type="monotone"
              dataKey="expense"
              stroke="#EF4444"
              strokeWidth={2}
              dot={false}
              name="支出"
            />
            <Line
              type="monotone"
              dataKey="balance"
              stroke="#3B82F6"
              strokeWidth={2}
              dot={false}
              name="余额"
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
