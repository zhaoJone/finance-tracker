"""
Tests for CategoryMatcher service.
"""
from uuid import uuid4

import pytest

from src.repository.category_match_rule import CategoryMatchRuleRepository
from src.schemas.category_match_rule import CategoryMatchRule
from src.service.category_matcher import CategoryMatcher


class MockRuleRepo(CategoryMatchRuleRepository):
    """In-memory mock for CategoryMatchRuleRepository."""

    def __init__(self) -> None:
        self._rules: list[CategoryMatchRule] = []

    async def create(self, rule: CategoryMatchRule) -> CategoryMatchRule:
        self._rules.append(rule)
        return rule

    async def match_by_keyword(self, user_id: str, keyword: str) -> CategoryMatchRule | None:
        # Exact match
        for r in self._rules:
            if r.keyword == keyword and str(r.user_id) == user_id:
                return r
        # Partial match
        for r in self._rules:
            if r.keyword in keyword.replace(" ", "") and str(r.user_id) == user_id:
                return r
        return None

    async def list(self, user_id: str) -> list[CategoryMatchRule]:
        return [r for r in self._rules if str(r.user_id) == user_id]


@pytest.fixture
def matcher() -> CategoryMatcher:
    return CategoryMatcher(MockRuleRepo())


@pytest.fixture
def uid() -> str:
    return str(uuid4())


@pytest.fixture
def cat_id() -> str:
    return str(uuid4())


class TestCategoryMatcher:
    @pytest.mark.asyncio
    async def test_match_exact(self, matcher: CategoryMatcher, uid: str, cat_id: str) -> None:
        await matcher._rule_repo.create(CategoryMatchRule(
            id=uuid4(), user_id=uid, keyword="麦当劳", category_id=cat_id,
        ))
        result = await matcher.match(user_id=uid, keyword="麦当劳")
        assert result is not None
        assert str(result.category_id) == cat_id

    @pytest.mark.asyncio
    async def test_match_partial(self, matcher: CategoryMatcher, uid: str, cat_id: str) -> None:
        await matcher._rule_repo.create(CategoryMatchRule(
            id=uuid4(), user_id=uid, keyword="麦当劳", category_id=cat_id,
        ))
        result = await matcher.match(user_id=uid, keyword="麦当劳（xx路店）")
        assert result is not None
        assert str(result.category_id) == cat_id

    @pytest.mark.asyncio
    async def test_no_match(self, matcher: CategoryMatcher, uid: str, cat_id: str) -> None:
        await matcher._rule_repo.create(CategoryMatchRule(
            id=uuid4(), user_id=uid, keyword="麦当劳", category_id=cat_id,
        ))
        result = await matcher.match(user_id=uid, keyword="肯德基")
        assert result is None

    @pytest.mark.asyncio
    async def test_match_all(self, matcher: CategoryMatcher, uid: str, cat_id: str) -> None:
        await matcher._rule_repo.create(CategoryMatchRule(
            id=uuid4(), user_id=uid, keyword="麦当劳", category_id=cat_id,
        ))
        results = await matcher.match_all(user_id=uid, keywords=["麦当劳", "星巴克"])
        assert results["麦当劳"] is not None
        assert str(results["麦当劳"].category_id) == cat_id
        assert results["星巴克"] is None

    @pytest.mark.asyncio
    async def test_match_all_deduplicates(self, matcher: CategoryMatcher, uid: str, cat_id: str) -> None:
        await matcher._rule_repo.create(CategoryMatchRule(
            id=uuid4(), user_id=uid, keyword="麦当劳", category_id=cat_id,
        ))
        results = await matcher.match_all(user_id=uid, keywords=["麦当劳", "麦当劳", "麦当劳"])
        assert len(results) == 1

    @pytest.mark.asyncio
    async def test_no_rules_returns_none(self, matcher: CategoryMatcher, uid: str) -> None:
        result = await matcher.match(user_id=uid, keyword="麦当劳")
        assert result is None

    @pytest.mark.asyncio
    async def test_user_isolation(self, matcher: CategoryMatcher, cat_id: str) -> None:
        uid_a = str(uuid4())
        uid_b = str(uuid4())
        await matcher._rule_repo.create(CategoryMatchRule(
            id=uuid4(), user_id=uid_a, keyword="麦当劳", category_id=cat_id,
        ))
        result_a = await matcher.match(user_id=uid_a, keyword="麦当劳")
        result_b = await matcher.match(user_id=uid_b, keyword="麦当劳")
        assert result_a is not None
        assert result_b is None
