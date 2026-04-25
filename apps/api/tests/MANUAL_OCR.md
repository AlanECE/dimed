# Protocole de test manuel — OCR vignettes per-ligne

## But

Valider bout-en-bout que le préparateur peut, **par ligne** dans la table de
préparation, scanner une photo de vignette et obtenir les **4 champs**
imprimés (`lot`, `fab`, `exp`, `ppa`) pré-remplis automatiquement, plus la
case `verifie` cochée si tout est cohérent avec le catalogue.

Le flux **galerie bulk** (drag-drop multiple + assignation manuelle) est
**supprimé** depuis la migration 015. Un seul flux : un bouton OCR par ligne.

## Pré-requis

1. `docker compose -f docker/docker-compose.yml up -d` — tous les containers healthy
2. `docker compose exec api python -m alembic current` doit afficher `015 (head)`
3. `docker/.env` contient :
   ```
   DIMED_OPENROUTER_API_KEY=sk-or-v1-...
   DIMED_OCR_MODEL=google/gemma-3-27b-it:free
   ```
   (compte gratuit : https://openrouter.ai — 20 req/min, 200 req/jour)
4. Un jeu de **vignettes réelles** (photos d'étiquettes pharma avec lot + fab +
   exp + PPA lisibles) prêt sur ton poste, format JPG/PNG/WEBP, < 10 MiB.

## Setup de la commande de test

- Login `pharmacien@dimed.dz` / `dimed` → http://localhost:3000/login,
  créer une commande avec 2-3 lignes (de préférence des médicaments dont tu
  as les vignettes physiques)
- Login `operatrice@dimed.dz` / `dimed` → accepter, affecter caddie
- Login `preparateur@dimed.dz` / `dimed` → `/preparation` → ouvrir la commande

## Per-ligne scan — 7 scénarios

### 1. Scan réussi (golden path)

- **Action** : sur une ligne, cliquer **Scanner** (file picker) ou l'icône
  **caméra** à côté (capture directe sur mobile/tablet via `capture="environment"`)
  → choisir / prendre une photo nette où les 4 champs sont visibles ET dont
  le **PPA imprimé == catalogue**
- **Attendu UI** :
  - [ ] La row prend un effet "scan beam" teal qui balaie pendant l'analyse
  - [ ] Bouton devient **Analyse…** désactivé
  - [ ] Au retour : les cellules Lot / Fab / Exp / PPA apparaissent en
        cascade (reveal staggered, ~50/150/250/350 ms)
  - [ ] La checkbox `OK` se coche **automatiquement** avec une animation
        pulse (halo teal, 600 ms)
  - [ ] Le bouton devient **Re-scan** (variant secondary)
  - [ ] Une thumbnail 36×36 dorée apparaît à gauche de la désignation
  - [ ] Toast vert "Vignette scannée et validée"
- **Attendu DB** :
  - `lignes_commande.{n_lot, fab, exp, ppa, verifie=true}` reflètent l'OCR
  - 1 row dans `vignettes` liée à la ligne (`uq_vignettes_ligne_id`)
  - Fichier sur disque dans `/storage/images/vignettes/{vignette_id}.{ext}`

### 2. Scan PPA divergent

- **Action** : scanner une photo où le PPA imprimé diffère du PPA catalogue
  (le modèle a évolué, ou tu prends une photo avec une étiquette modifiée)
- **Attendu UI** :
  - [ ] Cellules révélées comme en (1)
  - [ ] Sous la valeur PPA : pill amber `cat. {prix} — divergent`
  - [ ] La case `OK` reste **décochée**
  - [ ] Toast jaune "Vérification : PPA divergent du catalogue"
- **Attendu réponse API** : `warnings: ["ppa_divergent"]`, `ligne.verifie=false`

### 3. Scan partiel (champ manquant)

- **Action** : scanner une photo floue où l'OCR ne peut pas lire un champ
  (par ex. PPA effacé) — répéter jusqu'à ce que la réponse contienne au moins
  un `null`
- **Attendu UI** :
  - [ ] La cellule manquante reste vide (placeholder `—`)
  - [ ] La case `OK` reste **décochée**
  - [ ] Toast jaune avec la liste des manquants ("PPA manquant", etc.)
- **Attendu réponse API** : `warnings` inclut le `missing_*` correspondant,
  `verifie=false`

### 4. Re-scan sur ligne déjà scannée

- **Action** : cliquer **Re-scan** sur une ligne qui a déjà été scannée,
  uploader une autre photo (de la même boîte ou d'une autre)
- **Attendu UI** :
  - [ ] L'ancienne thumbnail disparaît, la nouvelle prend sa place
  - [ ] Les valeurs Lot/Fab/Exp/PPA sont **écrasées** par celles du nouveau scan
- **Attendu DB / disque** :
  - L'ancien fichier `/storage/images/vignettes/{old_id}.{ext}` est **supprimé**
  - La row `vignettes` réutilise le même UUID (1:1 avec ligne)
  - `vignettes.filename` pointe vers le nouveau fichier

### 5. Édition manuelle après scan

- **Action** : sur une ligne déjà scannée + cochée, modifier manuellement le
  champ Lot (ou Fab / Exp / PPA) en cliquant dans la cellule input
- **Attendu** :
  - [ ] La case `OK` se **décoche** automatiquement (toute édition manuelle
        invalide la vérification — le préparateur a touché)
  - [ ] La nouvelle valeur est persistée (PATCH `update-ligne`)
  - [ ] La thumbnail reste (la photo OCR sert toujours de preuve)

### 6. Clear vignette (suppression)

- **Action** : hover sur la thumbnail (le ✕ rouge apparaît au top-right) →
  cliquer ✕
- **Attendu UI** :
  - [ ] Thumbnail disparaît, bouton repasse à **Scanner** (variant outline)
  - [ ] Cellules Lot/Fab/Exp/PPA repassent à vides
  - [ ] Case `OK` décochée
  - [ ] Toast vert "Vignette retirée"
- **Attendu DB / disque** :
  - Row `vignettes` supprimée
  - Fichier disque supprimé
  - `lignes_commande.{n_lot, fab, exp, ppa, verifie}` tous à `null` / `false`

### 7. Erreurs

| Cas                                  | Attendu                                                                       |
| ------------------------------------ | ----------------------------------------------------------------------------- |
| Fichier > 10 MiB                     | toast "Image exceeds 10 MiB limit" (HTTP 413), pas de fichier sauvé           |
| Type non image (PDF, txt)            | toast "Unsupported format (JPG/PNG/WEBP only)" (HTTP 415)                     |
| OpenRouter KO (couper internet)      | toast "OCR error: …" (HTTP 502), **fichier PAS sauvegardé** sur disque        |
| `DIMED_OPENROUTER_API_KEY` manquant  | toast "DIMED_OPENROUTER_API_KEY is not set" (HTTP 500)                        |
| Commande déjà finalisée (LIVREE)     | toast "Order is finalized" (HTTP 409)                                         |
| Mauvais rôle (livreur)               | 403, le bouton ne devrait pas apparaître pour ce rôle (page protégée)         |

## Mocking offline (dev sans OpenRouter)

Pour itérer sur le frontend sans dépendre du quota OpenRouter, deux options :

1. **respx + tests** : voir `apps/api/tests/test_ocr_service.py` qui mocke
   `httpx.AsyncClient.post` vers `openrouter.ai/api/v1/chat/completions`
   avec un payload prédéfini. Tu peux extraire ce mock dans un middleware
   `app.middleware("http")` qui court-circuite l'appel quand
   `DIMED_OCR_OFFLINE=1`.
2. **stub local** : remplacer `app.ocr.service.extract_vignette_fields` par
   un stub renvoyant un `VignetteExtraction` synthétique (utile pour les
   smoke E2E déterministes).

## Tests pytest automatiques (offline)

```
cd apps/api
uv sync --all-groups
uv run pytest tests/test_ocr_service.py tests/test_dlc_parsing.py -v
```

Tests d'intégration (API live, pas d'appel OpenRouter) :

```
uv run pytest tests/test_vignette_per_ligne_integration.py -v
```

Smoke avec vraie API OpenRouter (1 seul appel, à usage ponctuel) :

```
DIMED_RUN_LIVE_OCR=1 DIMED_SAMPLE_VIGNETTE=/chemin/vers/vignette.jpg \
  uv run pytest tests/test_vignette_per_ligne_integration.py::test_per_ligne_scan_live_ocr -v
```

## Tableau de tracking qualité OCR

À remplir au moins une fois avec ton corpus pour évaluer si le modèle free suffit.

| Vignette | Lot réel | Fab réel | Exp réel | PPA réel | Lot OCR | Fab OCR | Exp OCR | PPA OCR | Latence (s) |
| -------- | -------- | -------- | -------- | -------- | ------- | ------- | ------- | ------- | ----------- |
| 1        | ...      | ...      | ...      | ...      | ...     | ...     | ...     | ...     | ...         |
| 2        | ...      | ...      | ...      | ...      | ...     | ...     | ...     | ...     | ...         |
| 3        | ...      | ...      | ...      | ...      | ...     | ...     | ...     | ...     | ...         |

**Indicateurs à surveiller** :

- % d'extraction correcte par champ (objectif ≥80 % sur photos nettes)
- % de PPA divergents → si trop élevé, indique un catalogue désynchronisé
- Latence moyenne (gemma free ≈ 3–7 s par image)

## Logs utiles

```
# Voir les appels OCR côté API
docker compose -f docker/docker-compose.yml logs api --tail 100 -f | grep -i ocr

# Inspecter ce qui est stocké sur disque
docker compose exec api ls -la /storage/images/vignettes/

# Vérifier l'unicité ligne_id dans vignettes
docker compose exec db psql -U dimed -d dimed -c \
  "SELECT ligne_id, count(*) FROM vignettes GROUP BY ligne_id HAVING count(*) > 1;"
# (doit retourner 0 lignes — contrainte uq_vignettes_ligne_id)
```
