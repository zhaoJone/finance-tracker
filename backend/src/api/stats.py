"""
Stats API routes.
"""
from datetime import date as date_type
from typing import Any

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.responses import success_response
from src.config.database import get_db
from src.repository import CategoryRepository, TransactionRepository
from src.service import TransactionService

router = APIRouter(prefix="/api/stats", tags=["stats"])


async def get_service(db: AsyncSession = Depends(get_db)) -> TransactionService:
    """Dependency injection for TransactionService."""
    tx_repo = TransactionRepository(db)
    cat_repo = CategoryRepository(db)
    return TransactionService(tx_repo, cat_repo)


@router.get("/monthly")
async def get_monthly_stats(
    year: int = Query(..., description="Year (e.g. 2026)"),
    month: int = Query(..., ge=1, le=12, description="Month (1-12)"),
    service: TransactionService = Depends(get_service),
) -> Any:
    """Get monthly income/expense summary."""
    summary = await service.get_monthly_summary(year, month)
    return success_response(data=summary.model_dump(mode="json"))


@router.get("/by-category")
async def get_by_category_stats(
    start_date: str | None = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: str | None = Query(None, description="End date (YYYY-MM-DD)"),
    service: TransactionService = Depends(get_service),
) -> Any:
    """Get breakdown by category."""
    parsed_start = date_type.fromisoformat(start_date) if start_date else None
    parsed_end = date_type.fromisoformat(end_date) if end_date else None

    summary = await service.get_category_summary(
        start_date=parsed_start,
        end_date=parsed_end,
    )
    return success_response(data=summary.model_dump(mode="json"))
