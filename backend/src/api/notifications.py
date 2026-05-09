"""Raw notification parsing API — server-side unified regex parsers.

Mobile sends raw text → backend runs all 3 parsers → returns result.
Eliminates the need to update mobile app when adding new formats.
"""
from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends

from src.api.deps import get_current_user
from src.api.responses import success_response
from src.parsers.facade import parse_notification
from src.schemas.raw_parse import RawParseRequest, RawParseResponseData
from src.schemas.user import User

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


@router.post("/raw-parse")
async def parse_raw_notification(
    body: RawParseRequest,
    user: User = Depends(get_current_user),
) -> Any:
    """Parse a raw notification text using all server-side parsers.

    Runs AlipayParser, WeChatParser, and BankParser sequentially.
    Returns structured ParsedNotification on success, null on failure.
    Stateless — no transaction is created.
    """
    parsed = parse_notification(body.raw_text)

    return success_response(
        data=RawParseResponseData(
            parsed=parsed,
            source_hint=body.source_hint,
        ).model_dump(),
        message="解析完成" if parsed else "无法识别为支付通知",
    )
