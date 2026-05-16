from __future__ import annotations

from __package__.constants import DEFAULT_GREETING


def build_greeting(name: str, shout: bool = False) -> str:
    """Pure greeting builder.

    Args:
        name: Name to greet.
        shout: If True, the result is uppercased.

    Returns:
        Greeting string.
    """
    message = f"{DEFAULT_GREETING}, {name}!"
    return message.upper() if shout else message
