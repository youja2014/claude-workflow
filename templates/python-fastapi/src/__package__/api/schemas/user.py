from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class UserCreateRequest(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=200)


class UserResponse(BaseModel):
    id: int
    email: EmailStr
    name: str
    created_at: datetime
