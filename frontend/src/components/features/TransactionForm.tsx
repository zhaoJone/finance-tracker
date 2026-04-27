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

  // Auto-select first category when filteredCategories has exactly one item and nothing is selected
  const effectiveCategoryId = (() => {
    if (categoryId && filteredCategories.some((c) => c.id === categoryId)) return categoryId;
    if (filteredCategories.length === 1) return filteredCategories[0].id;
    if (categoryId === "" && filteredCategories.length > 0) return filteredCategories[0].id;
    return categoryId;
  })();

  const handleCategoryChange = (value: string) => {
    if (value === "__manage__") {
      navigate("/categories");
      return;
    }
    setCategoryId(value);
  };

  const handleTypeChange = (value: "income" | "expense") => {
    setType(value);
    const newFiltered = categories.filter((c) => c.type === value);
    if (newFiltered.length === 1) {
      setCategoryId(newFiltered[0].id);
    } else {
      setCategoryId("");
    }
  };

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();

    if (effectiveCategoryId === "__manage__") {
      navigate("/categories");
      return;
    }

    const amountInCents = Math.round(parseFloat(amount) * 100);
    if (isNaN(amountInCents) || amountInCents <= 0) return;

    onSubmit({
      amount: amountInCents,
      category_id: effectiveCategoryId,
      note,
      date,
      type,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <div className="grid grid-cols-2 gap-4">
        <Select
          label="类型"
          value={type}
          onChange={(e) => handleTypeChange(e.target.value as "income" | "expense")}
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
          value={effectiveCategoryId}
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
        <Button type="submit" disabled={isLoading || !effectiveCategoryId || effectiveCategoryId === "__manage__"}>
          {isLoading ? "保存中..." : initialData ? "更新" : "创建"}
        </Button>
      </div>
    </form>
  );
}
