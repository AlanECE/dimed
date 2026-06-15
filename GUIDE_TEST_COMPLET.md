# DIMED S5 — Guide de test complet (toutes les fonctionnalités)

> App : http://localhost:3000 — API : http://localhost:8000 — Mot de passe de **tous** les comptes : `dimed`
> Astuce : ouvre un onglet **navigation privée** par rôle pour ne pas te déconnecter à chaque changement.

| Rôle | Email |
|---|---|
| Pharmacien | `pharmacien@dimed.dz` |
| Opératrice | `operatrice@dimed.dz` |
| Préparateur | `preparateur@dimed.dz` |
| Contrôleur | `controleur@dimed.dz` |
| Magasinier | `magasinier@dimed.dz` |
| Livreur | `livreur@dimed.dz` |
| Admin | `admin@dimed.dz` |

> 🔎 **QR / scan** : chaque scanner a une **saisie manuelle** intégrée. En réunion, tape simplement le numéro `CLS……` (lu sur le PDF des étiquettes ou ci-dessous). Pas besoin de caméra.

---

## 🎬 Données déjà prêtes pour tester le magasinier tout de suite

Deux commandes sont déjà étiquetées et attendent le scan :

| Commande | Colis à scanner | Pour tester |
|---|---|---|
| **C00000042** | `CLS00000004`, `CLS00000005`, `CLS00000006` (3 colis) | flux complet + dépôt sur pad |
| **C00000052** | `CLS00000010`, `CLS00000011` (2 colis) | popup « colis d'une autre commande » |

---

# PARTIE A — Cycle de la commande (étapes 1 & 2 : pharmacien + opératrice)

### A1. Pharmacien saisit sa commande
1. Connecte-toi en **pharmacien**.
2. Crée une commande, ajoute des articles → elle est en statut **créée**.
3. **Tant qu'elle est en « créée »**, tu peux **éditer les lignes** (quantités, articles) et même **annuler** la commande. → Vérifie que c'est possible.

### A2. Opératrice valide ou refuse
1. Connecte-toi en **opératrice**.
2. Ouvre la commande du pharmacien.
3. **Validation** → la commande passe à l'étape suivante (acceptée). Vérifie qu'après validation **le pharmacien ne peut plus éditer**.
4. (Autre test) Sur une nouvelle commande, teste le **refus avec motif** → la commande **reste en « créée »** avec le motif affiché.

> ✅ Ce qui est testé : la nouvelle feature de Hicham (saisie éditable pharmacien + validation/refus opératrice).

---

# PARTIE B — Préparation (préparateur)

1. Connecte-toi en **préparateur**.
2. Démarre la préparation d'une commande acceptée → **assigne un caddie** du pool.
3. Renseigne les **quantités prélevées** + coche **vérifié** sur chaque ligne.
4. **Finalise la préparation** → la commande part en vérification.

---

# PARTIE C — Contrôle + génération des étiquettes QR (contrôleur)

1. Connecte-toi en **contrôleur**, onglet **Vérification**.
2. **Assigne un camion** à la commande.
3. **Saisis le nombre de colis** (ex : `3`) dans le champ dédié, puis **Valide le contrôle**.
   → Crée N colis tracés `CLS……`, uniques, reliés à la commande + pharmacien + date.
4. Clique le bouton **Étiquettes** (icône QR) → télécharge le **PDF A6, une étiquette QR par colis**.

> 💬 À dire : *le facturier fera cette étape depuis S4 ; ici l'endpoint et le PDF sont prêts à être consommés par S4.*

---

# PARTIE D — ⭐ Magasinier : scan par commande → affectation pad (LE NOUVEAU FLUX)

> Logique : le magasinier récupère une commande (du facturier), **scanne TOUS ses colis sur son diable**. Ce n'est **qu'une fois tous les colis d'une même commande scannés** que le système lui dit **sur quel pad** poser la commande.

