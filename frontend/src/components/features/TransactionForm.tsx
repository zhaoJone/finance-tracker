import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
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

  const navigate = useNavigate();
  const filteredCategories = categories.filter((c) => c.type === type);

  const handleCategoryChange = (value: string) => {
    if (value === "__manage__") {
      navigate("/categories");
      return;
    }
    setCategoryId(value);
  };

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();

    if (categoryId === "__manage__") {
      navigate("/categories");
      return;
    }

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
          label="类型"
          value={type}
          onChange={(e) => {
            setType(e.target.value as "income" | "expense");
            setCategoryId("");
          }}
          options={[
            { value: "expense", label: "支出" },
            { value: "income", label: "收入" },
          ]}
        />
        <Input
          label="金额"
          type="number"
          step="0.01"
          min="0"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="0.00"
          required
        />
      </div>

      <div>
        <Select
          label="分类"
          value={categoryId}
          onChange={(e) => handleCategoryChange(e.target.value)}
          options={[
            ...filteredCategories.map((c) => ({ value: c.id, label: c.name })),
            { value: "__manage__", label: "+ 管理分类" },
          ]}
          required
        />
      </div>

      <Input
        label="日期"
        type="date"
        value={date}
        onChange={(e) => setDate(e.target.value)}
        required
      />

      <Input
        label="备注"
        value={note}
        onChange={(e) => setNote(e.target.value)}
        placeholder="选填"
      />

      <div className="flex gap-2 justify-end">
        {onCancel && (
          <Button type="button" variant="outline" onClick={onCancel}>
            取消
          </Button>
        )}
        <Button type="submit" disabled={isLoading || !categoryId || categoryId === "__manage__"}>
          {isLoading ? "保存中..." : initialData ? "更新" : "创建"}
        </Button>
      </div>
    </form>
  );
}
