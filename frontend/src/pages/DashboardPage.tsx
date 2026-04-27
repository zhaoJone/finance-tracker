import { useCategoryStats, useMonthlyStats } from "@/hooks";
import { CategoryStats, MonthlyChart } from "@/components/features";
import { useMemo } from "react";

function formatCurrency(amount: number): string {
  return `¥${amount.toFixed(2)}`;
}

export function DashboardPage() {
  const now = new Date();
  const { data: monthlyData } = useMonthlyStats({ year: now.getFullYear(), month: now.getMonth() + 1 });

  const { data: categoryStats } = useCategoryStats();

  const currentMonthData = useMemo(() => {
    if (!monthlyData) return null;
    return {
      income: monthlyData.income / 100,
      expense: monthlyData.expense / 100,
      balance: monthlyData.balance / 100,
    };
  }, [monthlyData]);

  const monthLabel = `${now.getMonth() + 1}月`;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">仪表盘</h1>
        <span className="text-sm text-gray-400">{monthLabel}</span>
      </div>

      {currentMonthData ? (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white p-5 rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow duration-200">
            <div className="flex items-center gap-2 mb-3">
              <div className="w-1.5 h-5 bg-green-500 rounded-full" />
              <p className="text-sm text-gray-500">本月收入</p>
            </div>
            <p className="text-2xl font-bold text-green-600">{formatCurrency(currentMonthData.income)}</p>
          </div>
          <div className="bg-white p-5 rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow duration-200">
            <div className="flex items-center gap-2 mb-3">
              <div className="w-1.5 h-5 bg-red-500 rounded-full" />
              <p className="text-sm text-gray-500">本月支出</p>
            </div>
            <p className="text-2xl font-bold text-red-500">{formatCurrency(currentMonthData.expense)}</p>
          </div>
          <div className="bg-white p-5 rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow duration-200">
            <div className="flex items-center gap-2 mb-3">
              <div className={`w-1.5 h-5 rounded-full ${currentMonthData.balance >= 0 ? "bg-blue-500" : "bg-red-500"}`} />
              <p className="text-sm text-gray-500">本月结余</p>
            </div>
            <p className={`text-2xl font-bold ${currentMonthData.balance >= 0 ? "text-blue-600" : "text-red-500"}`}>
              {formatCurrency(currentMonthData.balance)}
            </p>
          </div>
        </div>
      ) : (
        <div className="bg-white p-8 rounded-xl border border-gray-100 shadow-sm text-center">
          <p className="text-gray-400">暂无本月数据</p>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {categoryStats && <CategoryStats data={categoryStats} />}
        {monthlyData && <MonthlyChart data={[monthlyData]} />}
      </div>
    </div>
  );
}
