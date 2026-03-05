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
- Geolocalisation livreur (mentionnee mais non detaillee)
- Multi-tenant / multi-entrepots (deploiement specifique DIMED Pharma)

## Context

- Entrepots en Algerie avec couverture reseau limitee — mode offline necessaire (OCR local, sync auto)
- Module OCR deja partiellement implemente dans `ocr/` (Python 3.14, EasyOCR, OpenCV, Pydantic)
- Documents reels identifies : feuilles de route, listes de prelevement (format connu)
- 5 acteurs distincts avec des interfaces differentes : pharmacien (web), operatrice (web), preparateur (mobile), controleur (mobile), livreur (mobile)
- 30 photos reelles d'etiquettes pharmaceutiques disponibles pour tests OCR dans `ocr/Etiquettes/`
- BDD medicaments : source non definie, interface abstraite (Protocol Python) deja concue

## Constraints

- **Stack**: Backend Python (FastAPI), Frontend React/Next.js, Mobile React Native, BDD PostgreSQL
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

---
*Last updated: 2026-03-05 after initialization*
