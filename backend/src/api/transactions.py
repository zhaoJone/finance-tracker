"""
Transaction API routes - all endpoints require authentication.
"""
from datetime import datetime
from typing import Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, Query

from src.api.deps import DBSession, get_current_user
from src.api.responses import error_response, success_response
from src.api.schemas import TransactionCreate, TransactionUpdate
from src.repository import CategoryRepository, TransactionRepository
from src.schemas import Transaction
from src.schemas.user import User

router = APIRouter(prefix="/api/transactions", tags=["transactions"])


async def get_tx_repo(db: DBSession) -> TransactionRepository:
    """Dependency injection for TransactionRepository."""
    return TransactionRepository(db)


async def get_category_repo(db: DBSession) -> CategoryRepository:
    """Dependency injection for CategoryRepository."""
    return CategoryRepository(db)


@router.get("")
async def list_transactions(
    start_date: str | None = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: str | None = Query(None, description="End date (YYYY-MM-DD)"),
    category_id: UUID | None = Query(None, description="Filter by category"),
    type: str | None = Query(None, description="income or expense"),
    repo: TransactionRepository = Depends(get_tx_repo),
    user: User = Depends(get_current_user),
) -> Any:
    """List transactions with optional filters (user-scoped)."""
    from datetime import date as date_type

    parsed_start = date_type.fromisoformat(start_date) if start_date else None
    parsed_end = date_type.fromisoformat(end_date) if end_date else None

    transactions = await repo.list(
        user_id=str(user.id),
        start_date=parsed_start,
        end_date=parsed_end,
        category_id=category_id,
        tx_type=type,
    )
    return success_response(data=[tx.model_dump(mode="json") for tx in transactions])


@router.post("")
async def create_transaction(
    body: TransactionCreate,
    repo: TransactionRepository = Depends(get_tx_repo),
    user: User = Depends(get_current_user),
) -> Any:
    """Create a new transaction for the current user."""
    now = datetime.now()
    tx = Transaction(
        id=uuid4(),
        user_id=user.id,
        amount=body.amount,
        category_id=body.category_id,
        note=body.note,
        date=body.date,
        type=body.type,
        created_at=now,
    )
    created = await repo.create(tx)
    return success_response(data=created.model_dump(mode="json"), message="Transaction created")


@router.put("/{tx_id}")
async def update_transaction(
    tx_id: UUID,
    body: TransactionUpdate,
    repo: TransactionRepository = Depends(get_tx_repo),
    user: User = Depends(get_current_user),
) -> Any:
    """Update an existing transaction (only if owned by current user)."""
    existing = await repo.get(tx_id, user_id=str(user.id))
    if existing is None:
        return error_response(
            error="Not found",
            code="TRANSACTION_NOT_FOUND",
            detail=f"Transaction {tx_id} not found",
            status_code=404,
        )

    updated_data = existing.model_dump()
    update_data = body.model_dump(exclude_unset=True)
    updated_data.update(update_data)

    updated_tx = Transaction(**updated_data)
    result = await repo.update(updated_tx)
    if result is None:
        return error_response(
            error="Update failed",
            code="UPDATE_FAILED",
            detail="Transaction was not updated",
            status_code=400,
        )
    return success_response(data=result.model_dump(mode="json"), message="Transaction updated")


@router.delete("/{tx_id}")
async def delete_transaction(
    tx_id: UUID,
    repo: TransactionRepository = Depends(get_tx_repo),
    user: User = Depends(get_current_user),
) -> Any:
    """Delete a transaction (only if owned by current user)."""
    existing = await repo.get(tx_id, user_id=str(user.id))
    if existing is None:
        return error_response(
            error="Not found",
            code="TRANSACTION_NOT_FOUND",
            detail=f"Transaction {tx_id} not found",
            status_code=404,
        )

    deleted = await repo.delete(tx_id)
    if not deleted:
        return error_response(
            error="Delete failed",
            code="DELETE_FAILED",
            detail="Transaction was not deleted",
            status_code=400,
        )
    return success_response(data={"id": str(tx_id)}, message="Transaction deleted")
