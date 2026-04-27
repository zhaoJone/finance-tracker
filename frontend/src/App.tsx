import { BrowserRouter, Routes, Route, Link, Navigate } from "react-router-dom";
import { DashboardPage, TransactionsPage, CategoriesPage } from "@/pages";
import LoginPage from "@/pages/LoginPage";
import RegisterPage from "@/pages/RegisterPage";
import { useAuth } from "@/contexts/AuthContext";

function NavBar() {
  const { user, logout } = useAuth();
  return (
    <nav className="bg-white border-b border-gray-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-14">
          <div className="flex gap-6">
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
          <div className="flex items-center gap-3">
            <span className="text-sm text-gray-500">{user?.email}</span>
            <button
              onClick={logout}
              className="text-sm text-gray-500 hover:text-gray-900"
            >
              退出
            </button>
          </div>
        </div>
      </div>
    </nav>
  );
}

function ProtectedLayout({ children }: { children: React.ReactNode }) {
  const { user, isLoading } = useAuth();
  if (isLoading) return null;
  if (!user) return <Navigate to="/login" replace />;
  return (
    <>
      <NavBar />
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">{children}</main>
    </>
  );
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route
          path="/"
          element={
            <ProtectedLayout>
              <DashboardPage />
            </ProtectedLayout>
          }
        />
        <Route
          path="/transactions"
          element={
            <ProtectedLayout>
              <TransactionsPage />
            </ProtectedLayout>
          }
        />
        <Route
          path="/categories"
          element={
            <ProtectedLayout>
              <CategoriesPage />
            </ProtectedLayout>
          }
        />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
