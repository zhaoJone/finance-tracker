import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from "recharts";
import type { MonthlySummary } from "@/schemas/stats";

export interface MonthlyChartProps {
  data: MonthlySummary[];
}

function formatAmount(cents: number): string {
  return `$${(cents / 100).toFixed(0)}`;
}

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

export function MonthlyChart({ data }: MonthlyChartProps) {
  const chartData = data.map((item) => ({
    name: `${MONTHS[item.month - 1]} ${item.year}`,
    income: item.income / 100,
    expense: item.expense / 100,
    balance: item.balance / 100,
  }));

  if (data.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        No data available
      </div>
    );
  }

  return (
    <div className="bg-white p-4 rounded-lg border border-gray-200">
      <h3 className="text-sm font-medium text-gray-700 mb-4">Monthly Overview</h3>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
            <XAxis dataKey="name" tick={{ fontSize: 12 }} stroke="#9CA3AF" />
            <YAxis tick={{ fontSize: 12 }} stroke="#9CA3AF" tickFormatter={(v) => `$${v}`} />
            <Tooltip formatter={(value) => formatAmount((value as number) * 100)} />
            <Legend />
            <Line
              type="monotone"
              dataKey="income"
              stroke="#10B981"
              strokeWidth={2}
              dot={false}
              name="Income"
            />
            <Line
              type="monotone"
              dataKey="expense"
              stroke="#EF4444"
              strokeWidth={2}
              dot={false}
              name="Expense"
            />
            <Line
              type="monotone"
              dataKey="balance"
              stroke="#3B82F6"
              strokeWidth={2}
              dot={false}
              name="Balance"
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
