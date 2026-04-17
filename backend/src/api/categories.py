"""
Category API routes.
"""
from typing import Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.responses import error_response, success_response
from src.api.schemas import CategoryCreate, CategoryUpdate
from src.config.database import get_db
from src.repository import CategoryRepository
from src.schemas import Category

router = APIRouter(prefix="/api/categories", tags=["categories"])


async def get_category_repo(db: AsyncSession = Depends(get_db)) -> CategoryRepository:
    """Dependency injection for CategoryRepository."""
    return CategoryRepository(db)


@router.get("")
async def list_categories(
    repo: CategoryRepository = Depends(get_category_repo),
) -> Any:
    """List all categories grouped by type."""
    categories = await repo.list()
    income = [c.model_dump(mode="json") for c in categories if c.type == "income"]
    expense = [c.model_dump(mode="json") for c in categories if c.type == "expense"]
    return success_response(data={"income": income, "expense": expense})


@router.post("")
async def create_category(
    body: CategoryCreate,
    repo: CategoryRepository = Depends(get_category_repo),
) -> Any:
    """Create a new category."""
    category = Category(
        id=uuid4(),
        name=body.name,
        color=body.color,
        type=body.type,
    )
    created = await repo.create(category)
    return success_response(data=created.model_dump(mode="json"), message="Category created")


@router.put("/{cat_id}")
async def update_category(
    cat_id: UUID,
    body: CategoryUpdate,
    repo: CategoryRepository = Depends(get_category_repo),
) -> Any:
    """Update an existing category."""
    existing = await repo.get(cat_id)
    if existing is None:
        return error_response(
            error="Not found",
            code="CATEGORY_NOT_FOUND",
            detail=f"Category {cat_id} not found",
            status_code=404,
        )

    update_data = body.model_dump(exclude_unset=True)
    updated_category = Category(
        id=existing.id,
        name=update_data.get("name", existing.name),
        color=update_data.get("color", existing.color),
        type=existing.type,
    )
    result = await repo.update(updated_category)
    if result is None:
        return error_response(
            error="Update failed",
            code="UPDATE_FAILED",
            detail="Category was not updated",
            status_code=400,
        )
    return success_response(data=result.model_dump(mode="json"), message="Category updated")


@router.delete("/{cat_id}")
async def delete_category(
    cat_id: UUID,
    repo: CategoryRepository = Depends(get_category_repo),
) -> Any:
    """Delete a category. Fails with 409 if transactions are linked."""
    existing = await repo.get(cat_id)
    if existing is None:
        return error_response(
            error="Not found",
            code="CATEGORY_NOT_FOUND",
            detail=f"Category {cat_id} not found",
            status_code=404,
        )

    tx_count = await repo.count_transactions(cat_id)
    if tx_count > 0:
        return error_response(
            error="Conflict",
            code="CATEGORY_HAS_TRANSACTIONS",
            detail=f"Cannot delete category with {tx_count} linked transactions",
            status_code=409,
        )

    deleted = await repo.delete(cat_id)
    if not deleted:
        return error_response(
            error="Delete failed",
            code="DELETE_FAILED",
            detail="Category was not deleted",
            status_code=400,
        )
    return success_response(data={"id": str(cat_id)}, message="Category deleted")
