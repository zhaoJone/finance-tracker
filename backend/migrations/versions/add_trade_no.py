"""add trade_no column for notification deduplication

Revision ID: add_trade_no
Revises: add_user_id_columns
Create Date: 2026-04-28 03:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "add_trade_no"
down_revision: Union[str, Sequence[str], None] = "add_user_id_columns"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add trade_no column for deduplication."""
    op.add_column(
        "transactions",
        sa.Column("trade_no", sa.String(length=64), nullable=True, default=""),
    )
    op.execute("UPDATE transactions SET trade_no = '' WHERE trade_no IS NULL")
    op.create_index("ix_transactions_trade_no", "transactions", ["trade_no"])


def downgrade() -> None:
    """Remove trade_no column."""
    op.drop_index("ix_transactions_trade_no", "transactions")
    op.drop_column("transactions", "trade_no")
