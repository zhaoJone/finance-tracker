"""
银行通知解析器 — 支持招商银行及通用银行格式。
"""
from __future__ import annotations

import re
from datetime import datetime
from src.parsers.base import NotificationParser
from src.schemas.notification import ParsedNotification

_CMB_AMOUNT = re.compile(r"(?:消费|支出|收到转账|还款)人民币(\d+\.?\d*)元")
_CMB_QUICKPAY = re.compile(r"发生快捷支付(?:扣款|退款)，人民币(\d+\.?\d*)")
_GENERIC_AMOUNT = re.compile(r"(?:消费|支取)\s*(?:RMB\s*)?(\d+\.?\d*)")
_CMB_TIME = re.compile(r"于(\d{1,2})月(\d{1,2})日(\d{1,2}):(\d{2})")
_GENERIC_TIME = re.compile(r"于(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2}):(\d{2})")
_BRACKET_MERCHANT = re.compile(r"【([^】]+)】")
_TRAILING_MERCHANT = re.compile(r"[-—]([^-—\s]{2,10})$")


class BankParser(NotificationParser):
    def parse(self, raw_text: str) -> ParsedNotification | None:
        amount_str, is_income = self._extract_amount(raw_text)
        if amount_str is None:
            return None

        amount_fen = int(float(amount_str.replace(",", "")) * 100)
        timestamp = self._extract_timestamp(raw_text)
        counterparty = self._extract_counterparty(raw_text)

        return ParsedNotification(
            source="bank", raw_text=raw_text, amount=amount_fen,
            type="income" if is_income else "expense",
            counterparty=counterparty, timestamp=timestamp, trade_no="",
        )

    def _extract_amount(self, text: str) -> tuple[str | None, bool]:
        m = _CMB_AMOUNT.search(text)
        if m:
            return m.group(1), "收到转账" in text
        m = _CMB_QUICKPAY.search(text)
        if m:
            return m.group(1), "退款" in text
        m = _GENERIC_AMOUNT.search(text)
        if m:
            return m.group(1), False
        return None, False

    def _extract_timestamp(self, text: str) -> datetime:
        m = _CMB_TIME.search(text)
        if m:
            month, day, hour, minute = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
            year = datetime.now().year
            if month > datetime.now().month:
                year -= 1
            return datetime(year, month, day, hour, minute)
        m = _GENERIC_TIME.search(text)
        if m:
            return datetime(int(m.group(1)), int(m.group(2)), int(m.group(3)),
                          int(m.group(4)), int(m.group(5)), int(m.group(6)))
        return datetime.now()

    def _extract_counterparty(self, text: str) -> str:
        for content in _BRACKET_MERCHANT.findall(text):
            if "银行" not in content:
                return content  # type: ignore[no-any-return]
        m = _TRAILING_MERCHANT.search(text)
        if m:
            return m.group(1)
        return ""
