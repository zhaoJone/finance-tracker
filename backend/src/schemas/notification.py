"""
ParsedNotification - 标准化通知解析结果。

从支付宝/微信/银行等通知来源解析后，统一成此格式，
交由 TransactionCreator 创建交易记录。
"""
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class ParsedNotification(BaseModel):
    """标准化通知解析结果。"""

    source: Literal["alipay", "wechat", "bank"]
    raw_text: str = Field(..., description="原始通知文本")
    amount: int = Field(..., description="金额，单位：分（fen）")
    type: Literal["income", "expense"]
    counterparty: str = Field(default="", description="交易对方")
    timestamp: datetime
    trade_no: str = Field(default="", description="平台交易号，用于去重")

    model_config = {"str_strip_whitespace": True}
