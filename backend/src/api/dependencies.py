"""
API dependencies: database connection.
"""
from typing import Any

import aiosqlite


async def get_db() -> Any:
    """Create and yield an async SQLite connection."""
    db = await aiosqlite.connect("finance.db")
    db.row_factory = aiosqlite.Row
    try:
        yield db
    finally:
        await db.close()