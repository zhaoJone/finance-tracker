"""
FastAPI application entry point.
"""
from fastapi import FastAPI

from src.api.categories import router as categories_router
from src.api.stats import router as stats_router
from src.api.transactions import router as transactions_router

app = FastAPI(title="Finance Tracker API", version="1.0.0")

app.include_router(transactions_router)
app.include_router(categories_router)
app.include_router(stats_router)


@app.get("/health")
async def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "ok"}