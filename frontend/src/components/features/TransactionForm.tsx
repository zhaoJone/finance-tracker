import { useState, type FormEvent } from "react";
import type { Category, TransactionCreate, Transaction } from "@/schemas";
import { Button, Input, Select } from "@/components/ui";

export interface TransactionFormProps {
  categories: Category[];
  onSubmit: (data: TransactionCreate) => void;
  onCancel?: () => void;
  initialData?: Transaction;
  isLoading?: boolean;
}

export function TransactionForm({
  categories,
  onSubmit,
  onCancel,
  initialData,
  isLoading,
}: TransactionFormProps) {
  const [amount, setAmount] = useState(initialData?.amount.toString() ?? "");
  const [categoryId, setCategoryId] = useState(initialData?.category_id ?? "");
  const [note, setNote] = useState(initialData?.note ?? "");
  const [date, setDate] = useState(initialData?.date ?? new Date().toISOString().split("T")[0]);
  const [type, setType] = useState<"income" | "expense">(initialData?.type ?? "expense");

  const filteredCategories = categories.filter((c) => c.type === type);

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();

    const amountInCents = Math.round(parseFloat(amount) * 100);
    if (isNaN(amountInCents) || amountInCents <= 0) return;

    onSubmit({
      amount: amountInCents,
      category_id: categoryId,
      note,
      date,
      type,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4 bg-white p-4 rounded-lg border border-gray-200">
      <div className="grid grid-cols-2 gap-4">
        <Select
          label="Type"
          value={type}
          onChange={(e) => {
            setType(e.target.value as "income" | "expense");
            setCategoryId("");
          }}
          options={[
            { value: "expense", label: "Expense" },
            { value: "income", label: "Income" },
          ]}
        />
        <Input
          label="Amount"
          type="number"
          step="0.01"
          min="0"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="0.00"
          required
        />
      </div>

      <Select
        label="Category"
        value={categoryId}
        onChange={(e) => setCategoryId(e.target.value)}
        options={filteredCategories.map((c) => ({ value: c.id, label: c.name }))}
        required
      />

      <Input
        label="Date"
        type="date"
        value={date}
        onChange={(e) => setDate(e.target.value)}
        required
      />

      <Input
        label="Note"
        value={note}
        onChange={(e) => setNote(e.target.value)}
        placeholder="Optional note"
      />

      <div className="flex gap-2 justify-end">
        {onCancel && (
          <Button type="button" variant="outline" onClick={onCancel}>
            Cancel
          </Button>
        )}
        <Button type="submit" disabled={isLoading}>
          {isLoading ? "Saving..." : initialData ? "Update" : "Create"}
        </Button>
      </div>
    </form>
  );
}
