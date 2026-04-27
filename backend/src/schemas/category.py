"""
Category domain model.
"""
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


class Category(BaseModel):
    """A category for transactions."""

    id: UUID
    user_id: UUID
    name: str = Field(..., min_length=1, max_length=50)
    color: str = Field(..., description="Hex color code, e.g. #FF5733")
    type: Literal["income", "expense"]

    model_config = {"str_strip_whitespace": True}
