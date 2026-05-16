from __future__ import annotations


class DomainError(Exception):
    """Base class for all domain-level errors."""


class UserNotFoundError(DomainError):
    def __init__(self, user_id: int) -> None:
        super().__init__(f"User not found: {user_id}")
        self.user_id = user_id


class EmailAlreadyTakenError(DomainError):
    def __init__(self, email: str) -> None:
        super().__init__(f"Email already taken: {email}")
        self.email = email
