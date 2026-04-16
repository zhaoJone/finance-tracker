export interface MonthlySummary {
  year: number;
  month: number;
  income: number;
  expense: number;
  balance: number;
}

export interface CategoryBreakdown {
  category_id: string;
  category_name: string;
  amount: number;
  percentage: number;
}

export interface CategorySummary {
  categories: CategoryBreakdown[];
  total_income: number;
  total_expense: number;
}
