"""
支付宝通知解析器。
"""
from __future__ import annotations

import re
from datetime import datetime
from src.parsers.base import NotificationParser
from src.schemas.notification import ParsedNotification

_ALIPAY_EXPENSE = re.compile(
    r"【支付宝】您有一笔支出，金额\uffe5?\xa5?(\d+\.?\d*)，"
    r"收款商家[：:](.+?)，(.+?)。(\d{1,2}/\d{1,2})\s+(\d{1,2}:\d{2})",
    re.UNICODE,
)

_ALIPAY_INCOME = re.compile(
    r"【支付宝】您有一笔收入，金额\uffe5?\xa5?(\d+\.?\d*)，"
    r"对方[：:](.+?)，(.+?)。(\d{1,2}/\d{1,2})\s+(\d{1,2}:\d{2})",
    re.UNICODE,
)

_ALIPAY_TRADE_REMIND = re.compile(
    r"交易提醒\s+你有一笔(\d+\.\d+)元的(支出|收入)，点此查看详情。"
)

_TRADE_NO = re.compile(r"交易号[：:]?\s*(\d{20,})")


def _parse_alipay_amount(amount_str: str) -> int:
    value = float(amount_str.replace(",", ""))
    return int(value * 100)


def _parse_alipay_datetime(date_str: str, time_str: str) -> datetime:
    now = datetime.now()
    day, month = map(int, date_str.split("/"))
    hour, minute = map(int, time_str.split(":"))
    return datetime(now.year, month, day, hour, minute)


class AlipayParser(NotificationParser):
    def parse(self, raw_text: str) -> ParsedNotification | None:
        text = raw_text.strip()
        if "【支付宝】" not in text and "交易提醒" not in text:
            return None
        result = self._parse_standard(text)
        if result is not None:
            return result
        return self._parse_remind(text)

    def _parse_standard(self, text: str) -> ParsedNotification | None:
        m = _ALIPAY_EXPENSE.match(text)
        is_income = False
        if not m:
            m = _ALIPAY_INCOME.match(text)
            if m:
                is_income = True
        if not m:
            return None
        amount = _parse_alipay_amount(m.group(1))
        counterparty = m.group(2).strip()
        status = m.group(3).strip()
        if status != "已完成":
            return None
        timestamp = _parse_alipay_datetime(m.group(4), m.group(5))
        trade_no_match = _TRADE_NO.search(text)
        trade_no = trade_no_match.group(1) if trade_no_match else ""
        return ParsedNotification(
            source="alipay",
            raw_text=text,
            amount=amount,
            type="income" if is_income else "expense",
            counterparty=counterparty,
            timestamp=timestamp,
            trade_no=trade_no,
        )

    def _parse_remind(self, text: str) -> ParsedNotification | None:
        m = _ALIPAY_TRADE_REMIND.match(text)
        if not m:
            return None
        amount = _parse_alipay_amount(m.group(1))
        tx_type = "income" if m.group(2) == "收入" else "expense"
        return ParsedNotification(
            source="alipay",
            raw_text=text,
            amount=amount,
            type=tx_type,  # type: ignore[arg-type]
            counterparty="",
            timestamp=datetime.now(),
            trade_no="",
        )
