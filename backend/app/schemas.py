from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class AuthIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str | None = None


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class RefreshIn(BaseModel):
    refresh_token: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str
    email: str


class ClassRoomOut(BaseModel):
    id: int
    code: str
    name: str
    lat: float
    lng: float
    radius_m: int

    model_config = {"from_attributes": True}


class CheckInIn(BaseModel):
    classroom_id: int
    lat: float
    lng: float


class CheckInOut(BaseModel):
    id: int
    classroom_id: int
    classroom_name: str
    lat: float
    lng: float
    distance_m: float
    created_at: datetime

    model_config = {"from_attributes": True}
