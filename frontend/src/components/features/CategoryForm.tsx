import { useState, type FormEvent } from "react";
import type { Category } from "@/schemas";
import { Button, Input } from "@/components/ui";
import { useCreateCategory, useUpdateCategory } from "@/hooks";

const PRESET_COLORS = [
  "#FF6B6B", "#FF8E53", "#FFCD56", "#4ECDC4",
  "#45B7D1", "#6C5CE7", "#A29BFE", "#FD79A8",
  "#F8B500", "#00B894", "#E17055", "#74B9FF",
];

export interface CategoryFormProps {
  category?: Category | null;
  type: "income" | "expense";
  onSubmit: () => void;
  onCancel: () => void;
}

export function CategoryForm({ category, type, onSubmit, onCancel }: CategoryFormProps) {
  const [name, setName] = useState(category?.name ?? "");
  const [color, setColor] = useState(category?.color ?? PRESET_COLORS[0]);

  const createCategory = useCreateCategory();
  const updateCategory = useUpdateCategory();

  const isEditing = !!category;
  const effectiveType = isEditing ? category.type : type;
  const isLoading = createCategory.isPending || updateCategory.isPending;

  const charCount = name.length;
  const maxChars = 10;

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    if (!name.trim()) return;

    try {
      if (isEditing) {
        await updateCategory.mutateAsync({ id: category.id, name: name.trim(), color });
      } else {
        await createCategory.mutateAsync({ name: name.trim(), color, type: effectiveType });
      }
      onSubmit();
    } catch {
      // Error handled by mutation
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
        <h3 className="text-lg font-medium text-gray-900 mb-4">
          {isEditing ? "编辑分类" : "新增分类"}
        </h3>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="text-sm font-medium text-gray-700">分类名称</label>
              <span className="text-xs text-gray-400">{charCount}/{maxChars}</span>
            </div>
            <Input
              value={name}
              onChange={(e) => setName(e.target.value.slice(0, maxChars))}
              placeholder="最多10个字"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              类型
            </label>
            <div className="px-3 py-2 bg-gray-50 rounded-lg text-sm text-gray-600">
              {effectiveType === "income" ? "收入" : "支出"}
            </div>
            {isEditing && (
              <p className="text-xs text-gray-400 mt-1">编辑时类型不可更改</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              颜色
            </label>
            <div className="flex flex-wrap gap-2">
              {PRESET_COLORS.map((c) => (
                <button
                  key={c}
                  type="button"
                  onClick={() => setColor(c)}
                  className={`w-8 h-8 rounded-full flex items-center justify-center ${
                    color === c ? "ring-2 ring-offset-2 ring-blue-500" : ""
                  }`}
                  style={{ backgroundColor: c }}
                >
                  {color === c && (
                    <span className="text-white text-xs">✓</span>
                  )}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              预览
            </label>
            <div className="bg-white p-3 rounded-lg border border-gray-200 flex items-center gap-3">
              <div
                className="w-4 h-4 rounded-full"
                style={{ backgroundColor: color }}
              />
              <span className="text-sm font-medium text-gray-900">
                {name || "分类名称"}
              </span>
            </div>
          </div>

          <div className="flex gap-2 justify-end pt-2">
            <Button type="button" variant="outline" onClick={onCancel}>
              取消
            </Button>
            <Button type="submit" disabled={isLoading || !name.trim()}>
              {isLoading ? "保存中..." : "保存"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
