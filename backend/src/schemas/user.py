"""
User domain model and auth schemas.
"""
from datetime import datetime
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator


class User(BaseModel):
    """Authenticated user."""

    id: UUID
    email: EmailStr
    created_at: datetime

    model_config = {"str_strip_whitespace": True}


class UserCreate(BaseModel):
    """Payload for user registration."""

    email: EmailStr
    password: Annotated[str, Field(min_length=6, max_length=128)]

    @field_validator("password")
    @classmethod
    def password_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("password cannot be empty")
        return v


class UserLogin(BaseModel):
    """Payload for user login."""

    email: EmailStr
    password: str = Field(..., min_length=1)


class Token(BaseModel):
    """JWT access token response."""

    access_token: str
    token_type: Literal["bearer"] = "bearer"


class TokenData(BaseModel):
    """Payload extracted from JWT token."""

    user_id: str
