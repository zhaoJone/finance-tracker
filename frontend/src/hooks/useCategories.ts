import { useQuery } from "@tanstack/react-query";
import type { Category } from "@/schemas/category";

interface ApiResponse<T> {
  data: T;
  message: string;
}

async function fetchJson<T>(url: string): Promise<T> {
  const response = await fetch(url, {
    headers: {
      "Content-Type": "application/json",
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
  return useQuery<Category[]>({
    queryKey: ["categories"],
    queryFn: () => fetchJson<Category[]>("/api/categories"),
  });
}
