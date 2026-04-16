"""
Tests for category model.
"""
from uuid import uuid4

import pytest
from pydantic import ValidationError

from src.schemas import Category


class TestCategory:
    def test_valid_category(self) -> None:
        cat = Category(
            id=uuid4(),
            name="Food",
            color="#FF5733",
            type="expense",
        )
        assert cat.name == "Food"
        assert cat.color == "#FF5733"

    def test_income_category(self) -> None:
        cat = Category(
            id=uuid4(),
            name="Salary",
            color="#00FF00",
            type="income",
        )
        assert cat.type == "income"

    def test_invalid_type(self) -> None:
        with pytest.raises(ValidationError):
            Category(
                id=uuid4(),
                name="Test",
                color="#000000",
                type="invalid",
            )

    def test_name_strip_whitespace(self) -> None:
        cat = Category(
            id=uuid4(),
            name="  Food  ",
            color="#FF5733",
            type="expense",
        )
        assert cat.name == "Food"

    def test_empty_name_fails(self) -> None:
        with pytest.raises(ValidationError):
            Category(
                id=uuid4(),
                name="",
                color="#FF5733",
                type="expense",
            )
