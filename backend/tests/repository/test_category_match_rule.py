"""
Tests for CategoryMatchRuleRepository.
"""
from uuid import uuid4

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from src.repository.category_match_rule import CategoryMatchRuleRepository
from src.repository.models import Base
from src.schemas.category_match_rule import CategoryMatchRule


@pytest_asyncio.fixture
async def session() -> AsyncSession:
    """Create an in-memory SQLite database with SQLAlchemy."""
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    factory = async_sessionmaker(
        bind=engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with factory() as sess:
        yield sess
    await engine.dispose()


@pytest.fixture
def repo(session: AsyncSession) -> CategoryMatchRuleRepository:
    return CategoryMatchRuleRepository(session)


def make_rule(
    keyword: str = "麦当劳",
    category_id: str | None = None,
    user_id: str | None = None,
) -> CategoryMatchRule:
    if user_id is None:
        user_id = str(uuid4())
    if category_id is None:
        category_id = str(uuid4())
    return CategoryMatchRule(
        id=uuid4(),
        user_id=user_id,
        keyword=keyword,
        category_id=category_id,
    )


class TestCategoryMatchRuleRepositoryCreate:
    @pytest.mark.asyncio
    async def test_create_returns_rule(self, repo: CategoryMatchRuleRepository) -> None:
        rule = make_rule()
        result = await repo.create(rule)
        assert result.id == rule.id
        assert result.keyword == rule.keyword

    @pytest.mark.asyncio
    async def test_create_persists_to_db(self, repo: CategoryMatchRuleRepository) -> None:
        rule = make_rule()
        await repo.create(rule)
        rules = await repo.list(user_id=str(rule.user_id))
        assert len(rules) == 1
        assert rules[0].id == rule.id


class TestCategoryMatchRuleRepositoryList:
    @pytest.mark.asyncio
    async def test_list_empty(self, repo: CategoryMatchRuleRepository) -> None:
        result = await repo.list(user_id=str(uuid4()))
        assert result == []

    @pytest.mark.asyncio
    async def test_list_multiple(self, repo: CategoryMatchRuleRepository) -> None:
        uid = str(uuid4())
        cat_id = str(uuid4())
        for kw in ["麦当劳", "星巴克", "滴滴"]:
            await repo.create(make_rule(keyword=kw, user_id=uid, category_id=cat_id))
        result = await repo.list(user_id=uid)
        assert len(result) == 3

    @pytest.mark.asyncio
    async def test_list_user_scoped(self, repo: CategoryMatchRuleRepository) -> None:
        uid_a = str(uuid4())
        uid_b = str(uuid4())
        cat_id = str(uuid4())
        await repo.create(make_rule(keyword="麦当劳", user_id=uid_a, category_id=cat_id))
        await repo.create(make_rule(keyword="星巴克", user_id=uid_b, category_id=cat_id))
        assert len(await repo.list(user_id=uid_a)) == 1
        assert len(await repo.list(user_id=uid_b)) == 1


class TestCategoryMatchRuleFindByKeyword:
    @pytest.mark.asyncio
    async def test_exact_match(self, repo: CategoryMatchRuleRepository) -> None:
        uid = str(uuid4())
        cat_id = str(uuid4())
        await repo.create(make_rule(keyword="麦当劳", user_id=uid, category_id=cat_id))
        result = await repo.find_by_keyword(user_id=uid, keyword="麦当劳")
        assert result is not None
        assert result.keyword == "麦当劳"

    @pytest.mark.asyncio
    async def test_no_match(self, repo: CategoryMatchRuleRepository) -> None:
        result = await repo.find_by_keyword(user_id=str(uuid4()), keyword="不存在")
        assert result is None


class TestCategoryMatchRuleMatchByKeyword:
    @pytest.mark.asyncio
    async def test_exact_match(self, repo: CategoryMatchRuleRepository) -> None:
        uid = str(uuid4())
        cat_id = str(uuid4())
        await repo.create(make_rule(keyword="麦当劳", user_id=uid, category_id=cat_id))
        result = await repo.match_by_keyword(user_id=uid, keyword="麦当劳")
        assert result is not None
        assert result.keyword == "麦当劳"

    @pytest.mark.asyncio
    async def test_partial_match(self, repo: CategoryMatchRuleRepository) -> None:
        uid = str(uuid4())
        cat_id = str(uuid4())
        await repo.create(make_rule(keyword="麦当劳", user_id=uid, category_id=cat_id))
        result = await repo.match_by_keyword(user_id=uid, keyword="麦当劳（xx店）")
        assert result is not None
        assert result.keyword == "麦当劳"

    @pytest.mark.asyncio
    async def test_no_partial_match_when_not_contained(self, repo: CategoryMatchRuleRepository) -> None:
        uid = str(uuid4())
        cat_id = str(uuid4())
        await repo.create(make_rule(keyword="麦当劳", user_id=uid, category_id=cat_id))
        result = await repo.match_by_keyword(user_id=uid, keyword="肯德基")
        assert result is None


class TestCategoryMatchRuleDelete:
    @pytest.mark.asyncio
    async def test_delete_existing(self, repo: CategoryMatchRuleRepository) -> None:
        uid = str(uuid4())
        rule = make_rule(user_id=uid)
        await repo.create(rule)
        result = await repo.delete(rule.id, user_id=uid)
        assert result is True
        assert await repo.list(user_id=uid) == []

    @pytest.mark.asyncio
    async def test_delete_scoped_to_user(self, repo: CategoryMatchRuleRepository) -> None:
        uid = str(uuid4())
        rule = make_rule(user_id=uid)
        await repo.create(rule)
        result = await repo.delete(rule.id, user_id=str(uuid4()))
        assert result is False

    @pytest.mark.asyncio
    async def test_delete_nonexistent(self, repo: CategoryMatchRuleRepository) -> None:
        result = await repo.delete(uuid4(), user_id=str(uuid4()))
        assert result is False
