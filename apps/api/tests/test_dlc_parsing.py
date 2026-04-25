"""Unit tests for DLC string parsing — pure logic, no I/O."""

from datetime import date

import pytest

from app.ocr.service import _parse_date


@pytest.mark.parametrize(
    "raw,expected",
    [
        ("2027-05-31", date(2027, 5, 31)),
        ("31/05/2027", date(2027, 5, 31)),
        ("31-05-2027", date(2027, 5, 31)),
        ("31/05/27", date(2027, 5, 31)),
        # month/year only → last day of month
        ("05/2027", date(2027, 5, 31)),
        ("02/2028", date(2028, 2, 29)),  # leap year
        ("02-2027", date(2027, 2, 28)),
        ("2027-05", date(2027, 5, 31)),
        # day-first vs year-first auto-swap when unambiguous
        ("2027-5-1", date(2027, 5, 1)),
    ],
)
def test_parse_date_valid(raw: str, expected: date) -> None:
    assert _parse_date(raw) == expected


@pytest.mark.parametrize(
    "raw",
    [
        None,
        "",
        "null",
        "N/A",
        "not a date",
        "99/99/9999",
        "2027-13-01",
    ],
)
def test_parse_date_invalid(raw) -> None:
    assert _parse_date(raw) is None


def test_parse_date_passthrough_date() -> None:
    d = date(2030, 1, 15)
    assert _parse_date(d) == d
