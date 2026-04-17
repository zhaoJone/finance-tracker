import { BrowserRouter, Routes, Route, Link } from "react-router-dom";
import { DashboardPage, TransactionsPage, CategoriesPage } from "@/pages";

function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-gray-50">
        <nav className="bg-white border-b border-gray-200">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex gap-6 h-14">
              <Link
                to="/"
                className="flex items-center text-sm font-medium text-gray-900"
              >
                仪表盘
              </Link>
              <Link
                to="/transactions"
                className="flex items-center text-sm font-medium text-gray-500 hover:text-gray-900"
              >
                交易记录
              </Link>
              <Link
                to="/categories"
                className="flex items-center text-sm font-medium text-gray-500 hover:text-gray-900"
              >
                分类管理
              </Link>
            </div>
          </div>
        </nav>
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <Routes>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/transactions" element={<TransactionsPage />} />
            <Route path="/categories" element={<CategoriesPage />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}

export default App;
