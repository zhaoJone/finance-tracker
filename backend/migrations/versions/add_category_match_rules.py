"""add category_match_rules table for notification auto-categorization

Revision ID: add_category_match_rules
Revises: add_trade_no
Create Date: 2026-05-01 11:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "add_category_match_rules"
down_revision: Union[str, Sequence[str], None] = "add_trade_no"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create category_match_rules table."""
    op.create_table(
        "category_match_rules",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("keyword", sa.String(length=100), nullable=False),
        sa.Column("category_id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.current_timestamp()),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ),
        sa.ForeignKeyConstraint(["category_id"], ["categories.id"], ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_category_match_rules_user_id", "category_match_rules", ["user_id"])
    op.create_index("ix_category_match_rules_keyword", "category_match_rules", ["keyword"])


def downgrade() -> None:
    """Drop category_match_rules table."""
    op.drop_index("ix_category_match_rules_keyword", table_name="category_match_rules")
    op.drop_index("ix_category_match_rules_user_id", table_name="category_match_rules")
    op.drop_table("category_match_rules")
