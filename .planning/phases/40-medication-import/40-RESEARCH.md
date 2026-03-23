# Phase 40 Research: Medication Import

## pg_trgm Fuzzy Search (from Tavily)

### Setup
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_medicaments_designation_trgm
    ON medicaments USING gin (designation gin_trgm_ops);
```

### Query Pattern
```sql
-- Fuzzy search with similarity ranking
SELECT id, designation, ppa, similarity(designation, 'paracetamol') AS score
FROM medicaments
WHERE designation % 'paracetamol'  -- % uses pg_trgm.similarity_threshold (default 0.3)
ORDER BY designation <-> 'paracetamol'  -- <-> is distance operator (1 - similarity)
LIMIT 20;
```

### SQLAlchemy 2.0 Integration
```python
from sqlalchemy import func, text

# Enable extension in migration
op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")

# Query with similarity
query = (
    select(Medicament)
    .where(func.similarity(Medicament.designation, search_term) > 0.3)
    .order_by(Medicament.designation.op("<->")(search_term))
    .limit(limit)
    .offset(offset)
)
```

### Threshold
- Default `pg_trgm.similarity_threshold` = 0.3
- For short search terms (3-4 chars), lower to 0.1-0.2
- For pharmaceutical names, 0.2 is a good balance (typo-tolerant but not too loose)

## openpyxl Import Pattern

```python
from openpyxl import load_workbook

wb = load_workbook("Articles.xlsx", read_only=True)
ws = wb.active

for row in ws.iter_rows(min_row=2, values_only=True):
    code_article, designation, lot, date_prod, date_exp, prix_vente, ppa, ug, fabricant = row
    # Validate and insert
```

### Upsert with SQLAlchemy (PostgreSQL ON CONFLICT)
```python
from sqlalchemy.dialects.postgresql import insert

stmt = insert(Medicament).values(
    code_article=code_article,
    designation=designation,
    ppa=ppa,
    fabricant=fabricant,
)
stmt = stmt.on_conflict_do_update(
    index_elements=["code_article"],
    set_={"designation": stmt.excluded.designation, "ppa": stmt.excluded.ppa, "fabricant": stmt.excluded.fabricant},
)
await db.execute(stmt)
```

## Alembic Migration Addition

Need a new migration to add pg_trgm extension and GIN index:
```python
def upgrade():
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    op.execute(
        "CREATE INDEX idx_medicaments_designation_trgm "
        "ON medicaments USING gin (designation gin_trgm_ops)"
    )

def downgrade():
    op.execute("DROP INDEX IF EXISTS idx_medicaments_designation_trgm")
    op.execute("DROP EXTENSION IF EXISTS pg_trgm")
```

---
*Research completed: 2026-03-23 for Phase 40*
*Sources: Tavily (pg_trgm tutorials, SO answers)*
