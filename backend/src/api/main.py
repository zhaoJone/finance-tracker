"""
FastAPI application entry point.
"""
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI

from src.api.auth import router as auth_router
from src.api.categories import router as categories_router
from src.api.responses import success_response  # noqa: F401
from src.api.stats import router as stats_router
from src.api.transactions import router as transactions_router


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Run migrations on startup."""
    # Migrations already run manually; skip auto-migration to avoid asyncio.run() conflicts
    yield


app = FastAPI(lifespan=lifespan, title="Finance Tracker API", version="1.0.0")

app.include_router(transactions_router)
app.include_router(categories_router)
app.include_router(stats_router)
app.include_router(auth_router)


@app.get("/health")
async def health_check() -> dict[str, object]:
    """Health check endpoint."""
    return {"status": "ok", "data": {"status": "ok"}}


@app.get("/api/health")
async def api_health_check() -> dict[str, object]:
    """API health check endpoint for Docker/healthcheck."""
    return {"status": "ok", "data": {"status": "ok"}}
