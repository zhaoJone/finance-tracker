"""Parser facade — stateless unified entry point for all notification parsers."""
from __future__ import annotations
from src.parsers import AlipayParser, BankParser, NotificationParser, WeChatParser
from src.schemas.notification import ParsedNotification

_PARSERS: list[NotificationParser] = [
    AlipayParser(),
    WeChatParser(),
    BankParser(),
]

def parse_notification(raw_text: str) -> ParsedNotification | None:
    """Try all parsers in order, return first match or None."""
    for parser in _PARSERS:
        result = parser.parse(raw_text)
        if result is not None:
            return result
    return None
