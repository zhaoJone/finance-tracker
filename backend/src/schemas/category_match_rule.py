"""
CategoryMatchRule - represents a user-configured keyword-to-category mapping.
"""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class CategoryMatchRule(BaseModel):
    """A user-defined rule: when notification counterparty contains keyword, auto-assign category."""

    id: UUID
    user_id: UUID
    keyword: str = Field(..., min_length=1, max_length=100)
    category_id: UUID
    created_at: datetime = Field(default_factory=datetime.now)

    model_config = {"str_strip_whitespace": True}


class CategoryMatchRuleCreate(BaseModel):
    """Request body for creating a match rule."""

    keyword: str = Field(..., min_length=1, max_length=100, description="Merchant keyword to match")
    category_id: UUID
