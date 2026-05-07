"""
Category Match Rule API - user-managed keyword-to-category mappings.
"""
from typing import Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends

from src.api.deps import DBSession, get_current_user
from src.api.responses import error_response, success_response
from src.repository.category_match_rule import CategoryMatchRuleRepository
from src.schemas.category_match_rule import CategoryMatchRule, CategoryMatchRuleCreate
from src.schemas.user import User

router = APIRouter(prefix="/api/category-match-rules", tags=["category-match-rules"])


async def get_rule_repo(db: DBSession) -> CategoryMatchRuleRepository:
    """Dependency injection for CategoryMatchRuleRepository."""
    return CategoryMatchRuleRepository(db)


@router.get("")
async def list_rules(
    rule_repo: CategoryMatchRuleRepository = Depends(get_rule_repo),
    user: User = Depends(get_current_user),
) -> Any:
    """List all match rules for the current user."""
    rules = await rule_repo.list(user_id=str(user.id))
    return success_response(data=[r.model_dump(mode="json") for r in rules])


@router.post("")
async def create_rule(
    body: CategoryMatchRuleCreate,
    rule_repo: CategoryMatchRuleRepository = Depends(get_rule_repo),
    user: User = Depends(get_current_user),
) -> Any:
    """Create a new match rule (keyword → category)."""
    # Check if keyword already exists for this user
    existing = await rule_repo.find_by_keyword(user_id=str(user.id), keyword=body.keyword)
    if existing is not None:
        return error_response(
            error="Rule already exists",
            code="RULE_EXISTS",
            detail=f"Keyword '{body.keyword}' already has a match rule",
            status_code=409,
        )

    now = __import__("datetime").datetime.now()
    rule = CategoryMatchRule(
        id=uuid4(),
        user_id=user.id,
        keyword=body.keyword,
        category_id=body.category_id,
        created_at=now,
    )
    created = await rule_repo.create(rule)
    return success_response(data=created.model_dump(mode="json"), message="Rule created")


@router.delete("/{rule_id}")
async def delete_rule(
    rule_id: UUID,
    rule_repo: CategoryMatchRuleRepository = Depends(get_rule_repo),
    user: User = Depends(get_current_user),
) -> Any:
    """Delete a match rule."""
    deleted = await rule_repo.delete(rule_id, user_id=str(user.id))
    if not deleted:
        return error_response(
            error="Not found",
            code="RULE_NOT_FOUND",
            detail=f"Rule {rule_id} not found or not owned by user",
            status_code=404,
        )
    return success_response(data={"id": str(rule_id)}, message="Rule deleted")
