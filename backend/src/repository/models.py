"""
SQLAlchemy ORM models for database tables.
"""
import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy models."""
    pass


class UserTable(Base):
    """SQLAlchemy model for users table."""

    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=func.now(), nullable=False)

    categories: Mapped[list["CategoryTable"]] = relationship("CategoryTable", back_populates="user")
    transactions: Mapped[list["TransactionTable"]] = relationship("TransactionTable", back_populates="user")


class CategoryTable(Base):
    """SQLAlchemy model for categories table."""

    __tablename__ = "categories"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    color: Mapped[str] = mapped_column(String(20), nullable=False)
    type: Mapped[str] = mapped_column(String(10), nullable=False)

    user: Mapped["UserTable"] = relationship("UserTable", back_populates="categories")
    transactions: Mapped[list["TransactionTable"]] = relationship(
        "TransactionTable", back_populates="category"
    )


class TransactionTable(Base):
    """SQLAlchemy model for transactions table."""

    __tablename__ = "transactions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    amount: Mapped[int] = mapped_column(Integer, nullable=False)
    category_id: Mapped[str] = mapped_column(String(36), ForeignKey("categories.id"), nullable=False)
    note: Mapped[str] = mapped_column(Text, default="")
    date: Mapped[datetime.date] = mapped_column(nullable=False)
    type: Mapped[str] = mapped_column(String(10), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=func.now(), nullable=False)

    user: Mapped["UserTable"] = relationship("UserTable", back_populates="transactions")
    category: Mapped["CategoryTable"] = relationship("CategoryTable", back_populates="transactions")
