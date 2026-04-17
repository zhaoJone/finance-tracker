"""
Tests for CategoryRepository.
"""
from uuid import uuid4

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from src.repository.category import CategoryRepository
from src.repository.models import Base
from src.schemas import Category


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
def repo(session: AsyncSession) -> CategoryRepository:
    return CategoryRepository(session)


def make_category(
    override: dict | None = None,
) -> Category:
    cat = Category(
        id=uuid4(),
        name="Test Category",
        color="#FF5733",
        type="expense",
    )
    if override:
        cat = Category(**{**cat.model_dump(), **override})
    return cat


class TestCategoryRepositoryCreate:
    @pytest.mark.asyncio
    async def test_create_returns_category(self, repo: CategoryRepository) -> None:
        cat = make_category()
        result = await repo.create(cat)
        assert result.id == cat.id
        assert result.name == cat.name

    @pytest.mark.asyncio
    async def test_create_persists_to_db(self, repo: CategoryRepository) -> None:
        cat = make_category()
        await repo.create(cat)
        stored = await repo.get(cat.id)
        assert stored is not None
        assert stored.id == cat.id


class TestCategoryRepositoryGet:
    @pytest.mark.asyncio
    async def test_get_existing(self, repo: CategoryRepository) -> None:
        cat = make_category()
        await repo.create(cat)
        result = await repo.get(cat.id)
        assert result is not None
        assert result.id == cat.id

    @pytest.mark.asyncio
    async def test_get_nonexistent(self, repo: CategoryRepository) -> None:
        result = await repo.get(uuid4())
        assert result is None


class TestCategoryRepositoryList:
    @pytest.mark.asyncio
    async def test_list_empty(self, repo: CategoryRepository) -> None:
        result = await repo.list()
        assert result == []

    @pytest.mark.asyncio
    async def test_list_all(self, repo: CategoryRepository) -> None:
        for i in range(3):
            await repo.create(make_category({"name": f"Category {i}"}))
        result = await repo.list()
        assert len(result) == 3


class TestCategoryRepositoryUpdate:
    @pytest.mark.asyncio
    async def test_update_existing(self, repo: CategoryRepository) -> None:
        cat = make_category({"name": "Old Name"})
        await repo.create(cat)
        updated = cat.model_copy(update={"name": "New Name"})
        result = await repo.update(updated)
        assert result is not None
        assert result.name == "New Name"

    @pytest.mark.asyncio
    async def test_update_nonexistent(self, repo: CategoryRepository) -> None:
        cat = make_category()
        result = await repo.update(cat)
        assert result is None


class TestCategoryRepositoryDelete:
    @pytest.mark.asyncio
    async def test_delete_existing(self, repo: CategoryRepository) -> None:
        cat = make_category()
        await repo.create(cat)
        result = await repo.delete(cat.id)
        assert result is True
        assert await repo.get(cat.id) is None

    @pytest.mark.asyncio
    async def test_delete_nonexistent(self, repo: CategoryRepository) -> None:
        result = await repo.delete(uuid4())
        assert result is False
