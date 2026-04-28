"""
NotificationService - 聚合通知解析器，处理去重与交易创建。
"""
import hashlib
from datetime import datetime
from typing import Any
from uuid import UUID, uuid4

from src.parsers import AlipayParser, NotificationParser, WeChatParser
from src.repository import CategoryRepository, TransactionRepository
from src.schemas import Transaction
from src.schemas.notification import ParsedNotification


class NotificationService:
    """聚合通知解析，批量导入时自动去重。"""

    def __init__(
        self,
        tx_repo: TransactionRepository,
        category_repo: CategoryRepository,
    ) -> None:
        self._tx_repo = tx_repo
        self._category_repo = category_repo
        self._parsers: list[NotificationParser] = [
            AlipayParser(),
            WeChatParser(),
        ]

    def parse(self, raw_text: str) -> ParsedNotification | None:
        """尝试所有解析器解析通知文本。"""
        for parser in self._parsers:
            result = parser.parse(raw_text)
            if result is not None:
                return result
        return None

    def _make_dedup_key(self, notification: ParsedNotification) -> str:
        """生成去重键：优先用 trade_no，否则用关键字段的 SHA256 哈希。"""
        if notification.trade_no:
            return notification.trade_no
        raw = (
            f"{notification.source}"
            f"{notification.amount}"
            f"{notification.counterparty}"
            f"{notification.timestamp.isoformat()}"
        )
        return hashlib.sha256(raw.encode()).hexdigest()[:32]

    async def import_notifications(
        self,
        notifications: list[ParsedNotification],
        user_id: UUID,
        default_category_id: UUID,
    ) -> dict[str, Any]:
        """
        批量导入通知，自动过滤已存在的（去重）。

        Returns:
            dict with keys: created (int), skipped (int), errors (list)
        """
        created = 0
        skipped = 0
        errors: list[str] = []

        for notification in notifications:
            dedup_key = self._make_dedup_key(notification)

            # 去重检查
            existing = await self._tx_repo.find_by_trade_no(dedup_key, str(user_id))
            if existing is not None:
                skipped += 1
                continue

            try:
                tx = Transaction(
                    id=uuid4(),
                    user_id=user_id,
                    amount=notification.amount,
                    category_id=default_category_id,
                    note=f"[{notification.source}] {notification.counterparty}",
                    date=notification.timestamp.date(),
                    type=notification.type,
                    trade_no=dedup_key,
                    created_at=datetime.now(),
                )
                await self._tx_repo.create(tx)
                created += 1
            except Exception as e:
                errors.append(f"Failed to create transaction: {e}")

        return {
            "created": created,
            "skipped": skipped,
            "errors": errors,
        }
