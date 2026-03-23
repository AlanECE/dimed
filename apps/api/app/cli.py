"""CLI for DIMED API administration.

Usage:
    python -m app.cli create-admin --email admin@dimed.dz --password <pwd>
"""

import argparse
import asyncio
from uuid import uuid4

from sqlalchemy import select

from app.auth.service import hash_password
from app.db.session import async_session
from app.models.user import User, UserRole


async def create_admin(email: str, password: str) -> None:
    async with async_session() as session:
        result = await session.execute(select(User).where(User.email == email))
        if result.scalar_one_or_none():
            print(f"Admin {email} already exists, skipping.")
            return

        admin = User(
            id=uuid4(),
            email=email,
            password_hash=hash_password(password),
            role=UserRole.ADMIN,
            nom="Administrator",
            is_active=True,
        )
        session.add(admin)
        await session.commit()
        print(f"Admin {email} created successfully.")


def main() -> None:
    parser = argparse.ArgumentParser(description="DIMED API CLI")
    subparsers = parser.add_subparsers(dest="command")

    create_admin_parser = subparsers.add_parser("create-admin")
    create_admin_parser.add_argument("--email", required=True)
    create_admin_parser.add_argument("--password", required=True)

    args = parser.parse_args()

    if args.command == "create-admin":
        asyncio.run(create_admin(args.email, args.password))
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
