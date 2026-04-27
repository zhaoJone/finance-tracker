"""
Tests for transaction model.
"""
from datetime import date, datetime
from uuid import uuid4

import pytest
from pydantic import ValidationError

from src.schemas import Transaction


class TestTransaction:
    def test_valid_transaction(self) -> None:
        uid = uuid4()
        tx = Transaction(
            id=uuid4(),
            user_id=uid,
            amount=1000,
            category_id=uuid4(),
            note="Test",
            date=date(2026, 1, 1),
            type="income",
            created_at=datetime(2026, 1, 1, 12, 0, 0),
        )
        assert tx.type == "income"
        assert tx.amount == 1000

    def test_expense_transaction(self) -> None:
        uid = uuid4()
        tx = Transaction(
            id=uuid4(),
            user_id=uid,
            amount=500,
            category_id=uuid4(),
            note="",
            date=date(2026, 4, 15),
            type="expense",
            created_at=datetime.now(),
        )
        assert tx.type == "expense"
        assert tx.note == ""

    def test_invalid_type(self) -> None:
        with pytest.raises(ValidationError):
            Transaction(
                id=uuid4(),
                user_id=uuid4(),
                amount=100,
                category_id=uuid4(),
                note="",
                date=date(2026, 1, 1),
                type="invalid",
                created_at=datetime.now(),
            )

    def test_note_strip_whitespace(self) -> None:
        uid = uuid4()
        tx = Transaction(
            id=uuid4(),
            user_id=uid,
            amount=100,
            category_id=uuid4(),
            note="  hello  ",
            date=date(2026, 1, 1),
            type="income",
            created_at=datetime.now(),
        )
        assert tx.note == "hello"
