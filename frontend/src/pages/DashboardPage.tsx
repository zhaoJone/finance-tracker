import { useCategoryStats, useMonthlyStats } from "@/hooks";
import { CategoryStats, MonthlyChart } from "@/components/features";
import { useMemo } from "react";

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

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>

      {currentMonthData && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <p className="text-sm text-gray-500">Income</p>
            <p className="text-2xl font-bold text-green-600">${currentMonthData.income.toFixed(2)}</p>
          </div>
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <p className="text-sm text-gray-500">Expense</p>
            <p className="text-2xl font-bold text-red-600">${currentMonthData.expense.toFixed(2)}</p>
          </div>
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <p className="text-sm text-gray-500">Balance</p>
            <p className={`text-2xl font-bold ${currentMonthData.balance >= 0 ? "text-blue-600" : "text-red-600"}`}>
              ${currentMonthData.balance.toFixed(2)}
            </p>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {categoryStats && <CategoryStats data={categoryStats} />}
        <MonthlyChart data={[]} />
      </div>
    </div>
  );
}
