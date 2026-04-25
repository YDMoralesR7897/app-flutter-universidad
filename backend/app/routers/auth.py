from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas, security
from ..config import settings
from ..db import get_db

router = APIRouter(prefix="/auth", tags=["auth"])


def _issue_tokens(db: Session, user: models.User) -> schemas.TokenPair:
    jti = security.new_jti()
    expires = datetime.utcnow() + timedelta(days=settings.refresh_token_days)
    db.add(models.RefreshToken(jti=jti, user_id=user.id, expires_at=expires))
    db.commit()
    return schemas.TokenPair(
        access_token=security.make_access_token(user.id, user.email),
        refresh_token=jti,
        user_id=str(user.id),
        email=user.email,
    )


@router.post("/register", response_model=schemas.TokenPair)
def register(data: schemas.AuthIn, db: Session = Depends(get_db)):
    existing = db.scalar(select(models.User).where(models.User.email == data.email))
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "email_taken")
    user = models.User(
        email=data.email,
        password_hash=security.hash_password(data.password),
        full_name=data.full_name or data.email.split("@")[0],
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return _issue_tokens(db, user)


@router.post("/login", response_model=schemas.TokenPair)
def login(data: schemas.LoginIn, db: Session = Depends(get_db)):
    user = db.scalar(select(models.User).where(models.User.email == data.email))
    if not user or not security.verify_password(data.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid_credentials")
    return _issue_tokens(db, user)


@router.post("/refresh", response_model=schemas.TokenPair)
def refresh(data: schemas.RefreshIn, db: Session = Depends(get_db)):
    rt = db.scalar(
        select(models.RefreshToken).where(models.RefreshToken.jti == data.refresh_token),
    )
    if rt is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid_refresh")

    # Detección de reuso: el token ya fue rotado antes.
    if rt.revoked_at is not None:
        # Se revoca toda la cadena del usuario como medida defensiva.
        for other in db.scalars(
            select(models.RefreshToken).where(
                models.RefreshToken.user_id == rt.user_id,
                models.RefreshToken.revoked_at.is_(None),
            ),
        ):
            other.revoked_at = datetime.utcnow()
        db.commit()
        raise HTTPException(status.HTTP_409_CONFLICT, "refresh_reuse_detected")

    if rt.expires_at < datetime.utcnow():
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "refresh_expired")

    user = db.get(models.User, rt.user_id)
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "user_gone")

    # Rotar: marca el actual como revocado, emite uno nuevo y los enlaza.
    new_jti = security.new_jti()
    rt.revoked_at = datetime.utcnow()
    rt.replaced_by = new_jti
    new_expires = datetime.utcnow() + timedelta(days=settings.refresh_token_days)
    db.add(
        models.RefreshToken(jti=new_jti, user_id=user.id, expires_at=new_expires),
    )
    db.commit()
    return schemas.TokenPair(
        access_token=security.make_access_token(user.id, user.email),
        refresh_token=new_jti,
        user_id=str(user.id),
        email=user.email,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(data: schemas.RefreshIn, db: Session = Depends(get_db)):
    rt = db.scalar(
        select(models.RefreshToken).where(models.RefreshToken.jti == data.refresh_token),
    )
    if rt and rt.revoked_at is None:
        rt.revoked_at = datetime.utcnow()
        db.commit()
    return None
