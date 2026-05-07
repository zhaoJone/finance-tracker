"""
CategoryMatcher - match notification counterparty to category via user-defined rules.

Used by:
- NotificationService.import_notifications() for auto-categorization
- Mobile app to pre-fill category dropdown selections
"""
from src.repository.category_match_rule import CategoryMatchRuleRepository
from src.schemas.category_match_rule import CategoryMatchRule


class CategoryMatcher:
    """Match merchant names to categories using user-defined keyword rules."""

    def __init__(self, rule_repo: CategoryMatchRuleRepository) -> None:
        self._rule_repo = rule_repo

    async def match(self, user_id: str, keyword: str) -> CategoryMatchRule | None:
        """Try to find a matching rule for the given merchant keyword.
        
        Matching strategy:
        1. Exact match on keyword
        2. Partial match: rule.keyword is contained in merchant keyword
        """
        return await self._rule_repo.match_by_keyword(user_id, keyword)

    async def match_all(
        self, user_id: str, keywords: list[str]
    ) -> dict[str, CategoryMatchRule | None]:
        """Batch match multiple keywords. Returns {keyword: rule_or_None}."""
        results: dict[str, CategoryMatchRule | None] = {}
        for kw in keywords:
            if kw not in results:
                results[kw] = await self.match(user_id, kw)
        return results
