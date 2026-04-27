"""add user_id and users table

Revision ID: add_user_id_columns
Revises: 1336ca897ff4
Create Date: 2026-04-27 07:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'add_user_id_columns'
down_revision: Union[str, Sequence[str], None] = '1336ca897ff4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add user_id columns and users table."""
    # Create users table first (needed for FK)
    op.create_table(
        'users',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('password_hash', sa.String(length=255), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('email'),
    )
    op.create_index('ix_users_email', 'users', ['email'])

    # Insert system user to satisfy FK for existing rows
    op.execute("INSERT INTO users (id, email, password_hash, created_at) VALUES ('00000000-0000-0000-0000-000000000000', 'system@placeholder', 'placeholder', NOW())")

    # Add user_id to categories (nullable first to avoid FK violation on existing rows)
    op.add_column('categories', sa.Column('user_id', sa.String(length=36), nullable=True))
    op.execute("UPDATE categories SET user_id = '00000000-0000-0000-0000-000000000000' WHERE user_id IS NULL")
    op.alter_column('categories', 'user_id', nullable=False)
    op.create_index('ix_categories_user_id', 'categories', ['user_id'])
    op.create_foreign_key('fk_categories_user_id', 'categories', 'users', ['user_id'], ['id'])

    # Add user_id to transactions
    op.add_column('transactions', sa.Column('user_id', sa.String(length=36), nullable=True))
    op.execute("UPDATE transactions SET user_id = '00000000-0000-0000-0000-000000000000' WHERE user_id IS NULL")
    op.alter_column('transactions', 'user_id', nullable=False)
    op.create_index('ix_transactions_user_id', 'transactions', ['user_id'])
    op.create_foreign_key('fk_transactions_user_id', 'transactions', 'users', ['user_id'], ['id'])


def downgrade() -> None:
    """Remove user_id columns and users table."""
    op.drop_constraint('fk_transactions_user_id', 'transactions', type_='foreignkey')
    op.drop_index('ix_transactions_user_id', 'transactions')
    op.drop_column('transactions', 'user_id')

    op.drop_constraint('fk_categories_user_id', 'categories', type_='foreignkey')
    op.drop_index('ix_categories_user_id', 'categories')
    op.drop_column('categories', 'user_id')

    op.drop_index('ix_users_email', 'users')
    op.drop_table('users')
