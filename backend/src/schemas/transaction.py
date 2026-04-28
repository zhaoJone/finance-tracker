"""
Transaction domain model.
"""
from datetime import date, datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


class Transaction(BaseModel):
    """A financial transaction (income or expense)."""

    id: UUID
    user_id: UUID
    amount: int = Field(..., description="Amount in cents (fen)")
    category_id: UUID
    note: str = ""
    date: date
    type: Literal["income", "expense"]
    trade_no: str = ""
    created_at: datetime

    model_config = {"str_strip_whitespace": True}
