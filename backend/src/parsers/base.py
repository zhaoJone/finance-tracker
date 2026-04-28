"""
通知解析器 - 策略模式基类。
"""
from abc import abstractmethod

from src.schemas.notification import ParsedNotification


class NotificationParser:
    """通知解析器抽象基类。"""

    @abstractmethod
    def parse(self, raw_text: str) -> ParsedNotification | None:
        """解析通知文本，返回标准化结果，解析失败返回 None。"""
        ...
