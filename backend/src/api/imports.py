"""
Notification import API routes - imports with per-notification categories.
"""
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends

from src.api.deps import DBSession, get_current_user
from src.api.responses import error_response, success_response
from src.repository import CategoryRepository, TransactionRepository
from src.repository.category_match_rule import CategoryMatchRuleRepository
from src.schemas.notification import ParsedNotification
from src.schemas.user import User
from src.service.notification import NotificationService

router = APIRouter(prefix="/api/transactions", tags=["transactions"])


async def get_tx_repo(db: DBSession) -> TransactionRepository:
    """Dependency injection for TransactionRepository."""
    return TransactionRepository(db)


async def get_category_repo(db: DBSession) -> CategoryRepository:
    """Dependency injection for CategoryRepository."""
    return CategoryRepository(db)


async def get_rule_repo(db: DBSession) -> CategoryMatchRuleRepository:
    """Dependency injection for CategoryMatchRuleRepository."""
    return CategoryMatchRuleRepository(db)


@router.post("/import")
async def import_notifications(
    notifications: list[ParsedNotification],
    default_category_id: UUID | None = None,
    tx_repo: TransactionRepository = Depends(get_tx_repo),
    category_repo: CategoryRepository = Depends(get_category_repo),
    rule_repo: CategoryMatchRuleRepository = Depends(get_rule_repo),
    user: User = Depends(get_current_user),
) -> Any:
    """
    批量导入支付通知，自动去重。

    - notifications: 解析后的通知列表（每条可带 category_id）
    - default_category_id: 未指定分类时的默认值
    """
    # Validate default_category_id if provided
    if default_category_id is not None:
        category = await category_repo.get(default_category_id, user_id=str(user.id))
        if category is None:
            return error_response(
                error="Category not found",
                code="CATEGORY_NOT_FOUND",
                detail="default_category_id does not belong to current user",
                status_code=400,
            )

    service = NotificationService(tx_repo, category_repo, rule_repo)
    result = await service.import_notifications(
        notifications=notifications,
        user_id=user.id,
        default_category_id=default_category_id,
    )
    return success_response(data=result, message="Import completed")


@router.get("/unclassified")
async def list_unclassified_transactions(
    tx_repo: TransactionRepository = Depends(get_tx_repo),
    category_repo: CategoryRepository = Depends(get_category_repo),
    user: User = Depends(get_current_user),
) -> Any:
    """List transactions with untracked categories (for future 'unclassified' support)."""
    # Fetch all categories for this user
    categories = await category_repo.list(user_id=str(user.id))
    category_ids = {str(c.id) for c in categories}

    # Fetch all transactions
    all_txs = await tx_repo.list(user_id=str(user.id))
    # Filter transactions whose category_id is not in the user's category list
    unclassified = [tx for tx in all_txs if str(tx.category_id) not in category_ids]

    tx_dicts = []
    for tx in unclassified:
        d = tx.model_dump(mode="json")
        d["category_name"] = None
        d["category_color"] = None
        tx_dicts.append(d)

    return success_response(data=tx_dicts)


@router.patch("/batch-category")
async def batch_update_category(
    transaction_ids: list[UUID],
    category_id: UUID,
    tx_repo: TransactionRepository = Depends(get_tx_repo),
    category_repo: CategoryRepository = Depends(get_category_repo),
    user: User = Depends(get_current_user),
) -> Any:
    """
    Batch update multiple transactions to the same category.
    Previously used for 'unclassified' batch processing.
    """
    # Validate category belongs to user
    cat = await category_repo.get(category_id, user_id=str(user.id))
    if cat is None:
        return error_response(
            error="Category not found",
            code="CATEGORY_NOT_FOUND",
            detail="category_id does not belong to current user",
            status_code=400,
        )

    updated = 0
    errors: list[str] = []
    for tx_id in transaction_ids:
        existing = await tx_repo.get(tx_id, user_id=str(user.id))
        if existing is None:
            errors.append(f"Transaction {tx_id} not found")
            continue

        updated_data = existing.model_dump()
        updated_data["category_id"] = category_id
        from src.schemas import Transaction

        updated_tx = Transaction(**updated_data)
        result = await tx_repo.update(updated_tx)
        if result is not None:
            updated += 1
        else:
            errors.append(f"Failed to update {tx_id}")

    return success_response(
        data={"updated": updated, "errors": errors},
        message=f"Updated {updated} transactions",
    )