1. Connecte-toi en **magasinier** → page **« Pads de tir »**.

### D1. Scan progressif d'une commande
2. Scanne (ou saisis) `CLS00000004`.
   → La carte commande **C00000042** apparaît : pharmacien, date, **barre de progression « 1 / 3 »**, pastilles 1·2·3 (la 1 passe au vert), toast « Colis 1 / 3 ».
3. Scanne `CLS00000005` → **« 2 / 3 »**.
4. Scanne `CLS00000006` → **« 3 / 3 »** : un panneau vert apparaît **« Tous les colis scannés — affectez la commande à un pad »** avec le **pad suggéré**.

> 🔒 Avant d'avoir tout scanné, **aucun pad n'est proposé** — le message indique « scannez les X colis restants ». C'est exactement le comportement demandé.

### D2. Affectation sur le pad
5. Le pad suggéré est pré-sélectionné (tu peux en choisir un autre dans la liste). Clique **« Affecter au pad »**.
   → Toast « Commande C00000042 déposée sur PAD-0X (3 colis) ». La carte se réinitialise, prête pour la commande suivante.
6. Regarde la colonne **« État des pads de tir »** à droite → le pad affiche **C00000042 → 3/3**.

### D3. Test de la popup « colis d'une autre commande »
7. Scanne `CLS00000010` → démarre la commande **C00000052** (« 1 / 2 »).
8. **Sans finir**, scanne `CLS00000004`… *(déjà déposé → toast « déjà sur pad »)*. À la place, pour bien voir la popup : scanne un colis d'une **3ᵉ** commande, ou utilise le bouton **« Changer »**.
   - **Bouton « Changer »** (commande incomplète) → **popup** « Abandonner la commande en cours ? Il manque N colis… » → tu peux **Continuer** ou **Abandonner et recommencer**.
   - **Scan d'un colis d'une autre commande** alors qu'une est en cours et incomplète → **popup** « Colis d'une autre commande » → **Rester sur Cxxxx** ou **Passer à Cyyyy**.

> ✅ Ce qui est testé : progression 1..N, pad affecté **seulement** quand la commande est complète, **un seul pad pour tous les colis** d'une commande, et les **popups** de sortie de boucle / colis étranger.

---

# PARTIE E — ⭐ Livreur : chargement par scan + livraison

1. Connecte-toi en **livreur**, page **Livraison** (tournée du jour).

### E1. Chargement du camion
2. Section **« Chargement du camion — scan des colis »** : scanne les colis de tes commandes.
   → Contenu camion en temps réel, progression **chargés / total** par commande.
3. Clique **« Valider le chargement »** **avant** d'avoir tout scanné → **panneau rouge** listant **les colis manquants** par numéro.
4. Scanne le reste → **« Valider le chargement »** passe au vert.

### E2. Tournée + livraison
5. **Signe** la feuille de route (expédition + chauffeur), puis **Démarre la tournée**.
6. Sur une commande, ouvre **« Livré »** → il faut **re-scanner les colis** sur place ; la **signature du pharmacien** ne se débloque qu'une fois **tous les colis scannés**.
7. Signe → commande **livrée**, colis au statut **« Livré »**.

---

# PARTIE F — Vérifications transverses

- **Notifications** : à la fin du chargement d'une commande, le **pharmacien** reçoit une notif « commande chargée ».
- **Admin** : a accès à toutes les pages (dont « Pads de tir »).
- **Audit** : chaque scan (dépôt pad / chargement / livraison) est journalisé en base (`scans_colis`).

---

## En cas de souci

- **Recréer des colis à scanner** : refais la PARTIE C (contrôleur, nb_colis) sur une commande préparée → de nouveaux `CLS……` apparaissent.
- **Relancer la stack** : voir `DEMO_WORKFLOW_S5.md` § 5.
- **Voir les logs API en direct** : `apps/api/uvicorn.err.log` et `uvicorn.out.log`.
