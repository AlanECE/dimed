# DIMED S5 — Workflow de démonstration (réunion)

> **Nouveauté présentée :** traçabilité des colis par QR code unique, interface **Magasinier** (pads de tir) et chargement **Livreur** par scan.

---

## 0. Accès & comptes

- **Application web :** http://localhost:3000
- **API :** http://localhost:8000 (doc interactive : http://localhost:8000/docs)
- **Mot de passe pour tous les comptes démo :** `dimed`

| Rôle | Email | Sert à montrer |
|---|---|---|
| Opératrice | `operatrice@dimed.dz` | Création de commande |
| Préparateur | `preparateur@dimed.dz` | Préparation / picking |
| Contrôleur | `controleur@dimed.dz` | **Saisie du nb de colis + étiquettes QR** |
| Magasinier | `magasinier@dimed.dz` | **Mise sur pad de tir par scan** (NOUVEAU) |
| Livreur | `livreur@dimed.dz` | **Chargement & livraison par scan** |

> Astuce démo : ouvre 5 onglets (ou navigation privée) un par rôle pour switcher vite.

---

## 1. Le fil conducteur (1 phrase)

> « Chaque colis reçoit une **étiquette QR unique** liée à la commande, au pharmacien et à la date. Le magasinier la scanne pour le **poser sur le bon pad de tir**, le livreur la scanne pour **charger** puis **livrer** — et le système refuse de valider s'il manque un colis. »

---

## 2. Workflow pas-à-pas

### Étape 1 — Opératrice : créer la commande
1. Login `operatrice@dimed.dz`.
2. Créer une commande pour le pharmacien, ajouter 2-3 articles.
3. **Accepter** la commande.

### Étape 2 — Préparateur : préparer
1. Login `preparateur@dimed.dz`.
2. Démarrer la préparation (assigner un caddie du pool).
3. Renseigner les quantités prélevées + cocher « vérifié », puis **Finaliser la préparation**.

### Étape 3 — Contrôleur : fixer le nombre de colis + générer les étiquettes ⭐
1. Login `controleur@dimed.dz`, onglet **Vérification**.
2. Assigner un camion à la commande.
3. **Saisir le nombre de colis** (ex : `3`) dans le champ dédié, puis **Valider le contrôle**.
   → Le système crée 3 colis tracés : `CLS00000001`, `CLS00000002`, `CLS00000003`.
4. Cliquer sur le bouton **Étiquettes** (icône QR) → télécharge le **PDF A6, une étiquette par colis** (QR + « Colis 1/3 », pharmacien, date, contenu).

> 💬 À dire : *« C'est ce PDF que le facturier imprimera depuis S4 — ici on a juste exposé l'endpoint et le rendu. »*

### Étape 4 — Magasinier : mise sur pad de tir par scan ⭐⭐ (LE point fort)
1. Login `magasinier@dimed.dz` → page **« Pads de tir »** (s'ouvre par défaut).
2. **Scanner** un colis :
   - soit avec la **caméra** (pointer le QR du PDF affiché sur un autre écran / téléphone),
   - soit via la **saisie manuelle** intégrée : taper `CLS00000001` puis Entrée. *(idéal en réunion, zéro dépendance caméra)*
3. La fiche colis s'affiche : commande, pharmacien, adresse, **« Colis 1/3 »**, contenu.
4. Le système **suggère un pad libre** → cliquer **Confirmer le dépôt**.
5. Scanner le **2ᵉ colis de la même commande** → montrer que le pad est désormais **« imposé »** (même commande = même pad), badge ambre.
6. Déposer les 3 colis. La colonne de droite **« État des pads »** se met à jour en temps réel (`3/3`).

> 💬 Points à souligner : QR = **numéro seul** (léger, robuste) ; toutes les infos viennent du serveur au scan ; **regroupement automatique** des colis d'une commande sur le même pad.

### Étape 5 — Livreur : chargement du camion par scan ⭐
1. Login `livreur@dimed.dz`, page **Livraison** (tournée du jour).
2. Section **« Chargement du camion — scan des colis »** : scanner (ou saisir) les colis.
   → Le contenu du camion se remplit en temps réel, progression `chargés/total` par commande.
3. Cliquer **Valider le chargement** AVANT d'avoir tout scanné → un **panneau rouge liste précisément les colis manquants**.
4. Scanner les colis restants → **Valider le chargement** passe au vert.

### Étape 6 — Livreur : démarrer la tournée + livrer
1. Signer la feuille de route (expédition + chauffeur), **Démarrer la tournée**.
2. Sur une commande, ouvrir **« Livré »** : il faut **re-scanner les colis** sur place avant que la **signature du pharmacien** ne se débloque.
3. Une fois tous scannés → signature → commande livrée. Les colis passent au statut **« Livré »**.

---

## 3. Les 4 messages à retenir (slide de clôture)

1. **Traçabilité unitaire** : chaque colis a une identité (QR) liée commande/pharmacien/date, et un **journal de scans** (dépôt, chargement, livraison).
2. **Zéro oubli** : impossible de valider un chargement incomplet — les manquants sont listés nommément.
3. **Magasinier guidé** : pad suggéré, regroupement automatique par commande, override possible.
4. **Prêt pour S4** : tout est exposé en **API** ; l'étiquette/facturation côté S4 n'aura qu'à consommer ces endpoints.

---

## 4. Si la caméra ne coopère pas

La **saisie manuelle** est intégrée partout (champ « Ou saisir le numéro du colis »). Tape simplement le `CLS……` affiché sur le PDF des étiquettes. La démo fonctionne **sans aucune caméra**.

---

## 5. Démarrer / relancer la stack (mémo technique)

```powershell
# Base + cache (déjà lancés)
docker compose -f docker/docker-compose.yml -f docker/docker-compose.override.yml up -d db redis

# API (depuis apps/api) — base sur le port 55432 (PostgreSQL natif occupe 5432)
$env:DIMED_DATABASE_URL = "postgresql+asyncpg://dimed:dimed@localhost:55432/dimed"
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000

# Web (depuis apps/web)
pnpm dev
```

> Le compte `magasinier@dimed.dz` et les 6 pads (PAD-01→06) sont créés automatiquement au démarrage de l'API (seed + migration 016).
