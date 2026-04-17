import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import type { Category } from "@/schemas/category";

interface ApiResponse<T> {
  data: T;
  message: string;
}

interface CategoriesResponse {
  income: Category[];
  expense: Category[];
}

async function fetchJson<T>(url: string, options?: RequestInit): Promise<T> {
  const response = await fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options?.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail || error.error || "API Error");
  }

  const result: ApiResponse<T> = await response.json();
  return result.data;
}

export function useCategories() {
  return useQuery<CategoriesResponse>({
    queryKey: ["categories"],
    queryFn: () => fetchJson<CategoriesResponse>("/api/categories"),
  });
}

export function useCreateCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { name: string; color: string; type: "income" | "expense" }) =>
      fetchJson<Category>("/api/categories", {
        method: "POST",
        body: JSON.stringify(data),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["categories"] });
    },
  });
}

export function useUpdateCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, ...data }: { id: string; name?: string; color?: string }) =>
      fetchJson<Category>(`/api/categories/${id}`, {
        method: "PUT",
        body: JSON.stringify(data),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["categories"] });
    },
  });
}

export function useDeleteCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) =>
      fetchJson<{ id: string }>(`/api/categories/${id}`, {
        method: "DELETE",
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["categories"] });
    },
  });
}
