import { useQuery } from "@tanstack/react-query";
import type { CategorySummary } from "@/schemas/stats";

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

export interface UseCategoryStatsOptions {
  start_date?: string;
  end_date?: string;
}

export function useCategoryStats(options: UseCategoryStatsOptions = {}) {
  const { start_date, end_date } = options;

  const params = new URLSearchParams();
  if (start_date) params.set("start_date", start_date);
  if (end_date) params.set("end_date", end_date);

  const queryString = params.toString();
  const url = `/api/stats/by-category${queryString ? `?${queryString}` : ""}`;

  return useQuery<CategorySummary>({
    queryKey: ["stats", "by-category", start_date, end_date],
    queryFn: () => fetchJson<CategorySummary>(url),
  });
}
