-- Seed demo data: fill "—" fields on invoices/BLs/prelevements
-- Idempotent: re-run safe. Run via:
--   docker exec -i docker-db-1 psql -U dimed -d dimed < apps/api/scripts/seed_demo_data.sql

BEGIN;

-- 1. Pharmacien contact info (fills client block on Merinal invoice)
UPDATE users
SET
    adresse = COALESCE(NULLIF(adresse, ''), 'Rue des Frères Bouadou, Bir Mourad Rais, Alger'),
    secteur = COALESCE(NULLIF(secteur, ''), 'Alger Centre'),
    telephone = COALESCE(NULLIF(telephone, ''), '+213 21 54 78 90')
WHERE role = 'pharmacien';

UPDATE users
SET telephone = COALESCE(NULLIF(telephone, ''), '+213 21 54 79 01')
WHERE role = 'operatrice';

-- 2. Commercial on commandes (taken from an operatrice nom)
UPDATE commandes c
SET commercial = u.nom
FROM users u
WHERE u.role = 'operatrice'
  AND (c.commercial IS NULL OR c.commercial = '')
  AND u.id = (SELECT id FROM users WHERE role = 'operatrice' ORDER BY created_at LIMIT 1);

-- 3. Arrivages (one lot per medicament, realistic date_peremption + lot ref)
--    Only inserts if no arrivages exist yet.
INSERT INTO arrivages (id, medicament_id, quantite, n_lot, date_arrivage, date_peremption, fournisseur, created_at_arrivage, created_at, updated_at)
SELECT
    gen_random_uuid(),
    m.id,
    GREATEST(m.stock_quantity, 50),
    'L' || LPAD((ROW_NUMBER() OVER (ORDER BY m.designation))::text, 4, '0') || '-26',
    (NOW() - INTERVAL '30 days')::date,
    (NOW() + (INTERVAL '1 day' * (360 + (ROW_NUMBER() OVER (ORDER BY m.designation) * 17) % 540)))::date,
    'SAIDAL Distribution',
    NOW(),
    NOW(),
    NOW()
FROM medicaments m
WHERE NOT EXISTS (SELECT 1 FROM arrivages WHERE arrivages.medicament_id = m.id);

-- 4. Backfill lignes_commande.n_lot from the latest arrivage per medicament
UPDATE lignes_commande lc
SET n_lot = a.n_lot
FROM (
    SELECT DISTINCT ON (medicament_id) medicament_id, n_lot
    FROM arrivages
    ORDER BY medicament_id, date_arrivage DESC
) a
WHERE lc.medicament_id = a.medicament_id
  AND (lc.n_lot IS NULL OR lc.n_lot = '');

COMMIT;

-- Quick sanity checks (printed after commit)
\echo ''
\echo 'Seed summary:'
SELECT
    (SELECT COUNT(*) FROM users WHERE role = 'pharmacien' AND adresse IS NOT NULL) AS pharmaciens_with_adresse,
    (SELECT COUNT(*) FROM commandes WHERE commercial IS NOT NULL) AS commandes_with_commercial,
    (SELECT COUNT(*) FROM arrivages) AS arrivages_total,
    (SELECT COUNT(*) FROM lignes_commande WHERE n_lot IS NOT NULL) AS lignes_with_lot;
