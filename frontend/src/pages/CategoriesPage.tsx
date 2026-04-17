import { useState } from "react";
import { useCategories, useDeleteCategory } from "@/hooks";
import { CategoryForm } from "@/components/features";
import type { Category } from "@/schemas";
import { Button } from "@/components/ui";

export function CategoriesPage() {
  const [activeTab, setActiveTab] = useState<"income" | "expense">("expense");
  const [showForm, setShowForm] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<Category | null>(null);

  const { data: categoriesData, isLoading } = useCategories();
  const deleteCategory = useDeleteCategory();

  const categories = activeTab === "income"
    ? (categoriesData?.income ?? [])
    : (categoriesData?.expense ?? []);

  const handleEdit = (category: Category) => {
    setEditingCategory(category);
    setShowForm(true);
  };

  const handleDelete = async (category: Category) => {
    try {
      await deleteCategory.mutateAsync(category.id);
      setConfirmDelete(null);
    } catch (err: unknown) {
      const error = err as Error;
      if (error.message.includes("409") || error.message.includes("linked")) {
        alert(`该分类下有交易记录，无法删除`);
        setConfirmDelete(null);
      }
    }
  };

  const handleFormClose = () => {
    setShowForm(false);
    setEditingCategory(null);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">分类管理</h1>
        <Button onClick={() => setShowForm(true)}>
          + 新增分类
        </Button>
      </div>

      <div className="border-b border-gray-200">
        <nav className="flex gap-6">
          <button
            onClick={() => setActiveTab("expense")}
            className={`pb-2 text-sm font-medium border-b-2 ${
              activeTab === "expense"
                ? "border-blue-600 text-blue-600"
                : "border-transparent text-gray-500 hover:text-gray-700"
            }`}
          >
            支出类
          </button>
          <button
            onClick={() => setActiveTab("income")}
            className={`pb-2 text-sm font-medium border-b-2 ${
              activeTab === "income"
                ? "border-blue-600 text-blue-600"
                : "border-transparent text-gray-500 hover:text-gray-700"
            }`}
          >
            收入类
          </button>
        </nav>
      </div>

      {isLoading ? (
        <div className="text-center py-8 text-gray-500">加载中...</div>
      ) : categories.length === 0 ? (
        <div className="text-center py-12">
          <div className="text-gray-400 mb-2">暂无分类</div>
          <div className="text-gray-400 text-sm">点击右上角添加分类</div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {categories.map((category) => (
            <div
              key={category.id}
              className="bg-white p-4 rounded-lg border border-gray-200 flex items-center justify-between"
            >
              <div className="flex items-center gap-3">
                <div
                  className="w-4 h-4 rounded-full"
                  style={{ backgroundColor: category.color }}
                />
                <span className="text-sm font-medium text-gray-900">
                  {category.name}
                </span>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => handleEdit(category)}
                  className="p-1 text-gray-400 hover:text-blue-600 text-sm"
                >
                  编辑
                </button>
                <button
                  onClick={() => setConfirmDelete(category)}
                  className="p-1 text-gray-400 hover:text-red-600 text-sm"
                >
                  删除
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showForm && (
        <CategoryForm
          category={editingCategory}
          type={activeTab}
          onSubmit={handleFormClose}
          onCancel={handleFormClose}
        />
      )}

      {confirmDelete && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-sm w-full mx-4">
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              确认删除
            </h3>
            <p className="text-sm text-gray-500 mb-4">
              确认删除「{confirmDelete.name}」分类？此操作不可撤销。
            </p>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={() => setConfirmDelete(null)}>
                取消
              </Button>
              <Button
                variant="danger"
                onClick={() => handleDelete(confirmDelete)}
                isLoading={deleteCategory.isPending}
              >
                删除
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
