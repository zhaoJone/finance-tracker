export type TransactionType = "income" | "expense";

export interface Transaction {
  id: string;
  amount: number;
  category_id: string;
  note: string;
  date: string;
  type: TransactionType;
  created_at: string;
}

export interface TransactionCreate {
  amount: number;
  category_id: string;
  note?: string;
  date: string;
  type: TransactionType;
}

export interface TransactionUpdate {
  category_id?: string;
  note?: string;
}

export interface TransactionFilter {
  start_date?: string;
  end_date?: string;
  category_id?: string;
  type?: TransactionType;
}
