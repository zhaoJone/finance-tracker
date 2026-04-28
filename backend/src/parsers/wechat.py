"""
微信支付通知解析器。
"""
import re
from datetime import datetime

from src.parsers.base import NotificationParser
from src.schemas.notification import ParsedNotification


# 微信支付通知格式：微信支付，¥58.00，哆来茶，28/04/26 14:32:24支付完成
_WECHAT_PATTERN = re.compile(
    r"微信支付，¥?￥?([\d,]+\.?\d*)，(.+?)，(\d{2}/\d{2}/\d{2})\s+(\d{2}:\d{2}:\d{2})支付完成",
    re.UNICODE,
)


def _parse_wechat_amount(amount_str: str) -> int:
    """将金额字符串转换为分（整数）。"""
    value = float(amount_str.replace(",", ""))
    return int(value * 100)


def _parse_wechat_datetime(date_str: str, time_str: str) -> datetime:
    """将 '28/04/26' 和 '14:32:24' 转换为 datetime。"""
    day, month, year = map(int, date_str.split("/"))
    # 处理两位年份
    year = 2000 + year
    hour, minute, second = map(int, time_str.split(":"))
    return datetime(year, month, day, hour, minute, second)


class WeChatParser(NotificationParser):
    """解析微信支付通知。"""

    def parse(self, raw_text: str) -> ParsedNotification | None:
        if "微信支付" not in raw_text:
            return None

        m = _WECHAT_PATTERN.match(raw_text.strip())
        if not m:
            return None

        amount_str = m.group(1)
        counterparty = m.group(2).strip()
        date_str = m.group(3)
        time_str = m.group(4)

        amount = _parse_wechat_amount(amount_str)
        timestamp = _parse_wechat_datetime(date_str, time_str)

        # 微信交易号格式：微信支付订单号（数字）
        trade_no_match = re.search(r"支付单号[：:]?\s*(\d+)", raw_text)
        trade_no = trade_no_match.group(1) if trade_no_match else ""

        return ParsedNotification(
            source="wechat",
            raw_text=raw_text,
            amount=amount,
            type="expense",
            counterparty=counterparty,
            timestamp=timestamp,
            trade_no=trade_no,
        )
