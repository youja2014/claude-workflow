from __future__ import annotations

from __package__.core.greeting import build_greeting


def test_default_greeting_includes_name() -> None:
    assert build_greeting("Alice") == "Hello, Alice!"


def test_shout_uppercases_output() -> None:
    assert build_greeting("Bob", shout=True) == "HELLO, BOB!"
