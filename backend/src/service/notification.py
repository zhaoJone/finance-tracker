"""
NotificationService - 聚合通知解析器，处理去重与交易创建。
"""
import hashlib
from datetime import datetime
from typing import Any
from uuid import UUID, uuid4

from src.parsers import AlipayParser, NotificationParser, WeChatParser
from src.repository import CategoryRepository, TransactionRepository
from src.repository.category_match_rule import CategoryMatchRuleRepository
from src.schemas import Transaction
from src.schemas.notification import ParsedNotification
from src.service.category_matcher import CategoryMatcher


class NotificationService:
    """聚合通知解析，批量导入时自动去重。"""

    def __init__(
        self,
        tx_repo: TransactionRepository,
        category_repo: CategoryRepository,
        rule_repo: CategoryMatchRuleRepository | None = None,
    ) -> None:
        self._tx_repo = tx_repo
        self._category_repo = category_repo
        self._matcher = CategoryMatcher(rule_repo) if rule_repo else None
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

    async def _precompute_category_ids(
        self,
        notifications: list[ParsedNotification],
        user_id_str: str,
        default_category_id: UUID | None = None,
    ) -> dict[int, UUID | None]:
        """Pre-compute category_id for each notification index.
        
        优先级：
        1. notification.category_id（移动端指定）
        2. 规则匹配（keyword → category_id）
        3. default_category_id（API 参数）
        4. None（无默认分类）
        """
        # Collect unique counterparties for batch matching
        unique_keywords = set()
        for n in notifications:
            if n.category_id is None and n.counterparty:
                unique_keywords.add(n.counterparty)

        # Batch match all counterparties
        matched_rules: dict[str, UUID] = {}
        if self._matcher and unique_keywords:
            results = await self._matcher.match_all(user_id_str, list(unique_keywords))
            for kw, rule in results.items():
                if rule is not None:
                    matched_rules[kw] = rule.category_id

        # Build result map
        result: dict[int, UUID | None] = {}
        for i, n in enumerate(notifications):
            assigned: UUID | None
            if n.category_id is not None:
                assigned = n.category_id
            elif n.counterparty in matched_rules:
                assigned = matched_rules[n.counterparty]
            else:
                assigned = default_category_id
            result[i] = assigned

        return result

    async def import_notifications(
        self,
        notifications: list[ParsedNotification],
        user_id: UUID,
        default_category_id: UUID | None = None,
    ) -> dict[str, Any]:
        """
        批量导入通知，自动过滤已存在的（去重）。

        Returns:
            dict with keys: created (int), skipped (int), errors (list)
        """
        created = 0
        skipped = 0
        errors: list[str] = []
        user_id_str = str(user_id)

        # Pre-compute all category IDs before the loop
        cat_ids = await self._precompute_category_ids(
            notifications=notifications,
            user_id_str=user_id_str,
            default_category_id=default_category_id,
        )

        for i, notification in enumerate(notifications):
            dedup_key = self._make_dedup_key(notification)

            # 去重检查
            existing = await self._tx_repo.find_by_trade_no(dedup_key, user_id_str)
            if existing is not None:
                skipped += 1
                continue

            category_id = cat_ids[i]
            if category_id is None:
                errors.append(f"Notification {i} has no category_id and no default")
                continue

            try:
                tx = Transaction(
                    id=uuid4(),
                    user_id=user_id,
                    amount=notification.amount,
                    category_id=category_id,
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
