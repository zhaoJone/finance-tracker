"""Raw notification parse schemas — pure Pydantic models, zero dependencies."""
from __future__ import annotations

from pydantic import BaseModel, Field

from src.schemas.notification import ParsedNotification


class RawParseRequest(BaseModel):
    """Request body: raw notification text to parse server-side."""

    raw_text: str = Field(
        ..., min_length=1, max_length=2000, description="通知原始文本"
    )
    source_hint: str | None = Field(
        default=None,
        description="可选来源提示 (alipay/wechat/bank)，来自 Android 包名",
    )


class RawParseResponseData(BaseModel):
    """Response data: parsed result or null."""

    parsed: ParsedNotification | None = Field(
        description="解析结果，null 表示所有解析器均无法识别"
    )
    source_hint: str | None = Field(
        default=None, description="来源提示透传"
    )
