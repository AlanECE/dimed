# Protocole de test manuel — OCR vignettes pharmaceutiques

## But
Valider bout-en-bout que le préparateur peut uploader des photos de vignettes et obtenir des **DLC** extraites + matching avec les lignes de commande, avec une galerie persistée.

## Pré-requis

1. `docker compose -f docker/docker-compose.yml up -d` — tous les containers healthy
2. `docker compose exec api python -m alembic current` doit afficher `013 (head)`
3. `docker/.env` contient :
   ```
   DIMED_OPENROUTER_API_KEY=sk-or-v1-...
   DIMED_OCR_MODEL=google/gemma-3-27b-it:free
   ```
   (compte gratuit : https://openrouter.ai — 20 req/min, 200 req/jour)
4. Un jeu de **vignettes réelles** (photos de étiquettes pharma avec DLC lisible) prêt sur ton poste

## Scénario "golden path"

### 1. Préparer une commande (2 min)
- Login `pharmacien@dimed.dz` / `dimed` → http://localhost:3000/login
- Ajouter 3 médicaments au panier (prends ceux dont tu as les vignettes)
- Valider la commande → logout

### 2. Accepter + affecter un caddie (1 min)
- Login `operatrice@dimed.dz` / `dimed`
- `/commandes` → accepter la commande créée
- Assigner un caddie depuis la pool

### 3. Démarrer la préparation (30 s)
- Login `preparateur@dimed.dz` / `dimed`
- `/preparation` → sélectionner la commande → "Démarrer la préparation"

### 4. Upload vignettes (2 min)
- Bouton **Vignettes** (en haut à droite de la commande)
- Drag & drop tes 3 photos dans le dropzone
- Observer :
  - [ ] Spinner par vignette pendant le scan
  - [ ] DLC extraite s'affiche sous chaque miniature
  - [ ] `suggested_ligne_id` pré-sélectionné dans le `<select>` quand le modèle reconnaît le code article
- Valider le matching (corriger manuellement si l'auto-suggest se trompe)

### 5. Vérifier la persistance (30 s)
- Fermer le dialog
- Observer : colonne **DLC** de chaque ligne remplie au format `DD/MM/YYYY`
- Refresh F5 → galerie toujours là, DLC toujours là
- Ouvrir une image depuis la galerie → doit s'afficher (via `/static/images/vignettes/...`)

### 6. Finaliser (non bloquant) (1 min)
- Laisser **1 ligne sans DLC** volontairement
- Cliquer "Finaliser la préparation"
- Attendu : toast **warning** ("Attention : 1 ligne sans DLC") mais la finalisation passe — statut devient `EN_VERIFICATION`

## Scénarios d'erreur à tester

| Cas | Action | Attendu |
|---|---|---|
| Fichier trop gros | Upload image > 10 MiB | toast "Image exceeds 10 MiB limit" (413) |
| Mauvais MIME | Drag d'un PDF ou .txt | toast "Only image files are allowed" (400) |
| Mauvais statut | Upload sur commande `LIVREE` | 409 "Vignette upload not allowed from status livree" |
| Sans clé API | Retirer `DIMED_OPENROUTER_API_KEY`, restart api | 503 "DIMED_OPENROUTER_API_KEY is not set" |
| OpenRouter KO | Couper internet | 502 "OCR service error: …" |
| Mauvais rôle | Login `livreur@dimed.dz`, POST direct | 403 |

## Tableau de tracking qualité OCR

À remplir au moins une fois avec ton vrai corpus pour évaluer si le modèle free suffit.

| Vignette | DLC réelle | DLC extraite | Match auto suggéré ? | Code article lu ? | Temps (s) |
|---|---|---|---|---|---|
| 1 | ... | ... | ☐ | ☐ | ... |
| 2 | ... | ... | ☐ | ☐ | ... |
| 3 | ... | ... | ☐ | ☐ | ... |

**Indicateurs à surveiller** :
- % de DLC correctes (objectif ≥80 % sur vignettes nettes)
- % de matching auto correct (objectif ≥60 % — sinon le code_article est peu lisible et on mise tout sur la sélection manuelle)
- Latence moyenne (gemma free ≈ 3–7 s par image)

## Tests pytest automatiques (offline)

```
cd apps/api
uv sync --all-groups
uv run pytest tests/test_ocr_service.py tests/test_dlc_parsing.py -v
```

Tests d'intégration (API live, pas d'appel OpenRouter) :
```
uv run pytest tests/test_vignettes_integration.py -v
```

Test smoke avec vraie API OpenRouter (1 seul appel, à usage ponctuel) :
```
DIMED_RUN_LIVE_OCR=1 DIMED_SAMPLE_VIGNETTE=/chemin/vers/vignette.jpg \
  uv run pytest tests/test_vignettes_integration.py::test_vignette_upload_live_ocr -v
```

## Logs utiles

```
# Voir les appels OCR côté API
docker compose -f docker/docker-compose.yml logs api --tail 100 -f | grep -i ocr

# Inspecter ce qui est stocké sur disque
docker compose exec api ls -la /storage/images/vignettes/
```
