"""
FastAPI application entry point.
"""
from contextlib import asynccontextmanager
from pathlib import Path
from typing import AsyncGenerator

import aiosqlite
from fastapi import FastAPI

from src.api.categories import router as categories_router
from src.api.stats import router as stats_router
from src.api.transactions import router as transactions_router


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Initialize database on startup."""
    db_path = Path("/app/data/finance.db")
    db_path.parent.mkdir(parents=True, exist_ok=True)
    async with aiosqlite.connect(db_path) as db:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS transactions (
                id TEXT PRIMARY KEY,
                amount INTEGER NOT NULL,
                category_id TEXT NOT NULL,
                note TEXT,
                date TEXT NOT NULL,
                type TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS categories (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                color TEXT NOT NULL,
                icon TEXT NOT NULL,
                type TEXT NOT NULL
            )
        """)
        await db.commit()
    yield


app = FastAPI(lifespan=lifespan, title="Finance Tracker API", version="1.0.0")

app.include_router(transactions_router)
app.include_router(categories_router)
app.include_router(stats_router)


@app.get("/health")
async def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "ok"}


@app.get("/api/health")
async def api_health_check() -> dict[str, str]:
    """API health check endpoint for Docker/healthcheck."""
    return {"status": "ok"}