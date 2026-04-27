"""
Shared authentication dependencies - must not import from api/ submodules.
"""
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.database import get_db
from src.repository.user import UserRepository
from src.schemas.user import User
from src.service.auth import decode_token

DBSession = Annotated[AsyncSession, Depends(get_db)]

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login", auto_error=False)


async def get_current_user(
    db: DBSession,
    token: str | None = Depends(oauth2_scheme),
) -> User:
    """Get the current authenticated user from JWT token.

    Raises HTTPException 401 if token is missing/invalid or user not found.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if token is None:
        raise credentials_exception
    token_data = decode_token(token)
    if token_data is None:
        raise credentials_exception
    repo = UserRepository(db)
    user = await repo.get_by_id(token_data.user_id)
    if user is None:
        raise credentials_exception
    return user
