"""
统一响应类型：SuccessResponse 和 ErrorResponse。
"""
from typing import Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class SuccessResponse(BaseModel, Generic[T]):
    """统一成功响应格式。"""

    data: T
    message: str = "OK"


class ErrorResponse(BaseModel):
    """统一错误响应格式。"""

    error: str
    code: str
    detail: str | None = None
