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
  return type === "income" ? `+¥${formatted}` : `-¥${formatted}`;
}

function getCategoryName(categoryId: string, categories: Category[]): string {
  return categories.find((c) => c.id === categoryId)?.name ?? "未知";
}

function getCategoryColor(categoryId: string, categories: Category[]): string {
  return categories.find((c) => c.id === categoryId)?.color ?? "#9CA3AF";
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}年${month}月${day}日`;
}

export function TransactionList({
  transactions,
  categories,
  onEdit,
  onDelete,
}: TransactionListProps) {
  if (transactions.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center bg-white rounded-xl border border-gray-100 shadow-sm">
        <div className="w-12 h-12 mb-4 rounded-full bg-gray-100 flex items-center justify-center">
          <svg className="w-6 h-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
        </div>
        <p className="text-gray-500 font-medium">暂无交易记录</p>
        <p className="text-gray-400 text-sm mt-1">点击上方「添加交易」开始记录</p>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {transactions.map((tx) => (
        <div
          key={tx.id}
          className="flex items-center justify-between p-4 bg-white rounded-xl border border-gray-100 shadow-sm hover:shadow-md hover:border-gray-200 transition-all duration-150"
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
            <span className="text-xs text-gray-400">{formatDate(tx.date)}</span>
            <div className="flex gap-1">
              {onEdit && (
                <button
                  onClick={() => onEdit(tx)}
                  className="p-1 text-gray-400 hover:text-blue-600"
                >
                  编辑
                </button>
              )}
              {onDelete && (
                <button
                  onClick={() => onDelete(tx.id)}
                  className="p-1 text-gray-400 hover:text-red-600"
                >
                  删除
                </button>
              )}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
