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
        <TransactionForm
          categories={categories}
          onSubmit={handleSubmit}
          onCancel={() => setShowForm(false)}
          isLoading={createTransaction.isPending}
        />
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 bg-white p-4 rounded-lg border border-gray-200">
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
          className="px-3 py-2 border border-gray-300 rounded-lg text-sm"
        />
      </div>

      {isLoading ? (
        <div className="text-center py-8 text-gray-500">加载中...</div>
      ) : (
        <TransactionList transactions={transactions} categories={categories} />
      )}
    </div>
  );
}
