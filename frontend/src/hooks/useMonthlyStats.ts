import { useQuery } from "@tanstack/react-query";
import type { MonthlySummary } from "@/schemas/stats";

interface ApiResponse<T> {
  data: T;
  message: string;
}

async function fetchJson<T>(url: string): Promise<T> {
  const token = localStorage.getItem("token");
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const response = await fetch(url, { headers });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail || error.error || "API Error");
  }

  const result: ApiResponse<T> = await response.json();
  return result.data;
}

export interface UseMonthlyStatsOptions {
  year: number;
  month: number;
}

export function useMonthlyStats(options: UseMonthlyStatsOptions) {
  const { year, month } = options;

  return useQuery<MonthlySummary>({
    queryKey: ["stats", "monthly", year, month],
    queryFn: () =>
      fetchJson<MonthlySummary>(
        `/api/stats/monthly?year=${year}&month=${month}`
      ),
  });
}
