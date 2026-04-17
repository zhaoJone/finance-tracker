"""
API request/response schemas for transactions.
"""
from datetime import date
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class TransactionCreate(BaseModel):
    """Request body for creating a transaction."""

    amount: int = Field(..., description="Amount in cents (fen)", gt=0)
    category_id: UUID
    note: str = ""
    date: date
    type: Literal["income", "expense"]


class TransactionUpdate(BaseModel):
    """Request body for updating a transaction."""

    amount: Optional[int] = Field(None, description="Amount in cents (fen)", gt=0)
    category_id: Optional[UUID] = None
    note: Optional[str] = None
    date: Optional[date] = None
    type: Optional[Literal["income", "expense"]] = None


class TransactionFilter(BaseModel):
    """Query parameters for listing transactions."""

    start_date: Optional[date] = None
    end_date: Optional[date] = None
    category_id: Optional[UUID] = None
    type: Optional[Literal["income", "expense"]] = None


class CategoryCreate(BaseModel):
    """Request body for creating a category."""

    name: str = Field(..., min_length=1, max_length=10)
    color: str = Field(..., description="Hex color code, e.g. #FF5733")
    type: Literal["income", "expense"]


class CategoryUpdate(BaseModel):
    """Request body for updating a category."""

    name: Optional[str] = Field(None, min_length=1, max_length=10)
    color: Optional[str] = None