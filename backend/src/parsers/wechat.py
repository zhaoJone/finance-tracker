"""
微信支付通知解析器。
"""
from __future__ import annotations

import re
from datetime import datetime
from src.parsers.base import NotificationParser
from src.schemas.notification import ParsedNotification


class WeChatParser(NotificationParser):
    def parse(self, raw_text: str) -> ParsedNotification | None:
        if "微信支付" not in raw_text:
            return None
        text = raw_text.strip()

        m = re.match(
            r"微信支付，\uffe5?\xa5?(\d+\.?\d*)，(.+?)，"
            r"(\d{2}/\d{2}/\d{2})\s+(\d{2}:\d{2}:\d{2})支付完成",
            text, re.UNICODE,
        )
        if m:
            amount = int(float(m.group(1).replace(",", "")) * 100)
            timestamp = _parse_wechat_dt(m.group(3), m.group(4))
            trade_no = ""
            tn = re.search(r"支付单号[：:]?\s*(\d+)", text)
            if tn:
                trade_no = tn.group(1)
            return ParsedNotification(
                source="wechat", raw_text=text, amount=amount,
                type="expense", counterparty=m.group(2).strip(),
                timestamp=timestamp, trade_no=trade_no,
            )

        m2 = re.match(
            r"微信支付，\uffe5?\xa5?(\d+\.?\d*)，(.+?)[，。]?",
            text, re.UNICODE,
        )
        if m2:
            amount = int(float(m2.group(1).replace(",", "")) * 100)
            return ParsedNotification(
                source="wechat", raw_text=text, amount=amount,
                type="expense", counterparty=m2.group(2).strip(),
                timestamp=datetime.now(), trade_no="",
            )

        return None


def _parse_wechat_dt(date_str: str, time_str: str) -> datetime:
    day, month, year = map(int, date_str.split("/"))
    year = 2000 + year
    hour, minute, second = map(int, time_str.split(":"))
    return datetime(year, month, day, hour, minute, second)
