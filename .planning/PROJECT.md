# DIMED - Gestion Logistique Pharmaceutique

## What This Is

DIMED est un systeme de gestion logistique pharmaceutique pour l'entrepot DIMED Pharma en Algerie. Il couvre toute la chaine de distribution : commande en ligne par le pharmacien, preparation des colis en entrepot avec verification OCR des etiquettes, et livraison avec signature electronique. Le systeme est compose de 3 modules sequentiels (Commande, Preparation/Verification, Livraison) utilises par 5 acteurs (pharmacien, operatrice, preparateur, controleur, livreur).

## Core Value

Assurer la tracabilite complete et fiable de la chaine logistique pharmaceutique, de la commande a la livraison signee, en reduisant les erreurs de preparation par verification OCR automatique.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- OCR pipeline de base : preprocessing image, extraction EasyOCR, fuzzy matching BDD medicaments (existant dans ocr/)

### Active

<!-- Current scope. Building toward these. -->

**Module 1 - Commande en ligne (v1 prioritaire) :**
- [ ] Catalogue medicaments consultable par le pharmacien
- [ ] Passation de commande (panier, validation)
- [ ] Tableau de bord operatrice (reception, validation commandes)
- [ ] Generation automatique facture + bon de livraison (code-barre)
- [ ] Envoi commande au stock (transition vers Module 2)
- [ ] Association commandes / camion / feuille de route
- [ ] Notifications pharmacien a chaque changement de statut
- [ ] Cycle de vie complet des commandes (Creee -> Acceptee -> En preparation -> ... -> Livree)

**Module 2 - Preparation & Verification (v2) :**
- [ ] Scan caddie / association commande
- [ ] Scan etiquettes OCR + verification automatique par article
- [ ] Liste de prelevement avec zones A/B/C/D
- [ ] Sous-processus verification controleur
- [ ] Generation QR codes colis
- [ ] Visa preparateur/controleur

**Module 3 - Livraison (v2) :**
- [ ] Feuille de route livreur
- [ ] Checklist chargement avec scan QR obligatoire
- [ ] Tournee de livraison
- [ ] Signature electronique pharmacien
- [ ] Confirmation livraison

### Out of Scope

- Gestion du stock (hors perimetre applicatif initial)
- Creation des comptes clients (processus administratif separe)
- Planification des tournees (processus logistique amont)
- Gestion de la flotte vehicules
- Geolocalisation livreur (mentionnee mais non detaillee — reportee en v2+)
- Multi-tenant / multi-entrepots (deploiement specifique DIMED Pharma)

## Context

- Entrepots en Algerie avec couverture reseau limitee — mode offline necessaire (OCR local, sync auto)
- Module OCR deja partiellement implemente dans `ocr/` (Python 3.14, EasyOCR, OpenCV, Pydantic)
- Documents reels identifies : feuilles de route, listes de prelevement (format connu)
- 5 acteurs distincts avec des interfaces differentes : pharmacien (web), operatrice (web), preparateur (mobile), controleur (mobile), livreur (mobile)
- 30 photos reelles d'etiquettes pharmaceutiques disponibles pour tests OCR dans `ocr/Etiquettes/`
- BDD medicaments : import depuis `Articles.xlsx` (fichier Excel fourni avec les articles)
- 5 CDC detailles disponibles dans le repo (Cahier_des_Charges_DIMED.docx, CDC_Global, CDC_Module1, CDC_Module2, CDC_Module3)
- Exigences fonctionnelles formalisees : 12 pour M1 (EF-1-xx), 30 pour M2 (EF-2-xx), 17 pour M3 (EF-3-xx)
- 7 regles de gestion par module, 7 risques majeurs identifies, 8 questions ouvertes

## Constraints

- **Stack**: Backend Python (FastAPI), Frontend React/Next.js 15, Mobile React Native (Expo), BDD PostgreSQL
- **Monorepo**: Turborepo (apps/web, apps/mobile, apps/api, packages/)
- **Infra**: Docker Compose (dev), images hardened (prod)
- **Auth**: JWT custom (access + refresh tokens) + RBAC 5 roles
- **OCR**: CPU-only, pas de dependance cloud, EasyOCR en local
- **Offline**: OCR + scan codes-barres/QR doivent fonctionner sans reseau
- **Reglementaire**: Domaine pharmaceutique — tracabilite lots, DLC, prix (PPA), aucune erreur validee silencieusement
- **Deploiement**: Interne DIMED Pharma, entrepot unique
- **Plateforme**: Web (pharmacien, operatrice) + Mobile (preparateur, controleur, livreur)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Module 1 en priorite | Fondation des donnees (commandes, factures, BL) necessaire avant Module 2 et 3 | -- Pending |
| Stack hybride Python/JS | Backend Python coherent avec OCR existant, React/RN pour les interfaces | -- Pending |
| PostgreSQL | Donnees relationnelles structurees, robuste pour la logistique | -- Pending |
| Deploiement mono-entrepot | Specifique DIMED Pharma, pas de complexite multi-tenant | -- Pending |
| Approche confidence-first OCR | Domaine pharma : mieux vaut correction manuelle que erreur silencieuse | -- Pending |
| Turborepo + Docker securise | Monorepo pour partage de types, Docker hardened pour la prod | -- Pending |
| JWT custom (pas Supabase/Keycloak) | Deploiement interne, pas de dependance cloud, controle total | -- Pending |
| Import Articles.xlsx pour BDD medicaments | Source disponible immediatement, compatible avec Protocol existant | -- Pending |
| Strategie incrementale par module | M1 complet livrable, puis M2, puis M3 — chaque module independant | -- Pending |

---
*Last updated: 2026-03-23 after brainstorming and GSD re-initialization*
