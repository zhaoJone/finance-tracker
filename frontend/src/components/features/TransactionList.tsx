import type { Transaction, Category } from "@/schemas";
import { Badge } from "@/components/ui";

export interface TransactionListProps {
  transactions: Transaction[];
  categories: Category[];
  onEdit?: (transaction: Transaction) => void;
  onDelete?: (id: string) => void;
}

function formatAmount(amount: number, type: "income" | "expense"): string {
  const formatted = (amount / 100).toFixed(2);
  return type === "income" ? `+$${formatted}` : `-$${formatted}`;
}

function getCategoryName(categoryId: string, categories: Category[]): string {
  return categories.find((c) => c.id === categoryId)?.name ?? "Unknown";
}

function getCategoryColor(categoryId: string, categories: Category[]): string {
  return categories.find((c) => c.id === categoryId)?.color ?? "#9CA3AF";
}

export function TransactionList({
  transactions,
  categories,
  onEdit,
  onDelete,
}: TransactionListProps) {
  if (transactions.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        No transactions yet
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {transactions.map((tx) => (
        <div
          key={tx.id}
          className="flex items-center justify-between p-3 bg-white rounded-lg border border-gray-200 hover:border-gray-300 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div
              className="w-3 h-3 rounded-full"
              style={{ backgroundColor: getCategoryColor(tx.category_id, categories) }}
            />
            <div>
              <p className="text-sm font-medium text-gray-900">
                {getCategoryName(tx.category_id, categories)}
              </p>
              <p className="text-xs text-gray-500">{tx.note || "—"}</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Badge variant={tx.type === "income" ? "success" : "error"}>
              {formatAmount(tx.amount, tx.type)}
            </Badge>
            <span className="text-xs text-gray-400">{tx.date}</span>
            <div className="flex gap-1">
              {onEdit && (
                <button
                  onClick={() => onEdit(tx)}
                  className="p-1 text-gray-400 hover:text-blue-600"
                >
                  Edit
                </button>
              )}
              {onDelete && (
                <button
                  onClick={() => onDelete(tx.id)}
                  className="p-1 text-gray-400 hover:text-red-600"
                >
                  Delete
                </button>
              )}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
