"""
Category API routes.
"""
from typing import Any

from fastapi import APIRouter, Depends
import aiosqlite

from src.api.responses import success_response
from src.repository import CategoryRepository

router = APIRouter(prefix="/api/categories", tags=["categories"])


async def get_db() -> Any:
    """Create and yield an async SQLite connection."""
    db = await aiosqlite.connect(":memory:")
    db.row_factory = aiosqlite.Row
    try:
        yield db
    finally:
        await db.close()


async def get_category_repo(db: Any = Depends(get_db)) -> CategoryRepository:
    """Dependency injection for CategoryRepository."""
    return CategoryRepository(db)


@router.get("")
async def list_categories(
    repo: CategoryRepository = Depends(get_category_repo),
) -> Any:
    """List all categories."""
    categories = await repo.list()
    return success_response(data=[cat.model_dump(mode="json") for cat in categories])