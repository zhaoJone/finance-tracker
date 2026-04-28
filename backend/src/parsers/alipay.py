"""
支付宝通知解析器。
"""
import re
from datetime import datetime

from src.parsers.base import NotificationParser
from src.schemas.notification import ParsedNotification


_ALIPAY_PATTERNS = [
    # 支出通知：您有一笔支出，金额¥128.50，收款商家：麦当劳，已完成。28/04 14:32
    re.compile(
        r"【支付宝】您有一笔支出，金额￥?([\d,]+\.?\d*)，收款商家[：:](.+?)，(.+?)。(\d{1,2}/\d{1,2})\s+(\d{1,2}:\d{2})",
        re.UNICODE,
    ),
    # 收入通知：您有一笔收入，金额¥50.00，对方：张三，已完成。28/04 14:32
    re.compile(
        r"【支付宝】您有一笔收入，金额￥?([\d,]+\.?\d*)，对方[：:](.+?)，(.+?)。(\d{1,2}/\d{1,2})\s+(\d{1,2}:\d{2})",
        re.UNICODE,
    ),
]


def _parse_alipay_amount(amount_str: str) -> int:
    """将金额字符串转换为分（整数）。"""
    value = float(amount_str.replace(",", ""))
    return int(value * 100)


def _parse_alipay_datetime(date_str: str, time_str: str) -> datetime:
    """将 '28/04' 和 '14:32' 转换为 datetime（今年）。"""
    now = datetime.now()
    day, month = map(int, date_str.split("/"))
    hour, minute = map(int, time_str.split(":"))
    return datetime(now.year, month, day, hour, minute)


class AlipayParser(NotificationParser):
    """解析支付宝支付通知。"""

    def parse(self, raw_text: str) -> ParsedNotification | None:
        if "【支付宝】" not in raw_text:
            return None

        for pattern in _ALIPAY_PATTERNS:
            m = pattern.match(raw_text.strip())
            if not m:
                continue

            amount_str = m.group(1)
            counterparty = m.group(2).strip()
            status = m.group(3).strip()
            date_str = m.group(4)
            time_str = m.group(5)

            if status != "已完成":
                return None

            amount = _parse_alipay_amount(amount_str)
            timestamp = _parse_alipay_datetime(date_str, time_str)
            tx_type: str = "expense" if "支出" in raw_text[:10] else "income"

            # trade_no 从通知文本中提取（支付宝交易号格式：20位数字）
            trade_no_match = re.search(r"交易号[：:]?\s*(\d{20,})", raw_text)
            trade_no = trade_no_match.group(1) if trade_no_match else ""

            return ParsedNotification(
                source="alipay",
                raw_text=raw_text,
                amount=amount,
                type=tx_type,  # type: ignore[arg-type]
                counterparty=counterparty,
                timestamp=timestamp,
                trade_no=trade_no,
            )

        return None
