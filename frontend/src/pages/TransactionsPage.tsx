import { useState } from "react";
import { useTransactions, useCreateTransaction, useUpdateTransaction, useDeleteTransaction, useCategories } from "@/hooks";
import { TransactionList, TransactionForm } from "@/components/features";
import { Button, Select } from "@/components/ui";
import type { TransactionFilter, Transaction, Category } from "@/schemas";

export function TransactionsPage() {
  const [showForm, setShowForm] = useState(false);
  const [editingTx, setEditingTx] = useState<Transaction | null>(null);
  const [filters, setFilters] = useState<TransactionFilter>({});

  const { data: transactions = [], isLoading } = useTransactions({ filters });
  const { data: categoriesData } = useCategories();
  const createTransaction = useCreateTransaction();
  const updateTransaction = useUpdateTransaction();
  const deleteTransaction = useDeleteTransaction();

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

  const handleCreate = async (data: Parameters<typeof createTransaction.mutate>[0]) => {
    await createTransaction.mutateAsync(data);
    setShowForm(false);
  };

  const handleUpdate = async (data: Parameters<typeof createTransaction.mutate>[0]) => {
    if (!editingTx) return;
    await updateTransaction.mutateAsync({
      id: editingTx.id,
      data: { note: data.note, category_id: data.category_id },
    });
    setEditingTx(null);
  };

  const handleEdit = (tx: Transaction) => {
    setEditingTx(tx);
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm("确定要删除这笔交易吗？")) return;
    await deleteTransaction.mutateAsync(id);
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditingTx(null);
  };

  const isSubmitting = createTransaction.isPending || updateTransaction.isPending;

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
        <Button onClick={() => { setShowForm(!showForm); setEditingTx(null); }}>
          {showForm && !editingTx ? "取消" : "添加交易"}
        </Button>
      </div>

      {showForm && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <TransactionForm
            categories={categories}
            onSubmit={editingTx ? handleUpdate : handleCreate}
            onCancel={handleCancel}
            isLoading={isSubmitting}
            initialData={editingTx ?? undefined}
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
        <TransactionList
          transactions={transactions}
          categories={categories}
          onEdit={handleEdit}
          onDelete={handleDelete}
        />
      )}
    </div>
  );
}
