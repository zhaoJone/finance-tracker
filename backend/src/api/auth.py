"""
Authentication API routes.
"""

from uuid import UUID

from fastapi import APIRouter, Depends, Form, HTTPException, status

from src.api.deps import DBSession, get_current_user
from src.repository.user import UserRepository
from src.schemas.user import Token, User, UserCreate
from src.service.auth import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate, db: DBSession) -> Token:
    """Register a new user."""
    repo = UserRepository(db)
    existing = await repo.get_by_email(user_data.email)
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )
    password_hash = hash_password(user_data.password)
    user = await repo.create(email=user_data.email, password_hash=password_hash)
    access_token = create_access_token(user_id=str(user.id))
    return Token(access_token=access_token)


@router.post("/login", response_model=Token)
async def login(
    db: DBSession,
    email: str = Form(...),
    password: str = Form(...),
) -> Token:
    """Login with email and password (OAuth2 compatible form)."""
    from src.repository.models import UserTable
    from sqlalchemy import select

    stmt = select(UserTable).where(UserTable.email == email)
    result = await db.execute(stmt)
    row = result.scalar_one_or_none()
    if row is None or not verify_password(password, row.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    user = User(id=UUID(row.id), email=row.email, created_at=row.created_at)
    access_token = create_access_token(user_id=str(user.id))
    return Token(access_token=access_token)


@router.get("/me", response_model=User)
async def get_me(current_user: User = Depends(get_current_user)) -> User:
    """Get current authenticated user info."""
    return current_user
