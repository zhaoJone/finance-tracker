import { useState } from "react";
import { useTransactions, useCreateTransaction, useCategories } from "@/hooks";
import { TransactionList, TransactionForm } from "@/components/features";
import { Button, Select } from "@/components/ui";
import type { TransactionFilter } from "@/schemas";

export function TransactionsPage() {
  const [showForm, setShowForm] = useState(false);
  const [filters, setFilters] = useState<TransactionFilter>({});

  const { data: transactions = [], isLoading } = useTransactions({ filters });
  const { data: categories = [] } = useCategories();
  const createTransaction = useCreateTransaction();

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
    { value: "", label: "All Types" },
    { value: "income", label: "Income" },
    { value: "expense", label: "Expense" },
  ];

  const categoryOptions = [
    { value: "", label: "All Categories" },
    ...categories.map((c) => ({ value: c.id, label: c.name })),
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Transactions</h1>
        <Button onClick={() => setShowForm(!showForm)}>
          {showForm ? "Cancel" : "Add Transaction"}
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
          label="Type"
          value={filters.type ?? ""}
          onChange={(e) => handleFilterChange("type", e.target.value)}
          options={typeOptions}
        />
        <Select
          label="Category"
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
        <div className="text-center py-8 text-gray-500">Loading...</div>
      ) : (
        <TransactionList transactions={transactions} categories={categories} />
      )}
    </div>
  );
}
