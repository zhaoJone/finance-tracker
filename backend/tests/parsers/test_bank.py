"""Tests for BankParser — covers all 6 bank notification formats."""
from __future__ import annotations

from src.parsers.bank import BankParser

parser = BankParser()

# ── 测试用例 ──

CMB_CONSUME = (
    "【招商银行】您尾号8888的信用卡于05月01日12:30消费人民币128.00元"
)
CMB_EXPENSE = (
    "【招商银行】您尾号6666的一卡通于05月01日12:30支出人民币500.00元"
)
CMB_INCOME = (
    "【招商银行】您尾号6666的一卡通于05月01日12:30收到转账人民币1000.00元"
)
CMB_REPAY = (
    "【招商银行】您尾号8888的信用卡于05月01日12:30还款人民币2000.00元"
)
CMB_QUICKPAY = (
    "招商银行 您账户9746于05月08日19:03在"
    "【财付通-微信支付-拼多多平台商户】发生快捷支付扣款，人民币75.05"
)
CMB_REFUND = (
    "招商银行 您账户9746于05月08日19:03在"
    "【淘宝网】发生快捷支付退款，人民币50.00"
)
GENERIC_BANK = (
    "您尾号1234的银行卡片于2024-01-01 12:00:00消费RMB 56.78元"
)
NON_BANK = "【天气预报】今天多云转晴，气温15-22℃"


def test_cmb_consume() -> None:
    """招行信用卡消费 → expense, 12800 fen."""
    result = parser.parse(CMB_CONSUME)
    assert result is not None
    assert result.amount == 12800
    assert result.type == "expense"
    assert result.source == "bank"


def test_cmb_expense() -> None:
    """招行一卡通支出 → expense, 50000 fen."""
    result = parser.parse(CMB_EXPENSE)
    assert result is not None
    assert result.amount == 50000
    assert result.type == "expense"
    assert result.source == "bank"


def test_cmb_income() -> None:
    """招行收到转账 → income, 100000 fen."""
    result = parser.parse(CMB_INCOME)
    assert result is not None
    assert result.amount == 100000
    assert result.type == "income"
    assert result.source == "bank"


def test_cmb_repay() -> None:
    """招行还款 → expense, 200000 fen."""
    result = parser.parse(CMB_REPAY)
    assert result is not None
    assert result.amount == 200000
    assert result.type == "expense"
    assert result.source == "bank"


def test_cmb_quickpay() -> None:
    """招行快捷支付扣款 → expense, 7505 fen, 商户=拼多多."""
    result = parser.parse(CMB_QUICKPAY)
    assert result is not None
    assert result.amount == 7505
    assert result.type == "expense"
    assert "拼多多" in result.counterparty


def test_cmb_refund() -> None:
    """招行快捷支付退款 → income, 5000 fen."""
    result = parser.parse(CMB_REFUND)
    assert result is not None
    assert result.amount == 5000
    assert result.type == "income"
    assert "淘宝" in result.counterparty


def test_generic_bank() -> None:
    """通用银行格式 → expense, 5678 fen, 2024年时间戳."""
    result = parser.parse(GENERIC_BANK)
    assert result is not None
    assert result.amount == 5678
    assert result.type == "expense"
    assert result.timestamp.year == 2024
    assert result.timestamp.month == 1
    assert result.timestamp.day == 1


def test_non_bank_returns_none() -> None:
    """非银行通知 → None."""
    assert parser.parse(NON_BANK) is None
