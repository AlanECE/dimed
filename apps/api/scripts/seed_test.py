"""Seed minimal test data: one pharmacien + 3 medicaments."""

import asyncio
from decimal import Decimal
from uuid import uuid4

from sqlalchemy import select

from app.auth.service import hash_password
from app.db.session import async_session
from app.models.medicament import Medicament
from app.models.user import User, UserRole


async def main() -> None:
    async with async_session() as db:
        # pharmacien
        existing = await db.execute(select(User).where(User.email == "pharma@dimed.dz"))
        if not existing.scalar_one_or_none():
            db.add(
                User(
                    id=uuid4(),
                    email="pharma@dimed.dz",
                    password_hash=hash_password("Pharma12345!"),
                    role=UserRole.PHARMACIEN,
                    nom="Pharmacie Test",
                    adresse="12 rue de Test, Alger",
                    secteur="Alger Centre",
                    telephone="+213 21 00 00 00",
                    is_active=True,
                    is_email_verified=True,
                )
            )
            print("pharmacien created: pharma@dimed.dz / Pharma12345!")
        else:
            print("pharmacien already exists")

        # 3 medicaments
        meds = [
            {
                "code_article": "TEST001",
                "designation": "Doliprane 1000mg",
                "dci": "Paracetamol",
                "dosage": "1000mg",
                "forme": "Comprime",
                "ppa": Decimal("250.00"),
                "fabricant": "SAIDAL",
                "stock_quantity": 200,
                "featured": True,
            },
            {
                "code_article": "TEST002",
                "designation": "Amoxicilline 500mg",
                "dci": "Amoxicilline",
                "dosage": "500mg",
                "forme": "Gelule",
                "ppa": Decimal("420.50"),
                "fabricant": "Merinal",
                "stock_quantity": 150,
                "featured": True,
            },
            {
                "code_article": "TEST003",
                "designation": "Aspirine 500mg",
                "dci": "Acide acetylsalicylique",
                "dosage": "500mg",
                "forme": "Comprime effervescent",
                "ppa": Decimal("180.00"),
                "fabricant": "SAIDAL",
                "stock_quantity": 300,
                "featured": False,
            },
        ]
        for m in meds:
            existing = await db.execute(
                select(Medicament).where(Medicament.code_article == m["code_article"])
            )
            if not existing.scalar_one_or_none():
                db.add(Medicament(id=uuid4(), **m))
                print(f"medicament created: {m['code_article']} - {m['designation']}")
            else:
                print(f"medicament already exists: {m['code_article']}")

        await db.commit()


if __name__ == "__main__":
    asyncio.run(main())
