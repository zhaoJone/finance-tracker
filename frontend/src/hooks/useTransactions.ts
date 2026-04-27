import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import type { Transaction, TransactionCreate, TransactionFilter } from "@/schemas/transaction";

interface ApiResponse<T> {
  data: T;
  message: string;
}

interface ErrorResponse {
  error: string;
  code: string;
  detail?: string;
}

async function fetchJson<T>(url: string, options?: RequestInit): Promise<T> {
  const token = localStorage.getItem("token");
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const response = await fetch(url, {
    headers,
    ...options,
  });

  if (!response.ok) {
    const error: ErrorResponse = await response.json();
    throw new Error(error.detail || error.error || "API Error");
  }

  const result: ApiResponse<T> = await response.json();
  return result.data;
}

export function useTransactions(options: { filters?: TransactionFilter } = {}) {
  const { filters = {} } = options;
  const params = new URLSearchParams();
  if (filters.start_date) params.set("start_date", filters.start_date);
  if (filters.end_date) params.set("end_date", filters.end_date);
  if (filters.category_id) params.set("category_id", filters.category_id);
  if (filters.type) params.set("type", filters.type);

  const queryString = params.toString();
  const url = `/api/transactions${queryString ? `?${queryString}` : ""}`;

  return useQuery<Transaction[]>({
    queryKey: ["transactions", filters],
    queryFn: () => fetchJson<Transaction[]>(url),
  });
}

export function useCreateTransaction() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: TransactionCreate) =>
      fetchJson<Transaction>("/api/transactions", {
        method: "POST",
        body: JSON.stringify(data),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["transactions"] });
      queryClient.invalidateQueries({ queryKey: ["stats"] });
    },
  });
}
