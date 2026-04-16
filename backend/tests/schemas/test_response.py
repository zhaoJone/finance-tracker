"""
Tests for response models.
"""
import pytest
from pydantic import ValidationError

from src.schemas import ErrorResponse, SuccessResponse


class TestSuccessResponse:
    def test_with_data(self) -> None:
        resp = SuccessResponse(data={"key": "value"}, message="OK")
        assert resp.data == {"key": "value"}
        assert resp.message == "OK"

    def test_default_message(self) -> None:
        resp = SuccessResponse(data=[1, 2, 3])
        assert resp.message == "OK"

    def test_with_string_data(self) -> None:
        resp = SuccessResponse(data="hello")
        assert resp.data == "hello"


class TestErrorResponse:
    def test_basic_error(self) -> None:
        resp = ErrorResponse(error="Not found", code="NOT_FOUND")
        assert resp.error == "Not found"
        assert resp.code == "NOT_FOUND"
        assert resp.detail is None

    def test_with_detail(self) -> None:
        resp = ErrorResponse(
            error="Validation error",
            code="VALIDATION_ERROR",
            detail="Field 'amount' must be positive",
        )
        assert resp.detail == "Field 'amount' must be positive"

    def test_missing_required_fields(self) -> None:
        with pytest.raises(ValidationError):
            ErrorResponse(error="Only error")
