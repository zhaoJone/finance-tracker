"""
统一响应辅助函数。
"""
from typing import Any

from fastapi.responses import JSONResponse

from src.schemas import ErrorResponse, SuccessResponse


def success_response(data: Any, message: str = "OK") -> JSONResponse:
    """构建统一成功响应。"""
    return JSONResponse(
        content=SuccessResponse(data=data, message=message).model_dump(),
        status_code=200,
    )


def error_response(
    error: str,
    code: str,
    detail: str | None = None,
    status_code: int = 400,
) -> JSONResponse:
    """构建统一错误响应。"""
    return JSONResponse(
        content=ErrorResponse(error=error, code=code, detail=detail).model_dump(),
        status_code=status_code,
    )