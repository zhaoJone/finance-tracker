import { useState } from "react";
import { useTransactions, useCreateTransaction, useCategories } from "@/hooks";
import { TransactionList, TransactionForm } from "@/components/features";
import { Button, Select } from "@/components/ui";
import type { TransactionFilter, Category } from "@/schemas";

export function TransactionsPage() {
  const [showForm, setShowForm] = useState(false);
  const [filters, setFilters] = useState<TransactionFilter>({});

  const { data: transactions = [], isLoading } = useTransactions({ filters });
  const { data: categoriesData } = useCategories();
  const createTransaction = useCreateTransaction();

  const categories: Category[] = [
    ...(categoriesData?.income ?? []),
    ...(categoriesData?.expense ?? []),
  ];

  const handleFilterChange = (key: keyof TransactionFilter, value: string) => {
    setFilters((prev) => ({
      ...prev,
      [key]: value || undefined,
    }));
  };

  const handleSubmit = async (data: Parameters<typeof createTransaction.mutate>[0]) => {
    await createTransaction.mutateAsync(data);
    setShowForm(false);
  };

  const typeOptions = [
    { value: "", label: "全部类型" },
    { value: "income", label: "收入" },
    { value: "expense", label: "支出" },
  ];

  const categoryOptions = [
    { value: "", label: "全部分类" },
    ...categories.map((c) => ({ value: c.id, label: c.name })),
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">交易记录</h1>
        <Button onClick={() => setShowForm(!showForm)}>
          {showForm ? "取消" : "添加交易"}
        </Button>
      </div>

      {showForm && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <TransactionForm
            categories={categories}
            onSubmit={handleSubmit}
            onCancel={() => setShowForm(false)}
            isLoading={createTransaction.isPending}
          />
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 bg-white p-5 rounded-xl border border-gray-100 shadow-sm">
        <Select
          label="类型"
          value={filters.type ?? ""}
          onChange={(e) => handleFilterChange("type", e.target.value)}
          options={typeOptions}
        />
        <Select
          label="分类"
          value={filters.category_id ?? ""}
          onChange={(e) => handleFilterChange("category_id", e.target.value)}
          options={categoryOptions}
        />
        <div className="flex flex-col gap-1">
          <label className="text-sm font-medium text-gray-700">月份</label>
          <input
            type="month"
            value={filters.start_date ? filters.start_date.slice(0, 7) : ""}
            onChange={(e) => {
              const value = e.target.value;
              if (value) {
                handleFilterChange("start_date", `${value}-01`);
                handleFilterChange("end_date", `${value}-31`);
              } else {
                handleFilterChange("start_date", "");
                handleFilterChange("end_date", "");
              }
            }}
            className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-gray-900 transition-colors"
          />
        </div>
      </div>

      {isLoading ? (
        <div className="text-center py-8 text-gray-500">加载中...</div>
      ) : (
        <TransactionList transactions={transactions} categories={categories} />
      )}
    </div>
  );
}
