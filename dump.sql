--
-- PostgreSQL database dump
--

\restrict e4jCiL8lHw6TtVH3re2HumdyL2w8ZSYTcpdGgmDkmIAONjfczZOUY6FbT4x6dX9

-- Dumped from database version 16.13 (Debian 16.13-1.pgdg12+1)
-- Dumped by pg_dump version 16.13 (Debian 16.13-1.pgdg12+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: colisstatus; Type: TYPE; Schema: public; Owner: dimed
--

CREATE TYPE public.colisstatus AS ENUM (
    'etiquete',
    'sur_pad',
    'charge',
    'livre'
);


ALTER TYPE public.colisstatus OWNER TO dimed;

--
-- Name: creancestatut; Type: TYPE; Schema: public; Owner: dimed
--

CREATE TYPE public.creancestatut AS ENUM (
    'en_attente',
    'partiel',
    'soldee',
    'en_retard'
);


ALTER TYPE public.creancestatut OWNER TO dimed;

--
-- Name: orderstatus; Type: TYPE; Schema: public; Owner: dimed
--

CREATE TYPE public.orderstatus AS ENUM (
    'creee',
    'acceptee',
    'annulee',
    'en_preparation',
    'prelevee_partiellement',
    'en_verification',
    'prete',
    'en_route',
    'livree',
    'refusee',
    'retournee',
    'livree_partiellement'
);


ALTER TYPE public.orderstatus OWNER TO dimed;

--
-- Name: reclamationmotif; Type: TYPE; Schema: public; Owner: dimed
--

CREATE TYPE public.reclamationmotif AS ENUM (
    'produit_endommage',
    'produit_manquant',
    'erreur_facturation',
    'erreur_produit',
    'autre'
);


ALTER TYPE public.reclamationmotif OWNER TO dimed;

--
-- Name: reclamationstatut; Type: TYPE; Schema: public; Owner: dimed
--

CREATE TYPE public.reclamationstatut AS ENUM (
    'ouverte',
    'en_cours',
    'resolue',
    'rejetee'
);


ALTER TYPE public.reclamationstatut OWNER TO dimed;

--
-- Name: scantype; Type: TYPE; Schema: public; Owner: dimed
--

CREATE TYPE public.scantype AS ENUM (
    'depot_pad',
    'chargement',
    'livraison'
);


ALTER TYPE public.scantype OWNER TO dimed;

--
-- Name: userrole; Type: TYPE; Schema: public; Owner: dimed
--

CREATE TYPE public.userrole AS ENUM (
    'admin',
    'pharmacien',
    'operatrice',
    'preparateur',
    'controleur',
    'livreur',
    'magasinier',
    'facturier'
);


ALTER TYPE public.userrole OWNER TO dimed;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO dimed;

--
-- Name: arrivages; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.arrivages (
    id uuid NOT NULL,
    medicament_id uuid NOT NULL,
    quantite integer NOT NULL,
    n_lot character varying(50),
    date_arrivage date NOT NULL,
    date_peremption date,
    fournisseur character varying(255),
    created_at_arrivage timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(255)
);


ALTER TABLE public.arrivages OWNER TO dimed;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.audit_log (
    id uuid NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id uuid NOT NULL,
    action character varying(50) NOT NULL,
    actor_id uuid,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    old_value jsonb,
    new_value jsonb
);


ALTER TABLE public.audit_log OWNER TO dimed;

--
-- Name: bl_seq; Type: SEQUENCE; Schema: public; Owner: dimed
--

CREATE SEQUENCE public.bl_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bl_seq OWNER TO dimed;

--
-- Name: bons_livraison; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.bons_livraison (
    id uuid NOT NULL,
    commande_id uuid NOT NULL,
    code_barre character varying(100) NOT NULL,
    date_emission timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid
);


ALTER TABLE public.bons_livraison OWNER TO dimed;

--
-- Name: caddies; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.caddies (
    id uuid NOT NULL,
    commande_id uuid NOT NULL,
    numero character varying(50) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone,
    updated_by uuid
);


ALTER TABLE public.caddies OWNER TO dimed;

--
-- Name: caddies_pool; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.caddies_pool (
    id uuid NOT NULL,
    numero character varying(20) NOT NULL,
    is_available boolean DEFAULT true NOT NULL,
    current_commande_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone,
    updated_by uuid
);


ALTER TABLE public.caddies_pool OWNER TO dimed;

--
-- Name: camions; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.camions (
    id uuid NOT NULL,
    nom character varying(100) NOT NULL,
    plaque character varying(20) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid
);


ALTER TABLE public.camions OWNER TO dimed;

--
-- Name: colis; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.colis (
    id uuid NOT NULL,
    numero character varying(20) NOT NULL,
    commande_id uuid NOT NULL,
    index_colis integer NOT NULL,
    statut public.colisstatus DEFAULT 'etiquete'::public.colisstatus NOT NULL,
    pad_tir_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid
);


ALTER TABLE public.colis OWNER TO dimed;

--
-- Name: colis_lignes; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.colis_lignes (
    id uuid NOT NULL,
    colis_id uuid NOT NULL,
    ligne_commande_id uuid NOT NULL,
    quantite integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid
);


ALTER TABLE public.colis_lignes OWNER TO dimed;

--
-- Name: colis_seq; Type: SEQUENCE; Schema: public; Owner: dimed
--

CREATE SEQUENCE public.colis_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.colis_seq OWNER TO dimed;

--
-- Name: commande_seq; Type: SEQUENCE; Schema: public; Owner: dimed
--

CREATE SEQUENCE public.commande_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.commande_seq OWNER TO dimed;

--
-- Name: commandes; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.commandes (
    id uuid NOT NULL,
    reference_id character varying(20) NOT NULL,
    pharmacien_id uuid NOT NULL,
    operatrice_id uuid,
    statut public.orderstatus DEFAULT 'creee'::public.orderstatus NOT NULL,
    montant_total numeric(12,2) DEFAULT '0'::numeric NOT NULL,
    commercial character varying(255),
    date_validation timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    camion_id uuid,
    signature_pharmacien bytea,
    motif_echec character varying(500),
    nb_colis integer,
    visa_preparateur character varying(255),
    visa_controleur character varying(255),
    feuille_route_id uuid,
    preparateur_id uuid,
    operatrice_comment character varying(500)
);


ALTER TABLE public.commandes OWNER TO dimed;

--
-- Name: creances; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.creances (
    id uuid NOT NULL,
    pharmacien_id uuid NOT NULL,
    facture_id uuid NOT NULL,
    montant_total numeric(12,2) NOT NULL,
    montant_paye numeric(12,2) DEFAULT 0 NOT NULL,
    statut public.creancestatut DEFAULT 'en_attente'::public.creancestatut NOT NULL,
    echeance date NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid
);


ALTER TABLE public.creances OWNER TO dimed;

--
-- Name: facture_seq; Type: SEQUENCE; Schema: public; Owner: dimed
--

CREATE SEQUENCE public.facture_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.facture_seq OWNER TO dimed;

--
-- Name: factures; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.factures (
    id uuid NOT NULL,
    reference_id character varying(20) NOT NULL,
    commande_id uuid NOT NULL,
    date_emission timestamp with time zone NOT NULL,
    montant_ht numeric(12,2) NOT NULL,
    montant_ttc numeric(12,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid
);


ALTER TABLE public.factures OWNER TO dimed;

--
-- Name: feuilles_route; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.feuilles_route (
    id uuid NOT NULL,
    date date NOT NULL,
    ligne character varying(100),
    n_rotation character varying(50),
    compteurs jsonb DEFAULT '{}'::jsonb NOT NULL,
    signature_expedition bytea,
    signature_chauffeur bytea,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    camion_id uuid NOT NULL,
    livreur_id uuid,
    chargement_valide boolean DEFAULT false NOT NULL
);


ALTER TABLE public.feuilles_route OWNER TO dimed;

--
-- Name: lignes_commande; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.lignes_commande (
    id uuid NOT NULL,
    commande_id uuid NOT NULL,
    medicament_id uuid NOT NULL,
    designation character varying(500) NOT NULL,
    qte_demandee integer NOT NULL,
    prix_unitaire numeric(10,2) NOT NULL,
    n_lot character varying(50),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    qte_prelevee integer,
    verifie boolean DEFAULT false NOT NULL,
    remise_pct numeric(5,2) DEFAULT 0 NOT NULL,
    fab date,
    exp date,
    ppa numeric(10,2)
);


ALTER TABLE public.lignes_commande OWNER TO dimed;

--
-- Name: medicaments; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.medicaments (
    id uuid NOT NULL,
    code_article character varying(50) NOT NULL,
    designation character varying(500) NOT NULL,
    dci character varying(255),
    dosage character varying(100),
    forme character varying(100),
    ppa numeric(10,2) NOT NULL,
    fabricant character varying(255),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    stock_quantity integer DEFAULT 0 NOT NULL,
    image_path character varying(500),
    featured boolean DEFAULT false NOT NULL
);


ALTER TABLE public.medicaments OWNER TO dimed;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.notifications (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    commande_id uuid NOT NULL,
    type character varying(30) NOT NULL,
    message text NOT NULL,
    read boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notifications OWNER TO dimed;

--
-- Name: pads_tir; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.pads_tir (
    id uuid NOT NULL,
    code character varying(20) NOT NULL,
    nom character varying(100) NOT NULL,
    actif boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid
);


ALTER TABLE public.pads_tir OWNER TO dimed;

--
-- Name: prelevement_seq; Type: SEQUENCE; Schema: public; Owner: dimed
--

CREATE SEQUENCE public.prelevement_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.prelevement_seq OWNER TO dimed;

--
-- Name: reclamations; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.reclamations (
    id uuid NOT NULL,
    pharmacien_id uuid NOT NULL,
    commande_id uuid NOT NULL,
    motif public.reclamationmotif NOT NULL,
    description text NOT NULL,
    statut public.reclamationstatut DEFAULT 'ouverte'::public.reclamationstatut NOT NULL,
    resolution text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid
);


ALTER TABLE public.reclamations OWNER TO dimed;

--
-- Name: scans_colis; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.scans_colis (
    id uuid NOT NULL,
    colis_id uuid NOT NULL,
    type_scan public.scantype NOT NULL,
    user_id uuid NOT NULL,
    pad_tir_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid
);


ALTER TABLE public.scans_colis OWNER TO dimed;

--
-- Name: users; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255),
    role public.userrole NOT NULL,
    nom character varying(255) NOT NULL,
    adresse character varying(500),
    secteur character varying(100),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    telephone character varying(30),
    google_id character varying(255),
    oauth_provider character varying(20),
    is_email_verified boolean DEFAULT false NOT NULL
);


ALTER TABLE public.users OWNER TO dimed;

--
-- Name: vignettes; Type: TABLE; Schema: public; Owner: dimed
--

CREATE TABLE public.vignettes (
    id uuid NOT NULL,
    commande_id uuid NOT NULL,
    ligne_id uuid NOT NULL,
    filename character varying(255) NOT NULL,
    extracted_exp date,
    extracted_raw text,
    uploaded_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    extracted_lot character varying(64),
    extracted_fab date,
    extracted_ppa numeric(10,2),
    extracted_designation character varying(500)
);


ALTER TABLE public.vignettes OWNER TO dimed;

--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.alembic_version (version_num) FROM stdin;
017
\.


--
-- Data for Name: arrivages; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.arrivages (id, medicament_id, quantite, n_lot, date_arrivage, date_peremption, fournisseur, created_at_arrivage, created_at, updated_at, created_by) FROM stdin;
070122b7-08c7-4262-8937-9d51aeeefc52	02787863-90cc-4020-93a4-0fc4bab203c7	85	L0001-26	2026-03-14	2027-04-25	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
660c1b87-8086-44ad-831a-e509317b940a	592e33a9-acd2-410c-81f2-6cb3f8f17298	50	L0002-26	2026-03-14	2027-05-12	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
49509f13-7f99-47f2-afbc-4310ef15e632	72dcd068-d94c-4c76-9dca-3ddace1e5962	50	L0003-26	2026-03-14	2027-05-29	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
76f4df72-546f-46d4-9248-1ce96bd6180b	ec9ea5cf-4731-4d28-b580-f45b357b1aa2	50	L0004-26	2026-03-14	2027-06-15	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
585e4688-5de3-4bfd-88fb-aab25679eef3	7435046b-fc3b-4c8e-9041-9c1e886aa102	50	L0005-26	2026-03-14	2027-07-02	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
864144cc-b394-4f92-9044-f677d3d7a02c	1cc0c15a-e7e6-4789-906b-5e4783200168	96	L0006-26	2026-03-14	2027-07-19	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
3ba3cf87-c954-4d14-ab81-ddee2352a77d	5de5ae08-5390-4c43-902b-da95cd27194f	50	L0007-26	2026-03-14	2027-08-05	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
e1749893-978f-4c61-a326-892c878f3562	5e57f1e4-b43f-45ba-aadc-c6d1b7533292	50	L0008-26	2026-03-14	2027-08-22	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
4380e652-58d2-4aa2-89dd-250c5e5de1f6	c459f9ab-45f0-4f9d-a550-390cbc27e360	50	L0009-26	2026-03-14	2027-09-08	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
094fd650-b141-416e-99ff-92c8b041b66a	473b8bb5-8018-4b2f-ab5e-ad44ef8e42e7	159	L0010-26	2026-03-14	2027-09-25	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
fc27545a-1cf1-49de-8a2c-ad9048ce5f21	ab1d5e9a-449a-4c78-bb6b-ca1e8f5fbec6	50	L0011-26	2026-03-14	2027-10-12	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
97d25412-2655-4dc2-b3f9-27953b06019d	bec9aaab-341b-43ba-90ca-879287313958	50	L0012-26	2026-03-14	2027-10-29	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
d07ca645-8f85-438d-8836-8de67f067ec2	ab13b2e4-c0c3-443c-bc5d-79959ddda161	154	L0013-26	2026-03-14	2027-11-15	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
10c8612d-0e82-456f-9234-148af22a9c5b	e1d4f0a0-3b16-4fb9-a70e-174e94c547ed	195	L0014-26	2026-03-14	2027-12-02	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
7cab216d-9e87-4de5-9a5c-e3ac848cd539	ebaf3ac2-f1e4-4790-a80e-2f4a23f49a69	75	L0015-26	2026-03-14	2027-12-19	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
9828db29-4b6d-4e57-81c2-21156b01ca0f	d28edd13-f03d-41a5-985e-626fc9e22aa8	54	L0016-26	2026-03-14	2028-01-05	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
5ad813a5-5148-4dda-a1f2-2d9276fb82b0	e69ff623-2b32-4abf-8680-b87723647fa3	83	L0017-26	2026-03-14	2028-01-22	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
da941d42-9402-4111-b495-46453876cbcf	9a7837b7-4dbf-4fc5-ad18-374b0c0841c1	50	L0018-26	2026-03-14	2028-02-08	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
299a6360-1cca-429f-829d-0ec353d80958	e9ecc48f-388d-4304-9d48-0ea710cdcc43	150	L0019-26	2026-03-14	2028-02-25	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
cdbca814-749a-4d2a-ac67-df02cc9e4331	d301b519-7d97-4df6-8b7f-99321a9965b3	162	L0020-26	2026-03-14	2028-03-13	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
1a0883c1-1704-4e9d-8abc-7472c8c10169	31b2d93c-67d9-4b01-98ec-c4c1130fc635	195	L0021-26	2026-03-14	2028-03-30	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
88887b56-fc7e-4393-a8eb-2b40b0dcb245	89d5ed34-a1ae-4c0d-a081-e57a52bf52ef	50	L0022-26	2026-03-14	2028-04-16	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
1393b901-9d3e-4a35-87f2-fd2d9b19a08d	bd0ee39a-b886-4631-8dd9-50e77aef7b27	184	L0023-26	2026-03-14	2028-05-03	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
26175907-6c8f-45be-9aea-c466e39b9881	60b3d23b-7a49-42c2-8dc1-e63a13d8a224	76	L0024-26	2026-03-14	2028-05-20	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
124c3c31-fbff-4d6c-9796-a70e5ad3d949	d5d2a015-c492-492a-bef6-b1425165ff2a	115	L0025-26	2026-03-14	2028-06-06	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
33975d6b-2589-41e0-b56f-85377de0ef2c	6ef1aae9-5d86-46ca-ae3e-dcd15e0ffceb	187	L0026-26	2026-03-14	2028-06-23	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
4cb930a9-3cd7-4059-8485-8f83e14e1017	4c558dc1-93d8-4dad-ba93-8d00338f89fe	100	L0027-26	2026-03-14	2028-07-10	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
ce696699-b4fd-4bfe-9875-2e13763dc0cf	e67fa525-e8f5-490d-a37d-0abc1ed84664	182	L0028-26	2026-03-14	2028-07-27	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
0f040895-ebce-441f-a99f-d80f944b590f	f1b74f45-18f0-4aaa-b552-faff0cdf32cc	50	L0029-26	2026-03-14	2028-08-13	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
f41e08a2-1516-4623-a88a-a5fd558dd45e	3e947b0c-090b-468e-a135-344ba0de8b6a	79	L0030-26	2026-03-14	2028-08-30	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
84f9e320-0386-40aa-9aaf-728945b3bce6	dc79af65-ce69-4b42-8a33-aa0ec4813825	122	L0031-26	2026-03-14	2028-09-16	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
d5e102bf-5398-4e27-b1f5-7f1f5d7cfd25	6c34c012-7915-4776-a07f-39eb6adc4c34	50	L0032-26	2026-03-14	2027-04-12	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
a718eb82-ac25-4281-af8a-492870d98a84	37b0ceb3-ff58-4610-b493-915df2b6e67f	145	L0033-26	2026-03-14	2027-04-29	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
3fbc510b-98f8-4211-9b84-f2ae2eeefc3f	718e574e-aff6-4e31-a887-2a142d7fbf5b	111	L0034-26	2026-03-14	2027-05-16	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
1a0fea4d-1aaa-4693-97f3-ec42b717a1e3	48a02c65-af24-4a5c-91b5-9b0cb660b686	55	L0035-26	2026-03-14	2027-06-02	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
9d636373-5508-42ca-85da-b990505bc387	002bf55d-20b7-40f8-b285-344ae637253b	50	L0036-26	2026-03-14	2027-06-19	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
dccae67e-7e19-4daa-944e-88dc19d8f207	96f86264-21b4-4624-93c2-a84ab4a73eb5	159	L0037-26	2026-03-14	2027-07-06	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
95e1aa66-f09a-4822-927a-f8c2970e8ea5	265d9f6e-50d3-4478-93f4-84aaa900acdb	50	L0038-26	2026-03-14	2027-07-23	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
9a74a5e5-f042-4217-a1d4-c9d0e42ea910	4a8921b4-7955-472d-91f3-d77d0b4e70dc	132	L0039-26	2026-03-14	2027-08-09	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
d6c16b01-8f8f-4b62-918a-1e2ddcc25e91	d54e9418-743e-4640-97cf-0ca9ec070608	126	L0040-26	2026-03-14	2027-08-26	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
1371d1bc-9284-4525-9bea-45ce0e6e9cd2	473d9ce3-b656-4539-9de1-bc68e43f94b5	50	L0041-26	2026-03-14	2027-09-12	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
77f21dd2-9079-4af9-baa4-6e5fa29e1ee5	e25a1819-0bbc-43b2-9593-d3bde568bda3	157	L0042-26	2026-03-14	2027-09-29	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
70005e64-b574-4654-bd89-9b1062a8f126	c6c70da4-4f84-4f76-907c-5fd86517cb7a	70	L0043-26	2026-03-14	2027-10-16	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
8c4bc1f2-aec1-475c-8a4b-00fab2a0fa45	e159e6cd-d383-4ac3-a955-68c205f6bde5	50	L0044-26	2026-03-14	2027-11-02	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
9caa96ae-8343-4c4d-bec8-01780c65d720	1edb4fdf-1c7c-4847-b8bd-f6164f1d75e5	90	L0045-26	2026-03-14	2027-11-19	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
747a5731-b2f6-48b0-9896-9c38250e7791	97960dea-f0cd-4dab-9efc-9936d7b12737	192	L0046-26	2026-03-14	2027-12-06	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
9127f9e0-79cb-4899-a765-566dbf784a08	1446c26d-4837-4291-bad7-4acca0c651b0	110	L0047-26	2026-03-14	2027-12-23	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
53b0fdc2-159c-479c-9e20-78102f42d0c5	8a6f23ce-73e7-4884-9157-bd6d68e9512b	50	L0048-26	2026-03-14	2028-01-09	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
84366587-9ea4-4698-a051-0ca8de4d9c7b	c4e77422-c7f3-4011-88b1-55232d4bf98c	147	L0049-26	2026-03-14	2028-01-26	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
7aedd91c-70ef-4d6b-a8df-8a757238ff73	b1353279-83a9-4d7a-a6a8-c3481da6139c	156	L0050-26	2026-03-14	2028-02-12	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
df9bd6ad-fdef-4bbc-8cd8-6b1fdadf132f	152e22ac-2097-4928-b645-6b1df6e80f60	128	L0051-26	2026-03-14	2028-02-29	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
90b9c653-1876-47da-99e5-8ac59e858091	d3332ba8-f855-40cc-bf1c-ebf8bc2a4724	50	L0052-26	2026-03-14	2028-03-17	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
3b8364bd-6678-48c2-884c-05d14ba1ffa2	9616350b-6010-407d-a0af-e24f0b6735c5	61	L0053-26	2026-03-14	2028-04-03	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
358146aa-ce15-46fb-981c-7f620cd98788	0a5b47a1-87a0-4c55-afd8-cd50997fc5e6	50	L0054-26	2026-03-14	2028-04-20	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
bef18cca-99fa-405b-aed0-d122ea11329f	e42c1764-5523-4ed4-b52d-290fdd10e7e0	193	L0055-26	2026-03-14	2028-05-07	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
86e8582f-e21c-481c-9dd4-12703fdb3d90	14b55f14-7697-4007-9c0b-3dfaf4990871	180	L0056-26	2026-03-14	2028-05-24	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
dd4ff1a2-1c4a-4d90-9ad2-04818a2cfeb3	d2b0aba9-adbb-4681-b337-a10389693607	131	L0057-26	2026-03-14	2028-06-10	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
39fa5b56-c38d-477b-901b-a87db9be5eda	ce67703d-1b3a-4f61-8ddd-b7073630ef7e	172	L0058-26	2026-03-14	2028-06-27	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
3a86b2bd-10af-4540-bfbb-8d33b8f25164	256a4ce1-c8c0-43c6-a760-fa83b811553b	50	L0059-26	2026-03-14	2028-07-14	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
27747709-b8c2-4d13-8a39-1550b0cdc2cf	18d2e53e-ed6b-4135-8400-e5a2fa88ca71	50	L0060-26	2026-03-14	2028-07-31	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
4956a502-3de9-4c94-ac95-1413b320e110	b8887577-7eed-4b52-8d41-06acdfe166a2	50	L0061-26	2026-03-14	2028-08-17	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
3d6f8fc4-8634-4617-a602-83ece62ec1ec	e119e611-bac0-4f7c-b95e-4355da3dbc7a	50	L0062-26	2026-03-14	2028-09-03	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
3353300c-8637-407f-9ae9-ec3914e8b20e	bd7b8de8-7fa4-4263-a9ec-b6ab31e8853a	50	L0063-26	2026-03-14	2028-09-20	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
1169b82b-4f05-472a-b4f7-7643da76370e	ba23a7c2-5caa-4999-8c95-63db832edb54	50	L0064-26	2026-03-14	2027-04-16	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
a965489b-4f1a-4ee3-9224-71ef08ad34af	8c963051-9879-44c3-a9f6-2ecec552d375	123	L0065-26	2026-03-14	2027-05-03	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
825c0fb9-ec3a-4df5-b41d-f774f6861114	8f35a066-02b3-4fb9-bd3f-a14b782e7386	97	L0066-26	2026-03-14	2027-05-20	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
be4c0d11-d521-45b2-b15a-f6bcbdc404e5	5aa3d706-712c-4be2-85f3-6eb0acb33019	99	L0067-26	2026-03-14	2027-06-06	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
0f084c2f-c313-4bda-9f82-4e972f8dd1ab	052e7836-f493-48b6-a4a6-7cfbf1c9fa71	50	L0068-26	2026-03-14	2027-06-23	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
c2a761dd-15a3-48fc-8fb7-bc3983641db7	dac665c6-7a27-4915-a2c7-c7e0f097d00f	84	L0069-26	2026-03-14	2027-07-10	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
cc59f1aa-bff6-4b7b-8f1d-0d483536be56	a277aa77-32c3-466b-b829-be57a731ca6a	50	L0070-26	2026-03-14	2027-07-27	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
aa96b981-16dc-436d-bdec-002fbe3ddb27	1ea308e2-43bb-4381-bf59-ef378ee8482e	50	L0071-26	2026-03-14	2027-08-13	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
0d0e2564-e162-4205-b838-a18e7bef406d	2022fa77-0632-475d-8ff3-40ebb1869f4a	124	L0072-26	2026-03-14	2027-08-30	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
5f049504-38a2-47b9-951f-d06a8843e8ca	e5080ce5-f87b-45b9-b80d-c09129dfb92a	50	L0073-26	2026-03-14	2027-09-16	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
edeb69e9-0207-442a-b2b7-f7157a443f54	1565fc1f-0c0b-4225-acd2-b0e16db57b96	50	L0074-26	2026-03-14	2027-10-03	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
b419fa26-99a5-44d3-8ba9-2b404c526964	6a2e419e-eef6-4531-aa32-7182f1647503	187	L0075-26	2026-03-14	2027-10-20	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
f2119d3e-1721-4cac-8e3f-28da011f6e65	a5b4ea63-cca6-49f3-87e5-6ecb6cd17ec0	93	L0076-26	2026-03-14	2027-11-06	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
caac846f-d462-4281-8f06-d113638b909e	7ef1546e-cce2-4f28-a931-bf8d45a40cf6	50	L0077-26	2026-03-14	2027-11-23	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
c0597039-af6e-49af-b438-50b1ea8b810c	ceb9eb32-2a7d-4dc2-9067-108dd35a3898	83	L0078-26	2026-03-14	2027-12-10	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
2e912a0b-77fd-41f2-a369-bb58db8d1fab	8f75d14b-4f8b-4f51-8ab6-5178684ec719	50	L0079-26	2026-03-14	2027-12-27	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
9d2ac4f6-96ae-4d8b-a6f3-909d4bcea7c7	4eb13f82-85cf-44a9-b75e-4c799f9048a9	50	L0080-26	2026-03-14	2028-01-13	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
3c2761ef-2fb9-4aae-9cff-79385c3889ab	953c0383-c8f4-4314-89e6-cadfb7808947	91	L0081-26	2026-03-14	2028-01-30	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
c1b6bd56-d63c-4e2f-9b2c-762f63aa0fa5	6bf0f9f2-b32b-4531-a5dc-70fe95d22122	87	L0082-26	2026-03-14	2028-02-16	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
f80c210e-e03f-4495-985f-ffa0fa9e269a	d70fd4c8-795b-4175-9f07-5d4969cc205e	50	L0083-26	2026-03-14	2028-03-04	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
8a4353b9-1019-4a1c-b559-1ef9a22726f1	4c601da5-4d3a-4a92-8e8b-bc7cd970b7d7	194	L0084-26	2026-03-14	2028-03-21	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
87f66d2e-efd3-4358-ba3b-df4b40618cd2	6aca0dd5-6e3a-48a8-8373-e3c17e21b741	122	L0085-26	2026-03-14	2028-04-07	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
1e6985ea-3bdb-4235-b38b-e5e84d02939a	4812aaae-f518-46b7-8cce-d277d958a2c1	50	L0086-26	2026-03-14	2028-04-24	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
2772c192-e995-4acf-98e1-29023e064bd1	ddb60ae4-703f-40c9-975f-1310f11aea22	83	L0087-26	2026-03-14	2028-05-11	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
66b7d8ab-e61a-419f-b580-f9084a8bea96	27f929f9-3c52-4cdd-be09-d8fdde335b39	60	L0088-26	2026-03-14	2028-05-28	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
ad7c86cc-e213-46ed-b31d-1f660f095649	ea848d2f-888b-4158-867e-6f5a220ada4c	195	L0089-26	2026-03-14	2028-06-14	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
18a9e800-bf87-4209-a44b-36710595484c	cf502a80-748d-4c4c-a829-384cd4f28632	50	L0090-26	2026-03-14	2028-07-01	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
a9030dea-a0ea-4979-8286-b110ace94619	74b28038-7f09-4e38-94de-8663150fbb77	50	L0091-26	2026-03-14	2028-07-18	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
755c47d0-912f-477c-a98d-04d1b2b2fb1b	6ca85bf4-69cb-4172-8f25-9c7405e02b24	181	L0092-26	2026-03-14	2028-08-04	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
7f8c3d56-2ba5-4ea0-95e3-a1e69d928434	a77bf257-0ccd-4a19-9bd6-e6e12e2075e6	50	L0093-26	2026-03-14	2028-08-21	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
071e8a3f-921d-4161-965b-1a128d197a9e	f8168f08-94ca-47d5-8b60-e542663b07bd	112	L0094-26	2026-03-14	2028-09-07	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
963eb045-f1b3-4813-a85d-487cf209260c	c5066342-35e2-4e77-a282-e03f94f8e9d7	76	L0095-26	2026-03-14	2028-09-24	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
1c473e16-87eb-4c8d-a5f6-74ac035e2c6e	c256cc07-1613-449a-a081-865b4cd18362	156	L0096-26	2026-03-14	2027-04-20	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
a88ca869-d1c9-450a-af79-bf4832c88ccb	07bed11f-ad1b-4b14-b442-a6434e07c748	124	L0097-26	2026-03-14	2027-05-07	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
87c3dc20-8031-4fc6-bdf8-e4f8a5b5ad6f	111a069a-3bf3-4c20-b9ed-3d501863c434	117	L0098-26	2026-03-14	2027-05-24	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
a1e66ef3-8414-4f46-9964-5941ab20deef	22a9bb22-6149-41d7-952c-06a41a5836ed	89	L0099-26	2026-03-14	2027-06-10	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
aa60785a-91b1-4017-a241-7db835568569	8e1cde62-bb09-4d9c-bef5-9e81ac6622d7	51	L0100-26	2026-03-14	2027-06-27	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
da6804b9-cdb3-4d00-a0ba-87281e3cde55	af1dce31-cec9-4fda-9329-0d712504057c	52	L0101-26	2026-03-14	2027-07-14	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
175dd92d-13e4-415b-9dcb-ae267fa2022a	5cbe1185-ccc4-4607-96bc-3620ea2e5ba8	183	L0102-26	2026-03-14	2027-07-31	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
0d616117-367c-47b9-8ce6-c3002539bfa6	26e04ec4-2950-43fa-a436-c48ce8879994	105	L0103-26	2026-03-14	2027-08-17	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
c38b2012-1b18-4ccd-9982-1051beb62add	fa79823a-56dc-49d4-8066-411a1961632b	50	L0104-26	2026-03-14	2027-09-03	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
17ff4810-2bfc-4879-b476-b0ae62ccf617	aec61c3d-971c-4b13-a145-28834d0bff3e	50	L0105-26	2026-03-14	2027-09-20	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
614892da-5637-44f2-9c83-3f851b04660e	7c9fcf31-23dd-4a53-aebc-1e497c5a8dcc	50	L0106-26	2026-03-14	2027-10-07	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
e3b4a2a5-a3bb-4356-bf21-5c2ebf31387c	bd9da9fc-b681-4350-9efa-27960a2367ef	50	L0107-26	2026-03-14	2027-10-24	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
07bccaf5-2d8e-411e-8af4-2aa7dbf84826	f2ffd93d-9452-411e-8761-0c6dab585eac	117	L0108-26	2026-03-14	2027-11-10	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
3b032fc2-c703-459d-9397-3478b7cfa156	0de5f9dd-0cae-4ddd-a7e0-35dc57ebd1db	50	L0109-26	2026-03-14	2027-11-27	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
3c548a34-8cd8-45ca-85a1-fdd25ec4e8a6	67fa873a-35b0-4fe6-b298-b16ad881a6fd	64	L0110-26	2026-03-14	2027-12-14	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
c57d0a6a-138e-4c32-b982-4e2375a8ae0a	ccabfbea-b88d-4ecc-adbd-f39e307f633f	50	L0111-26	2026-03-14	2027-12-31	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
0e093ad0-1c53-4135-abcc-3a5c212d6b55	5324d9c2-76ab-47ae-9315-762c637ab9c9	142	L0112-26	2026-03-14	2028-01-17	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
d3d34502-2797-4f9e-a1a2-4e2d5b508aa8	9dcccb2a-7b0f-4fea-b604-9e92d121fcbe	50	L0113-26	2026-03-14	2028-02-03	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
a55a1f69-f33d-41a4-be59-f4e77d9b06cc	413704c7-8e5d-445c-8b46-84b61cfd1169	50	L0114-26	2026-03-14	2028-02-20	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
14ffe099-be2c-4426-8284-c2819774e535	7c0d3e06-83ea-44e0-a8b3-2a75b7cc692e	50	L0115-26	2026-03-14	2028-03-08	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
74e86e95-ad2a-4f76-89de-cb372edeade5	d7783e41-91bd-4ed5-bcb4-f4bd32cacbaf	94	L0116-26	2026-03-14	2028-03-25	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
aa21b94f-0245-4b80-97a6-1892577e046c	484c5892-982e-4cc1-95ec-b43985ed3190	92	L0117-26	2026-03-14	2028-04-11	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
923a47ae-5745-46ae-b75b-e10f56016959	b16a1713-398c-48a0-9212-4911b0c409b8	102	L0118-26	2026-03-14	2028-04-28	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
62ba6568-ad26-44f5-9584-4acf48bbd4b6	a2034563-fd1b-4cc3-8e5d-217deebe5977	113	L0119-26	2026-03-14	2028-05-15	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
3ee78352-beaf-419a-9f0e-4e58652f6db3	36f4b481-e00d-4014-8fd6-e1a159aaf576	159	L0120-26	2026-03-14	2028-06-01	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
7bddfcab-9162-4814-aa34-24f3ae912ada	f2e819c3-9380-4537-bd11-286dd2263274	195	L0121-26	2026-03-14	2028-06-18	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
be68421e-5d80-4855-bfba-9d27bd17ea4d	172ef723-7572-4360-ba73-71b60206190e	111	L0122-26	2026-03-14	2028-07-05	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
017f9d40-cd79-4ff5-861c-e5cab2bfdda5	6eb24a03-0742-4a48-98a0-7ccde1425db8	157	L0123-26	2026-03-14	2028-07-22	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
a7c2b400-3e44-4325-93a0-91e02c26483d	ebd03bee-a78b-42fc-8b71-080d8212d153	116	L0124-26	2026-03-14	2028-08-08	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
df524117-6bd3-4275-b9a1-1e8b7dd30a71	52a18303-30a4-46b4-82ab-ca088a49e938	54	L0125-26	2026-03-14	2028-08-25	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
5ea22cd9-0a9e-4c0e-bef4-a43000a71e3d	01c4ce47-9509-4f19-b702-3ddd606cb25a	142	L0126-26	2026-03-14	2028-09-11	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
5ee7f533-5d29-4afe-96ee-c41586f8966a	6f6d653e-1b45-442a-9fc0-79094297f312	50	L0127-26	2026-03-14	2028-09-28	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
5b373560-cc25-43c9-8016-4f92f0d5f57d	08ca1341-1e22-4565-aba2-4b531b908fb9	50	L0128-26	2026-03-14	2027-04-24	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
08dcc860-450b-4014-aaa6-c8a01873dade	5513c45a-7ba0-4b71-9fd1-83b81677074d	50	L0129-26	2026-03-14	2027-05-11	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
38f6b853-526e-46c3-857f-ed617b4ac914	26ed47f8-74cd-4e69-a321-4f5475c54f6f	166	L0130-26	2026-03-14	2027-05-28	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
cf81423d-997f-4300-af7d-ef16cf6dae95	b918e0e8-ae78-4421-9846-b06c0ebfa335	136	L0131-26	2026-03-14	2027-06-14	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
0b32b8e8-1236-443f-b4a6-5cb806ea0933	78fbc574-ac4f-4397-9540-395592946b0c	65	L0132-26	2026-03-14	2027-07-01	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
2e3647e8-52df-4c84-aa89-5560b8be10c4	7e5d5112-6e77-4cdd-99c3-e0e6daeae119	164	L0133-26	2026-03-14	2027-07-18	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
d68fd885-3646-445b-a4fb-26a279816545	e05026da-2f54-4e7f-890e-aec8779a2bf2	50	L0134-26	2026-03-14	2027-08-04	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
b6b0d36d-eec6-4df5-bf23-27fe96ee9ec5	3679cb2b-e8e9-4d33-9ec4-32e070e6557d	50	L0135-26	2026-03-14	2027-08-21	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
1a2c8758-5d78-4c0e-9fb7-dc7555d45e45	b341e09b-3c3a-4c2f-a8bc-a94f44e1b79a	50	L0136-26	2026-03-14	2027-09-07	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
3b732ebf-b79d-4e6c-8bb4-e19d2e7bf4e6	05afce1d-1090-4542-9656-152249a6a3b0	50	L0137-26	2026-03-14	2027-09-24	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
384d89b1-39eb-45fa-85c3-7437104de5ef	06eb2f49-2bb8-430a-a1d0-d0119dac0071	182	L0138-26	2026-03-14	2027-10-11	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
5660c8d2-a9ca-4912-a60b-690f373cd11e	881ad61b-eb1a-4bbf-89a8-aead96014bf5	62	L0139-26	2026-03-14	2027-10-28	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
14e88555-e1e8-4341-835b-7fff36a14e27	6931e056-2b2a-4744-8592-83d154258514	198	L0140-26	2026-03-14	2027-11-14	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
cb3cea83-b3f3-41aa-9dc0-e15ba3e8ce25	83eb3b93-8e45-4673-b414-a77b3999bbb1	168	L0141-26	2026-03-14	2027-12-01	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
5b287b6a-c2bf-4d99-b481-7806b45f3af8	700422a9-c456-455f-a379-2a1e5ea5e6dc	50	L0142-26	2026-03-14	2027-12-18	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
23c3a565-f67c-4d79-9e1a-bf2b88eb4703	fc7ee691-a366-4fbc-8860-99d1d2c30057	127	L0143-26	2026-03-14	2028-01-04	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
a856dfa8-2ee4-4d27-8303-f4d6dd17f16f	66ab38b5-6dcb-4757-9015-2cf3630e2059	50	L0144-26	2026-03-14	2028-01-21	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
dd9bb103-fce0-4642-ac43-e0e1869980ef	8ee5677b-e5db-46f0-b33a-cc6773ce2822	193	L0145-26	2026-03-14	2028-02-07	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
bfb3d7e0-1cc7-43b3-ac15-2bf6358f5e16	3dec0f6d-bd43-4826-bda9-224016a1216e	152	L0146-26	2026-03-14	2028-02-24	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
b6d75d60-9739-40a0-aa48-ab3aa198843a	2edde32f-67a8-4ab3-a810-59d65a3932f1	50	L0147-26	2026-03-14	2028-03-12	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
967cb1c9-6622-48cc-a333-c6aee949367b	8bfe8acf-0e1f-434a-8a60-e914f0e992ad	102	L0148-26	2026-03-14	2028-03-29	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
2456f386-3b66-41fb-b1c6-e96c3bbeb5c3	95e4b260-b2de-4657-a568-6f10481c4a65	50	L0149-26	2026-03-14	2028-04-15	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
a8170226-e654-4e22-988d-52804505197d	51772893-c6ac-46e1-8f1e-29f7eb37d1f4	152	L0150-26	2026-03-14	2028-05-02	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
c1bccebf-a6e1-4782-9dde-6750f110e6f3	d66e3aa0-1ebd-4ec1-919d-9905e9dc3fa3	50	L0151-26	2026-03-14	2028-05-19	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
f1eef6a3-e7cd-4f5f-bd62-979e86e87e2d	5f3cbd0e-44e4-4833-b8e2-39c4b3cbc8a6	50	L0152-26	2026-03-14	2028-06-05	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
b08cda70-d485-435e-90b9-9bd451ed14a3	f507348c-1f33-490f-ad91-45d0bc56b281	198	L0153-26	2026-03-14	2028-06-22	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
f8a88d87-cc34-40a9-8867-5442514872c6	8b49c481-0b8c-4fd6-8854-c4fec4484b71	165	L0154-26	2026-03-14	2028-07-09	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
2dfecf1b-4d09-4204-9767-7681059548ac	6ccade22-6a58-4328-a8ad-56aee1df6935	50	L0155-26	2026-03-14	2028-07-26	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
27e4c1ca-0146-4066-9e45-c86f8f35bb0e	bd05e4e7-ed79-463a-b0bc-88bea0e00146	50	L0156-26	2026-03-14	2028-08-12	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
ecc5c5e8-9906-4577-9d96-7a26fa9ddb18	014f117c-c473-42a8-9436-1d764d393cf7	50	L0157-26	2026-03-14	2028-08-29	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
af765421-e5e7-4610-b5bd-6c4f934ae98e	c46a46be-f2b5-4609-9563-3f1b583cec60	178	L0158-26	2026-03-14	2028-09-15	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
fd73c347-fac2-4c58-86a4-b7c060988f33	148fbdbe-1912-47e8-a68f-9116dfe183e2	81	L0159-26	2026-03-14	2027-04-11	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
5a69447b-edda-4408-93e5-3746bc71b0cf	a06dc368-e687-467f-91b9-45a088de1d5f	196	L0160-26	2026-03-14	2027-04-28	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
425632b2-5b7d-495a-a375-0d325002f6a5	4a43a972-ce5f-40d6-8fac-3618867c2664	85	L0161-26	2026-03-14	2027-05-15	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
04f3b317-5cb7-4b6d-a3d5-f8b82162d753	c78104d2-46d5-49ee-b6ab-151900cea1e8	198	L0162-26	2026-03-14	2027-06-01	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
0a126496-b1d6-4cf1-9469-e07e79bbecce	e7a05b83-3400-4dd3-947f-20dfc1a0c2f1	175	L0163-26	2026-03-14	2027-06-18	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
a0ecc76c-c314-493a-9f7d-254e9b94506e	4db77aad-b63f-4d60-a06d-387911960116	133	L0164-26	2026-03-14	2027-07-05	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
908227f8-64eb-40a3-bcac-c94a33e0b5d1	6988420b-5aae-4f37-b42b-c1960597571e	156	L0165-26	2026-03-14	2027-07-22	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
8b02cbc6-22d8-43c6-b0a5-4b246ca25aff	2f816437-9c70-4901-a2d9-f661737a90a1	185	L0166-26	2026-03-14	2027-08-08	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
baaf58d5-d909-4e36-a857-f2b8cbe34edf	5034e666-f53b-45b3-ad91-478d389082f4	50	L0167-26	2026-03-14	2027-08-25	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
455e34ad-3c79-4ad8-916f-65808d61f95d	e7dd4896-e4c1-40e9-b39a-2c05dc9d4e67	50	L0168-26	2026-03-14	2027-09-11	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
4225f4c2-f5d7-4357-90eb-a4190796fe0c	5a22b2a5-3180-404e-9340-87e5928feb15	50	L0169-26	2026-03-14	2027-09-28	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
43fd855a-2e6e-4958-ae1a-fcbbefa4d749	88c8d3b9-c187-425c-a2cc-9b5c81d9c75d	97	L0170-26	2026-03-14	2027-10-15	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
19412bac-fdf8-40d3-a59f-7cc90283401c	6ecd7702-e826-4279-b480-59afa6a97df7	117	L0171-26	2026-03-14	2027-11-01	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
be70466e-3932-4b70-8259-19cd19ce69cd	63a54387-c2d8-49ef-8ef5-972c0e1fa35c	153	L0172-26	2026-03-14	2027-11-18	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
c353ebd5-4603-4188-827a-c4946233d59f	8a063409-4eec-4c69-a64d-e324ecbf0cf3	161	L0173-26	2026-03-14	2027-12-05	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
62cb1034-6996-40bf-998c-9c60255da042	0029ee37-f901-46a4-9eb5-d41d164c8103	50	L0174-26	2026-03-14	2027-12-22	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
679ac9d0-41aa-4180-affc-7f09ebcbf976	aa72e0d2-f3cb-4145-8b11-ab07d834ad4e	156	L0175-26	2026-03-14	2028-01-08	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
89894ec1-8bc5-4829-8a39-b29c39b55fa6	37c51961-338d-45ec-81f6-20a5ee475c86	50	L0176-26	2026-03-14	2028-01-25	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
63ff88b0-06f7-4818-abe4-93b144156999	c0c4e9eb-b124-4649-8603-ec2090d9b779	50	L0177-26	2026-03-14	2028-02-11	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
4d45d523-b4a4-4c38-b923-e482bd6b400f	23b8d8a5-22e8-4197-a44f-f77df51a9427	178	L0178-26	2026-03-14	2028-02-28	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
7422f3c4-ff35-4209-99fa-e792d86d6ebd	4037461d-2650-43ff-8df4-9da73f02300f	180	L0179-26	2026-03-14	2028-03-16	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
71fbe1db-e464-47df-9c4a-221c4f29de7f	85d79d5d-ba26-46aa-9647-ff79261c7994	58	L0180-26	2026-03-14	2028-04-02	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
44de72b4-b455-4701-8a1a-8aca90d710c9	20cd80d6-ab26-4775-977b-98d72fa83438	106	L0181-26	2026-03-14	2028-04-19	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
a201ff4e-2555-42e1-832e-aa662e8f0cbd	a8728fbc-a1b2-440c-9c45-6588fb304429	144	L0182-26	2026-03-14	2028-05-06	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
d9851f72-42f1-4e5a-a2ed-431fdff55ea5	03a5a254-31f1-46fc-9a3c-7398d332c479	130	L0183-26	2026-03-14	2028-05-23	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
c67bf364-91d3-445f-8ddc-00e18e1598d2	d4a4f866-09a2-48ae-9899-356112e99296	129	L0184-26	2026-03-14	2028-06-09	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
aa296f46-4701-40a9-8904-8ac77b974ca5	524c5fb4-4f2c-49f2-8432-90ca2cc013f9	75	L0185-26	2026-03-14	2028-06-26	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
ef94f7da-da49-48ac-817b-b487101025e9	3ff2fa32-995b-42c8-aa98-9418cdd9ccbb	50	L0186-26	2026-03-14	2028-07-13	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
aac85648-96ea-485e-9520-6260d0f777b8	9b849738-afb3-4307-95f7-9910c1d4ba70	50	L0187-26	2026-03-14	2028-07-30	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
90332abc-2f39-4841-89eb-3f1cd0b4c4fb	88b5e910-42ac-4730-accc-794716afcc99	164	L0188-26	2026-03-14	2028-08-16	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
539e5825-ab7f-43a8-9a54-8d0f78791efb	c36818db-9d37-461d-bdea-ac71158aa847	50	L0189-26	2026-03-14	2028-09-02	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
6e574ca3-7a72-483c-9044-d49cad39ae75	c466daaa-d5a4-4610-b810-458353d45263	89	L0190-26	2026-03-14	2028-09-19	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
b8f01e8d-f2fa-41fb-a533-c9324cc8816c	2751de35-dd4c-48cf-a2ec-83b4ae3d399e	50	L0191-26	2026-03-14	2027-04-15	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
95765b51-629d-4209-8102-07c23109866f	68ff5893-3b79-4bac-973c-4d64e66be1ec	119	L0192-26	2026-03-14	2027-05-02	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
e92b961a-bee8-4684-bb67-342fcf740ff6	14c4de2e-b376-4b15-b198-a443cc528ce9	50	L0193-26	2026-03-14	2027-05-19	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
35804a94-1f02-47b8-942a-bfc9c74b90ca	ee5bcc2e-98b8-470d-a111-310f96e52425	170	L0194-26	2026-03-14	2027-06-05	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
eca3688a-c62b-4151-be23-835832991f50	90200f27-9a7f-471d-9328-f060d1c24891	50	L0195-26	2026-03-14	2027-06-22	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
c07d90dd-e336-48e9-93d4-788f28fdff4f	f8e8d8ec-5b27-435a-aa18-228df987e4de	78	L0196-26	2026-03-14	2027-07-09	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
12c72c43-8d2e-420f-99cd-dfebf2967205	8a418e73-4323-4fa2-ab33-d6c42c78bbea	50	L0197-26	2026-03-14	2027-07-26	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
1de66149-04eb-4567-a4cd-5cad6d4921ac	0e0413b5-fdaf-42a8-8a3f-f61af8cef26e	50	L0198-26	2026-03-14	2027-08-12	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
1d61e67b-e026-4ec5-87af-baba712520bc	712985a6-5d7c-4a44-a374-6645167d4989	192	L0199-26	2026-03-14	2027-08-29	SAIDAL Distribution	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	2026-04-13 16:41:14.968546+00	\N
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.audit_log (id, entity_type, entity_id, action, actor_id, "timestamp", old_value, new_value) FROM stdin;
a301ea81-0f7b-41c6-a67d-ced420e1b32c	users	9f334b50-59fc-4c16-8635-e9f29c46cdf7	insert	\N	2026-03-26 10:08:48.259648+00	\N	{"id": "9f334b50-59fc-4c16-8635-e9f29c46cdf7", "nom": "Administrator", "role": "admin", "email": "admin@dimed.dz", "adresse": "None", "secteur": "None", "is_active": "True", "created_at": "2026-03-26 10:08:48.259648+00:00", "created_by": "None", "updated_at": "2026-03-26 10:08:48.259648+00:00", "password_hash": "$2b$12$5SLvzbmf6vRCVfke1e4IsuFRar5uk7JpmIjtpGDbRmuUIr6wvNKzO"}
b24490d4-20f3-4b97-b07b-cefc33bb82f0	users	80b3ae99-edfc-4220-a471-03c5366fb10d	insert	\N	2026-03-26 10:56:38.10231+00	\N	{"id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "nom": "Pharmacie Centrale", "role": "pharmacien", "email": "pharmacien@dimed.dz", "adresse": "None", "secteur": "None", "is_active": "True", "created_at": "2026-03-26 10:56:38.102310+00:00", "created_by": "None", "updated_at": "2026-03-26 10:56:38.102310+00:00", "password_hash": "$2b$12$B6GxGTni7xNUulE77EIoHewz5Kjx6SaMC2kwoiey2U5efx3Odii0i"}
9e4bf3dc-be8e-47c3-b919-cd95ed50f14a	users	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	insert	\N	2026-03-26 10:56:38.10231+00	\N	{"id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "nom": "Fatima Operatrice", "role": "operatrice", "email": "operatrice@dimed.dz", "adresse": "None", "secteur": "None", "is_active": "True", "created_at": "2026-03-26 10:56:38.102310+00:00", "created_by": "None", "updated_at": "2026-03-26 10:56:38.102310+00:00", "password_hash": "$2b$12$PLcGHPtUIxtKimUdmoJB1unPNeb7lZvvTKoL548rPvtS6eb4lDZ/6"}
8f2c4e49-6b90-488b-9225-643fac4a8120	users	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	insert	\N	2026-03-26 10:56:38.10231+00	\N	{"id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62", "nom": "Karim Preparateur", "role": "preparateur", "email": "preparateur@dimed.dz", "adresse": "None", "secteur": "None", "is_active": "True", "created_at": "2026-03-26 10:56:38.102310+00:00", "created_by": "None", "updated_at": "2026-03-26 10:56:38.102310+00:00", "password_hash": "$2b$12$u6ucold4kYgC3l6btprrgOF5qMRsd8ottq62HlzP7u6lU88qMT3AW"}
1711fb9f-ee9f-4cb3-b2c6-ef13cb74c35f	users	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	insert	\N	2026-03-26 10:56:38.10231+00	\N	{"id": "aec28fb7-8dfb-4781-b2b0-932d1a9e891d", "nom": "Yacine Controleur", "role": "controleur", "email": "controleur@dimed.dz", "adresse": "None", "secteur": "None", "is_active": "True", "created_at": "2026-03-26 10:56:38.102310+00:00", "created_by": "None", "updated_at": "2026-03-26 10:56:38.102310+00:00", "password_hash": "$2b$12$R3THkp6A89M/s43IdkZaR.83AJzFGjqKC5py5I.O3sV6L3OYrt0Fy"}
2c5c1157-6f04-4b5c-8623-fb82b468e182	users	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	insert	\N	2026-03-26 10:56:38.10231+00	\N	{"id": "ef6fb6ab-1b1a-41ea-bf5a-658502d156f7", "nom": "Ahmed Livreur", "role": "livreur", "email": "livreur@dimed.dz", "adresse": "None", "secteur": "None", "is_active": "True", "created_at": "2026-03-26 10:56:38.102310+00:00", "created_by": "None", "updated_at": "2026-03-26 10:56:38.102310+00:00", "password_hash": "$2b$12$bvdw3yUvAKlddqB8wiTDF.9I1kN2GbxWwIsPyheEXx6HGiRP8BhQ6"}
39064cd2-ac2f-4ff4-8b40-62271a2f3e16	commandes	6082713a-d865-4e27-8a42-5bfedaa5c38d	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:04:24.277773+00	\N	{"id": "6082713a-d865-4e27-8a42-5bfedaa5c38d", "statut": "creee", "camion_id": "None", "commercial": "None", "created_at": "2026-03-26 11:04:24.277773+00:00", "created_by": "None", "updated_at": "2026-03-26 11:04:24.277773+00:00", "reference_id": "C00000004", "montant_total": "3691.50", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None"}
2bece64a-41b5-4308-be7b-2176e9ca9ed9	lignes_commande	648eb1fb-1340-4544-8b0a-4277571ecc78	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:04:24.277773+00	\N	{"id": "648eb1fb-1340-4544-8b0a-4277571ecc78", "n_lot": "None", "created_at": "2026-03-26 11:04:24.277773+00:00", "created_by": "None", "updated_at": "2026-03-26 11:04:24.277773+00:00", "commande_id": "6082713a-d865-4e27-8a42-5bfedaa5c38d", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "5", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
510a0050-ad64-421f-b458-59b87abd39ca	lignes_commande	69c98964-6bb7-416e-b786-22dc6db35e79	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:04:24.277773+00	\N	{"id": "69c98964-6bb7-416e-b786-22dc6db35e79", "n_lot": "None", "created_at": "2026-03-26 11:04:24.277773+00:00", "created_by": "None", "updated_at": "2026-03-26 11:04:24.277773+00:00", "commande_id": "6082713a-d865-4e27-8a42-5bfedaa5c38d", "designation": "APROVASC 150MG/5MG  B/30 COMP. PELLI", "qte_demandee": "1", "medicament_id": "72dcd068-d94c-4c76-9dca-3ddace1e5962", "prix_unitaire": "1497.50"}
791469a1-bba1-4a4e-8d36-bdacc3692b4e	lignes_commande	d3915e19-fa90-4cfa-aae5-4c3dd2b4656c	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:04:24.277773+00	\N	{"id": "d3915e19-fa90-4cfa-aae5-4c3dd2b4656c", "n_lot": "None", "created_at": "2026-03-26 11:04:24.277773+00:00", "created_by": "None", "updated_at": "2026-03-26 11:04:24.277773+00:00", "commande_id": "6082713a-d865-4e27-8a42-5bfedaa5c38d", "designation": "APROVEL. 150MG B/28 COMP. PELLI", "qte_demandee": "1", "medicament_id": "7435046b-fc3b-4c8e-9041-9c1e886aa102", "prix_unitaire": "1201.50"}
50c51344-6453-4246-bec8-53080ce787d9	commandes	8749fa09-b997-45a6-b5be-e9b1f49c23d2	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:04:39.866189+00	\N	{"id": "8749fa09-b997-45a6-b5be-e9b1f49c23d2", "statut": "creee", "camion_id": "None", "commercial": "None", "created_at": "2026-03-26 11:04:39.866189+00:00", "created_by": "None", "updated_at": "2026-03-26 11:04:39.866189+00:00", "reference_id": "C00000005", "montant_total": "198.50", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None"}
1a5eff02-b627-4359-98d2-21adf309bcc0	lignes_commande	0c7e9412-7c38-4a48-9c2f-a12be4950c66	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:04:39.866189+00	\N	{"id": "0c7e9412-7c38-4a48-9c2f-a12be4950c66", "n_lot": "None", "created_at": "2026-03-26 11:04:39.866189+00:00", "created_by": "None", "updated_at": "2026-03-26 11:04:39.866189+00:00", "commande_id": "8749fa09-b997-45a6-b5be-e9b1f49c23d2", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
7a42da89-8aa7-43ca-8f0c-361947cfd8fc	commandes	0bff5c32-f6f8-4986-92ea-b6a8147cba6a	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:15:16.104921+00	\N	{"id": "0bff5c32-f6f8-4986-92ea-b6a8147cba6a", "statut": "creee", "camion_id": "None", "commercial": "None", "created_at": "2026-03-26 11:15:16.104921+00:00", "created_by": "None", "updated_at": "2026-03-26 11:15:16.104921+00:00", "reference_id": "C00000006", "montant_total": "198.50", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None"}
68685770-3b7c-478b-b4ca-22de6b11fe8c	lignes_commande	dbd086e4-3616-4600-9d2d-3455f9854acc	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:15:16.104921+00	\N	{"id": "dbd086e4-3616-4600-9d2d-3455f9854acc", "n_lot": "None", "created_at": "2026-03-26 11:15:16.104921+00:00", "created_by": "None", "updated_at": "2026-03-26 11:15:16.104921+00:00", "commande_id": "0bff5c32-f6f8-4986-92ea-b6a8147cba6a", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
f9485503-9f4c-43a0-a76b-ae024c1a264b	commandes	0bff5c32-f6f8-4986-92ea-b6a8147cba6a	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-26 11:16:20.943614+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-03-26 11:16:20.948245+00:00"}
983b1cd4-df5d-455e-aa25-01c2866228f9	factures	385fdfc5-aac8-4ee7-8200-4cb87191099d	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-26 11:16:20.943614+00	\N	{"id": "385fdfc5-aac8-4ee7-8200-4cb87191099d", "created_at": "2026-03-26 11:16:20.943614+00:00", "created_by": "None", "montant_ht": "198.50", "updated_at": "2026-03-26 11:16:20.943614+00:00", "commande_id": "0bff5c32-f6f8-4986-92ea-b6a8147cba6a", "montant_ttc": "198.50", "reference_id": "F0000000001", "date_emission": "2026-03-26 11:16:20.953454+00:00"}
77342e89-a897-4b18-9a5f-0d318cd3c3c0	lignes_commande	c3c874a3-436e-493a-8c80-ce1c3405939b	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-01 13:51:54.090058+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
5b8efdd7-1d79-4769-917d-bca5ce98e49f	bons_livraison	51c17462-f70e-4c60-8280-66ce4a9f2161	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-26 11:16:20.943614+00	\N	{"id": "51c17462-f70e-4c60-8280-66ce4a9f2161", "code_barre": "BL00000001", "created_at": "2026-03-26 11:16:20.943614+00:00", "created_by": "None", "updated_at": "2026-03-26 11:16:20.943614+00:00", "commande_id": "0bff5c32-f6f8-4986-92ea-b6a8147cba6a", "date_emission": "2026-03-26 11:16:20.953454+00:00"}
72678da6-22c8-4810-af8e-c272a18c53e6	commandes	39c1dfe9-f87e-48b9-82f9-585965bef503	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:29:21.70522+00	\N	{"id": "39c1dfe9-f87e-48b9-82f9-585965bef503", "statut": "creee", "camion_id": "None", "commercial": "None", "created_at": "2026-03-26 11:29:21.705220+00:00", "created_by": "None", "updated_at": "2026-03-26 11:29:21.705220+00:00", "reference_id": "C00000007", "montant_total": "6445.58", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None"}
3aa22f40-50fd-4295-b9db-06e8f0f0bb80	lignes_commande	f5df1af1-0fb5-4a1c-9a92-aea12585a54a	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:29:21.70522+00	\N	{"id": "f5df1af1-0fb5-4a1c-9a92-aea12585a54a", "n_lot": "None", "created_at": "2026-03-26 11:29:21.705220+00:00", "created_by": "None", "updated_at": "2026-03-26 11:29:21.705220+00:00", "commande_id": "39c1dfe9-f87e-48b9-82f9-585965bef503", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
fe2d8d4b-bad8-4ffc-9c62-7f34c5650fcb	lignes_commande	60766ac0-3aec-448c-9656-b2ae56626d89	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:29:21.70522+00	\N	{"id": "60766ac0-3aec-448c-9656-b2ae56626d89", "n_lot": "None", "created_at": "2026-03-26 11:29:21.705220+00:00", "created_by": "None", "updated_at": "2026-03-26 11:29:21.705220+00:00", "commande_id": "39c1dfe9-f87e-48b9-82f9-585965bef503", "designation": "APROVASC 150MG/5MG  B/30 COMP. PELLI", "qte_demandee": "3", "medicament_id": "72dcd068-d94c-4c76-9dca-3ddace1e5962", "prix_unitaire": "1497.50"}
3189418f-e676-43ca-8236-1fe4b91532c0	lignes_commande	c0801d80-246d-4722-a678-2928a0a48676	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 11:29:21.70522+00	\N	{"id": "c0801d80-246d-4722-a678-2928a0a48676", "n_lot": "None", "created_at": "2026-03-26 11:29:21.705220+00:00", "created_by": "None", "updated_at": "2026-03-26 11:29:21.705220+00:00", "commande_id": "39c1dfe9-f87e-48b9-82f9-585965bef503", "designation": "APROVASC 300MG/10MG B/30 COMP. PELLI.SEC", "qte_demandee": "1", "medicament_id": "ec9ea5cf-4731-4d28-b580-f45b357b1aa2", "prix_unitaire": "1497.50"}
6794a5bf-18fd-44f4-92b3-4dec5f05aa75	commandes	39c1dfe9-f87e-48b9-82f9-585965bef503	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-26 11:30:31.006884+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-03-26 11:30:31.016091+00:00"}
224d91ec-3d84-4cd3-b08d-b6d003833bb5	factures	515ed173-8943-4982-9095-18dbb6ffdae4	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-26 11:30:31.006884+00	\N	{"id": "515ed173-8943-4982-9095-18dbb6ffdae4", "created_at": "2026-03-26 11:30:31.006884+00:00", "created_by": "None", "montant_ht": "6445.58", "updated_at": "2026-03-26 11:30:31.006884+00:00", "commande_id": "39c1dfe9-f87e-48b9-82f9-585965bef503", "montant_ttc": "6445.58", "reference_id": "F0000000002", "date_emission": "2026-03-26 11:30:31.026851+00:00"}
71ef8168-cd35-4803-bf67-6896e356c9bc	bons_livraison	b76ba340-dcf3-43f9-a035-f76ec5145d4f	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-26 11:30:31.006884+00	\N	{"id": "b76ba340-dcf3-43f9-a035-f76ec5145d4f", "code_barre": "BL00000002", "created_at": "2026-03-26 11:30:31.006884+00:00", "created_by": "None", "updated_at": "2026-03-26 11:30:31.006884+00:00", "commande_id": "39c1dfe9-f87e-48b9-82f9-585965bef503", "date_emission": "2026-03-26 11:30:31.026851+00:00"}
a5aec1a7-033f-46f8-99db-cd1308f63e32	commandes	6082713a-d865-4e27-8a42-5bfedaa5c38d	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-26 11:30:47.484064+00	{"statut": "creee"}	{"statut": "annulee"}
23da8c19-9408-48a1-8546-8cfd09fc27cc	commandes	39c1dfe9-f87e-48b9-82f9-585965bef503	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-03-26 12:01:54.223437+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
35042a3d-c100-4a75-a53d-9dbf373bdfda	commandes	0bff5c32-f6f8-4986-92ea-b6a8147cba6a	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-03-26 12:04:57.279917+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
3d54006c-6f98-48d2-855f-64e1310ba4d7	commandes	506905ec-c6d4-4c53-896e-3732e50f183b	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 12:22:32.284605+00	\N	{"id": "506905ec-c6d4-4c53-896e-3732e50f183b", "statut": "creee", "camion_id": "None", "commercial": "None", "created_at": "2026-03-26 12:22:32.284605+00:00", "created_by": "None", "updated_at": "2026-03-26 12:22:32.284605+00:00", "reference_id": "C00000008", "montant_total": "2151.58", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None"}
4a8e349e-2cf2-4a5a-b9db-e20947459ef2	lignes_commande	40eecbb5-12eb-4c3c-a11f-b229ac64f6c2	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 12:22:32.284605+00	\N	{"id": "40eecbb5-12eb-4c3c-a11f-b229ac64f6c2", "n_lot": "None", "created_at": "2026-03-26 12:22:32.284605+00:00", "created_by": "None", "updated_at": "2026-03-26 12:22:32.284605+00:00", "commande_id": "506905ec-c6d4-4c53-896e-3732e50f183b", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
d471cb6c-6792-443f-8379-4fbb44076b22	lignes_commande	925c988b-d4ea-4fee-a629-4c4c807a5b70	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 12:22:32.284605+00	\N	{"id": "925c988b-d4ea-4fee-a629-4c4c807a5b70", "n_lot": "None", "created_at": "2026-03-26 12:22:32.284605+00:00", "created_by": "None", "updated_at": "2026-03-26 12:22:32.284605+00:00", "commande_id": "506905ec-c6d4-4c53-896e-3732e50f183b", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
f7171883-d829-4d9e-8c6e-a8dedcacf4bb	lignes_commande	5011d0c0-95e6-4d53-ac14-061e87b65dfe	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 12:22:32.284605+00	\N	{"id": "5011d0c0-95e6-4d53-ac14-061e87b65dfe", "n_lot": "None", "created_at": "2026-03-26 12:22:32.284605+00:00", "created_by": "None", "updated_at": "2026-03-26 12:22:32.284605+00:00", "commande_id": "506905ec-c6d4-4c53-896e-3732e50f183b", "designation": "APROVASC 150MG/5MG  B/30 COMP. PELLI", "qte_demandee": "1", "medicament_id": "72dcd068-d94c-4c76-9dca-3ddace1e5962", "prix_unitaire": "1497.50"}
d65211cd-df06-4cd1-8d47-76ec956f3584	commandes	8749fa09-b997-45a6-b5be-e9b1f49c23d2	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-26 12:23:05.207857+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-03-26 12:23:05.238560+00:00"}
fd38813c-6b44-405e-8733-76946983ba4d	factures	c0939582-1194-4bd3-82c0-198162364b7e	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-26 12:23:05.207857+00	\N	{"id": "c0939582-1194-4bd3-82c0-198162364b7e", "created_at": "2026-03-26 12:23:05.207857+00:00", "created_by": "None", "montant_ht": "198.50", "updated_at": "2026-03-26 12:23:05.207857+00:00", "commande_id": "8749fa09-b997-45a6-b5be-e9b1f49c23d2", "montant_ttc": "198.50", "reference_id": "F0000000003", "date_emission": "2026-03-26 12:23:05.243816+00:00"}
4dd717bc-3979-4607-8a7d-9bd8ceb9b902	bons_livraison	e2d8f61c-1a0b-41e0-8f0a-7ef6a698ff52	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-26 12:23:05.207857+00	\N	{"id": "e2d8f61c-1a0b-41e0-8f0a-7ef6a698ff52", "code_barre": "BL00000003", "created_at": "2026-03-26 12:23:05.207857+00:00", "created_by": "None", "updated_at": "2026-03-26 12:23:05.207857+00:00", "commande_id": "8749fa09-b997-45a6-b5be-e9b1f49c23d2", "date_emission": "2026-03-26 12:23:05.243816+00:00"}
2d4a7a64-5ef1-4852-923c-5b5b4102ebe8	commandes	506905ec-c6d4-4c53-896e-3732e50f183b	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-26 12:23:12.881797+00	{"statut": "creee"}	{"statut": "annulee"}
5533e771-eb54-4edb-a911-2834936a9a33	commandes	dbbca1b4-1782-4fd5-9255-9e458cdbd550	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 13:41:23.351868+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-01 13:41:23.355428+00:00"}
83bffbcd-ff17-4104-9fe2-55183253d9a2	commandes	02d29f6f-7320-46de-9910-18a4a137f9fc	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 12:27:45.079296+00	\N	{"id": "02d29f6f-7320-46de-9910-18a4a137f9fc", "statut": "creee", "camion_id": "None", "commercial": "None", "created_at": "2026-03-26 12:27:45.079296+00:00", "created_by": "None", "updated_at": "2026-03-26 12:27:45.079296+00:00", "reference_id": "C00000009", "montant_total": "1448.08", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None"}
17b26c0f-48a9-4a14-975e-64f918e13b96	lignes_commande	d3c49026-4013-489f-a38a-4449cbee15cd	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 12:27:45.079296+00	\N	{"id": "d3c49026-4013-489f-a38a-4449cbee15cd", "n_lot": "None", "created_at": "2026-03-26 12:27:45.079296+00:00", "created_by": "None", "updated_at": "2026-03-26 12:27:45.079296+00:00", "commande_id": "02d29f6f-7320-46de-9910-18a4a137f9fc", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "5", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
621a21aa-5b8a-4a27-b79d-a7e6031128d6	lignes_commande	32227cd1-4816-4294-b5a3-1b87db43927e	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-26 12:27:45.079296+00	\N	{"id": "32227cd1-4816-4294-b5a3-1b87db43927e", "n_lot": "None", "created_at": "2026-03-26 12:27:45.079296+00:00", "created_by": "None", "updated_at": "2026-03-26 12:27:45.079296+00:00", "commande_id": "02d29f6f-7320-46de-9910-18a4a137f9fc", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
5d97a2a4-8bb1-425f-8914-119f9b03aa41	commandes	02d29f6f-7320-46de-9910-18a4a137f9fc	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-30 10:36:45.117185+00	{"statut": "creee"}	{"statut": "annulee"}
45a3b772-1176-4781-a92d-a416c8705410	commandes	39c1dfe9-f87e-48b9-82f9-585965bef503	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-03-30 11:31:15.049448+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
811be3a4-9ef1-46e0-83ec-4b0f498203b3	commandes	0bff5c32-f6f8-4986-92ea-b6a8147cba6a	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-03-30 11:31:15.925571+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
bb8b3a0d-f6fe-4bfd-b2ba-fa18db34a795	commandes	8749fa09-b997-45a6-b5be-e9b1f49c23d2	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-03-30 11:31:17.270401+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
517e9a69-5080-42ee-8c9c-feb8c070c08d	commandes	8749fa09-b997-45a6-b5be-e9b1f49c23d2	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-03-30 11:31:25.491792+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
660963d0-fc26-4114-8916-a22fb36a1258	commandes	f61d715f-0444-45bc-b848-927210e1a0b9	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-30 17:58:54.571366+00	\N	{"id": "f61d715f-0444-45bc-b848-927210e1a0b9", "statut": "creee", "camion_id": "None", "commercial": "None", "created_at": "2026-03-30 17:58:54.571366+00:00", "created_by": "None", "updated_at": "2026-03-30 17:58:54.571366+00:00", "reference_id": "C00000010", "montant_total": "200.15", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None"}
1fa24d4e-00b2-49b1-b3c2-68c6428f86ff	lignes_commande	7de8a0c4-4300-4c44-ab5b-1af712b686f6	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-30 17:58:54.571366+00	\N	{"id": "7de8a0c4-4300-4c44-ab5b-1af712b686f6", "n_lot": "None", "created_at": "2026-03-30 17:58:54.571366+00:00", "created_by": "None", "updated_at": "2026-03-30 17:58:54.571366+00:00", "commande_id": "f61d715f-0444-45bc-b848-927210e1a0b9", "designation": "DOLIPRANE. 1000MG B/8 COMP", "qte_demandee": "1", "medicament_id": "2022fa77-0632-475d-8ff3-40ebb1869f4a", "prix_unitaire": "100.11"}
73a2ed2d-b8bb-4e63-b34e-376ca1fbd027	lignes_commande	d64022fc-da5e-4cb7-9039-f87aedc26fc4	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-03-30 17:58:54.571366+00	\N	{"id": "d64022fc-da5e-4cb7-9039-f87aedc26fc4", "n_lot": "None", "created_at": "2026-03-30 17:58:54.571366+00:00", "created_by": "None", "updated_at": "2026-03-30 17:58:54.571366+00:00", "commande_id": "f61d715f-0444-45bc-b848-927210e1a0b9", "designation": "DOLIPRANE. 500MG B/16 COMP", "qte_demandee": "1", "medicament_id": "7ef1546e-cce2-4f28-a931-bf8d45a40cf6", "prix_unitaire": "100.04"}
768e5383-364f-40fd-94c4-f65a2614a94e	commandes	f61d715f-0444-45bc-b848-927210e1a0b9	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-30 17:59:59.728342+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-03-30 17:59:59.730903+00:00"}
dc2884c7-6659-46a9-8623-f63f66018de9	factures	310fd98f-4df3-44dc-aba8-e5b245ab9ad4	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-30 17:59:59.728342+00	\N	{"id": "310fd98f-4df3-44dc-aba8-e5b245ab9ad4", "created_at": "2026-03-30 17:59:59.728342+00:00", "created_by": "None", "montant_ht": "200.15", "updated_at": "2026-03-30 17:59:59.728342+00:00", "commande_id": "f61d715f-0444-45bc-b848-927210e1a0b9", "montant_ttc": "200.15", "reference_id": "F0000000004", "date_emission": "2026-03-30 17:59:59.739572+00:00"}
fa584456-0595-445e-a9e0-4e907f2cea1b	bons_livraison	7ea1b8ad-86b0-4950-802e-574557efb8a7	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-03-30 17:59:59.728342+00	\N	{"id": "7ea1b8ad-86b0-4950-802e-574557efb8a7", "code_barre": "BL00000004", "created_at": "2026-03-30 17:59:59.728342+00:00", "created_by": "None", "updated_at": "2026-03-30 17:59:59.728342+00:00", "commande_id": "f61d715f-0444-45bc-b848-927210e1a0b9", "date_emission": "2026-03-30 17:59:59.739572+00:00"}
a862b230-66b4-4ca0-9129-ee3c4d02cec6	commandes	f61d715f-0444-45bc-b848-927210e1a0b9	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-03-30 18:01:39.017366+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
3ea99894-0ffb-4786-b83b-95cc497b3b63	users	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-03-30 18:02:43.167792+00	{"nom": "Karim Preparateur", "adresse": "None", "secteur": "None"}	{"nom": "Preparateur", "adresse": "", "secteur": ""}
16a53ad8-1e4a-469e-99d6-4d6982e21ff3	users	80b3ae99-edfc-4220-a471-03c5366fb10d	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-01 12:55:59.354216+00	{"nom": "Pharmacie Centrale", "adresse": "None", "secteur": "None"}	{"nom": "Pharmacie 1", "adresse": "", "secteur": ""}
cbaa07cf-f37c-4326-8a18-d4c9e796efd5	lignes_commande	7de8a0c4-4300-4c44-ab5b-1af712b686f6	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-01 13:31:17.247379+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
f99ebc5b-25d8-494f-bf5a-a96fb6d91f8e	lignes_commande	d64022fc-da5e-4cb7-9039-f87aedc26fc4	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-01 13:31:18.521771+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
50645c84-26a9-4142-9029-857bfd10a64f	commandes	dbbca1b4-1782-4fd5-9255-9e458cdbd550	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-01 13:40:17.726588+00	\N	{"id": "dbbca1b4-1782-4fd5-9255-9e458cdbd550", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-01 13:40:17.726588+00:00", "created_by": "None", "updated_at": "2026-04-01 13:40:17.726588+00:00", "motif_echec": "None", "reference_id": "C00000013", "montant_total": "1600.11", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "None"}
e13df791-eb5f-4ea8-861f-5df29c4745b6	lignes_commande	c3c874a3-436e-493a-8c80-ce1c3405939b	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-01 13:40:17.726588+00	\N	{"id": "c3c874a3-436e-493a-8c80-ce1c3405939b", "n_lot": "None", "verifie": "False", "created_at": "2026-04-01 13:40:17.726588+00:00", "created_by": "None", "updated_at": "2026-04-01 13:40:17.726588+00:00", "commande_id": "dbbca1b4-1782-4fd5-9255-9e458cdbd550", "designation": "BANDELETTES ON CALL  EXTRA -1 TEST B/50", "qte_demandee": "1", "qte_prelevee": "None", "medicament_id": "ebaf3ac2-f1e4-4790-a80e-2f4a23f49a69", "prix_unitaire": "1500.00"}
fa6f7189-1eb9-4d32-9947-e567f82f1994	lignes_commande	4449c85f-cabb-4600-9670-79338b497c55	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-01 13:40:17.726588+00	\N	{"id": "4449c85f-cabb-4600-9670-79338b497c55", "n_lot": "None", "verifie": "False", "created_at": "2026-04-01 13:40:17.726588+00:00", "created_by": "None", "updated_at": "2026-04-01 13:40:17.726588+00:00", "commande_id": "dbbca1b4-1782-4fd5-9255-9e458cdbd550", "designation": "DOLIPRANE. 1000MG B/8 COMP", "qte_demandee": "1", "qte_prelevee": "None", "medicament_id": "2022fa77-0632-475d-8ff3-40ebb1869f4a", "prix_unitaire": "100.11"}
7e629806-ecab-4dd0-8e35-51e4532f7769	factures	8f2a34eb-6468-49ab-a65d-2a5d5505fac6	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 13:41:23.351868+00	\N	{"id": "8f2a34eb-6468-49ab-a65d-2a5d5505fac6", "created_at": "2026-04-01 13:41:23.351868+00:00", "created_by": "None", "montant_ht": "1600.11", "updated_at": "2026-04-01 13:41:23.351868+00:00", "commande_id": "dbbca1b4-1782-4fd5-9255-9e458cdbd550", "montant_ttc": "1600.11", "reference_id": "F0000000005", "date_emission": "2026-04-01 13:41:23.362026+00:00"}
e078648c-77e7-438e-a2c8-587b096bddd9	bons_livraison	7a4aad92-2261-4b6c-8851-da453567547f	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 13:41:23.351868+00	\N	{"id": "7a4aad92-2261-4b6c-8851-da453567547f", "code_barre": "BL00000005", "created_at": "2026-04-01 13:41:23.351868+00:00", "created_by": "None", "updated_at": "2026-04-01 13:41:23.351868+00:00", "commande_id": "dbbca1b4-1782-4fd5-9255-9e458cdbd550", "date_emission": "2026-04-01 13:41:23.362026+00:00"}
21a5a55c-030f-4c39-bef5-0dcaf2a5449a	medicaments	2022fa77-0632-475d-8ff3-40ebb1869f4a	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 13:41:23.351868+00	{"stock_quantity": "127"}	{"stock_quantity": "126"}
494b3d6e-9c75-4ad1-a014-711163b16efb	medicaments	ebaf3ac2-f1e4-4790-a80e-2f4a23f49a69	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 13:41:23.351868+00	{"stock_quantity": "77"}	{"stock_quantity": "76"}
c5264c2f-b418-42b5-9d01-bd1f57e21996	commandes	dbbca1b4-1782-4fd5-9255-9e458cdbd550	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-01 13:51:50.548693+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
4b49a2fb-6991-4d00-a508-06e2625f387e	lignes_commande	4449c85f-cabb-4600-9670-79338b497c55	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-01 13:51:55.338346+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
22ebc7c2-e0be-4da6-ac32-7ce8c79dd582	commandes	dbbca1b4-1782-4fd5-9255-9e458cdbd550	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-01 13:52:07.375652+00	{"nb_colis": "None", "visa_preparateur": "None"}	{"nb_colis": "1", "visa_preparateur": "Preparateur"}
57fe03c7-8422-4d30-9366-b15ada76a37f	commandes	dbbca1b4-1782-4fd5-9255-9e458cdbd550	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-01 13:52:07.375652+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
4173d241-1138-40a3-ade3-365daa51e9fc	users	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-01 13:53:16.766284+00	{"nom": "Yacine Controleur", "adresse": "None", "secteur": "None"}	{"nom": "Controleur", "adresse": "", "secteur": ""}
b945f373-009a-448e-a883-3196feb84a06	users	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-01 13:59:36.291782+00	{"nom": "Ahmed Livreur", "adresse": "None", "secteur": "None"}	{"nom": "Livreur", "adresse": "", "secteur": ""}
8b3c82f5-d0df-4534-8da3-a780ecaea9ab	commandes	f61d715f-0444-45bc-b848-927210e1a0b9	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-01 14:15:30.158331+00	{"nb_colis": "None", "visa_preparateur": "None"}	{"nb_colis": "1", "visa_preparateur": "Preparateur"}
60684d62-1de7-40fe-b47d-1af1b2db61d8	commandes	f61d715f-0444-45bc-b848-927210e1a0b9	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-01 14:15:30.158331+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
9aa3b03b-f575-4270-8c11-68124a29711c	commandes	106039b7-a430-4ce3-ae3a-e85ecdc1efa5	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-01 15:52:14.19294+00	\N	{"id": "106039b7-a430-4ce3-ae3a-e85ecdc1efa5", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-01 15:52:14.192940+00:00", "created_by": "None", "updated_at": "2026-04-01 15:52:14.192940+00:00", "motif_echec": "None", "reference_id": "C00000014", "montant_total": "1700.22", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
fe8339af-7185-4558-a6a7-2538d5535217	lignes_commande	ba742d17-fc37-4dcf-bc42-c7b66eefc92c	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-01 15:52:14.19294+00	\N	{"id": "ba742d17-fc37-4dcf-bc42-c7b66eefc92c", "n_lot": "None", "verifie": "False", "created_at": "2026-04-01 15:52:14.192940+00:00", "created_by": "None", "updated_at": "2026-04-01 15:52:14.192940+00:00", "commande_id": "106039b7-a430-4ce3-ae3a-e85ecdc1efa5", "designation": "DOLIPRANE. 1000MG B/8 COMP", "qte_demandee": "2", "qte_prelevee": "None", "medicament_id": "2022fa77-0632-475d-8ff3-40ebb1869f4a", "prix_unitaire": "100.11"}
84924c2d-3fa0-4b86-9030-6187b5992357	lignes_commande	a051e1ec-b013-4f00-998d-2916462efcbd	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-01 15:52:14.19294+00	\N	{"id": "a051e1ec-b013-4f00-998d-2916462efcbd", "n_lot": "None", "verifie": "False", "created_at": "2026-04-01 15:52:14.192940+00:00", "created_by": "None", "updated_at": "2026-04-01 15:52:14.192940+00:00", "commande_id": "106039b7-a430-4ce3-ae3a-e85ecdc1efa5", "designation": "BANDELETTES ON CALL  EXTRA -1 TEST B/50", "qte_demandee": "1", "qte_prelevee": "None", "medicament_id": "ebaf3ac2-f1e4-4790-a80e-2f4a23f49a69", "prix_unitaire": "1500.00"}
2b0d51cb-90a9-4745-828c-69f417b182cf	commandes	106039b7-a430-4ce3-ae3a-e85ecdc1efa5	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 15:54:31.561759+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-01 15:54:31.566159+00:00"}
89a9c0f3-cde2-406c-8741-aafdcaaa72b2	factures	9ab4d7db-3372-431a-9d16-62bf5560b1f0	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 15:54:31.561759+00	\N	{"id": "9ab4d7db-3372-431a-9d16-62bf5560b1f0", "created_at": "2026-04-01 15:54:31.561759+00:00", "created_by": "None", "montant_ht": "1700.22", "updated_at": "2026-04-01 15:54:31.561759+00:00", "commande_id": "106039b7-a430-4ce3-ae3a-e85ecdc1efa5", "montant_ttc": "1700.22", "reference_id": "F0000000006", "date_emission": "2026-04-01 15:54:31.572340+00:00"}
2aa76ec8-c1e6-4408-bc6f-461009d9eade	bons_livraison	71f71c05-3c15-4dc8-aac4-c0a1fcd4df2e	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 15:54:31.561759+00	\N	{"id": "71f71c05-3c15-4dc8-aac4-c0a1fcd4df2e", "code_barre": "BL00000006", "created_at": "2026-04-01 15:54:31.561759+00:00", "created_by": "None", "updated_at": "2026-04-01 15:54:31.561759+00:00", "commande_id": "106039b7-a430-4ce3-ae3a-e85ecdc1efa5", "date_emission": "2026-04-01 15:54:31.572340+00:00"}
375370da-c427-4095-95fa-bd80b2c39353	medicaments	ebaf3ac2-f1e4-4790-a80e-2f4a23f49a69	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 15:54:31.561759+00	{"stock_quantity": "76"}	{"stock_quantity": "75"}
2f9396c6-7a53-4ba2-ac7d-e1f512ae0eb0	medicaments	2022fa77-0632-475d-8ff3-40ebb1869f4a	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 15:54:31.561759+00	{"stock_quantity": "126"}	{"stock_quantity": "124"}
e6cf5807-0026-445b-a0d4-ac6d1bcfdaf3	commandes	9bf827a6-b240-4200-a206-40f132b84460	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-01 15:58:51.958055+00	\N	{"id": "9bf827a6-b240-4200-a206-40f132b84460", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-01 15:58:51.958055+00:00", "created_by": "None", "updated_at": "2026-04-01 15:58:51.958055+00:00", "motif_echec": "None", "reference_id": "C00000015", "montant_total": "397.00", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
0db1e99e-0c8b-4a86-a32a-a3b534ac502a	lignes_commande	42774df1-877b-468e-a7a7-18a226d71e63	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-01 15:58:51.958055+00	\N	{"id": "42774df1-877b-468e-a7a7-18a226d71e63", "n_lot": "None", "verifie": "False", "created_at": "2026-04-01 15:58:51.958055+00:00", "created_by": "None", "updated_at": "2026-04-01 15:58:51.958055+00:00", "commande_id": "9bf827a6-b240-4200-a206-40f132b84460", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "qte_prelevee": "None", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
ac22f86e-5565-4a11-bdc4-06bb843cea57	commandes	3f80e2e0-8be4-44f0-981e-95810dc3d429	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-01 15:59:03.371038+00	\N	{"id": "3f80e2e0-8be4-44f0-981e-95810dc3d429", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-01 15:59:03.371038+00:00", "created_by": "None", "updated_at": "2026-04-01 15:59:03.371038+00:00", "motif_echec": "None", "reference_id": "C00000016", "montant_total": "1366.74", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
5d3229d9-9b66-4c5a-93c7-e598a986cb5e	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:29:26.819267+00	{"stock_quantity": "25"}	{"stock_quantity": "21"}
1bc15cfa-d095-47e7-b21f-9b5f04c68d55	lignes_commande	9d62371b-49bb-482c-afc5-9d307d5c0eb9	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-01 15:59:03.371038+00	\N	{"id": "9d62371b-49bb-482c-afc5-9d307d5c0eb9", "n_lot": "None", "verifie": "False", "created_at": "2026-04-01 15:59:03.371038+00:00", "created_by": "None", "updated_at": "2026-04-01 15:59:03.371038+00:00", "commande_id": "3f80e2e0-8be4-44f0-981e-95810dc3d429", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "3", "qte_prelevee": "None", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
cfc56f6c-90b9-4a07-800a-9b33e285f3f4	commandes	3f80e2e0-8be4-44f0-981e-95810dc3d429	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 15:59:21.568905+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-01 15:59:21.572491+00:00"}
d32eedcf-0efc-448f-8591-fc37c7598896	factures	907d247c-c0be-4b56-b8df-db9c8f8cca2b	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 15:59:21.568905+00	\N	{"id": "907d247c-c0be-4b56-b8df-db9c8f8cca2b", "created_at": "2026-04-01 15:59:21.568905+00:00", "created_by": "None", "montant_ht": "1366.74", "updated_at": "2026-04-01 15:59:21.568905+00:00", "commande_id": "3f80e2e0-8be4-44f0-981e-95810dc3d429", "montant_ttc": "1366.74", "reference_id": "F0000000007", "date_emission": "2026-04-01 15:59:21.577759+00:00"}
f197705a-4d4e-442f-87b1-ee24b0c91707	bons_livraison	6439bc85-0c90-4afd-be79-3cf1ebf01783	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 15:59:21.568905+00	\N	{"id": "6439bc85-0c90-4afd-be79-3cf1ebf01783", "code_barre": "BL00000007", "created_at": "2026-04-01 15:59:21.568905+00:00", "created_by": "None", "updated_at": "2026-04-01 15:59:21.568905+00:00", "commande_id": "3f80e2e0-8be4-44f0-981e-95810dc3d429", "date_emission": "2026-04-01 15:59:21.577759+00:00"}
55856eb1-8966-4667-bfa3-3b531a5012a0	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-01 15:59:21.568905+00	{"stock_quantity": "28"}	{"stock_quantity": "25"}
45ce8cc0-3c86-4f6f-8dc1-ef1f0ba76966	commandes	3f80e2e0-8be4-44f0-981e-95810dc3d429	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:07:53.149407+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
ea230e65-a1b4-48f4-8897-5fa202577f29	lignes_commande	9d62371b-49bb-482c-afc5-9d307d5c0eb9	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:07:58.233106+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "3"}
2d7a479a-61eb-4b35-88d6-3e6d0c032306	commandes	3f80e2e0-8be4-44f0-981e-95810dc3d429	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:06.521923+00	{"nb_colis": "None", "visa_preparateur": "None"}	{"nb_colis": "1", "visa_preparateur": "Administrator"}
150b5eeb-f649-451e-8c15-5fe7142a3b14	commandes	3f80e2e0-8be4-44f0-981e-95810dc3d429	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:06.521923+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
2e75eeed-1710-4ccf-b1e7-44859951baf8	commandes	106039b7-a430-4ce3-ae3a-e85ecdc1efa5	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:10.556861+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
7201e2cb-1cc4-4557-abd5-426007f98f2b	lignes_commande	ba742d17-fc37-4dcf-bc42-c7b66eefc92c	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:14.01032+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "2"}
0d76ecec-fc47-4d16-a096-185533031faa	lignes_commande	a051e1ec-b013-4f00-998d-2916462efcbd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:23.390887+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
8479cb92-8a2a-4822-92eb-4090487f1eb5	lignes_commande	ba742d17-fc37-4dcf-bc42-c7b66eefc92c	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:24.514074+00	{"verifie": "True"}	{"verifie": "False"}
b4c1f4eb-612b-4a5d-9da2-3d7effb0b4f8	lignes_commande	a051e1ec-b013-4f00-998d-2916462efcbd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:26.341963+00	{"verifie": "True"}	{"verifie": "False"}
0ac3b4b4-aacf-4568-b2ac-fc9cfe9b3181	lignes_commande	a051e1ec-b013-4f00-998d-2916462efcbd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:26.499437+00	{"verifie": "False"}	{"verifie": "True"}
088bda1b-68f4-4ab9-8892-93ea63351160	lignes_commande	a051e1ec-b013-4f00-998d-2916462efcbd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:26.651554+00	{"verifie": "True"}	{"verifie": "False"}
a2b34030-0cdf-474e-8578-c618c0efecb8	lignes_commande	a051e1ec-b013-4f00-998d-2916462efcbd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:26.799903+00	{"verifie": "False"}	{"verifie": "True"}
953b9565-d46d-44f7-9048-1686952cd324	lignes_commande	a051e1ec-b013-4f00-998d-2916462efcbd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:26.953759+00	{"verifie": "True"}	{"verifie": "False"}
d2f8e82e-98c2-4b3e-92b7-600bfc0b4467	lignes_commande	a051e1ec-b013-4f00-998d-2916462efcbd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:27.101488+00	{"verifie": "False"}	{"verifie": "True"}
9ab68890-2cf1-44b5-8773-13d4a7be1405	lignes_commande	a051e1ec-b013-4f00-998d-2916462efcbd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:27.281972+00	{"verifie": "True"}	{"verifie": "False"}
24de24e2-a01f-4510-9144-9485eb3f530e	lignes_commande	a051e1ec-b013-4f00-998d-2916462efcbd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:27.947427+00	{"verifie": "False"}	{"verifie": "True"}
ee5e26c1-0ab6-4651-9d71-b8b92bfaa60e	lignes_commande	ba742d17-fc37-4dcf-bc42-c7b66eefc92c	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-01 16:08:29.240516+00	{"verifie": "False"}	{"verifie": "True"}
af8284d1-250a-4c1f-b900-bde48312b683	commandes	fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-07 11:48:01.080345+00	\N	{"id": "fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-07 11:48:01.080345+00:00", "created_by": "None", "updated_at": "2026-04-07 11:48:01.080345+00:00", "motif_echec": "None", "reference_id": "C00000017", "montant_total": "397.00", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
1188464b-1e77-48d2-afd3-1232d9b94622	lignes_commande	3c301701-ce0c-4dde-b616-1bcf9476ca17	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-07 11:48:01.080345+00	\N	{"id": "3c301701-ce0c-4dde-b616-1bcf9476ca17", "n_lot": "None", "verifie": "False", "created_at": "2026-04-07 11:48:01.080345+00:00", "created_by": "None", "updated_at": "2026-04-07 11:48:01.080345+00:00", "commande_id": "fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "qte_prelevee": "None", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
7888d68c-6020-49cf-ab09-c07afaf0d767	commandes	fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-07 11:48:49.89656+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-07 11:48:49.901105+00:00"}
45e53845-7847-4998-8b61-a1ad63c00e50	factures	36435051-5689-46eb-a657-69d75d186aa8	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-07 11:48:49.89656+00	\N	{"id": "36435051-5689-46eb-a657-69d75d186aa8", "created_at": "2026-04-07 11:48:49.896560+00:00", "created_by": "None", "montant_ht": "397.00", "updated_at": "2026-04-07 11:48:49.896560+00:00", "commande_id": "fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07", "montant_ttc": "397.00", "reference_id": "F0000000008", "date_emission": "2026-04-07 11:48:49.918040+00:00"}
a86eb2cb-97ee-4fad-a967-28f2c4610c00	bons_livraison	0940927f-befd-4379-9a0f-5f9143bb60d7	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-07 11:48:49.89656+00	\N	{"id": "0940927f-befd-4379-9a0f-5f9143bb60d7", "code_barre": "BL00000008", "created_at": "2026-04-07 11:48:49.896560+00:00", "created_by": "None", "updated_at": "2026-04-07 11:48:49.896560+00:00", "commande_id": "fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07", "date_emission": "2026-04-07 11:48:49.918040+00:00"}
889133c3-722b-4215-b564-ad8589f5b19a	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-07 11:48:49.89656+00	{"stock_quantity": "100"}	{"stock_quantity": "98"}
6e691478-abb2-4469-a5ff-862278f9736d	bons_livraison	e9c2857c-d295-43aa-b05f-cd39a3d2a006	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:29:26.819267+00	\N	{"id": "e9c2857c-d295-43aa-b05f-cd39a3d2a006", "code_barre": "BL00000011", "created_at": "2026-04-13 12:29:26.819267+00:00", "created_by": "None", "updated_at": "2026-04-13 12:29:26.819267+00:00", "commande_id": "870c4e4e-0ac5-47e6-9ad5-ad018343b8cd", "date_emission": "2026-04-13 12:29:26.864601+00:00"}
3110f2f7-8158-42bb-ae9f-2024c8b9ac39	medicaments	7435046b-fc3b-4c8e-9041-9c1e886aa102	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:29:26.819267+00	{"stock_quantity": "37"}	{"stock_quantity": "35"}
3dc18543-37ed-4d81-96f4-dcb50b5c8f77	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 10:11:11.642963+00	\N	{"id": "96fdb118-00e1-4720-b8f9-2f3b30e58611", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 10:11:11.642963+00:00", "created_by": "None", "updated_at": "2026-04-13 10:11:11.642963+00:00", "motif_echec": "None", "reference_id": "C00000018", "montant_total": "794.00", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
2aaaf842-452d-4bf8-88c0-4ef2097c16a6	lignes_commande	24a9669a-4617-4ea8-aa40-093540123489	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 10:11:11.642963+00	\N	{"id": "24a9669a-4617-4ea8-aa40-093540123489", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 10:11:11.642963+00:00", "created_by": "None", "updated_at": "2026-04-13 10:11:11.642963+00:00", "commande_id": "96fdb118-00e1-4720-b8f9-2f3b30e58611", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "4", "qte_prelevee": "None", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
5f457abc-70e2-49e8-a744-767883f3ffbc	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 10:25:07.989227+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-13 10:25:07.994238+00:00"}
d62dfec3-a190-4c33-ab72-3b3f2fe8a965	factures	e78fb4f8-980a-42bd-8a0d-189b6621bd74	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 10:25:07.989227+00	\N	{"id": "e78fb4f8-980a-42bd-8a0d-189b6621bd74", "created_at": "2026-04-13 10:25:07.989227+00:00", "created_by": "None", "montant_ht": "794.00", "updated_at": "2026-04-13 10:25:07.989227+00:00", "commande_id": "96fdb118-00e1-4720-b8f9-2f3b30e58611", "montant_ttc": "794.00", "reference_id": "F0000000009", "date_emission": "2026-04-13 10:25:08.006986+00:00"}
5fc375e5-5f25-45b4-90c5-7c4e5b0c2b12	bons_livraison	3668ec4c-1a02-471d-8fb8-34d9dd49f836	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 10:25:07.989227+00	\N	{"id": "3668ec4c-1a02-471d-8fb8-34d9dd49f836", "code_barre": "BL00000009", "created_at": "2026-04-13 10:25:07.989227+00:00", "created_by": "None", "updated_at": "2026-04-13 10:25:07.989227+00:00", "commande_id": "96fdb118-00e1-4720-b8f9-2f3b30e58611", "date_emission": "2026-04-13 10:25:08.006986+00:00"}
f4d01084-4f7d-46c8-a275-547f8a484393	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 10:25:07.989227+00	{"stock_quantity": "98"}	{"stock_quantity": "94"}
617ad83e-98e7-40c3-866d-5ea65f791e0e	commandes	106039b7-a430-4ce3-ae3a-e85ecdc1efa5	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 10:25:53.595996+00	{"nb_colis": "None", "visa_preparateur": "None"}	{"nb_colis": "1", "visa_preparateur": "Preparateur"}
cd8c38ad-1308-46d3-9afe-828e99a8db4e	commandes	106039b7-a430-4ce3-ae3a-e85ecdc1efa5	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 10:25:53.595996+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
28ba9616-f0e8-46e9-aa38-da52c919debe	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 11:36:57.533086+00	\N	{"id": "19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 11:36:57.533086+00:00", "created_by": "None", "updated_at": "2026-04-13 11:36:57.533086+00:00", "motif_echec": "None", "reference_id": "C00000019", "montant_total": "198.50", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
126a6cbe-a732-4fb1-9d56-7b4042dca344	lignes_commande	b2ee230b-9def-49b7-a218-34e15dd7e7b4	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 11:36:57.533086+00	\N	{"id": "b2ee230b-9def-49b7-a218-34e15dd7e7b4", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 11:36:57.533086+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 11:36:57.533086+00:00", "commande_id": "19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "qte_prelevee": "None", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
fb397b11-de65-4f24-87f3-c6aeb7f8597b	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 11:37:17.560937+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-13 11:37:17.566052+00:00"}
da5dbcf8-6d8a-4dfe-89ec-a36920bcdf86	factures	5a948b84-b9c8-4226-bfc1-f78fd99c1752	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 11:37:17.560937+00	\N	{"id": "5a948b84-b9c8-4226-bfc1-f78fd99c1752", "created_at": "2026-04-13 11:37:17.560937+00:00", "created_by": "None", "montant_ht": "198.50", "updated_at": "2026-04-13 11:37:17.560937+00:00", "commande_id": "19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6", "montant_ttc": "198.50", "reference_id": "F0000000010", "date_emission": "2026-04-13 11:37:17.585242+00:00"}
f69d73e1-db59-4755-8a8b-1a3cbd88faa2	bons_livraison	4e03caca-cab0-4aae-833d-ec4a30121c37	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 11:37:17.560937+00	\N	{"id": "4e03caca-cab0-4aae-833d-ec4a30121c37", "code_barre": "BL00000010", "created_at": "2026-04-13 11:37:17.560937+00:00", "created_by": "None", "updated_at": "2026-04-13 11:37:17.560937+00:00", "commande_id": "19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6", "date_emission": "2026-04-13 11:37:17.585242+00:00"}
918cb0d5-934b-442e-9278-f86d3e96a338	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 11:37:17.560937+00	{"stock_quantity": "94"}	{"stock_quantity": "93"}
f8408afa-3d8a-4a02-a879-461b0447d046	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 11:57:33.531091+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
4715cef6-1be1-449d-99fb-b066c93827f6	lignes_commande	b2ee230b-9def-49b7-a218-34e15dd7e7b4	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 11:57:36.592188+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
ab0b0169-4fbb-4264-b2ce-b0d9637acd03	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 11:57:39.716783+00	{"nb_colis": "None", "visa_preparateur": "None"}	{"nb_colis": "1", "visa_preparateur": "Preparateur"}
300fbae0-b23b-4c0e-95df-4a582d6996bf	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 11:57:39.716783+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
f9a71a38-2900-4c95-a628-6a367880055e	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:03:09.043002+00	{"camion_id": "None"}	{"camion_id": "1c2411aa-1f09-4c5d-8360-96180f6b4c54"}
596869b0-2696-48f6-8ed0-78994628ca9e	feuilles_route	9e74bad5-c9e7-445b-ad23-9e38baa4cf04	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:03:09.043002+00	\N	{"id": "9e74bad5-c9e7-445b-ad23-9e38baa4cf04", "date": "2026-04-13", "ligne": "None", "camion_id": "1c2411aa-1f09-4c5d-8360-96180f6b4c54", "compteurs": "{'colis_std': 0, 'sachets_std': 0, 'colis_frg': 0, 'sachets_frg': 0}", "created_at": "2026-04-13 12:03:09.043002+00:00", "created_by": "None", "livreur_id": "None", "n_rotation": "None", "updated_at": "2026-04-13 12:03:09.043002+00:00", "chargement_valide": "False", "signature_chauffeur": "***", "signature_expedition": "***"}
bc2b9eb3-ada3-40bc-bcfd-7c9b17a0b89a	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:03:09.043002+00	{"feuille_route_id": "None"}	{"feuille_route_id": "9e74bad5-c9e7-445b-ad23-9e38baa4cf04"}
bb07a977-edb0-46d2-8350-40b122b9b462	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:03:09.106026+00	{"statut": "en_verification"}	{"statut": "prete"}
363925bd-b2e7-4e3d-a476-c501c008943f	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:03:09.106026+00	{"visa_controleur": "None"}	{"visa_controleur": "Controleur"}
0a0410e4-f55d-46bd-9245-bc0ce3e6d4d3	commandes	3f80e2e0-8be4-44f0-981e-95810dc3d429	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:15:51.671095+00	{"camion_id": "None"}	{"camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7"}
0ebb2e15-0b9a-4628-8d7c-639c4f9fefab	feuilles_route	f969c5ec-cc7e-4f7f-a504-a5a893c143f3	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:15:51.671095+00	\N	{"id": "f969c5ec-cc7e-4f7f-a504-a5a893c143f3", "date": "2026-04-13", "ligne": "None", "camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7", "compteurs": "{'colis_std': 0, 'sachets_std': 0, 'colis_frg': 0, 'sachets_frg': 0}", "created_at": "2026-04-13 12:15:51.671095+00:00", "created_by": "None", "livreur_id": "None", "n_rotation": "None", "updated_at": "2026-04-13 12:15:51.671095+00:00", "chargement_valide": "False", "signature_chauffeur": "***", "signature_expedition": "***"}
16fe2d96-9da8-4ddd-a2dc-e8a2b2a95176	commandes	3f80e2e0-8be4-44f0-981e-95810dc3d429	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:15:51.671095+00	{"feuille_route_id": "None"}	{"feuille_route_id": "f969c5ec-cc7e-4f7f-a504-a5a893c143f3"}
38e2e749-afbb-4008-859f-a8cb9f33dcac	commandes	3f80e2e0-8be4-44f0-981e-95810dc3d429	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:15:51.720845+00	{"statut": "en_verification"}	{"statut": "prete"}
2383858c-1509-49fc-a99c-970d18e28c9a	commandes	3f80e2e0-8be4-44f0-981e-95810dc3d429	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:15:51.720845+00	{"visa_controleur": "None"}	{"visa_controleur": "Controleur"}
b104561e-2906-4640-a53a-beb419353577	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 12:16:31.917065+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
ee9d6178-45be-4fc0-b741-c58ffa24a251	lignes_commande	24a9669a-4617-4ea8-aa40-093540123489	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 12:16:36.343232+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "4"}
1214b184-98af-4595-bf94-4ad915e91689	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 12:16:37.977504+00	{"nb_colis": "None", "visa_preparateur": "None"}	{"nb_colis": "1", "visa_preparateur": "Administrator"}
87ad96ea-ff29-4346-8119-6bb99af707c5	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 12:16:37.977504+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
345e27e8-070e-40ac-9554-728a9328d864	commandes	fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 12:16:42.036629+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
bf2a081c-c00f-4fdb-9650-f553c5d9862d	commandes	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 12:22:03.897684+00	\N	{"id": "17c3ce0d-4a8e-4b70-8872-30d5b906bfe7", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 12:22:03.897684+00:00", "created_by": "None", "updated_at": "2026-04-13 12:22:03.897684+00:00", "motif_echec": "None", "reference_id": "C00000022", "montant_total": "3604.50", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "preparateur_id": "None", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
57bbf259-4c83-4eb4-949f-cb69ec559691	lignes_commande	066d7516-e62f-45c8-ad25-6b4553492b7a	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 12:22:03.897684+00	\N	{"id": "066d7516-e62f-45c8-ad25-6b4553492b7a", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 12:22:03.897684+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 12:22:03.897684+00:00", "commande_id": "17c3ce0d-4a8e-4b70-8872-30d5b906bfe7", "designation": "APROVEL. 150MG B/28 COMP. PELLI", "ocr_verifie": "False", "qte_demandee": "3", "qte_prelevee": "None", "medicament_id": "7435046b-fc3b-4c8e-9041-9c1e886aa102", "prix_unitaire": "1201.50"}
ec9ac80d-d482-4858-99f8-bae5fadddfaa	commandes	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 12:26:13.735977+00	\N	{"id": "870c4e4e-0ac5-47e6-9ad5-ad018343b8cd", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 12:26:13.735977+00:00", "created_by": "None", "updated_at": "2026-04-13 12:26:13.735977+00:00", "motif_echec": "None", "reference_id": "C00000023", "montant_total": "5019.32", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "preparateur_id": "None", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
8e0757c8-1cab-4c23-ae13-372493d55bca	lignes_commande	928178ad-2374-419a-96de-0c2762b8b95d	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 12:26:13.735977+00	\N	{"id": "928178ad-2374-419a-96de-0c2762b8b95d", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 12:26:13.735977+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 12:26:13.735977+00:00", "commande_id": "870c4e4e-0ac5-47e6-9ad5-ad018343b8cd", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "ocr_verifie": "False", "qte_demandee": "4", "qte_prelevee": "None", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
c2559907-4926-4aa9-8948-f2c0219e0463	lignes_commande	766e821a-2c9d-4dcf-a06b-f24231001170	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 12:26:13.735977+00	\N	{"id": "766e821a-2c9d-4dcf-a06b-f24231001170", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 12:26:13.735977+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 12:26:13.735977+00:00", "commande_id": "870c4e4e-0ac5-47e6-9ad5-ad018343b8cd", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "ocr_verifie": "False", "qte_demandee": "4", "qte_prelevee": "None", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
7e187e90-ae01-42b2-814c-cea6edc26e07	lignes_commande	96085a31-fae0-433c-a940-f8b409db7675	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 12:26:13.735977+00	\N	{"id": "96085a31-fae0-433c-a940-f8b409db7675", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 12:26:13.735977+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 12:26:13.735977+00:00", "commande_id": "870c4e4e-0ac5-47e6-9ad5-ad018343b8cd", "designation": "APROVEL. 150MG B/28 COMP. PELLI", "ocr_verifie": "False", "qte_demandee": "2", "qte_prelevee": "None", "medicament_id": "7435046b-fc3b-4c8e-9041-9c1e886aa102", "prix_unitaire": "1201.50"}
3ecd4792-ac65-47e6-8e78-87d81d7cbe4d	commandes	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:29:26.819267+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-13 12:29:26.832473+00:00"}
0016d3d1-1989-4c9d-8533-792c80ec913d	factures	ab9f0288-c002-40d2-928e-8e79405e105c	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:29:26.819267+00	\N	{"id": "ab9f0288-c002-40d2-928e-8e79405e105c", "created_at": "2026-04-13 12:29:26.819267+00:00", "created_by": "None", "montant_ht": "5019.32", "updated_at": "2026-04-13 12:29:26.819267+00:00", "commande_id": "870c4e4e-0ac5-47e6-9ad5-ad018343b8cd", "montant_ttc": "5019.32", "reference_id": "F0000000011", "date_emission": "2026-04-13 12:29:26.864601+00:00"}
d9d014cf-b6b1-42f8-b261-bbaf59c32341	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:29:26.819267+00	{"stock_quantity": "93"}	{"stock_quantity": "89"}
a719837c-7edf-46f6-a917-880b75ff895d	commandes	9bf827a6-b240-4200-a206-40f132b84460	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:31:54.62788+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-13 12:31:54.636993+00:00"}
7eda1b16-7ee4-4fc3-8260-6d7f473b197b	factures	9563b234-afc2-406f-9e6d-1969ae1ff186	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:31:54.62788+00	\N	{"id": "9563b234-afc2-406f-9e6d-1969ae1ff186", "created_at": "2026-04-13 12:31:54.627880+00:00", "created_by": "None", "montant_ht": "397.00", "updated_at": "2026-04-13 12:31:54.627880+00:00", "commande_id": "9bf827a6-b240-4200-a206-40f132b84460", "montant_ttc": "397.00", "reference_id": "F0000000012", "date_emission": "2026-04-13 12:31:54.660401+00:00"}
ae5ba7e2-4e18-4ed3-81a3-985c8a973f17	bons_livraison	79ebb877-e3f2-4770-8a1a-7865805d6cb2	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:31:54.62788+00	\N	{"id": "79ebb877-e3f2-4770-8a1a-7865805d6cb2", "code_barre": "BL00000012", "created_at": "2026-04-13 12:31:54.627880+00:00", "created_by": "None", "updated_at": "2026-04-13 12:31:54.627880+00:00", "commande_id": "9bf827a6-b240-4200-a206-40f132b84460", "date_emission": "2026-04-13 12:31:54.660401+00:00"}
cf95f60c-e768-4972-9eaa-5d053d7de941	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:31:54.62788+00	{"stock_quantity": "89"}	{"stock_quantity": "87"}
e3881ece-f880-49f3-8d60-f430f5241d77	lignes_commande	928178ad-2374-419a-96de-0c2762b8b95d	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 12:32:20.886101+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "4"}
9b23012c-4b3d-4fb7-8a7f-fa6a43eeb944	lignes_commande	928178ad-2374-419a-96de-0c2762b8b95d	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 12:32:21.725392+00	{"ocr_verifie": "False"}	{"ocr_verifie": "True"}
7bdfaf42-ddd5-47ce-b10a-e48771d9804c	lignes_commande	066d7516-e62f-45c8-ad25-6b4553492b7a	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 12:33:02.433328+00	{"ocr_verifie": "False"}	{"ocr_verifie": "True"}
f7089cef-127b-429c-971d-c359c7bac2cc	commandes	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:31:59.749756+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-13 12:31:59.758077+00:00"}
464aa970-47fa-45b9-9183-0af370b84bf5	factures	05413a45-651f-4684-be6b-e1f4dcc8c0dd	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:31:59.749756+00	\N	{"id": "05413a45-651f-4684-be6b-e1f4dcc8c0dd", "created_at": "2026-04-13 12:31:59.749756+00:00", "created_by": "None", "montant_ht": "3604.50", "updated_at": "2026-04-13 12:31:59.749756+00:00", "commande_id": "17c3ce0d-4a8e-4b70-8872-30d5b906bfe7", "montant_ttc": "3604.50", "reference_id": "F0000000013", "date_emission": "2026-04-13 12:31:59.779069+00:00"}
a1b36186-3c61-4383-9ac1-db1452e89c68	bons_livraison	58e244ff-f20b-4c00-849a-858a87f286bc	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:31:59.749756+00	\N	{"id": "58e244ff-f20b-4c00-849a-858a87f286bc", "code_barre": "BL00000013", "created_at": "2026-04-13 12:31:59.749756+00:00", "created_by": "None", "updated_at": "2026-04-13 12:31:59.749756+00:00", "commande_id": "17c3ce0d-4a8e-4b70-8872-30d5b906bfe7", "date_emission": "2026-04-13 12:31:59.779069+00:00"}
2c27ceef-e9cb-42d0-bf0d-99da7ff1cf44	medicaments	7435046b-fc3b-4c8e-9041-9c1e886aa102	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 12:31:59.749756+00	{"stock_quantity": "35"}	{"stock_quantity": "32"}
22319d23-83c2-4f27-986f-93e244c57fee	lignes_commande	066d7516-e62f-45c8-ad25-6b4553492b7a	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 12:33:00.041685+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "3"}
d2de6e2c-9be5-460a-aba6-44824a4c668f	commandes	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 12:32:17.684155+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
cebea78b-ec9e-4d3b-a677-5b0b40a152b4	commandes	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 12:32:42.464094+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
fe526b2d-c618-4c16-b5ac-27f238981c7c	commandes	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 12:33:05.470246+00	{"nb_colis": "None", "visa_preparateur": "None"}	{"nb_colis": "1", "visa_preparateur": "Preparateur"}
9b009c42-66bf-4225-9b90-2f9dd90d4c8f	commandes	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 12:33:05.470246+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
15e70a3e-925c-4e97-a85d-9af2e5b6479c	commandes	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:42:15.386114+00	{"camion_id": "None"}	{"camion_id": "7785e358-83c4-41e6-9e6b-db5ded7b6e97"}
02144cb0-15cd-4fd1-b79e-408eba3aec5f	feuilles_route	7ea42bcb-2193-47f0-a179-57d7cded6983	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:42:15.386114+00	\N	{"id": "7ea42bcb-2193-47f0-a179-57d7cded6983", "date": "2026-04-13", "ligne": "None", "camion_id": "7785e358-83c4-41e6-9e6b-db5ded7b6e97", "compteurs": "{'colis_std': 0, 'sachets_std': 0, 'colis_frg': 0, 'sachets_frg': 0}", "created_at": "2026-04-13 12:42:15.386114+00:00", "created_by": "None", "livreur_id": "None", "n_rotation": "None", "updated_at": "2026-04-13 12:42:15.386114+00:00", "chargement_valide": "False", "signature_chauffeur": "***", "signature_expedition": "***"}
b0a0d3f6-178f-41df-a8e1-e70b2a051fca	commandes	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:42:15.386114+00	{"feuille_route_id": "None"}	{"feuille_route_id": "7ea42bcb-2193-47f0-a179-57d7cded6983"}
13c8de01-f81c-4f4f-b402-ed9f34d0df6d	commandes	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:42:15.448184+00	{"statut": "en_verification"}	{"statut": "prete"}
b2873bfd-b653-45eb-b221-b562828559a9	commandes	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 12:42:15.448184+00	{"visa_controleur": "None"}	{"visa_controleur": "Controleur"}
5cab5477-e42b-4b2c-b982-de9178d35b3d	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 12:47:12.705043+00	{"camion_id": "None"}	{"camion_id": "1c2411aa-1f09-4c5d-8360-96180f6b4c54"}
640556f9-318d-4435-8f00-1f39616b247e	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 12:47:12.705043+00	{"feuille_route_id": "None"}	{"feuille_route_id": "9e74bad5-c9e7-445b-ad23-9e38baa4cf04"}
aa00ccdb-3363-4636-930d-78bb778e1bf5	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 12:47:12.745475+00	{"statut": "en_verification"}	{"statut": "prete"}
bcb9cc71-179c-4401-9bda-2b08f4e64563	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 12:47:12.745475+00	{"visa_controleur": "None"}	{"visa_controleur": "Administrator"}
7d312344-d67b-446c-929c-47158f5f433f	camions	4baf379b-7b7c-45c0-bbeb-6ce33d00c040	insert	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 12:49:12.485533+00	\N	{"id": "4baf379b-7b7c-45c0-bbeb-6ce33d00c040", "nom": "a", "plaque": "aaa", "created_at": "2026-04-13 12:49:12.485533+00:00", "created_by": "None", "updated_at": "2026-04-13 12:49:12.485533+00:00"}
7cd2bcaa-3008-4eb5-ad18-490398318fa4	feuilles_route	9e74bad5-c9e7-445b-ad23-9e38baa4cf04	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 12:56:59.347227+00	{"livreur_id": "None"}	{"livreur_id": "ef6fb6ab-1b1a-41ea-bf5a-658502d156f7"}
21310052-57c8-40aa-8445-8f5f67e92f63	commandes	9bf827a6-b240-4200-a206-40f132b84460	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:06:05.124521+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
a340b0e0-ab4f-4bf9-a0fc-72bbe26a1f92	lignes_commande	766e821a-2c9d-4dcf-a06b-f24231001170	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:06:20.734175+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "4"}
41f57099-dad0-41a3-bd0e-33fe9a8182f2	lignes_commande	766e821a-2c9d-4dcf-a06b-f24231001170	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:06:22.049945+00	{"ocr_verifie": "False"}	{"ocr_verifie": "True"}
b6a79c13-2585-4eea-bcad-e99b7fb237a7	lignes_commande	96085a31-fae0-433c-a940-f8b409db7675	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:06:22.971902+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "2"}
dfbe5047-43e8-4a92-8dbb-53eb7df972bd	lignes_commande	96085a31-fae0-433c-a940-f8b409db7675	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:06:23.691267+00	{"ocr_verifie": "False"}	{"ocr_verifie": "True"}
0d2e50f5-f628-446c-8927-62a6e1481635	commandes	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:06:41.02197+00	{"nb_colis": "None", "visa_preparateur": "None"}	{"nb_colis": "1", "visa_preparateur": "Administrator"}
bfdcee5b-5b1a-41b8-8721-5a7e14d8cf23	commandes	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:06:41.02197+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
8f0ac27d-637a-49e5-bf89-e2fe3519f87f	commandes	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:07:41.996044+00	{"camion_id": "None"}	{"camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7"}
eaad7840-6fad-4e97-ba99-e007a682897d	commandes	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:07:41.996044+00	{"feuille_route_id": "None"}	{"feuille_route_id": "f969c5ec-cc7e-4f7f-a504-a5a893c143f3"}
f7946ae3-c7fa-4c65-adc8-c170d92441bf	commandes	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:07:42.020693+00	{"statut": "en_verification"}	{"statut": "prete"}
f5b3de48-9d6c-469d-88d1-333cdb19f35c	commandes	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	update	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:07:42.020693+00	{"visa_controleur": "None"}	{"visa_controleur": "Administrator"}
ece64790-ae15-48e8-a166-8a2803e19d50	camions	4baf379b-7b7c-45c0-bbeb-6ce33d00c040	delete	9f334b50-59fc-4c16-8635-e9f29c46cdf7	2026-04-13 13:08:23.613308+00	{"id": "4baf379b-7b7c-45c0-bbeb-6ce33d00c040", "nom": "a", "plaque": "aaa", "created_at": "2026-04-13 12:49:12.485533+00:00", "created_by": "None", "updated_at": "2026-04-13 12:49:12.485533+00:00"}	\N
b14b7670-1169-4304-bcc1-98a098c67189	feuilles_route	9e74bad5-c9e7-445b-ad23-9e38baa4cf04	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 13:10:12.118076+00	{"chargement_valide": "False"}	{"chargement_valide": "True"}
2b75d6ff-3a72-4a7e-ba1e-3efc2554a74f	feuilles_route	9e74bad5-c9e7-445b-ad23-9e38baa4cf04	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 13:10:24.446149+00	{"signature_expedition": "***"}	{"signature_expedition": "***"}
c80b481f-edb8-438f-bfee-63df81976441	feuilles_route	9e74bad5-c9e7-445b-ad23-9e38baa4cf04	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 13:10:27.975336+00	{"signature_chauffeur": "***"}	{"signature_chauffeur": "***"}
22935198-1aab-4eae-a5a2-e282e7140b48	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 13:10:38.032072+00	{"statut": "prete"}	{"statut": "en_route"}
666cafbe-a289-470e-84e7-a2198cce0b3e	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 13:10:38.076373+00	{"statut": "prete"}	{"statut": "en_route"}
7febc56f-cc1e-4962-9675-8b9c790d9dd4	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 13:10:48.252423+00	{"statut": "en_route"}	{"statut": "livree"}
8d019ddf-f4b3-47dc-a88a-cc37803cf024	commandes	96fdb118-00e1-4720-b8f9-2f3b30e58611	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 13:10:48.252423+00	{"signature_pharmacien": "***"}	{"signature_pharmacien": "***"}
088a13d7-567e-4703-af05-e0baa34afcd1	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 13:10:54.607044+00	{"statut": "en_route"}	{"statut": "livree"}
6d20a46e-ebc3-485f-b159-9746f27361ba	commandes	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 13:10:54.607044+00	{"signature_pharmacien": "***"}	{"signature_pharmacien": "***"}
8d227aa4-11e6-4fed-b09a-5c040df1321b	commandes	f513fe06-a0cf-44fa-838f-5453e98790b5	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 13:36:09.730856+00	\N	{"id": "f513fe06-a0cf-44fa-838f-5453e98790b5", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 13:36:09.730856+00:00", "created_by": "None", "updated_at": "2026-04-13 13:36:09.730856+00:00", "motif_echec": "None", "reference_id": "C00000024", "montant_total": "397.00", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "preparateur_id": "None", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
13300788-2821-47b7-8664-3881655dbffe	lignes_commande	efe513cc-eae7-494e-8d03-8c64a0873620	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 13:36:09.730856+00	\N	{"id": "efe513cc-eae7-494e-8d03-8c64a0873620", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 13:36:09.730856+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 13:36:09.730856+00:00", "commande_id": "f513fe06-a0cf-44fa-838f-5453e98790b5", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "ocr_verifie": "False", "qte_demandee": "2", "qte_prelevee": "None", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
f7e125e2-bd7e-4070-927a-bae5c3819be2	commandes	48615e40-3d72-40e0-924d-fa4ea9ae3604	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 13:36:13.593355+00	\N	{"id": "48615e40-3d72-40e0-924d-fa4ea9ae3604", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 13:36:13.593355+00:00", "created_by": "None", "updated_at": "2026-04-13 13:36:13.593355+00:00", "motif_echec": "None", "reference_id": "C00000025", "montant_total": "1366.74", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "preparateur_id": "None", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
0bfb51ee-5cd9-4d56-9d10-bb2fa6d928b5	lignes_commande	adb88674-e1b5-40a2-8e3a-a3b20a829524	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 13:36:13.593355+00	\N	{"id": "adb88674-e1b5-40a2-8e3a-a3b20a829524", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 13:36:13.593355+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 13:36:13.593355+00:00", "commande_id": "48615e40-3d72-40e0-924d-fa4ea9ae3604", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "ocr_verifie": "False", "qte_demandee": "3", "qte_prelevee": "None", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
673fe8c3-01ea-4bcd-b3c9-bb3cd4290759	commandes	2c2e82ab-d610-4c51-9d96-3975c65d03db	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 13:36:22.779086+00	\N	{"id": "2c2e82ab-d610-4c51-9d96-3975c65d03db", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 13:36:22.779086+00:00", "created_by": "None", "updated_at": "2026-04-13 13:36:22.779086+00:00", "motif_echec": "None", "reference_id": "C00000026", "montant_total": "1038.80", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "preparateur_id": "None", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
9790e6d1-b7b8-4d6b-b176-81618904fa09	lignes_commande	14d5f54e-ee77-40ed-b820-a49120fc9088	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 13:36:22.779086+00	\N	{"id": "14d5f54e-ee77-40ed-b820-a49120fc9088", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 13:36:22.779086+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 13:36:22.779086+00:00", "commande_id": "2c2e82ab-d610-4c51-9d96-3975c65d03db", "designation": "ASPEC. 100MG B/98 COMP. SEC", "ocr_verifie": "False", "qte_demandee": "4", "qte_prelevee": "None", "medicament_id": "5e57f1e4-b43f-45ba-aadc-c6d1b7533292", "prix_unitaire": "259.70"}
676fb199-4ceb-4189-a61a-85e7831fa5c8	commandes	be9e9a4e-ca96-4d21-ba90-b920221f2efc	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 13:36:37.303887+00	\N	{"id": "be9e9a4e-ca96-4d21-ba90-b920221f2efc", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 13:36:37.303887+00:00", "created_by": "None", "updated_at": "2026-04-13 13:36:37.303887+00:00", "motif_echec": "None", "reference_id": "C00000027", "montant_total": "5990.00", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "preparateur_id": "None", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "signature_pharmacien": "***"}
b4b136d4-b0b7-4fa4-8d50-5b12f00de7f0	lignes_commande	61ea4cf4-92d8-458a-a4cf-83abc64e99ef	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 13:36:37.303887+00	\N	{"id": "61ea4cf4-92d8-458a-a4cf-83abc64e99ef", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 13:36:37.303887+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 13:36:37.303887+00:00", "commande_id": "be9e9a4e-ca96-4d21-ba90-b920221f2efc", "designation": "APROVASC 150MG/5MG  B/30 COMP. PELLI", "ocr_verifie": "False", "qte_demandee": "4", "qte_prelevee": "None", "medicament_id": "72dcd068-d94c-4c76-9dca-3ddace1e5962", "prix_unitaire": "1497.50"}
3e74bd00-280b-4d89-bd6c-45d68ec0ac84	commandes	2c2e82ab-d610-4c51-9d96-3975c65d03db	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:37:52.390464+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-13 13:37:52.393890+00:00"}
f6b835e5-c1b6-4f0a-b93a-5a93d39ef1e8	factures	6f405a65-22c1-460d-ac7e-75990c540497	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:37:52.390464+00	\N	{"id": "6f405a65-22c1-460d-ac7e-75990c540497", "created_at": "2026-04-13 13:37:52.390464+00:00", "created_by": "None", "montant_ht": "1038.80", "updated_at": "2026-04-13 13:37:52.390464+00:00", "commande_id": "2c2e82ab-d610-4c51-9d96-3975c65d03db", "montant_ttc": "1038.80", "reference_id": "F0000000014", "date_emission": "2026-04-13 13:37:52.402595+00:00"}
21b110b6-70dd-4d46-bc25-fec58d1baafe	bons_livraison	434a215a-8ce2-487e-b190-a23d4476be50	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:37:52.390464+00	\N	{"id": "434a215a-8ce2-487e-b190-a23d4476be50", "code_barre": "BL00000014", "created_at": "2026-04-13 13:37:52.390464+00:00", "created_by": "None", "updated_at": "2026-04-13 13:37:52.390464+00:00", "commande_id": "2c2e82ab-d610-4c51-9d96-3975c65d03db", "date_emission": "2026-04-13 13:37:52.402595+00:00"}
c5f2dbd9-9611-44e1-94ab-375c3d2f2341	medicaments	5e57f1e4-b43f-45ba-aadc-c6d1b7533292	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:37:52.390464+00	{"stock_quantity": "14"}	{"stock_quantity": "10"}
379f5680-00a6-456e-afe3-ab8391ce53bf	commandes	2c2e82ab-d610-4c51-9d96-3975c65d03db	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 13:38:44.48995+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
63a9090a-2244-4700-be28-4c23a53d9fe4	commandes	be9e9a4e-ca96-4d21-ba90-b920221f2efc	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:40:12.116127+00	{"statut": "creee"}	{"statut": "annulee"}
46a4407d-1bfd-4ea6-b8ea-6c0faa3e2741	commandes	48615e40-3d72-40e0-924d-fa4ea9ae3604	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:40:16.112649+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-13 13:40:16.115625+00:00"}
bc9efcb4-b656-418a-a933-714295f5346c	factures	c094a7f2-98c5-4320-b43b-0bbe49812bb5	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:40:16.112649+00	\N	{"id": "c094a7f2-98c5-4320-b43b-0bbe49812bb5", "created_at": "2026-04-13 13:40:16.112649+00:00", "created_by": "None", "montant_ht": "1366.74", "updated_at": "2026-04-13 13:40:16.112649+00:00", "commande_id": "48615e40-3d72-40e0-924d-fa4ea9ae3604", "montant_ttc": "1366.74", "reference_id": "F0000000015", "date_emission": "2026-04-13 13:40:16.120704+00:00"}
c832ed46-c853-4b58-a2e7-7a974f09cca9	bons_livraison	66d0894a-8f18-47cc-9a1a-719488053e77	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:40:16.112649+00	\N	{"id": "66d0894a-8f18-47cc-9a1a-719488053e77", "code_barre": "BL00000015", "created_at": "2026-04-13 13:40:16.112649+00:00", "created_by": "None", "updated_at": "2026-04-13 13:40:16.112649+00:00", "commande_id": "48615e40-3d72-40e0-924d-fa4ea9ae3604", "date_emission": "2026-04-13 13:40:16.120704+00:00"}
ed5b9aeb-3e0c-46ab-a806-a413c57a25f4	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:40:16.112649+00	{"stock_quantity": "21"}	{"stock_quantity": "18"}
a76e7496-b8ff-4872-84a4-4454cdcbe662	commandes	f513fe06-a0cf-44fa-838f-5453e98790b5	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:40:21.303155+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-13 13:40:21.306133+00:00"}
e613bca3-4d1c-4635-8e3f-0fff7bf0e167	lignes_commande	adb88674-e1b5-40a2-8e3a-a3b20a829524	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 13:40:33.451234+00	{"ocr_verifie": "False"}	{"ocr_verifie": "True"}
73b91377-d273-44f5-936b-fa98edae28e3	lignes_commande	14d5f54e-ee77-40ed-b820-a49120fc9088	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 13:38:47.855897+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "4"}
54a65a36-4d8f-480a-96f2-d9508486f415	commandes	48615e40-3d72-40e0-924d-fa4ea9ae3604	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 13:40:29.362318+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
55ed4474-6e38-4737-8a3e-422280a8d858	commandes	48615e40-3d72-40e0-924d-fa4ea9ae3604	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 13:43:23.170466+00	{"statut": "en_verification"}	{"statut": "prete"}
70eb2417-5179-4236-a4bc-ab4e36c39380	commandes	48615e40-3d72-40e0-924d-fa4ea9ae3604	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 13:43:23.170466+00	{"visa_controleur": "None"}	{"visa_controleur": "Controleur"}
cf1c05a2-9c11-497a-8320-c37000f5f694	lignes_commande	14d5f54e-ee77-40ed-b820-a49120fc9088	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 13:38:49.823483+00	{"ocr_verifie": "False"}	{"ocr_verifie": "True"}
73472d70-e44e-4d6d-a7cf-507893b271d1	commandes	48615e40-3d72-40e0-924d-fa4ea9ae3604	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 13:40:37.557658+00	{"nb_colis": "None", "visa_preparateur": "None"}	{"nb_colis": "1", "visa_preparateur": "Preparateur"}
a2a9e985-5b0d-4701-a24b-b649271f2490	commandes	48615e40-3d72-40e0-924d-fa4ea9ae3604	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 13:40:37.557658+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
0c321d79-4a0a-4be5-84b8-837da5598923	factures	2f986d6e-4075-4560-b4d2-6ed37b9c5f4f	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:40:21.303155+00	\N	{"id": "2f986d6e-4075-4560-b4d2-6ed37b9c5f4f", "created_at": "2026-04-13 13:40:21.303155+00:00", "created_by": "None", "montant_ht": "397.00", "updated_at": "2026-04-13 13:40:21.303155+00:00", "commande_id": "f513fe06-a0cf-44fa-838f-5453e98790b5", "montant_ttc": "397.00", "reference_id": "F0000000016", "date_emission": "2026-04-13 13:40:21.311974+00:00"}
cd689f59-bdfe-44ad-a17a-23222e975c21	bons_livraison	75f6ecbe-65e2-441d-bc3d-19fbe64a183b	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:40:21.303155+00	\N	{"id": "75f6ecbe-65e2-441d-bc3d-19fbe64a183b", "code_barre": "BL00000016", "created_at": "2026-04-13 13:40:21.303155+00:00", "created_by": "None", "updated_at": "2026-04-13 13:40:21.303155+00:00", "commande_id": "f513fe06-a0cf-44fa-838f-5453e98790b5", "date_emission": "2026-04-13 13:40:21.311974+00:00"}
7e504c0a-929a-43f0-8d46-3685dc534420	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 13:40:21.303155+00	{"stock_quantity": "87"}	{"stock_quantity": "85"}
76023b34-1de0-4927-977c-56123edd0d30	lignes_commande	adb88674-e1b5-40a2-8e3a-a3b20a829524	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 13:40:31.976269+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "3"}
9bed29f2-415b-4698-a8c7-3e82955885b6	commandes	48615e40-3d72-40e0-924d-fa4ea9ae3604	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 13:43:23.141372+00	{"camion_id": "None"}	{"camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7"}
7cfa5628-bb48-43df-9e01-70619023e7de	commandes	48615e40-3d72-40e0-924d-fa4ea9ae3604	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 13:43:23.141372+00	{"feuille_route_id": "None"}	{"feuille_route_id": "f969c5ec-cc7e-4f7f-a504-a5a893c143f3"}
c8068ef6-7d69-4ba3-8752-457fb3fadad9	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 20:11:54.635136+00	\N	{"id": "6e7ffbab-0205-4987-b782-0f9dfae7d304", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 20:11:54.635136+00:00", "created_by": "None", "updated_at": "2026-04-13 20:11:54.635136+00:00", "motif_echec": "None", "reference_id": "C00000028", "montant_total": "852.58", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "preparateur_id": "None", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "operatrice_comment": "None", "signature_pharmacien": "***"}
0826f73b-1b3e-4c44-9c55-56056981b775	lignes_commande	2e2814a3-d91c-4559-95ca-c50b0181bf8c	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 20:11:54.635136+00	\N	{"id": "2e2814a3-d91c-4559-95ca-c50b0181bf8c", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 20:11:54.635136+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 20:11:54.635136+00:00", "commande_id": "6e7ffbab-0205-4987-b782-0f9dfae7d304", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "ocr_verifie": "False", "qte_demandee": "2", "qte_prelevee": "None", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
486f6978-1c8b-4bd9-97aa-72b76bd3235f	lignes_commande	bf6c5dc4-6d96-4c7f-ad2a-eb77d4fef2f6	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 20:11:54.635136+00	\N	{"id": "bf6c5dc4-6d96-4c7f-ad2a-eb77d4fef2f6", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 20:11:54.635136+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 20:11:54.635136+00:00", "commande_id": "6e7ffbab-0205-4987-b782-0f9dfae7d304", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "ocr_verifie": "False", "qte_demandee": "1", "qte_prelevee": "None", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
de7f2568-f716-41f1-a4f5-eb2924067c66	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:14:14.410049+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-13 20:14:14.419314+00:00"}
4417420b-7edf-454a-9179-c9e5201b7045	factures	1ca1f1f2-5024-410c-98bf-50f870134326	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:14:14.410049+00	\N	{"id": "1ca1f1f2-5024-410c-98bf-50f870134326", "created_at": "2026-04-13 20:14:14.410049+00:00", "created_by": "None", "montant_ht": "852.58", "updated_at": "2026-04-13 20:14:14.410049+00:00", "commande_id": "6e7ffbab-0205-4987-b782-0f9dfae7d304", "montant_ttc": "852.58", "reference_id": "F0000000017", "date_emission": "2026-04-13 20:14:14.444203+00:00"}
2e1f10c6-b7c0-4660-ab0a-a37418900f00	bons_livraison	52495748-0209-41e3-a0d4-6e440e880754	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:14:14.410049+00	\N	{"id": "52495748-0209-41e3-a0d4-6e440e880754", "code_barre": "BL00000017", "created_at": "2026-04-13 20:14:14.410049+00:00", "created_by": "None", "updated_at": "2026-04-13 20:14:14.410049+00:00", "commande_id": "6e7ffbab-0205-4987-b782-0f9dfae7d304", "date_emission": "2026-04-13 20:14:14.444203+00:00"}
c956162c-7eb5-43a0-82ad-698df426d615	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:14:14.410049+00	{"stock_quantity": "18"}	{"stock_quantity": "17"}
a2818eb8-2dbd-4192-9bfb-8268164b806f	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:14:14.410049+00	{"stock_quantity": "85"}	{"stock_quantity": "83"}
e7be54f8-7bb1-4005-a79a-cdd05749d06b	caddies_pool	802cd6c5-26bf-4d33-8599-a741f84c0a2c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:15:23.515228+00	{"is_available": "True", "current_commande_id": "None"}	{"is_available": "False", "current_commande_id": "6e7ffbab-0205-4987-b782-0f9dfae7d304"}
1066b67d-254b-4ed1-8956-5246339668f7	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:15:23.515228+00	{"preparateur_id": "None"}	{"preparateur_id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62"}
812952e5-0eb4-4ad4-b069-a2f6ff731fed	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:15:23.515228+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
08c484c9-edde-4e85-b74a-d902d8f708df	lignes_commande	2e2814a3-d91c-4559-95ca-c50b0181bf8c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:15:33.471457+00	{"ocr_verifie": "False"}	{"ocr_verifie": "True"}
91bee5b9-b1a3-4385-b3b5-9388b54ae5bd	lignes_commande	2e2814a3-d91c-4559-95ca-c50b0181bf8c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:15:34.746604+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "2"}
975376c0-9993-46e0-9f5f-0562648b2e3c	lignes_commande	2e2814a3-d91c-4559-95ca-c50b0181bf8c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:15:34.840968+00	{"verifie": "True"}	{"verifie": "False"}
6efd4ea7-aa7e-440b-be0d-20211fedc875	lignes_commande	2e2814a3-d91c-4559-95ca-c50b0181bf8c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:15:37.905933+00	{"verifie": "False"}	{"verifie": "True"}
ed37273c-3a37-497d-9fe3-a42e4b02f7b4	lignes_commande	bf6c5dc4-6d96-4c7f-ad2a-eb77d4fef2f6	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:15:39.051946+00	{"ocr_verifie": "False"}	{"ocr_verifie": "True"}
fbcd4cfe-2891-4039-8656-d1c4738512d2	lignes_commande	bf6c5dc4-6d96-4c7f-ad2a-eb77d4fef2f6	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:15:41.867116+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
0466b756-3350-44bc-a3e3-586964d3d363	lignes_commande	2e2814a3-d91c-4559-95ca-c50b0181bf8c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:15:45.523509+00	{"verifie": "True"}	{"verifie": "False"}
efb38aba-71f2-4c6c-8443-56a7a148b8fc	lignes_commande	2e2814a3-d91c-4559-95ca-c50b0181bf8c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:15:46.217308+00	{"verifie": "False"}	{"verifie": "True"}
69260e91-3c95-43e9-8487-9c496cab07d7	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:16:01.759304+00	{"visa_preparateur": "None"}	{"visa_preparateur": "Preparateur"}
f7dfd7e6-0987-48d5-bd4c-d6598fa3da82	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:16:01.759304+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
29c97751-87ca-4412-8c6a-7602f09947b2	commandes	f513fe06-a0cf-44fa-838f-5453e98790b5	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:16:55.710697+00	{"preparateur_id": "None"}	{"preparateur_id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62"}
13e3e9d5-675d-453b-a076-72cec742fc2b	caddies_pool	802cd6c5-26bf-4d33-8599-a741f84c0a2c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:16:55.710697+00	{"is_available": "True", "current_commande_id": "None"}	{"is_available": "False", "current_commande_id": "f513fe06-a0cf-44fa-838f-5453e98790b5"}
e308e040-fba9-4803-a86b-7e1d91754238	commandes	f513fe06-a0cf-44fa-838f-5453e98790b5	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:16:55.710697+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
ccc32520-3fb5-471d-9a4c-6d500894ba88	lignes_commande	efe513cc-eae7-494e-8d03-8c64a0873620	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:16:57.346041+00	{"ocr_verifie": "False"}	{"ocr_verifie": "True"}
6ebdd15e-cb5c-4371-8f29-a7557f414c2f	lignes_commande	efe513cc-eae7-494e-8d03-8c64a0873620	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:16:58.172148+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "2"}
6603bf43-73ab-49c7-ad88-06b22c865f5e	commandes	f513fe06-a0cf-44fa-838f-5453e98790b5	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:16:59.495944+00	{"visa_preparateur": "None"}	{"visa_preparateur": "Preparateur"}
eaf30465-0a1a-45bc-9104-fe0710a46a8b	commandes	f513fe06-a0cf-44fa-838f-5453e98790b5	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:16:59.495944+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
cb96d5af-66cf-4679-9c3d-908283088c99	commandes	f513fe06-a0cf-44fa-838f-5453e98790b5	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:17:41.331802+00	{"camion_id": "None"}	{"camion_id": "7785e358-83c4-41e6-9e6b-db5ded7b6e97"}
ca845c28-bb74-49ef-aafa-85ef29ab219c	commandes	f513fe06-a0cf-44fa-838f-5453e98790b5	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:17:41.331802+00	{"feuille_route_id": "None"}	{"feuille_route_id": "7ea42bcb-2193-47f0-a179-57d7cded6983"}
247403ba-ce62-47cb-8c28-a7747c90a357	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:21:49.339156+00	{"preparateur_id": "None"}	{"preparateur_id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62"}
244158eb-da90-40d6-ab6a-71fa49b6ae64	caddies_pool	39c5bd49-2abb-4d81-905a-f28ad3bc3b4c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:21:49.339156+00	{"is_available": "True", "current_commande_id": "None"}	{"is_available": "False", "current_commande_id": "18a1fd87-3e0b-477f-a337-39709652df94"}
4664ebcd-fdbb-4655-b2d2-065d5080101f	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:21:49.339156+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
872e50d6-d3e6-47a3-b4d8-490541824605	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:22:38.830157+00	{"camion_id": "None"}	{"camion_id": "1c2411aa-1f09-4c5d-8360-96180f6b4c54"}
2e47af25-e7f2-46b5-918d-ebd52a82c5ad	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:22:38.830157+00	{"feuille_route_id": "None"}	{"feuille_route_id": "9e74bad5-c9e7-445b-ad23-9e38baa4cf04"}
6c20370b-fbc1-48bc-a182-83919b1b7d7c	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:23:57.358642+00	{"statut": "en_verification"}	{"statut": "prete"}
5cdfcff7-99e6-4cdf-98c0-e88cda6690b0	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:23:57.358642+00	{"visa_controleur": "None"}	{"visa_controleur": "Controleur"}
935ae12c-9897-4440-b50c-b4dc8009f938	commandes	f513fe06-a0cf-44fa-838f-5453e98790b5	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:17:41.725641+00	{"statut": "en_verification"}	{"statut": "prete"}
b7cb6f01-6b01-40cd-80d9-f83375ac40a8	commandes	f513fe06-a0cf-44fa-838f-5453e98790b5	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:17:41.725641+00	{"visa_controleur": "None"}	{"visa_controleur": "Controleur"}
7eadbf60-af7a-449d-b5b3-b7f14e56806d	commandes	7a976530-4b36-4705-8bf7-ce1168928a19	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 20:20:12.673589+00	\N	{"id": "7a976530-4b36-4705-8bf7-ce1168928a19", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 20:20:12.673589+00:00", "created_by": "None", "updated_at": "2026-04-13 20:20:12.673589+00:00", "motif_echec": "None", "reference_id": "C00000029", "montant_total": "397.00", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "preparateur_id": "None", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "operatrice_comment": "None", "signature_pharmacien": "***"}
5d4b59a7-408d-42ee-a487-f7d8d8b37b02	lignes_commande	3dddd6ce-bd8a-40c0-8446-de4f4fcdc4b2	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 20:20:12.673589+00	\N	{"id": "3dddd6ce-bd8a-40c0-8446-de4f4fcdc4b2", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 20:20:12.673589+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 20:20:12.673589+00:00", "commande_id": "7a976530-4b36-4705-8bf7-ce1168928a19", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "ocr_verifie": "False", "qte_demandee": "2", "qte_prelevee": "None", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
f1e2c3cd-6655-4c5c-9b81-d61fae35591f	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:21:23.16632+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-13 20:21:23.171205+00:00"}
56331fca-3bcd-4429-b2ef-9eb9fcea1a93	factures	80c2ab2f-a695-471d-81b9-6f6238505c24	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:21:23.16632+00	\N	{"id": "80c2ab2f-a695-471d-81b9-6f6238505c24", "created_at": "2026-04-13 20:21:23.166320+00:00", "created_by": "None", "montant_ht": "397.00", "updated_at": "2026-04-13 20:21:23.166320+00:00", "commande_id": "18a1fd87-3e0b-477f-a337-39709652df94", "montant_ttc": "397.00", "reference_id": "F0000000018", "date_emission": "2026-04-13 20:21:23.188874+00:00"}
6343eedf-f8d0-4ebd-be0d-f03d5eef5672	bons_livraison	bfc31af4-042d-4a87-aea7-91452dbb7784	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:21:23.16632+00	\N	{"id": "bfc31af4-042d-4a87-aea7-91452dbb7784", "code_barre": "BL00000018", "created_at": "2026-04-13 20:21:23.166320+00:00", "created_by": "None", "updated_at": "2026-04-13 20:21:23.166320+00:00", "commande_id": "18a1fd87-3e0b-477f-a337-39709652df94", "date_emission": "2026-04-13 20:21:23.188874+00:00"}
1650d555-66e5-4904-a578-46e5d61af4b2	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:21:23.16632+00	{"stock_quantity": "83"}	{"stock_quantity": "81"}
41eb3e79-a5cf-4d81-9fb5-119d73eb02da	lignes_commande	3544cf1b-52a8-4436-9ed7-ec64a9fda282	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:21:54.781807+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "2"}
a470e109-d0d3-45f2-8fa2-9956244af175	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 20:24:15.632318+00	{"statut": "prete"}	{"statut": "en_route"}
1e852069-18b7-4319-ac8e-3893ef2eea9e	commandes	81b6516c-629b-4d80-82d5-24a7801ae726	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 20:20:19.723784+00	\N	{"id": "81b6516c-629b-4d80-82d5-24a7801ae726", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 20:20:19.723784+00:00", "created_by": "None", "updated_at": "2026-04-13 20:20:19.723784+00:00", "motif_echec": "None", "reference_id": "C00000030", "montant_total": "911.16", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "preparateur_id": "None", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "operatrice_comment": "None", "signature_pharmacien": "***"}
dacdadd5-be89-4dc3-a807-bce7eea463de	lignes_commande	78aa0c58-eb76-436d-9e5a-52f6ec554db9	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 20:20:19.723784+00	\N	{"id": "78aa0c58-eb76-436d-9e5a-52f6ec554db9", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 20:20:19.723784+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 20:20:19.723784+00:00", "commande_id": "81b6516c-629b-4d80-82d5-24a7801ae726", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "ocr_verifie": "False", "qte_demandee": "2", "qte_prelevee": "None", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
3ab2ec2a-19a8-4018-a0e0-050cad9ced5d	commandes	81b6516c-629b-4d80-82d5-24a7801ae726	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:21:37.447254+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-04-13 20:21:37.453007+00:00"}
51dcc256-6203-4f5e-91d4-c75723fddad1	factures	7fc27e9e-9a6c-4d37-a39c-191626f13d8e	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:21:37.447254+00	\N	{"id": "7fc27e9e-9a6c-4d37-a39c-191626f13d8e", "created_at": "2026-04-13 20:21:37.447254+00:00", "created_by": "None", "montant_ht": "911.16", "updated_at": "2026-04-13 20:21:37.447254+00:00", "commande_id": "81b6516c-629b-4d80-82d5-24a7801ae726", "montant_ttc": "911.16", "reference_id": "F0000000019", "date_emission": "2026-04-13 20:21:37.469809+00:00"}
8610ed2d-467b-418c-9eb1-457b02faa2c7	bons_livraison	4d42e6ef-924d-4552-8214-b113d301d7fa	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:21:37.447254+00	\N	{"id": "4d42e6ef-924d-4552-8214-b113d301d7fa", "code_barre": "BL00000019", "created_at": "2026-04-13 20:21:37.447254+00:00", "created_by": "None", "updated_at": "2026-04-13 20:21:37.447254+00:00", "commande_id": "81b6516c-629b-4d80-82d5-24a7801ae726", "date_emission": "2026-04-13 20:21:37.469809+00:00"}
e7c6a8f1-ddfc-4338-94d0-7f5b757fbee0	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-04-13 20:21:37.447254+00	{"stock_quantity": "17"}	{"stock_quantity": "15"}
c5ce38c0-7e01-4e35-a031-f48de8939b00	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 20:22:47.281655+00	{"statut": "prete"}	{"statut": "en_route"}
fd5cb478-8d13-4f96-8b5e-024734e521eb	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 20:24:24.873207+00	{"statut": "en_route"}	{"statut": "livree"}
56f99517-fe8d-4a45-940a-f379000ddce2	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 20:24:24.873207+00	{"signature_pharmacien": "***"}	{"signature_pharmacien": "***"}
62621805-b772-4e0c-9c27-28179a39b5bb	commandes	18a1fd87-3e0b-477f-a337-39709652df94	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 20:20:29.891498+00	\N	{"id": "18a1fd87-3e0b-477f-a337-39709652df94", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-13 20:20:29.891498+00:00", "created_by": "None", "updated_at": "2026-04-13 20:20:29.891498+00:00", "motif_echec": "None", "reference_id": "C00000031", "montant_total": "397.00", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "preparateur_id": "None", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "operatrice_comment": "None", "signature_pharmacien": "***"}
642d071b-371d-4140-89bb-275fd1726b53	lignes_commande	3544cf1b-52a8-4436-9ed7-ec64a9fda282	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-13 20:20:29.891498+00	\N	{"id": "3544cf1b-52a8-4436-9ed7-ec64a9fda282", "n_lot": "None", "verifie": "False", "created_at": "2026-04-13 20:20:29.891498+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-13 20:20:29.891498+00:00", "commande_id": "18a1fd87-3e0b-477f-a337-39709652df94", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "ocr_verifie": "False", "qte_demandee": "2", "qte_prelevee": "None", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
d6cbc999-9d98-41ff-9ab5-4471a8005dcb	lignes_commande	3544cf1b-52a8-4436-9ed7-ec64a9fda282	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:21:53.834352+00	{"ocr_verifie": "False"}	{"ocr_verifie": "True"}
a5a47823-4c42-4601-97bf-6fa6ec6ae241	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:23:57.310329+00	{"camion_id": "None"}	{"camion_id": "1c2411aa-1f09-4c5d-8360-96180f6b4c54"}
5743be07-b843-4016-aacd-d2077b86d6e4	commandes	6e7ffbab-0205-4987-b782-0f9dfae7d304	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:23:57.310329+00	{"feuille_route_id": "None"}	{"feuille_route_id": "9e74bad5-c9e7-445b-ad23-9e38baa4cf04"}
b3b9e5d8-b8b9-4ec4-b2c8-c390e0621a6a	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 20:24:38.920928+00	{"statut": "en_route"}	{"statut": "retournee"}
6aa5dbb6-0766-48fa-a565-40edb536e6fc	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-04-13 20:24:38.920928+00	{"motif_echec": "None"}	{"motif_echec": "k"}
9f3ac661-ece1-4553-ba42-813ab8545dbf	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:22:02.525036+00	{"visa_preparateur": "None"}	{"visa_preparateur": "Preparateur"}
e45fd993-b6be-410e-9d6b-4dfc82ac196c	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-04-13 20:22:02.525036+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
032b61d8-f55c-48b9-92b4-0ad7e7d980f3	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:22:38.86976+00	{"statut": "en_verification"}	{"statut": "prete"}
28871235-c900-45b5-bb94-7f6b239be13d	commandes	18a1fd87-3e0b-477f-a337-39709652df94	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-04-13 20:22:38.86976+00	{"visa_controleur": "None"}	{"visa_controleur": "Controleur"}
caddfe4c-bdd2-4e10-975c-19358bc223d8	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:51:37.056864+00	{"stock_quantity": "76"}	{"stock_quantity": "74"}
c876aaf3-8b41-4dd7-a145-db6e28c19f74	commandes	9eac02e4-6c72-4e43-8eab-9a03d0b97c26	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-14 22:04:13.281688+00	\N	{"id": "9eac02e4-6c72-4e43-8eab-9a03d0b97c26", "statut": "creee", "nb_colis": "None", "camion_id": "None", "commercial": "None", "created_at": "2026-04-14 22:04:13.281688+00:00", "created_by": "None", "updated_at": "2026-04-14 22:04:13.281688+00:00", "motif_echec": "None", "reference_id": "C00000032", "montant_total": "200.22", "operatrice_id": "None", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d", "preparateur_id": "None", "date_validation": "None", "visa_controleur": "None", "feuille_route_id": "None", "visa_preparateur": "None", "operatrice_comment": "None", "signature_pharmacien": "***"}
400e7603-71bc-4cba-9d8e-090b107cdff6	lignes_commande	4af15eb0-92e6-47c4-88a4-b6358c755023	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-04-14 22:04:13.281688+00	\N	{"id": "4af15eb0-92e6-47c4-88a4-b6358c755023", "n_lot": "None", "verifie": "False", "created_at": "2026-04-14 22:04:13.281688+00:00", "created_by": "None", "remise_pct": "0.00", "updated_at": "2026-04-14 22:04:13.281688+00:00", "commande_id": "9eac02e4-6c72-4e43-8eab-9a03d0b97c26", "designation": "DOLIPRANE. 1000MG B/8 COMP", "ocr_verifie": "False", "qte_demandee": "2", "qte_prelevee": "None", "medicament_id": "2022fa77-0632-475d-8ff3-40ebb1869f4a", "prix_unitaire": "100.11"}
418effc5-b851-475f-848a-ed9dccc9a5ed	users	3fa3d47d-99e0-4ac6-94c1-565354f320eb	insert	\N	2026-06-15 15:49:18.853118+00	\N	{"id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "nom": "Magasinier Demo", "role": "magasinier", "email": "magasinier@dimed.dz", "is_active": "True", "created_at": "2026-06-15 15:49:18.853118+00:00", "updated_at": "2026-06-15 15:49:18.853118+00:00", "password_hash": "***", "is_email_verified": "True"}
5b627b4f-063d-4574-93df-b74b5915384c	commandes	7646e2c0-c917-471f-98a8-29c2fc69479b	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:25.373796+00	\N	{"id": "7646e2c0-c917-471f-98a8-29c2fc69479b", "statut": "creee", "created_at": "2026-06-15 15:50:25.373796+00:00", "updated_at": "2026-06-15 15:50:25.373796+00:00", "reference_id": "C00000033", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
a8cf56e5-87a1-48e3-9c7b-17d8dd897c5c	lignes_commande	e8863803-cf96-486b-b12b-ff36734d10db	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:25.373796+00	\N	{"id": "e8863803-cf96-486b-b12b-ff36734d10db", "verifie": "False", "created_at": "2026-06-15 15:50:25.373796+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:50:25.373796+00:00", "commande_id": "7646e2c0-c917-471f-98a8-29c2fc69479b", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
18fe651d-a9be-4027-95ec-9c11d67e61ef	lignes_commande	67571d1f-8d3b-48b3-b22b-95141657a2ef	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:25.373796+00	\N	{"id": "67571d1f-8d3b-48b3-b22b-95141657a2ef", "verifie": "False", "created_at": "2026-06-15 15:50:25.373796+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:50:25.373796+00:00", "commande_id": "7646e2c0-c917-471f-98a8-29c2fc69479b", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
55f49c99-a214-420d-8e76-9a91b044100e	commandes	7646e2c0-c917-471f-98a8-29c2fc69479b	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:25.440264+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 15:50:25.453265+00:00"}
a9c9f6fe-2ac6-48a0-9c27-d0bc616d6a48	factures	046d60a0-8f87-4529-a5c3-7dfafef7dc89	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:25.440264+00	\N	{"id": "046d60a0-8f87-4529-a5c3-7dfafef7dc89", "created_at": "2026-06-15 15:50:25.440264+00:00", "montant_ht": "852.58", "updated_at": "2026-06-15 15:50:25.440264+00:00", "commande_id": "7646e2c0-c917-471f-98a8-29c2fc69479b", "montant_ttc": "852.58", "reference_id": "F0000000020", "date_emission": "2026-06-15 15:50:25.482200+00:00"}
93a0a682-30ab-4c1c-a809-915bb141373e	creances	c9e75bb7-acc9-41c1-a09f-3d27d6eeb2b2	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:25.440264+00	\N	{"id": "c9e75bb7-acc9-41c1-a09f-3d27d6eeb2b2", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 15:50:25.440264+00:00", "facture_id": "046d60a0-8f87-4529-a5c3-7dfafef7dc89", "updated_at": "2026-06-15 15:50:25.440264+00:00", "montant_paye": "0", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
069962da-4243-4f63-9fbe-56f5bd1b1787	bons_livraison	5920fdbd-2226-4415-9299-115cac7a731c	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:25.440264+00	\N	{"id": "5920fdbd-2226-4415-9299-115cac7a731c", "code_barre": "BL00000020", "created_at": "2026-06-15 15:50:25.440264+00:00", "updated_at": "2026-06-15 15:50:25.440264+00:00", "commande_id": "7646e2c0-c917-471f-98a8-29c2fc69479b", "date_emission": "2026-06-15 15:50:25.482200+00:00"}
8fc093c9-c817-47d9-9961-82153ed54672	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:25.440264+00	{"stock_quantity": "15"}	{"stock_quantity": "14"}
883c8dd1-9a53-4937-9e01-25b93c3b14d7	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:25.440264+00	{"stock_quantity": "81"}	{"stock_quantity": "79"}
3350ea06-ea52-4e43-9e05-1794974e1c4b	caddies_pool	802cd6c5-26bf-4d33-8599-a741f84c0a2c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:50:26.106643+00	{"is_available": "True", "current_commande_id": "None"}	{"is_available": "False", "current_commande_id": "7646e2c0-c917-471f-98a8-29c2fc69479b"}
94af4b02-9910-496b-9c6d-0b43c8179aec	commandes	7646e2c0-c917-471f-98a8-29c2fc69479b	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:50:26.106643+00	{"preparateur_id": "None"}	{"preparateur_id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62"}
aff78547-1d24-4d52-8f7c-751cafa83bc5	commandes	7646e2c0-c917-471f-98a8-29c2fc69479b	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:50:26.106643+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
c27dcf5f-bb31-43a8-9257-fac0e0db1f2f	lignes_commande	e8863803-cf96-486b-b12b-ff36734d10db	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:50:26.252872+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "2"}
a24a9d42-3cb1-4327-8ac2-e9f6994e308f	lignes_commande	67571d1f-8d3b-48b3-b22b-95141657a2ef	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:50:26.283267+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
4f00a80d-7b13-45f1-94dd-ce371edefc2b	commandes	7646e2c0-c917-471f-98a8-29c2fc69479b	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:50:26.306914+00	{"visa_preparateur": "None"}	{"visa_preparateur": "Preparateur"}
ee1bd3ef-e0a2-4bd4-b731-da1fd752ac79	commandes	7646e2c0-c917-471f-98a8-29c2fc69479b	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:50:26.306914+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
4b758c07-0e42-4a52-8283-28de5942cd9e	commandes	7646e2c0-c917-471f-98a8-29c2fc69479b	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:50:26.736619+00	{"camion_id": "None"}	{"camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7"}
d9702558-071b-4bb3-be3d-1198decd624a	feuilles_route	5afebd2a-5d57-469b-8dc1-1aaa3a437189	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:50:26.736619+00	\N	{"id": "5afebd2a-5d57-469b-8dc1-1aaa3a437189", "date": "2026-06-15", "camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7", "compteurs": "{'colis_std': 0, 'sachets_std': 0, 'colis_frg': 0, 'sachets_frg': 0}", "created_at": "2026-06-15 15:50:26.736619+00:00", "updated_at": "2026-06-15 15:50:26.736619+00:00", "chargement_valide": "False"}
ea529758-eaa3-4114-80c3-0eb43c799786	commandes	7646e2c0-c917-471f-98a8-29c2fc69479b	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:50:26.736619+00	{"feuille_route_id": "None"}	{"feuille_route_id": "5afebd2a-5d57-469b-8dc1-1aaa3a437189"}
8af40035-03f0-4b85-9886-5f292a8de26c	commandes	7646e2c0-c917-471f-98a8-29c2fc69479b	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:50:26.816689+00	{"statut": "en_verification"}	{"statut": "prete"}
f139e938-0815-40ec-96fa-cd947fb1b033	commandes	7646e2c0-c917-471f-98a8-29c2fc69479b	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:50:26.816689+00	{"nb_colis": "None", "visa_controleur": "None"}	{"nb_colis": "3", "visa_controleur": "Controleur"}
ec99c9d3-16dc-4a0d-bcc5-5365976a9f97	colis	36b6616e-a0f9-4224-89b2-f744dcca9174	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:50:26.816689+00	\N	{"id": "36b6616e-a0f9-4224-89b2-f744dcca9174", "numero": "CLS00000001", "statut": "etiquete", "created_at": "2026-06-15 15:50:26.816689+00:00", "updated_at": "2026-06-15 15:50:26.816689+00:00", "commande_id": "7646e2c0-c917-471f-98a8-29c2fc69479b", "index_colis": "1"}
d9f04e4d-b129-457c-85b7-58f62140beac	colis	e934bb2d-0bc6-4d1f-a884-7f8649193733	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:50:26.816689+00	\N	{"id": "e934bb2d-0bc6-4d1f-a884-7f8649193733", "numero": "CLS00000002", "statut": "etiquete", "created_at": "2026-06-15 15:50:26.816689+00:00", "updated_at": "2026-06-15 15:50:26.816689+00:00", "commande_id": "7646e2c0-c917-471f-98a8-29c2fc69479b", "index_colis": "2"}
e713713f-1709-4c46-8cd0-7ff998015615	colis	3d1422e6-0ffc-4370-9678-4ee429565578	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:50:26.816689+00	\N	{"id": "3d1422e6-0ffc-4370-9678-4ee429565578", "numero": "CLS00000003", "statut": "etiquete", "created_at": "2026-06-15 15:50:26.816689+00:00", "updated_at": "2026-06-15 15:50:26.816689+00:00", "commande_id": "7646e2c0-c917-471f-98a8-29c2fc69479b", "index_colis": "3"}
b3b231d0-5402-43bb-917d-39d03440b689	scans_colis	364a24bb-5a68-43d0-97a0-c9aab8580bfd	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 15:50:27.441693+00	\N	{"id": "364a24bb-5a68-43d0-97a0-c9aab8580bfd", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "36b6616e-a0f9-4224-89b2-f744dcca9174", "type_scan": "depot_pad", "created_at": "2026-06-15 15:50:27.441693+00:00", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301", "updated_at": "2026-06-15 15:50:27.441693+00:00"}
76feaab5-8179-4ad4-8dc0-22a541bce021	colis	36b6616e-a0f9-4224-89b2-f744dcca9174	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 15:50:27.441693+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301"}
d68ee843-c9ad-46cd-9a80-d2f6a813e9ac	scans_colis	4b097f81-b2eb-4402-8a2d-b888d09799c3	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 15:50:27.523369+00	\N	{"id": "4b097f81-b2eb-4402-8a2d-b888d09799c3", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "e934bb2d-0bc6-4d1f-a884-7f8649193733", "type_scan": "depot_pad", "created_at": "2026-06-15 15:50:27.523369+00:00", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301", "updated_at": "2026-06-15 15:50:27.523369+00:00"}
e0985890-2516-4bcc-ab58-d1450b94595c	colis	e934bb2d-0bc6-4d1f-a884-7f8649193733	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 15:50:27.523369+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301"}
8bd79e4e-599d-4734-a254-0e99a3213538	scans_colis	e5bff6ab-489a-438e-95b8-607483df4088	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 15:50:27.555517+00	\N	{"id": "e5bff6ab-489a-438e-95b8-607483df4088", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "3d1422e6-0ffc-4370-9678-4ee429565578", "type_scan": "depot_pad", "created_at": "2026-06-15 15:50:27.555517+00:00", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301", "updated_at": "2026-06-15 15:50:27.555517+00:00"}
d7200e17-49c8-4df4-b1c5-de1716b02b9e	colis	3d1422e6-0ffc-4370-9678-4ee429565578	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 15:50:27.555517+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301"}
62704f4e-a491-4020-9a93-cd8eba0aed4b	scans_colis	8df2a5e4-e5de-490b-86b2-602eec33a2df	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.054764+00	\N	{"id": "8df2a5e4-e5de-490b-86b2-602eec33a2df", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "36b6616e-a0f9-4224-89b2-f744dcca9174", "type_scan": "chargement", "created_at": "2026-06-15 15:50:28.054764+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 15:50:28.054764+00:00"}
c2e2aa3d-ba5c-4f46-85bb-dfa4ad700a57	colis	36b6616e-a0f9-4224-89b2-f744dcca9174	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.054764+00	{"statut": "sur_pad"}	{"statut": "charge"}
fa81e93b-9906-4fb9-a88e-25a4cd6fd5cf	scans_colis	442bd1d7-16a9-44b9-868b-6c1a1abc03f4	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.116399+00	\N	{"id": "442bd1d7-16a9-44b9-868b-6c1a1abc03f4", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "e934bb2d-0bc6-4d1f-a884-7f8649193733", "type_scan": "chargement", "created_at": "2026-06-15 15:50:28.116399+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 15:50:28.116399+00:00"}
420b56da-c81c-487b-b89f-bea06094d96b	colis	e934bb2d-0bc6-4d1f-a884-7f8649193733	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.116399+00	{"statut": "sur_pad"}	{"statut": "charge"}
d84ebbfd-e997-439d-8789-ea057cfa720d	scans_colis	48822627-a4cc-4c7f-b583-60691a5f1b1b	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.160721+00	\N	{"id": "48822627-a4cc-4c7f-b583-60691a5f1b1b", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "3d1422e6-0ffc-4370-9678-4ee429565578", "type_scan": "chargement", "created_at": "2026-06-15 15:50:28.160721+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 15:50:28.160721+00:00"}
0f7626cd-0bae-4ec8-b524-3b69e775e636	colis	3d1422e6-0ffc-4370-9678-4ee429565578	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.160721+00	{"statut": "sur_pad"}	{"statut": "charge"}
38de5129-d4ea-4b43-adc3-98fa906905d6	feuilles_route	5afebd2a-5d57-469b-8dc1-1aaa3a437189	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.229634+00	{"chargement_valide": "False"}	{"chargement_valide": "True"}
ef9af155-640a-4536-9502-bf7a9cc9cba2	feuilles_route	5afebd2a-5d57-469b-8dc1-1aaa3a437189	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.254628+00	{"signature_expedition": "***"}	{"signature_expedition": "***"}
45a3e1f8-4ef0-4f05-a1a4-226e6dca8f9a	feuilles_route	5afebd2a-5d57-469b-8dc1-1aaa3a437189	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.276291+00	{"signature_chauffeur": "***"}	{"signature_chauffeur": "***"}
f691ee93-535a-453d-8234-76b974b42771	commandes	7646e2c0-c917-471f-98a8-29c2fc69479b	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.296602+00	{"statut": "prete"}	{"statut": "en_route"}
89b76da8-8f5b-4b68-9b1f-a2ac4d1f36d8	scans_colis	ede6269c-b142-4e9f-b03f-5b124a2d844a	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.336848+00	\N	{"id": "ede6269c-b142-4e9f-b03f-5b124a2d844a", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "36b6616e-a0f9-4224-89b2-f744dcca9174", "type_scan": "livraison", "created_at": "2026-06-15 15:50:28.336848+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 15:50:28.336848+00:00"}
7ba43c1e-51ff-4f69-9157-b915aa7b6694	colis	36b6616e-a0f9-4224-89b2-f744dcca9174	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.336848+00	{"statut": "charge"}	{"statut": "livre"}
89ef7fe8-596c-4127-99f4-5f2cbcc60ef4	scans_colis	36f28599-44ee-4578-81a7-7f804f6985b5	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.373533+00	\N	{"id": "36f28599-44ee-4578-81a7-7f804f6985b5", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "e934bb2d-0bc6-4d1f-a884-7f8649193733", "type_scan": "livraison", "created_at": "2026-06-15 15:50:28.373533+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 15:50:28.373533+00:00"}
5156f572-1b48-4bbc-9cb4-78d4d4a5c5e9	colis	e934bb2d-0bc6-4d1f-a884-7f8649193733	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.373533+00	{"statut": "charge"}	{"statut": "livre"}
734b0a97-f003-4a71-8837-96a2fd5376d0	scans_colis	56d01f24-7f96-4876-888d-ded1675db5e2	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.404734+00	\N	{"id": "56d01f24-7f96-4876-888d-ded1675db5e2", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "3d1422e6-0ffc-4370-9678-4ee429565578", "type_scan": "livraison", "created_at": "2026-06-15 15:50:28.404734+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 15:50:28.404734+00:00"}
8050a1e8-c35d-4308-a7fc-f2289b96e81a	colis	3d1422e6-0ffc-4370-9678-4ee429565578	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:28.404734+00	{"statut": "charge"}	{"statut": "livre"}
770d13e1-4795-4936-84c6-f72457208870	commandes	e7b4011b-5ed7-4f24-9ad2-2a04312b074e	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:29.721159+00	\N	{"id": "e7b4011b-5ed7-4f24-9ad2-2a04312b074e", "statut": "creee", "created_at": "2026-06-15 15:50:29.721159+00:00", "updated_at": "2026-06-15 15:50:29.721159+00:00", "reference_id": "C00000034", "montant_total": "397.00", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
1f21bc7b-ab79-419f-9dae-29ac1f9204e7	lignes_commande	3995f748-e345-4056-8ea9-426e0511a6c2	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:29.721159+00	\N	{"id": "3995f748-e345-4056-8ea9-426e0511a6c2", "verifie": "False", "created_at": "2026-06-15 15:50:29.721159+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:50:29.721159+00:00", "commande_id": "e7b4011b-5ed7-4f24-9ad2-2a04312b074e", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
8772c50b-b942-4556-b587-abe9f959d3b2	commandes	28b1f7b8-fe5e-45df-8bb4-c41ac4843a4c	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:31.065853+00	\N	{"id": "28b1f7b8-fe5e-45df-8bb4-c41ac4843a4c", "statut": "creee", "created_at": "2026-06-15 15:50:31.065853+00:00", "updated_at": "2026-06-15 15:50:31.065853+00:00", "reference_id": "C00000035", "montant_total": "397.00", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
96c51b8b-77f5-4fe2-a836-b7fe057608c9	lignes_commande	462c6f24-d437-4327-bfea-f2817d42b25f	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:31.065853+00	\N	{"id": "462c6f24-d437-4327-bfea-f2817d42b25f", "verifie": "False", "created_at": "2026-06-15 15:50:31.065853+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:50:31.065853+00:00", "commande_id": "28b1f7b8-fe5e-45df-8bb4-c41ac4843a4c", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
1d4467f4-c4d6-483c-9a71-b4a577a03a21	commandes	28b1f7b8-fe5e-45df-8bb4-c41ac4843a4c	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:31.096699+00	{"montant_total": "397.00"}	{"montant_total": "992.50"}
a5654ee3-deea-4e16-ba8e-3bd2a5f7c631	lignes_commande	462c6f24-d437-4327-bfea-f2817d42b25f	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:31.096699+00	{"qte_demandee": "2"}	{"qte_demandee": "5"}
b7edc235-e8a7-4e2c-93d4-e33e5244f1d2	commandes	634eadc7-857c-4ff9-8163-5b54a9eb0dda	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:51:38.094214+00	{"preparateur_id": "None"}	{"preparateur_id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62"}
c97f43b8-298e-45f4-99c1-2333f3168c6f	lignes_commande	c00a7de5-d233-473a-a32d-46d18de22b6e	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:31.129364+00	\N	{"id": "c00a7de5-d233-473a-a32d-46d18de22b6e", "verifie": "False", "created_at": "2026-06-15 15:50:31.129364+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:50:31.129364+00:00", "commande_id": "28b1f7b8-fe5e-45df-8bb4-c41ac4843a4c", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
d9002eb3-6a13-46b0-a366-4a1b99be6947	commandes	28b1f7b8-fe5e-45df-8bb4-c41ac4843a4c	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:31.129364+00	{"montant_total": "992.50"}	{"lignes": "<app.models.commande.LigneCommande object at 0x000001E6085C16D0>", "montant_total": "1448.08"}
7edc8d87-811b-4c5e-bc88-9898173cbdf6	commandes	28b1f7b8-fe5e-45df-8bb4-c41ac4843a4c	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:31.175989+00	{"lignes": "<app.models.commande.LigneCommande object at 0x000001E6085C17C0>", "montant_total": "1448.08"}	{"montant_total": "992.50"}
7fc23b06-0fb6-4739-8d31-5574b375ec69	lignes_commande	c00a7de5-d233-473a-a32d-46d18de22b6e	delete	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:31.175989+00	{"id": "c00a7de5-d233-473a-a32d-46d18de22b6e", "exp": "None", "fab": "None", "ppa": "None", "n_lot": "None", "verifie": "False", "remise_pct": "0.00", "commande_id": "28b1f7b8-fe5e-45df-8bb4-c41ac4843a4c", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "qte_prelevee": "None", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}	\N
75b2bb29-ced3-4198-98a5-c859c68b7af0	commandes	74e329cd-12fa-4a22-ac80-9c24b5d0e375	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:32.488775+00	\N	{"id": "74e329cd-12fa-4a22-ac80-9c24b5d0e375", "statut": "creee", "created_at": "2026-06-15 15:50:32.488775+00:00", "updated_at": "2026-06-15 15:50:32.488775+00:00", "reference_id": "C00000036", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
0fdf8fc0-aa02-45b7-820f-0820e5ae8ccd	lignes_commande	ed20ed63-8b72-446a-a420-87369615e8b5	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:32.488775+00	\N	{"id": "ed20ed63-8b72-446a-a420-87369615e8b5", "verifie": "False", "created_at": "2026-06-15 15:50:32.488775+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:50:32.488775+00:00", "commande_id": "74e329cd-12fa-4a22-ac80-9c24b5d0e375", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
c82f262c-f4c6-47b0-b1c2-86bfd7377c39	commandes	74e329cd-12fa-4a22-ac80-9c24b5d0e375	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:32.538317+00	{"statut": "creee"}	{"statut": "annulee"}
bdcbe1b7-1015-4ed3-bbca-de59eb982adf	commandes	3f8b751f-b7e4-4caf-a7f1-66a3cc2f9f5e	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:33.9261+00	\N	{"id": "3f8b751f-b7e4-4caf-a7f1-66a3cc2f9f5e", "statut": "creee", "created_at": "2026-06-15 15:50:33.926100+00:00", "updated_at": "2026-06-15 15:50:33.926100+00:00", "reference_id": "C00000037", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
b4201f75-d7a4-4f01-885f-ee3fa048f3cc	lignes_commande	574f1a95-0250-4131-a960-bc4daefce52e	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:33.9261+00	\N	{"id": "574f1a95-0250-4131-a960-bc4daefce52e", "verifie": "False", "created_at": "2026-06-15 15:50:33.926100+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:50:33.926100+00:00", "commande_id": "3f8b751f-b7e4-4caf-a7f1-66a3cc2f9f5e", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
1f2f0f84-6b6b-4076-9b27-efd403243e9b	commandes	3f8b751f-b7e4-4caf-a7f1-66a3cc2f9f5e	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:34.331446+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 15:50:34.336875+00:00"}
e95ff130-7257-4695-aa0e-143e5dc7eb52	factures	36da2157-5f10-44ff-af9a-d9cca814d0ef	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:34.331446+00	\N	{"id": "36da2157-5f10-44ff-af9a-d9cca814d0ef", "created_at": "2026-06-15 15:50:34.331446+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 15:50:34.331446+00:00", "commande_id": "3f8b751f-b7e4-4caf-a7f1-66a3cc2f9f5e", "montant_ttc": "198.50", "reference_id": "F0000000021", "date_emission": "2026-06-15 15:50:34.356499+00:00"}
1cd6aede-dbfa-43a5-afd3-8a3fbe7bad8b	creances	c3ba29be-1f17-4bde-80e2-a2646ed34db2	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:34.331446+00	\N	{"id": "c3ba29be-1f17-4bde-80e2-a2646ed34db2", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 15:50:34.331446+00:00", "facture_id": "36da2157-5f10-44ff-af9a-d9cca814d0ef", "updated_at": "2026-06-15 15:50:34.331446+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
1d803576-9e78-4db7-bfab-fabb85cb24a8	bons_livraison	796dbf15-725f-44b6-a688-921c61992f4d	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:34.331446+00	\N	{"id": "796dbf15-725f-44b6-a688-921c61992f4d", "code_barre": "BL00000021", "created_at": "2026-06-15 15:50:34.331446+00:00", "updated_at": "2026-06-15 15:50:34.331446+00:00", "commande_id": "3f8b751f-b7e4-4caf-a7f1-66a3cc2f9f5e", "date_emission": "2026-06-15 15:50:34.356499+00:00"}
4b0c0cda-53fe-4b0f-a627-38c73f49d2ca	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:34.331446+00	{"stock_quantity": "79"}	{"stock_quantity": "78"}
4e3bfd35-8f79-40a1-bd76-6edb5953ff5a	commandes	bdb4d02b-fdb8-481a-949a-1793843e552b	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:36.296772+00	\N	{"id": "bdb4d02b-fdb8-481a-949a-1793843e552b", "statut": "creee", "created_at": "2026-06-15 15:50:36.296772+00:00", "updated_at": "2026-06-15 15:50:36.296772+00:00", "reference_id": "C00000038", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
8495bc9c-3e55-46dd-bbd9-39ee41f079a6	lignes_commande	596b65ab-9337-4f5f-a178-7e608431c1d7	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:36.296772+00	\N	{"id": "596b65ab-9337-4f5f-a178-7e608431c1d7", "verifie": "False", "created_at": "2026-06-15 15:50:36.296772+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:50:36.296772+00:00", "commande_id": "bdb4d02b-fdb8-481a-949a-1793843e552b", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
8d42ad0c-9cd2-4b92-a5b5-28a810ca6699	commandes	bdb4d02b-fdb8-481a-949a-1793843e552b	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:36.337415+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 15:50:36.343251+00:00"}
3e5760dc-c005-4ff7-91df-259256b37d90	factures	77f5887f-3062-44fe-bfa1-c778a8b6e8e1	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:36.337415+00	\N	{"id": "77f5887f-3062-44fe-bfa1-c778a8b6e8e1", "created_at": "2026-06-15 15:50:36.337415+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 15:50:36.337415+00:00", "commande_id": "bdb4d02b-fdb8-481a-949a-1793843e552b", "montant_ttc": "198.50", "reference_id": "F0000000022", "date_emission": "2026-06-15 15:50:36.360829+00:00"}
cab7ac44-2a9e-4bde-b146-c7a81ebb93a4	creances	d070fdf9-7784-4036-9393-3ce27a558207	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:36.337415+00	\N	{"id": "d070fdf9-7784-4036-9393-3ce27a558207", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 15:50:36.337415+00:00", "facture_id": "77f5887f-3062-44fe-bfa1-c778a8b6e8e1", "updated_at": "2026-06-15 15:50:36.337415+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
20a3527a-e0b9-49b7-9db1-ee5ba3fa8531	bons_livraison	1a2643b5-3f16-44c1-a0f5-dca71cdb0fb3	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:36.337415+00	\N	{"id": "1a2643b5-3f16-44c1-a0f5-dca71cdb0fb3", "code_barre": "BL00000022", "created_at": "2026-06-15 15:50:36.337415+00:00", "updated_at": "2026-06-15 15:50:36.337415+00:00", "commande_id": "bdb4d02b-fdb8-481a-949a-1793843e552b", "date_emission": "2026-06-15 15:50:36.360829+00:00"}
2acbc180-fb44-4334-9b35-0e0a284f04c5	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:36.337415+00	{"stock_quantity": "78"}	{"stock_quantity": "77"}
0b49ecc0-2a69-4fd5-92c6-1a8be7032475	commandes	712e33d3-a45d-4ec6-82e1-488c453c04af	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:37.758943+00	\N	{"id": "712e33d3-a45d-4ec6-82e1-488c453c04af", "statut": "creee", "created_at": "2026-06-15 15:50:37.758943+00:00", "updated_at": "2026-06-15 15:50:37.758943+00:00", "reference_id": "C00000039", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
1fba4037-e381-499f-b5a9-8a5262a691dd	lignes_commande	09acc7ad-d731-4983-9f0c-85097f365ef7	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:37.758943+00	\N	{"id": "09acc7ad-d731-4983-9f0c-85097f365ef7", "verifie": "False", "created_at": "2026-06-15 15:50:37.758943+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:50:37.758943+00:00", "commande_id": "712e33d3-a45d-4ec6-82e1-488c453c04af", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
38763518-b2d8-4112-86b4-d42a26b38d9c	commandes	712e33d3-a45d-4ec6-82e1-488c453c04af	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:37.799595+00	{"operatrice_comment": "None"}	{"operatrice_comment": "Quantité erronée, merci de corriger la ligne 1"}
f0e35728-8fb8-4e86-b714-5b15fe744c68	commandes	712e33d3-a45d-4ec6-82e1-488c453c04af	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:37.850071+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 15:50:37.853567+00:00"}
f996db9e-7d35-436e-b4e1-4fa728daa4bb	factures	e91fc11a-f8c2-4977-8d51-04e9efdf4288	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:37.850071+00	\N	{"id": "e91fc11a-f8c2-4977-8d51-04e9efdf4288", "created_at": "2026-06-15 15:50:37.850071+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 15:50:37.850071+00:00", "commande_id": "712e33d3-a45d-4ec6-82e1-488c453c04af", "montant_ttc": "198.50", "reference_id": "F0000000023", "date_emission": "2026-06-15 15:50:37.869143+00:00"}
8025089a-590b-4a51-831a-78103a411fcc	creances	6f346a45-b7b2-429c-9697-c92e153684cd	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:37.850071+00	\N	{"id": "6f346a45-b7b2-429c-9697-c92e153684cd", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 15:50:37.850071+00:00", "facture_id": "e91fc11a-f8c2-4977-8d51-04e9efdf4288", "updated_at": "2026-06-15 15:50:37.850071+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
055229d6-4692-4ea9-b1a8-cab74c195b61	bons_livraison	e0a57ccb-ea71-414e-bca3-421f229068ac	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:37.850071+00	\N	{"id": "e0a57ccb-ea71-414e-bca3-421f229068ac", "code_barre": "BL00000023", "created_at": "2026-06-15 15:50:37.850071+00:00", "updated_at": "2026-06-15 15:50:37.850071+00:00", "commande_id": "712e33d3-a45d-4ec6-82e1-488c453c04af", "date_emission": "2026-06-15 15:50:37.869143+00:00"}
913d7270-7dc1-4b26-9ae9-eb913c5191ab	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:50:37.850071+00	{"stock_quantity": "77"}	{"stock_quantity": "76"}
706ad982-cbae-4be4-bbfd-246fdf3a62e4	commandes	4557c818-1e9d-4727-b43e-bcc5492248d6	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:39.320869+00	\N	{"id": "4557c818-1e9d-4727-b43e-bcc5492248d6", "statut": "creee", "created_at": "2026-06-15 15:50:39.320869+00:00", "updated_at": "2026-06-15 15:50:39.320869+00:00", "reference_id": "C00000040", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
0a5b24d9-4dd1-42b0-856a-955b51a40fc0	lignes_commande	e3c06ff5-0fe6-4c3a-8e6d-dbe78fc09a2a	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:39.320869+00	\N	{"id": "e3c06ff5-0fe6-4c3a-8e6d-dbe78fc09a2a", "verifie": "False", "created_at": "2026-06-15 15:50:39.320869+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:50:39.320869+00:00", "commande_id": "4557c818-1e9d-4727-b43e-bcc5492248d6", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
7de71f3b-93e9-4462-adc3-e712329b5a30	commandes	846e1200-4c52-443a-8e39-3c7e1a60e6d0	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:41.907222+00	\N	{"id": "846e1200-4c52-443a-8e39-3c7e1a60e6d0", "statut": "creee", "created_at": "2026-06-15 15:50:41.907222+00:00", "updated_at": "2026-06-15 15:50:41.907222+00:00", "reference_id": "C00000041", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
2ce4445c-3ff3-4be6-a2ca-715f260772c7	lignes_commande	51a417dd-952a-4fd7-8df4-acf287bce530	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 15:50:41.907222+00	\N	{"id": "51a417dd-952a-4fd7-8df4-acf287bce530", "verifie": "False", "created_at": "2026-06-15 15:50:41.907222+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:50:41.907222+00:00", "commande_id": "846e1200-4c52-443a-8e39-3c7e1a60e6d0", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
a445a3e5-d008-4362-86e7-08b3b6f17a7c	commandes	634eadc7-857c-4ff9-8163-5b54a9eb0dda	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:51:36.801539+00	\N	{"id": "634eadc7-857c-4ff9-8163-5b54a9eb0dda", "statut": "creee", "created_at": "2026-06-15 15:51:36.801539+00:00", "updated_at": "2026-06-15 15:51:36.801539+00:00", "reference_id": "C00000042", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
c66485ee-4e7d-4ae1-927b-5eb4d9152ec4	lignes_commande	84e4f913-dd9c-4918-8adc-0dbca4703900	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:51:36.801539+00	\N	{"id": "84e4f913-dd9c-4918-8adc-0dbca4703900", "verifie": "False", "created_at": "2026-06-15 15:51:36.801539+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:51:36.801539+00:00", "commande_id": "634eadc7-857c-4ff9-8163-5b54a9eb0dda", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
5685a770-5e5e-447a-99d1-d8d0275976af	lignes_commande	a6d4f103-fb36-481c-a0da-acc55cf1dda4	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:51:36.801539+00	\N	{"id": "a6d4f103-fb36-481c-a0da-acc55cf1dda4", "verifie": "False", "created_at": "2026-06-15 15:51:36.801539+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 15:51:36.801539+00:00", "commande_id": "634eadc7-857c-4ff9-8163-5b54a9eb0dda", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
023635b6-c210-4757-b9e7-8f68bca2eb3a	commandes	634eadc7-857c-4ff9-8163-5b54a9eb0dda	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:51:37.056864+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 15:51:37.064921+00:00"}
54a4b71b-ffcb-4a73-abba-13af483844c0	factures	70f35145-f5af-4763-907b-acc82e696f46	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:51:37.056864+00	\N	{"id": "70f35145-f5af-4763-907b-acc82e696f46", "created_at": "2026-06-15 15:51:37.056864+00:00", "montant_ht": "852.58", "updated_at": "2026-06-15 15:51:37.056864+00:00", "commande_id": "634eadc7-857c-4ff9-8163-5b54a9eb0dda", "montant_ttc": "852.58", "reference_id": "F0000000024", "date_emission": "2026-06-15 15:51:37.080196+00:00"}
f303bccb-f520-465b-b62d-f04dec2b2690	creances	f1ed1bd1-0fb9-421f-8cf5-9b02d20c8129	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:51:37.056864+00	\N	{"id": "f1ed1bd1-0fb9-421f-8cf5-9b02d20c8129", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 15:51:37.056864+00:00", "facture_id": "70f35145-f5af-4763-907b-acc82e696f46", "updated_at": "2026-06-15 15:51:37.056864+00:00", "montant_paye": "0", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
a08684ac-e02d-41b1-a965-5aac7275932a	bons_livraison	ac7e0e60-55c3-4bb2-b936-99a47617d21f	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:51:37.056864+00	\N	{"id": "ac7e0e60-55c3-4bb2-b936-99a47617d21f", "code_barre": "BL00000024", "created_at": "2026-06-15 15:51:37.056864+00:00", "updated_at": "2026-06-15 15:51:37.056864+00:00", "commande_id": "634eadc7-857c-4ff9-8163-5b54a9eb0dda", "date_emission": "2026-06-15 15:51:37.080196+00:00"}
c2ec13a2-a94b-43c0-9df6-1b523e4ae5e1	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 15:51:37.056864+00	{"stock_quantity": "14"}	{"stock_quantity": "13"}
0dbcfa85-53d3-4a64-bb01-f4fd332b65f9	caddies_pool	802cd6c5-26bf-4d33-8599-a741f84c0a2c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:51:38.094214+00	{"is_available": "True", "current_commande_id": "None"}	{"is_available": "False", "current_commande_id": "634eadc7-857c-4ff9-8163-5b54a9eb0dda"}
a76d90d3-7dd8-4a09-a90c-e5dfb5516984	commandes	634eadc7-857c-4ff9-8163-5b54a9eb0dda	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:51:38.094214+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
3e7d1a58-c7a1-45ab-9d58-fea08f644392	lignes_commande	84e4f913-dd9c-4918-8adc-0dbca4703900	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:51:38.826652+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
682d8573-0557-4855-9714-2e612a6da749	lignes_commande	a6d4f103-fb36-481c-a0da-acc55cf1dda4	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:51:38.963431+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
c7c74576-016f-44bb-8376-84cd5313005d	commandes	634eadc7-857c-4ff9-8163-5b54a9eb0dda	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:51:39.084257+00	{"visa_preparateur": "None"}	{"visa_preparateur": "Preparateur"}
f8b8b0ee-07ae-4766-908e-a56701244468	commandes	634eadc7-857c-4ff9-8163-5b54a9eb0dda	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:51:39.084257+00	{"statut": "en_preparation"}	{"statut": "prelevee_partiellement"}
84d6f9a9-8c00-436d-aef2-706e4c9bcaca	commandes	634eadc7-857c-4ff9-8163-5b54a9eb0dda	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 15:51:39.084257+00	{"statut": "prelevee_partiellement"}	{"statut": "en_verification"}
1b030337-e94f-4665-9e22-de5951dba85e	commandes	634eadc7-857c-4ff9-8163-5b54a9eb0dda	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:51:40.107857+00	{"camion_id": "None"}	{"camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7"}
523ff601-3439-4f5e-aed6-6ad41a35b908	commandes	634eadc7-857c-4ff9-8163-5b54a9eb0dda	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:51:40.107857+00	{"feuille_route_id": "None"}	{"feuille_route_id": "5afebd2a-5d57-469b-8dc1-1aaa3a437189"}
60b137d6-4a2c-4082-aedb-c0b76803bf6c	commandes	634eadc7-857c-4ff9-8163-5b54a9eb0dda	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:51:40.249629+00	{"statut": "en_verification"}	{"statut": "prete"}
5708efaa-3127-44b4-be82-b70dcd620c16	commandes	634eadc7-857c-4ff9-8163-5b54a9eb0dda	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:51:40.249629+00	{"nb_colis": "None", "visa_controleur": "None"}	{"nb_colis": "3", "visa_controleur": "Controleur"}
720bc4cd-3603-49d2-aedf-521630b55271	colis	feb38818-c5b5-4275-8122-482af5cabff9	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:51:40.249629+00	\N	{"id": "feb38818-c5b5-4275-8122-482af5cabff9", "numero": "CLS00000004", "statut": "etiquete", "created_at": "2026-06-15 15:51:40.249629+00:00", "updated_at": "2026-06-15 15:51:40.249629+00:00", "commande_id": "634eadc7-857c-4ff9-8163-5b54a9eb0dda", "index_colis": "1"}
4c10adbf-e8a5-4a9a-936e-f098870231e6	colis	77f65be3-db67-4a40-8aa7-eca7c8917770	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:51:40.249629+00	\N	{"id": "77f65be3-db67-4a40-8aa7-eca7c8917770", "numero": "CLS00000005", "statut": "etiquete", "created_at": "2026-06-15 15:51:40.249629+00:00", "updated_at": "2026-06-15 15:51:40.249629+00:00", "commande_id": "634eadc7-857c-4ff9-8163-5b54a9eb0dda", "index_colis": "2"}
5a4f9a82-9f57-4b2d-ab70-379217da754c	colis	e8524629-231b-47a9-924c-90c318a566c3	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 15:51:40.249629+00	\N	{"id": "e8524629-231b-47a9-924c-90c318a566c3", "numero": "CLS00000006", "statut": "etiquete", "created_at": "2026-06-15 15:51:40.249629+00:00", "updated_at": "2026-06-15 15:51:40.249629+00:00", "commande_id": "634eadc7-857c-4ff9-8163-5b54a9eb0dda", "index_colis": "3"}
3c8df37b-1323-4b08-bd25-b9ed9cae69d0	scans_colis	170a62fd-fe37-448d-8922-da12b6f67eed	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 15:51:57.90683+00	\N	{"id": "170a62fd-fe37-448d-8922-da12b6f67eed", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "feb38818-c5b5-4275-8122-482af5cabff9", "type_scan": "depot_pad", "created_at": "2026-06-15 15:51:57.906830+00:00", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301", "updated_at": "2026-06-15 15:51:57.906830+00:00"}
4d8d63ce-f2b2-4746-8c9b-6651fdc441b1	colis	feb38818-c5b5-4275-8122-482af5cabff9	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 15:51:57.90683+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301"}
7b41ae33-9acf-47ae-b1b7-4ab85799dee7	scans_colis	366ee6d4-803d-447f-a910-e5d2f65da8d0	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:03:31.551987+00	\N	{"id": "366ee6d4-803d-447f-a910-e5d2f65da8d0", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "feb38818-c5b5-4275-8122-482af5cabff9", "type_scan": "depot_pad", "created_at": "2026-06-15 16:03:31.551987+00:00", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301", "updated_at": "2026-06-15 16:03:31.551987+00:00"}
5bb42298-921b-4c49-b7f7-f546eb9e41d4	scans_colis	510c7946-9904-4a1e-94bc-642011a7961f	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:03:31.551987+00	\N	{"id": "510c7946-9904-4a1e-94bc-642011a7961f", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "77f65be3-db67-4a40-8aa7-eca7c8917770", "type_scan": "depot_pad", "created_at": "2026-06-15 16:03:31.551987+00:00", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301", "updated_at": "2026-06-15 16:03:31.551987+00:00"}
c9cc623a-6d53-45f8-9d8d-63106b200675	colis	77f65be3-db67-4a40-8aa7-eca7c8917770	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:03:31.551987+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301"}
5abd5fd0-c49e-4228-8672-3f3e1656e1e1	scans_colis	07e1194a-87d0-4bfb-9267-3dd36f775ff9	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:03:31.551987+00	\N	{"id": "07e1194a-87d0-4bfb-9267-3dd36f775ff9", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "e8524629-231b-47a9-924c-90c318a566c3", "type_scan": "depot_pad", "created_at": "2026-06-15 16:03:31.551987+00:00", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301", "updated_at": "2026-06-15 16:03:31.551987+00:00"}
400aa068-a518-4705-98a0-55ab9d2eb6dd	colis	e8524629-231b-47a9-924c-90c318a566c3	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:03:31.551987+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301"}
aef7abd7-13fb-47f3-832e-1f92b9bd2c3a	commandes	b457ab88-16a4-423c-a37c-7c9373b01e00	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:54.94945+00	\N	{"id": "b457ab88-16a4-423c-a37c-7c9373b01e00", "statut": "creee", "created_at": "2026-06-15 16:03:54.949450+00:00", "updated_at": "2026-06-15 16:03:54.949450+00:00", "reference_id": "C00000043", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
31836782-d442-4fa4-a6f8-a0348f822611	lignes_commande	4623a9dd-d41e-4487-b795-25997fda5acb	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:54.94945+00	\N	{"id": "4623a9dd-d41e-4487-b795-25997fda5acb", "verifie": "False", "created_at": "2026-06-15 16:03:54.949450+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:03:54.949450+00:00", "commande_id": "b457ab88-16a4-423c-a37c-7c9373b01e00", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
1b989e04-ea19-44a0-8c4e-5ab900c96d35	lignes_commande	e500ce49-19d5-4799-ac51-89c496b238e6	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:54.94945+00	\N	{"id": "e500ce49-19d5-4799-ac51-89c496b238e6", "verifie": "False", "created_at": "2026-06-15 16:03:54.949450+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:03:54.949450+00:00", "commande_id": "b457ab88-16a4-423c-a37c-7c9373b01e00", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
12cd3921-d326-4da2-a9c9-0b6c2ed618fc	commandes	b457ab88-16a4-423c-a37c-7c9373b01e00	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:55.016795+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:03:55.033887+00:00"}
b20d3098-21a8-45c2-a077-326f61e88326	factures	905ea0a2-811c-4610-85ba-7c45e9b74124	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:55.016795+00	\N	{"id": "905ea0a2-811c-4610-85ba-7c45e9b74124", "created_at": "2026-06-15 16:03:55.016795+00:00", "montant_ht": "852.58", "updated_at": "2026-06-15 16:03:55.016795+00:00", "commande_id": "b457ab88-16a4-423c-a37c-7c9373b01e00", "montant_ttc": "852.58", "reference_id": "F0000000025", "date_emission": "2026-06-15 16:03:55.072684+00:00"}
47e09f27-849f-46d9-a02e-8361376669c5	creances	0bb1f412-e3bd-4edd-b974-af7c1afaef02	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:55.016795+00	\N	{"id": "0bb1f412-e3bd-4edd-b974-af7c1afaef02", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:03:55.016795+00:00", "facture_id": "905ea0a2-811c-4610-85ba-7c45e9b74124", "updated_at": "2026-06-15 16:03:55.016795+00:00", "montant_paye": "0", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
1ae892ea-0718-460d-bd41-0ce34cb11e21	bons_livraison	2927e86d-d1a3-4f25-8c20-3c964935825b	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:55.016795+00	\N	{"id": "2927e86d-d1a3-4f25-8c20-3c964935825b", "code_barre": "BL00000025", "created_at": "2026-06-15 16:03:55.016795+00:00", "updated_at": "2026-06-15 16:03:55.016795+00:00", "commande_id": "b457ab88-16a4-423c-a37c-7c9373b01e00", "date_emission": "2026-06-15 16:03:55.072684+00:00"}
f417564f-9ec1-492e-a6ca-9cdeeb5a6b7e	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:55.016795+00	{"stock_quantity": "13"}	{"stock_quantity": "12"}
ac0ca032-7d23-41ae-bac3-09a4abf3741c	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:55.016795+00	{"stock_quantity": "74"}	{"stock_quantity": "72"}
98da6774-94a8-4e7f-97fb-8cfc250afd45	commandes	b457ab88-16a4-423c-a37c-7c9373b01e00	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:03:55.764113+00	{"preparateur_id": "None"}	{"preparateur_id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62"}
d7884130-4b8a-4304-811b-0418943d9df4	caddies_pool	802cd6c5-26bf-4d33-8599-a741f84c0a2c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:03:55.764113+00	{"is_available": "True", "current_commande_id": "None"}	{"is_available": "False", "current_commande_id": "b457ab88-16a4-423c-a37c-7c9373b01e00"}
f996ad7d-9a36-4dd7-a619-f6e176bd9f8a	commandes	b457ab88-16a4-423c-a37c-7c9373b01e00	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:03:55.764113+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
ca54640e-25a9-48b4-ac44-fdb94c24b4e0	lignes_commande	4623a9dd-d41e-4487-b795-25997fda5acb	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:03:55.875812+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "2"}
33df9beb-bf1f-46d2-9856-642b5ea52837	lignes_commande	e500ce49-19d5-4799-ac51-89c496b238e6	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:03:55.912383+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
cb844821-7721-406d-8494-8f95a4e25b28	commandes	b457ab88-16a4-423c-a37c-7c9373b01e00	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:03:55.946957+00	{"visa_preparateur": "None"}	{"visa_preparateur": "Preparateur"}
b93da75b-8042-454e-b62f-90933d125e6b	commandes	b457ab88-16a4-423c-a37c-7c9373b01e00	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:03:55.946957+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
d5d948db-4cdf-4f3a-bfbf-314810a7c9b3	commandes	b457ab88-16a4-423c-a37c-7c9373b01e00	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:03:56.526132+00	{"camion_id": "None"}	{"camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7"}
7adce025-557b-4437-89a3-e4d48b2dbb9d	commandes	b457ab88-16a4-423c-a37c-7c9373b01e00	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:03:56.526132+00	{"feuille_route_id": "None"}	{"feuille_route_id": "5afebd2a-5d57-469b-8dc1-1aaa3a437189"}
795f3729-a795-4f1f-b9b1-78429d7af39f	commandes	b457ab88-16a4-423c-a37c-7c9373b01e00	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:03:56.63148+00	{"statut": "en_verification"}	{"statut": "prete"}
15266325-91c3-4f1b-ac53-b9a21fc122ad	commandes	b457ab88-16a4-423c-a37c-7c9373b01e00	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:03:56.63148+00	{"nb_colis": "None", "visa_controleur": "None"}	{"nb_colis": "3", "visa_controleur": "Controleur"}
619b97cc-df4f-44b9-8ff1-d59b56eec12e	colis	9865055c-ae07-4449-9fa9-393ae8e05984	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:03:56.63148+00	\N	{"id": "9865055c-ae07-4449-9fa9-393ae8e05984", "numero": "CLS00000007", "statut": "etiquete", "created_at": "2026-06-15 16:03:56.631480+00:00", "updated_at": "2026-06-15 16:03:56.631480+00:00", "commande_id": "b457ab88-16a4-423c-a37c-7c9373b01e00", "index_colis": "1"}
067b54df-cbb9-4eb7-af4c-4eabc096fee0	colis	321c323c-856f-4ffe-a108-6d3dffeffc4d	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:03:56.63148+00	\N	{"id": "321c323c-856f-4ffe-a108-6d3dffeffc4d", "numero": "CLS00000008", "statut": "etiquete", "created_at": "2026-06-15 16:03:56.631480+00:00", "updated_at": "2026-06-15 16:03:56.631480+00:00", "commande_id": "b457ab88-16a4-423c-a37c-7c9373b01e00", "index_colis": "2"}
d349b672-b060-4777-ad3f-a2dddb2715d4	colis	1427f0c3-ba2d-4ef2-a865-79b32a844edf	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:03:56.63148+00	\N	{"id": "1427f0c3-ba2d-4ef2-a865-79b32a844edf", "numero": "CLS00000009", "statut": "etiquete", "created_at": "2026-06-15 16:03:56.631480+00:00", "updated_at": "2026-06-15 16:03:56.631480+00:00", "commande_id": "b457ab88-16a4-423c-a37c-7c9373b01e00", "index_colis": "3"}
0e430106-bbbb-4ff7-85ab-84dc872fcb69	scans_colis	28b50659-e01c-4771-b51b-0c13d3381358	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:03:57.434243+00	\N	{"id": "28b50659-e01c-4771-b51b-0c13d3381358", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "9865055c-ae07-4449-9fa9-393ae8e05984", "type_scan": "depot_pad", "created_at": "2026-06-15 16:03:57.434243+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-15 16:03:57.434243+00:00"}
5cff6434-8673-4190-9bd4-bf7fc9cebbad	colis	9865055c-ae07-4449-9fa9-393ae8e05984	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:03:57.434243+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
bb416c70-2643-4f2c-b6d9-80fb0653bb86	scans_colis	90512f54-dcfc-4f6e-8109-8f6e1a5a7d22	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:03:57.512846+00	\N	{"id": "90512f54-dcfc-4f6e-8109-8f6e1a5a7d22", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "321c323c-856f-4ffe-a108-6d3dffeffc4d", "type_scan": "depot_pad", "created_at": "2026-06-15 16:03:57.512846+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-15 16:03:57.512846+00:00"}
45e3ea1b-ea3c-49fb-af8f-fa4652d1cfa7	colis	321c323c-856f-4ffe-a108-6d3dffeffc4d	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:03:57.512846+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
60e8825f-567d-43bf-aaa4-33f413fc2523	scans_colis	07f28dca-4c58-40de-8b72-ba58801bce60	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:03:57.554686+00	\N	{"id": "07f28dca-4c58-40de-8b72-ba58801bce60", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "1427f0c3-ba2d-4ef2-a865-79b32a844edf", "type_scan": "depot_pad", "created_at": "2026-06-15 16:03:57.554686+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-15 16:03:57.554686+00:00"}
28b945f7-e0bb-4e21-bbda-80087b9c5a00	colis	1427f0c3-ba2d-4ef2-a865-79b32a844edf	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:03:57.554686+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
aeb68521-49e0-4d80-8b5b-8cc8822e0d37	scans_colis	9031aee7-2e1b-485f-8804-e535b8eb0f32	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.151013+00	\N	{"id": "9031aee7-2e1b-485f-8804-e535b8eb0f32", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "9865055c-ae07-4449-9fa9-393ae8e05984", "type_scan": "chargement", "created_at": "2026-06-15 16:03:58.151013+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:03:58.151013+00:00"}
f7d4d792-38c2-40c2-8edf-356ceae96d25	colis	9865055c-ae07-4449-9fa9-393ae8e05984	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.151013+00	{"statut": "sur_pad"}	{"statut": "charge"}
ac4a7518-1972-4e0e-905d-9fca32eaa4f8	scans_colis	37ce594a-0acb-45d5-b0f9-63ab742fa222	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.224351+00	\N	{"id": "37ce594a-0acb-45d5-b0f9-63ab742fa222", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "321c323c-856f-4ffe-a108-6d3dffeffc4d", "type_scan": "chargement", "created_at": "2026-06-15 16:03:58.224351+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:03:58.224351+00:00"}
e40e7da2-74de-470f-ba4a-4f2d6f0edf0a	colis	321c323c-856f-4ffe-a108-6d3dffeffc4d	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.224351+00	{"statut": "sur_pad"}	{"statut": "charge"}
0f26e588-4ff7-428a-8ad2-88bb03a8a4ec	commandes	53b0ca21-ecda-4875-8b88-45e6a4426f74	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:07.367451+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:04:07.376717+00:00"}
c7996731-c7fc-4260-b8cf-267b41dc8c77	scans_colis	cfd51e9a-c545-4eb7-912a-a871fbc30883	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.26844+00	\N	{"id": "cfd51e9a-c545-4eb7-912a-a871fbc30883", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "1427f0c3-ba2d-4ef2-a865-79b32a844edf", "type_scan": "chargement", "created_at": "2026-06-15 16:03:58.268440+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:03:58.268440+00:00"}
2349947a-61c3-44bc-a44d-ece2d118d487	colis	1427f0c3-ba2d-4ef2-a865-79b32a844edf	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.26844+00	{"statut": "sur_pad"}	{"statut": "charge"}
9dca5468-97e9-49cf-8682-2f89a6e4b3b6	commandes	b457ab88-16a4-423c-a37c-7c9373b01e00	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.401873+00	{"statut": "prete"}	{"statut": "en_route"}
8cae4685-441f-42df-811a-64bde6a9f83e	scans_colis	77933e11-a42c-4424-9047-a7e0aa827c9b	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.45238+00	\N	{"id": "77933e11-a42c-4424-9047-a7e0aa827c9b", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "9865055c-ae07-4449-9fa9-393ae8e05984", "type_scan": "livraison", "created_at": "2026-06-15 16:03:58.452380+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:03:58.452380+00:00"}
0a3fcedc-206f-4802-b5b2-454871249c44	colis	9865055c-ae07-4449-9fa9-393ae8e05984	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.45238+00	{"statut": "charge"}	{"statut": "livre"}
645e0fbe-f02d-44e4-bc61-2d7b68be8fe5	scans_colis	bdbd593b-5e20-4b27-9546-8ec56088c945	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.495277+00	\N	{"id": "bdbd593b-5e20-4b27-9546-8ec56088c945", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "321c323c-856f-4ffe-a108-6d3dffeffc4d", "type_scan": "livraison", "created_at": "2026-06-15 16:03:58.495277+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:03:58.495277+00:00"}
5b26d086-488b-4fe7-a86c-ae68c8ea9b13	colis	321c323c-856f-4ffe-a108-6d3dffeffc4d	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.495277+00	{"statut": "charge"}	{"statut": "livre"}
7332d248-76f9-4d26-b555-ce180c5b7105	scans_colis	31807036-40b5-4f15-a20b-f51167eef59a	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.5357+00	\N	{"id": "31807036-40b5-4f15-a20b-f51167eef59a", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "1427f0c3-ba2d-4ef2-a865-79b32a844edf", "type_scan": "livraison", "created_at": "2026-06-15 16:03:58.535700+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:03:58.535700+00:00"}
fd0385a4-12c3-4e81-a496-aa117c3a0014	colis	1427f0c3-ba2d-4ef2-a865-79b32a844edf	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:03:58.5357+00	{"statut": "charge"}	{"statut": "livre"}
6da34889-138e-4893-9da0-b8f5c21ffa30	commandes	06a1f38a-7a9b-4821-9370-040ff3df9e56	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:00.515329+00	\N	{"id": "06a1f38a-7a9b-4821-9370-040ff3df9e56", "statut": "creee", "created_at": "2026-06-15 16:04:00.515329+00:00", "updated_at": "2026-06-15 16:04:00.515329+00:00", "reference_id": "C00000044", "montant_total": "397.00", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
d60d39c0-b18e-4c97-a084-7ecc8119eb25	lignes_commande	930bc2e5-8a56-4385-8d16-ddd393e48e48	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:00.515329+00	\N	{"id": "930bc2e5-8a56-4385-8d16-ddd393e48e48", "verifie": "False", "created_at": "2026-06-15 16:04:00.515329+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:04:00.515329+00:00", "commande_id": "06a1f38a-7a9b-4821-9370-040ff3df9e56", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
1d8a29c0-bd80-4b27-b97a-fc3d50d58d01	commandes	e23d80e3-a890-4a3a-801a-b2b74b3e07d6	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:02.638432+00	\N	{"id": "e23d80e3-a890-4a3a-801a-b2b74b3e07d6", "statut": "creee", "created_at": "2026-06-15 16:04:02.638432+00:00", "updated_at": "2026-06-15 16:04:02.638432+00:00", "reference_id": "C00000045", "montant_total": "397.00", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
413fae76-928b-4409-bed2-8d946b5e792b	lignes_commande	c5cfa8f5-191f-4247-836e-11e602684b44	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:02.638432+00	\N	{"id": "c5cfa8f5-191f-4247-836e-11e602684b44", "verifie": "False", "created_at": "2026-06-15 16:04:02.638432+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:04:02.638432+00:00", "commande_id": "e23d80e3-a890-4a3a-801a-b2b74b3e07d6", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
d1a0516f-33d6-4051-9d6a-665e8b4d0d5d	commandes	e23d80e3-a890-4a3a-801a-b2b74b3e07d6	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:02.67498+00	{"montant_total": "397.00"}	{"montant_total": "992.50"}
c14aa2fd-f673-47f9-9b44-90b056913cc6	lignes_commande	c5cfa8f5-191f-4247-836e-11e602684b44	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:02.67498+00	{"qte_demandee": "2"}	{"qte_demandee": "5"}
47f551f6-6a9d-4579-8608-be9795e5277b	lignes_commande	9712d7c8-2261-47f6-9d3b-f0b0b114b83a	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:02.721706+00	\N	{"id": "9712d7c8-2261-47f6-9d3b-f0b0b114b83a", "verifie": "False", "created_at": "2026-06-15 16:04:02.721706+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:04:02.721706+00:00", "commande_id": "e23d80e3-a890-4a3a-801a-b2b74b3e07d6", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
28a63285-afa7-4fe5-bd28-f0cfbe3222ca	commandes	e23d80e3-a890-4a3a-801a-b2b74b3e07d6	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:02.721706+00	{"montant_total": "992.50"}	{"lignes": "<app.models.commande.LigneCommande object at 0x0000028F515D9A90>", "montant_total": "1448.08"}
5bbc8687-d1a8-480b-838d-89e4e20da60c	commandes	e23d80e3-a890-4a3a-801a-b2b74b3e07d6	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:02.774949+00	{"lignes": "<app.models.commande.LigneCommande object at 0x0000028F515D9D60>", "montant_total": "1448.08"}	{"montant_total": "992.50"}
a3ee5046-0db9-42d0-a461-a47d78a1844b	lignes_commande	9712d7c8-2261-47f6-9d3b-f0b0b114b83a	delete	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:02.774949+00	{"id": "9712d7c8-2261-47f6-9d3b-f0b0b114b83a", "exp": "None", "fab": "None", "ppa": "None", "n_lot": "None", "verifie": "False", "remise_pct": "0.00", "commande_id": "e23d80e3-a890-4a3a-801a-b2b74b3e07d6", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "qte_prelevee": "None", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}	\N
c329ed14-cac7-4d52-992e-16412ecd73df	commandes	17f6af5e-4fd3-468b-8f54-1a522a6328da	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:04.809129+00	\N	{"id": "17f6af5e-4fd3-468b-8f54-1a522a6328da", "statut": "creee", "created_at": "2026-06-15 16:04:04.809129+00:00", "updated_at": "2026-06-15 16:04:04.809129+00:00", "reference_id": "C00000046", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
964a8de2-7d5d-42b8-947d-a26808d6772c	lignes_commande	3c32c3b9-f362-4e37-a54c-ccfb7d4f57a6	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:04.809129+00	\N	{"id": "3c32c3b9-f362-4e37-a54c-ccfb7d4f57a6", "verifie": "False", "created_at": "2026-06-15 16:04:04.809129+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:04:04.809129+00:00", "commande_id": "17f6af5e-4fd3-468b-8f54-1a522a6328da", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
a93122e3-4ba3-462a-8b43-aff006015242	commandes	17f6af5e-4fd3-468b-8f54-1a522a6328da	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:04.852021+00	{"statut": "creee"}	{"statut": "annulee"}
c3a9272a-cfdb-4cc1-a805-54cf2a49d0f0	commandes	53b0ca21-ecda-4875-8b88-45e6a4426f74	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:06.904612+00	\N	{"id": "53b0ca21-ecda-4875-8b88-45e6a4426f74", "statut": "creee", "created_at": "2026-06-15 16:04:06.904612+00:00", "updated_at": "2026-06-15 16:04:06.904612+00:00", "reference_id": "C00000047", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
f0047f35-0584-4785-a1de-034cf44a3d89	lignes_commande	d0e53ff0-c1ef-45a3-bf64-724ae6d65fff	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:06.904612+00	\N	{"id": "d0e53ff0-c1ef-45a3-bf64-724ae6d65fff", "verifie": "False", "created_at": "2026-06-15 16:04:06.904612+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:04:06.904612+00:00", "commande_id": "53b0ca21-ecda-4875-8b88-45e6a4426f74", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
afa56001-f331-4760-aff1-9db1236d479a	factures	916b66d7-ef8d-4016-86db-d1c21b95e4ac	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:07.367451+00	\N	{"id": "916b66d7-ef8d-4016-86db-d1c21b95e4ac", "created_at": "2026-06-15 16:04:07.367451+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 16:04:07.367451+00:00", "commande_id": "53b0ca21-ecda-4875-8b88-45e6a4426f74", "montant_ttc": "198.50", "reference_id": "F0000000026", "date_emission": "2026-06-15 16:04:07.405483+00:00"}
e5b0029d-c484-468b-bd66-2b0d19d75872	creances	ce68b54e-76ce-4f0f-838c-0191ce205ea7	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:07.367451+00	\N	{"id": "ce68b54e-76ce-4f0f-838c-0191ce205ea7", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:04:07.367451+00:00", "facture_id": "916b66d7-ef8d-4016-86db-d1c21b95e4ac", "updated_at": "2026-06-15 16:04:07.367451+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
b2664c18-4340-4596-b016-a60599a4e459	bons_livraison	53cdf81f-3a93-4c4d-9e1a-e766e05bdbef	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:07.367451+00	\N	{"id": "53cdf81f-3a93-4c4d-9e1a-e766e05bdbef", "code_barre": "BL00000026", "created_at": "2026-06-15 16:04:07.367451+00:00", "updated_at": "2026-06-15 16:04:07.367451+00:00", "commande_id": "53b0ca21-ecda-4875-8b88-45e6a4426f74", "date_emission": "2026-06-15 16:04:07.405483+00:00"}
f3a9d1d8-2042-440e-91dd-79797bbfe8e8	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:07.367451+00	{"stock_quantity": "72"}	{"stock_quantity": "71"}
ef2a3274-ccf5-4817-8f43-ced5e78a5a2c	commandes	7e3dbefd-9e34-4af7-8137-bd435e68555e	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:10.006973+00	\N	{"id": "7e3dbefd-9e34-4af7-8137-bd435e68555e", "statut": "creee", "created_at": "2026-06-15 16:04:10.006973+00:00", "updated_at": "2026-06-15 16:04:10.006973+00:00", "reference_id": "C00000048", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
cd6f5492-04ea-4e29-80f7-510eb6c4c528	lignes_commande	bb329d26-f833-434e-bc60-fb6b97fd51bb	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:10.006973+00	\N	{"id": "bb329d26-f833-434e-bc60-fb6b97fd51bb", "verifie": "False", "created_at": "2026-06-15 16:04:10.006973+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:04:10.006973+00:00", "commande_id": "7e3dbefd-9e34-4af7-8137-bd435e68555e", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
e4945c06-095d-463d-9675-010fc3603f6a	commandes	7e3dbefd-9e34-4af7-8137-bd435e68555e	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:10.056726+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:04:10.064220+00:00"}
6268f000-d3f3-46c9-9f8f-d9c295c731a6	factures	2da19ffc-1863-43e7-8606-9c32287eee54	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:10.056726+00	\N	{"id": "2da19ffc-1863-43e7-8606-9c32287eee54", "created_at": "2026-06-15 16:04:10.056726+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 16:04:10.056726+00:00", "commande_id": "7e3dbefd-9e34-4af7-8137-bd435e68555e", "montant_ttc": "198.50", "reference_id": "F0000000027", "date_emission": "2026-06-15 16:04:10.082811+00:00"}
f0ee0785-8915-4d7b-90a3-60e1397f5aaa	creances	c0f369ea-97e2-4192-a844-ad158d6851b3	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:10.056726+00	\N	{"id": "c0f369ea-97e2-4192-a844-ad158d6851b3", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:04:10.056726+00:00", "facture_id": "2da19ffc-1863-43e7-8606-9c32287eee54", "updated_at": "2026-06-15 16:04:10.056726+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
e09eb1fe-309e-4105-9572-e885d1a6b4d4	bons_livraison	ab458bf0-c55f-41df-aa54-84b40c8cdc45	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:10.056726+00	\N	{"id": "ab458bf0-c55f-41df-aa54-84b40c8cdc45", "code_barre": "BL00000027", "created_at": "2026-06-15 16:04:10.056726+00:00", "updated_at": "2026-06-15 16:04:10.056726+00:00", "commande_id": "7e3dbefd-9e34-4af7-8137-bd435e68555e", "date_emission": "2026-06-15 16:04:10.082811+00:00"}
bd898caf-b67a-4960-8c85-ebdd6f0598a2	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:10.056726+00	{"stock_quantity": "71"}	{"stock_quantity": "70"}
78d1a4fb-37e7-4b39-86de-66f3edaf6fe0	commandes	afd7ad6c-776b-4c2c-9c6a-ce0134c65366	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:12.237768+00	\N	{"id": "afd7ad6c-776b-4c2c-9c6a-ce0134c65366", "statut": "creee", "created_at": "2026-06-15 16:04:12.237768+00:00", "updated_at": "2026-06-15 16:04:12.237768+00:00", "reference_id": "C00000049", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
d4ab501e-401d-4ec9-a065-8b527cf0e54f	lignes_commande	8e75487e-7798-459b-9d91-bf2f78b01b07	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:12.237768+00	\N	{"id": "8e75487e-7798-459b-9d91-bf2f78b01b07", "verifie": "False", "created_at": "2026-06-15 16:04:12.237768+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:04:12.237768+00:00", "commande_id": "afd7ad6c-776b-4c2c-9c6a-ce0134c65366", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
a7f4ec70-acc5-4c29-b639-b6b735ae0365	commandes	afd7ad6c-776b-4c2c-9c6a-ce0134c65366	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:12.275415+00	{"operatrice_comment": "None"}	{"operatrice_comment": "Quantité erronée, merci de corriger la ligne 1"}
622380f9-9b05-4b8a-b9ec-9ce39190e86d	commandes	afd7ad6c-776b-4c2c-9c6a-ce0134c65366	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:12.349117+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:04:12.361571+00:00"}
ff9ffead-7449-4d74-9674-f95994b9346b	factures	b294d7fb-9f0e-4565-b577-e06b7ce9735c	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:12.349117+00	\N	{"id": "b294d7fb-9f0e-4565-b577-e06b7ce9735c", "created_at": "2026-06-15 16:04:12.349117+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 16:04:12.349117+00:00", "commande_id": "afd7ad6c-776b-4c2c-9c6a-ce0134c65366", "montant_ttc": "198.50", "reference_id": "F0000000028", "date_emission": "2026-06-15 16:04:12.379940+00:00"}
f9027429-56f3-4658-a3de-fc76596f833f	creances	89e42005-8e22-4562-812b-02b100466d58	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:12.349117+00	\N	{"id": "89e42005-8e22-4562-812b-02b100466d58", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:04:12.349117+00:00", "facture_id": "b294d7fb-9f0e-4565-b577-e06b7ce9735c", "updated_at": "2026-06-15 16:04:12.349117+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
97fd7ea6-fc92-4d5a-8003-f8451e74236f	bons_livraison	686b33f9-bca7-4dd3-a611-d3d14693642d	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:12.349117+00	\N	{"id": "686b33f9-bca7-4dd3-a611-d3d14693642d", "code_barre": "BL00000028", "created_at": "2026-06-15 16:04:12.349117+00:00", "updated_at": "2026-06-15 16:04:12.349117+00:00", "commande_id": "afd7ad6c-776b-4c2c-9c6a-ce0134c65366", "date_emission": "2026-06-15 16:04:12.379940+00:00"}
128679c0-b142-4121-a778-3561035e50a6	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:12.349117+00	{"stock_quantity": "70"}	{"stock_quantity": "69"}
821b27f0-cf78-4f40-a6c7-c6cc4ae7939f	commandes	5913d330-9751-4b2e-b4d8-1696ce89b897	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:14.558401+00	\N	{"id": "5913d330-9751-4b2e-b4d8-1696ce89b897", "statut": "creee", "created_at": "2026-06-15 16:04:14.558401+00:00", "updated_at": "2026-06-15 16:04:14.558401+00:00", "reference_id": "C00000050", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
71ffd4c5-3510-4d16-95b1-567eef2e436f	lignes_commande	6e9a75db-0b86-4ee8-a3a1-47e2285db9bf	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:14.558401+00	\N	{"id": "6e9a75db-0b86-4ee8-a3a1-47e2285db9bf", "verifie": "False", "created_at": "2026-06-15 16:04:14.558401+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:04:14.558401+00:00", "commande_id": "5913d330-9751-4b2e-b4d8-1696ce89b897", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
04eb014e-420d-407e-95d5-2d1ffb2c34d0	commandes	40505262-756a-49d3-9366-d9b9feb92cd6	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:18.57493+00	\N	{"id": "40505262-756a-49d3-9366-d9b9feb92cd6", "statut": "creee", "created_at": "2026-06-15 16:04:18.574930+00:00", "updated_at": "2026-06-15 16:04:18.574930+00:00", "reference_id": "C00000051", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
db97c2a9-e1b8-4a9d-9bdb-5cc2dbd942aa	lignes_commande	d185de14-cc16-41e7-a05f-72ad71b23edd	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:04:18.57493+00	\N	{"id": "d185de14-cc16-41e7-a05f-72ad71b23edd", "verifie": "False", "created_at": "2026-06-15 16:04:18.574930+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:04:18.574930+00:00", "commande_id": "40505262-756a-49d3-9366-d9b9feb92cd6", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
dbe66d3e-33f8-4dc0-919e-a119ef86ab1a	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:51.475748+00	\N	{"id": "a90de1fe-e8f3-4c96-8107-69eba971d1a8", "statut": "creee", "created_at": "2026-06-15 16:04:51.475748+00:00", "updated_at": "2026-06-15 16:04:51.475748+00:00", "reference_id": "C00000052", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
8b711d3e-c808-42ff-9d36-2158f789d2ee	lignes_commande	0769b497-f3ce-4e1b-887a-cea724ccd950	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:51.475748+00	\N	{"id": "0769b497-f3ce-4e1b-887a-cea724ccd950", "verifie": "False", "created_at": "2026-06-15 16:04:51.475748+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:04:51.475748+00:00", "commande_id": "a90de1fe-e8f3-4c96-8107-69eba971d1a8", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
379b8188-6d17-4a94-8b76-606d63d85c56	lignes_commande	fda13102-756e-4fac-8026-ee784d4324a5	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:51.475748+00	\N	{"id": "fda13102-756e-4fac-8026-ee784d4324a5", "verifie": "False", "created_at": "2026-06-15 16:04:51.475748+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:04:51.475748+00:00", "commande_id": "a90de1fe-e8f3-4c96-8107-69eba971d1a8", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
0c5665d6-b43d-4691-9a3a-e8d4976c0a07	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:51.786482+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:04:51.794467+00:00"}
bfeaf3d0-26a3-48ac-8129-6a11fbaf49f4	factures	cbdeddeb-90ad-4a39-a18a-22d6fe271001	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:51.786482+00	\N	{"id": "cbdeddeb-90ad-4a39-a18a-22d6fe271001", "created_at": "2026-06-15 16:04:51.786482+00:00", "montant_ht": "852.58", "updated_at": "2026-06-15 16:04:51.786482+00:00", "commande_id": "a90de1fe-e8f3-4c96-8107-69eba971d1a8", "montant_ttc": "852.58", "reference_id": "F0000000029", "date_emission": "2026-06-15 16:04:51.819051+00:00"}
b0cf6549-ab9e-451e-a05e-0d9eb1d61111	creances	e480aff8-9d2d-4b8c-9a1f-6abde50d4161	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:51.786482+00	\N	{"id": "e480aff8-9d2d-4b8c-9a1f-6abde50d4161", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:04:51.786482+00:00", "facture_id": "cbdeddeb-90ad-4a39-a18a-22d6fe271001", "updated_at": "2026-06-15 16:04:51.786482+00:00", "montant_paye": "0", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
e5692dc5-6945-4712-99fe-acfedbd1247a	bons_livraison	ab7b768b-8e0b-492a-9e15-0a97ed8854a2	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:51.786482+00	\N	{"id": "ab7b768b-8e0b-492a-9e15-0a97ed8854a2", "code_barre": "BL00000029", "created_at": "2026-06-15 16:04:51.786482+00:00", "updated_at": "2026-06-15 16:04:51.786482+00:00", "commande_id": "a90de1fe-e8f3-4c96-8107-69eba971d1a8", "date_emission": "2026-06-15 16:04:51.819051+00:00"}
b3aa25f6-bfdb-45f8-8fe2-2c6dbf726450	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:51.786482+00	{"stock_quantity": "69"}	{"stock_quantity": "67"}
0650aedd-b158-4eb9-822e-ef246b918e17	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:04:51.786482+00	{"stock_quantity": "12"}	{"stock_quantity": "11"}
d0e5b7fc-24cc-40b7-985a-850f2367d07f	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:04:53.133031+00	{"preparateur_id": "None"}	{"preparateur_id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62"}
7acaa549-61f3-4453-b145-c9b5ba381fdc	caddies_pool	802cd6c5-26bf-4d33-8599-a741f84c0a2c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:04:53.133031+00	{"is_available": "True", "current_commande_id": "None"}	{"is_available": "False", "current_commande_id": "a90de1fe-e8f3-4c96-8107-69eba971d1a8"}
0d55102f-bf84-478d-a0f8-a84decc9a576	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:04:53.133031+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
9d397d51-79d7-46f8-9fc2-78e6ae08906c	lignes_commande	0769b497-f3ce-4e1b-887a-cea724ccd950	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:04:53.693065+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
3877d212-0ae3-456c-a1e0-d450758cc83d	lignes_commande	fda13102-756e-4fac-8026-ee784d4324a5	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:04:53.822503+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
7cf5833c-8bdc-4230-acd7-cf793e37496d	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:04:53.946723+00	{"visa_preparateur": "None"}	{"visa_preparateur": "Preparateur"}
5ccf5786-6725-4782-9801-29828a26d31d	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:04:53.946723+00	{"statut": "en_preparation"}	{"statut": "prelevee_partiellement"}
7c9ba9cf-c9d6-4a21-a6c5-f1ac2efb286b	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:04:53.946723+00	{"statut": "prelevee_partiellement"}	{"statut": "en_verification"}
5dca3154-dee7-48b2-bf5c-dd7a637ec14e	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:04:54.946266+00	{"camion_id": "None"}	{"camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7"}
8c223cea-e69a-4f72-93ea-357bc4e6ef0a	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:04:54.946266+00	{"feuille_route_id": "None"}	{"feuille_route_id": "5afebd2a-5d57-469b-8dc1-1aaa3a437189"}
686d9984-dc50-4166-a022-bdefba270d0a	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:04:55.104675+00	{"statut": "en_verification"}	{"statut": "prete"}
6b509222-53c1-4a8c-ad2a-640b99fe6f7f	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:04:55.104675+00	{"nb_colis": "None", "visa_controleur": "None"}	{"nb_colis": "2", "visa_controleur": "Controleur"}
c529f316-a02f-414e-b78a-356a9608e08f	colis	4566b695-b2c8-4009-b4a9-4fe8f9b2eb63	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:04:55.104675+00	\N	{"id": "4566b695-b2c8-4009-b4a9-4fe8f9b2eb63", "numero": "CLS00000010", "statut": "etiquete", "created_at": "2026-06-15 16:04:55.104675+00:00", "updated_at": "2026-06-15 16:04:55.104675+00:00", "commande_id": "a90de1fe-e8f3-4c96-8107-69eba971d1a8", "index_colis": "1"}
d52566a9-4537-4d60-9595-df784ac0f537	colis	72aef3f2-1486-4cd7-915d-423bde41ef8c	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:04:55.104675+00	\N	{"id": "72aef3f2-1486-4cd7-915d-423bde41ef8c", "numero": "CLS00000011", "statut": "etiquete", "created_at": "2026-06-15 16:04:55.104675+00:00", "updated_at": "2026-06-15 16:04:55.104675+00:00", "commande_id": "a90de1fe-e8f3-4c96-8107-69eba971d1a8", "index_colis": "2"}
61779262-06c6-4b56-8a83-18cd8527d607	commandes	70932ee6-bdba-4e93-b487-e0e51c7452f9	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:12:09.835448+00	\N	{"id": "70932ee6-bdba-4e93-b487-e0e51c7452f9", "statut": "creee", "created_at": "2026-06-15 16:12:09.835448+00:00", "updated_at": "2026-06-15 16:12:09.835448+00:00", "reference_id": "C00000053", "montant_total": "1688.63", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
94d1aca4-80a6-4a64-9835-4ea5f0b4c583	commandes	70932ee6-bdba-4e93-b487-e0e51c7452f9	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:15:34.950794+00	{"preparateur_id": "None"}	{"preparateur_id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62"}
be5ad77b-8f2c-43a0-a07a-cfff7f2c8f30	lignes_commande	204c3a7d-2dc8-4fb7-bc1e-57490e63e96b	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:12:09.835448+00	\N	{"id": "204c3a7d-2dc8-4fb7-bc1e-57490e63e96b", "verifie": "False", "created_at": "2026-06-15 16:12:09.835448+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:12:09.835448+00:00", "commande_id": "70932ee6-bdba-4e93-b487-e0e51c7452f9", "designation": "BIOCABASTINE 0,05℅ FL/5ML COLLYRE", "qte_demandee": "1", "medicament_id": "31b2d93c-67d9-4b01-98ec-c4c1130fc635", "prix_unitaire": "380.41"}
69840d09-d827-4ac3-8451-edc5a6325d90	lignes_commande	3b8c1adf-c358-4229-a40d-f6f48230246a	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:12:09.835448+00	\N	{"id": "3b8c1adf-c358-4229-a40d-f6f48230246a", "verifie": "False", "created_at": "2026-06-15 16:12:09.835448+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:12:09.835448+00:00", "commande_id": "70932ee6-bdba-4e93-b487-e0e51c7452f9", "designation": "BIOFENAC. 100MG B/10 SUPPO", "qte_demandee": "1", "medicament_id": "bd0ee39a-b886-4631-8dd9-50e77aef7b27", "prix_unitaire": "107.40"}
dc7229b3-d97e-4bea-91b6-f9d40c8b9f4f	lignes_commande	11a85157-854d-4c78-b93b-1ca890b9bdce	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:12:09.835448+00	\N	{"id": "11a85157-854d-4c78-b93b-1ca890b9bdce", "verifie": "False", "created_at": "2026-06-15 16:12:09.835448+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:12:09.835448+00:00", "commande_id": "70932ee6-bdba-4e93-b487-e0e51c7452f9", "designation": "BIOPAMOX. 250MG/5ML FL/60ML PDRE.P.SUSP.", "qte_demandee": "2", "medicament_id": "6ef1aae9-5d86-46ca-ae3e-dcd15e0ffceb", "prix_unitaire": "200.41"}
8f0381eb-2779-4d56-a009-8ebd4f3ed42d	lignes_commande	34ac5d2b-6707-47f1-b7da-8ea9471fc223	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:12:09.835448+00	\N	{"id": "34ac5d2b-6707-47f1-b7da-8ea9471fc223", "verifie": "False", "created_at": "2026-06-15 16:12:09.835448+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:12:09.835448+00:00", "commande_id": "70932ee6-bdba-4e93-b487-e0e51c7452f9", "designation": "CALCIDOSE 500MG B/30 SH", "qte_demandee": "2", "medicament_id": "3e947b0c-090b-468e-a135-344ba0de8b6a", "prix_unitaire": "400.00"}
d353a765-7cea-4ef1-9ff0-7f9d096fe5b9	commandes	70932ee6-bdba-4e93-b487-e0e51c7452f9	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:14:02.696749+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:14:02.731244+00:00"}
5b0ded16-bbe1-4a71-bd8f-e7a2b395a55a	factures	73fb6564-1952-4140-b828-cd51002bad57	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:14:02.696749+00	\N	{"id": "73fb6564-1952-4140-b828-cd51002bad57", "created_at": "2026-06-15 16:14:02.696749+00:00", "montant_ht": "1688.63", "updated_at": "2026-06-15 16:14:02.696749+00:00", "commande_id": "70932ee6-bdba-4e93-b487-e0e51c7452f9", "montant_ttc": "1688.63", "reference_id": "F0000000030", "date_emission": "2026-06-15 16:14:02.797822+00:00"}
297ff144-fd3e-4889-9fd8-44fe7e937af3	creances	bdead561-912d-4c66-a819-2c2ab91d5560	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:14:02.696749+00	\N	{"id": "bdead561-912d-4c66-a819-2c2ab91d5560", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:14:02.696749+00:00", "facture_id": "73fb6564-1952-4140-b828-cd51002bad57", "updated_at": "2026-06-15 16:14:02.696749+00:00", "montant_paye": "0", "montant_total": "1688.63", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
81ea64bc-90ca-4c46-981f-c807f657abc6	bons_livraison	85891160-aa45-408f-af07-ec6f79743fed	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:14:02.696749+00	\N	{"id": "85891160-aa45-408f-af07-ec6f79743fed", "code_barre": "BL00000030", "created_at": "2026-06-15 16:14:02.696749+00:00", "updated_at": "2026-06-15 16:14:02.696749+00:00", "commande_id": "70932ee6-bdba-4e93-b487-e0e51c7452f9", "date_emission": "2026-06-15 16:14:02.797822+00:00"}
09b415a1-fd4a-4642-a692-0f708bcbb999	medicaments	3e947b0c-090b-468e-a135-344ba0de8b6a	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:14:02.696749+00	{"stock_quantity": "79"}	{"stock_quantity": "77"}
31ad3441-9261-4fa5-987a-207425a215b9	medicaments	31b2d93c-67d9-4b01-98ec-c4c1130fc635	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:14:02.696749+00	{"stock_quantity": "195"}	{"stock_quantity": "194"}
2705b9e5-dd36-4af7-8931-5133bc0c4119	medicaments	bd0ee39a-b886-4631-8dd9-50e77aef7b27	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:14:02.696749+00	{"stock_quantity": "184"}	{"stock_quantity": "183"}
956189eb-484c-404c-ac11-b95f1c29f93c	medicaments	6ef1aae9-5d86-46ca-ae3e-dcd15e0ffceb	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:14:02.696749+00	{"stock_quantity": "187"}	{"stock_quantity": "185"}
c87fcd8e-b010-4ca8-8c4a-1a64f6cc1a99	lignes_commande	204c3a7d-2dc8-4fb7-bc1e-57490e63e96b	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:15:39.497765+00	{"verifie": "False"}	{"verifie": "True"}
fa915fa7-1e6e-47d6-99c4-365904ec7a4d	lignes_commande	11a85157-854d-4c78-b93b-1ca890b9bdce	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:15:41.192609+00	{"verifie": "False"}	{"verifie": "True"}
59261e72-c271-405c-9a07-80370bae33e0	lignes_commande	204c3a7d-2dc8-4fb7-bc1e-57490e63e96b	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.259666+00	{"qte_prelevee": "None"}	{"qte_prelevee": "0"}
62d6114a-393e-4723-b335-e268f47ce83e	commandes	70932ee6-bdba-4e93-b487-e0e51c7452f9	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.882739+00	{"camion_id": "None"}	{"camion_id": "1c2411aa-1f09-4c5d-8360-96180f6b4c54"}
565bfad0-4a7f-47fc-b244-fc6ff6c427f4	feuilles_route	777b09a3-e9bf-42bb-9187-bc037bf8af6e	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.882739+00	\N	{"id": "777b09a3-e9bf-42bb-9187-bc037bf8af6e", "date": "2026-06-15", "camion_id": "1c2411aa-1f09-4c5d-8360-96180f6b4c54", "compteurs": "{'colis_std': 0, 'sachets_std': 0, 'colis_frg': 0, 'sachets_frg': 0}", "created_at": "2026-06-15 16:20:36.882739+00:00", "updated_at": "2026-06-15 16:20:36.882739+00:00", "chargement_valide": "False"}
d52643db-21c8-4887-9e68-cde7a4339fba	commandes	70932ee6-bdba-4e93-b487-e0e51c7452f9	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.882739+00	{"feuille_route_id": "None"}	{"feuille_route_id": "777b09a3-e9bf-42bb-9187-bc037bf8af6e"}
2c5fadb3-b517-4a4a-849e-dd5270ad1d6a	scans_colis	8f44b835-def6-4dbe-a86d-e7b23d8a3df7	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:26:50.871261+00	\N	{"id": "8f44b835-def6-4dbe-a86d-e7b23d8a3df7", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "2de3edd1-5302-4617-82c9-244ddb424b2e", "type_scan": "depot_pad", "created_at": "2026-06-15 16:26:50.871261+00:00", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301", "updated_at": "2026-06-15 16:26:50.871261+00:00"}
d124b192-1d82-430e-985a-349df8e3cdf6	colis	2de3edd1-5302-4617-82c9-244ddb424b2e	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:26:50.871261+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301"}
15690984-ac80-44f1-8f17-8c6553819186	scans_colis	6cd0a172-5eb6-4b5a-8f43-2c63ac55d245	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:26:50.871261+00	\N	{"id": "6cd0a172-5eb6-4b5a-8f43-2c63ac55d245", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "4661cc5f-1c47-4c92-9bb3-9c8b8c2fd8db", "type_scan": "depot_pad", "created_at": "2026-06-15 16:26:50.871261+00:00", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301", "updated_at": "2026-06-15 16:26:50.871261+00:00"}
f72fc5de-420d-40ab-8649-00d908e0729a	colis	4661cc5f-1c47-4c92-9bb3-9c8b8c2fd8db	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:26:50.871261+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301"}
e3ccfaeb-0d1d-44bc-ada1-7d3ab6095326	scans_colis	b8104947-7867-4ab6-854b-8e6616837562	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:26:50.871261+00	\N	{"id": "b8104947-7867-4ab6-854b-8e6616837562", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "867bbd1b-110a-470e-8f20-b02bb47529d1", "type_scan": "depot_pad", "created_at": "2026-06-15 16:26:50.871261+00:00", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301", "updated_at": "2026-06-15 16:26:50.871261+00:00"}
c8741b86-a21b-40d2-a2ed-a96ad7040122	colis	867bbd1b-110a-470e-8f20-b02bb47529d1	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:26:50.871261+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301"}
c5f2d5ba-e8db-4606-ae6c-be77f1199a87	commandes	f619698f-e21f-4f0a-9fc3-e615b19b2d35	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:24.816121+00	{"lignes": "<app.models.commande.LigneCommande object at 0x000001ADB7C1FB60>", "montant_total": "1448.08"}	{"montant_total": "992.50"}
03f37c50-b684-46a8-be1e-624296c78100	caddies_pool	802cd6c5-26bf-4d33-8599-a741f84c0a2c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:15:34.950794+00	{"is_available": "True", "current_commande_id": "None"}	{"is_available": "False", "current_commande_id": "70932ee6-bdba-4e93-b487-e0e51c7452f9"}
b904ed54-ed06-4f2f-9f46-524c74a37231	commandes	70932ee6-bdba-4e93-b487-e0e51c7452f9	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:15:34.950794+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
0e1bc023-2259-43a5-b1fc-7f63ee3c85fe	lignes_commande	3b8c1adf-c358-4229-a40d-f6f48230246a	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:15:40.161568+00	{"verifie": "False"}	{"verifie": "True"}
1ab8c489-fc66-4c25-b084-6b7ccca18e81	lignes_commande	34ac5d2b-6707-47f1-b7da-8ea9471fc223	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:15:41.917834+00	{"verifie": "False"}	{"verifie": "True"}
e815d801-f5b8-4762-800a-6863f06e72b9	commandes	70932ee6-bdba-4e93-b487-e0e51c7452f9	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:15:46.987935+00	{"visa_preparateur": "None"}	{"visa_preparateur": "Preparateur"}
e783b893-0f18-4d06-9298-5b4eaac8c5ae	commandes	70932ee6-bdba-4e93-b487-e0e51c7452f9	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:15:46.987935+00	{"statut": "en_preparation"}	{"statut": "prelevee_partiellement"}
b77afdb0-fb95-4bb3-8f28-c6eb2c471990	commandes	70932ee6-bdba-4e93-b487-e0e51c7452f9	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:15:46.987935+00	{"statut": "prelevee_partiellement"}	{"statut": "en_verification"}
dd9b5ef6-d5c4-4c27-a0b9-4995b6126098	lignes_commande	3b8c1adf-c358-4229-a40d-f6f48230246a	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.358585+00	{"qte_prelevee": "None"}	{"qte_prelevee": "0"}
7f1d608a-14d4-48cc-bf96-85932f0080fb	lignes_commande	11a85157-854d-4c78-b93b-1ca890b9bdce	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.471429+00	{"qte_prelevee": "None"}	{"qte_prelevee": "0"}
af02fcdd-2106-4d1d-bfbd-7c385e41a3d5	lignes_commande	34ac5d2b-6707-47f1-b7da-8ea9471fc223	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.520681+00	{"qte_prelevee": "None"}	{"qte_prelevee": "0"}
65fd560e-ad1b-4967-bbb8-e27c552b19ea	commandes	70932ee6-bdba-4e93-b487-e0e51c7452f9	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.975657+00	{"statut": "en_verification"}	{"statut": "prete"}
69ada57c-50d4-48c7-9f2f-7300f931b41d	commandes	70932ee6-bdba-4e93-b487-e0e51c7452f9	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.975657+00	{"nb_colis": "None", "visa_controleur": "None"}	{"nb_colis": "4", "visa_controleur": "Controleur"}
aa7601c1-fa93-45f7-bd94-f580879865ec	colis	2de3edd1-5302-4617-82c9-244ddb424b2e	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.975657+00	\N	{"id": "2de3edd1-5302-4617-82c9-244ddb424b2e", "numero": "CLS00000012", "statut": "etiquete", "created_at": "2026-06-15 16:20:36.975657+00:00", "updated_at": "2026-06-15 16:20:36.975657+00:00", "commande_id": "70932ee6-bdba-4e93-b487-e0e51c7452f9", "index_colis": "1"}
ce12d52f-29ff-4b83-87f1-d679de53a24b	colis	4661cc5f-1c47-4c92-9bb3-9c8b8c2fd8db	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.975657+00	\N	{"id": "4661cc5f-1c47-4c92-9bb3-9c8b8c2fd8db", "numero": "CLS00000013", "statut": "etiquete", "created_at": "2026-06-15 16:20:36.975657+00:00", "updated_at": "2026-06-15 16:20:36.975657+00:00", "commande_id": "70932ee6-bdba-4e93-b487-e0e51c7452f9", "index_colis": "2"}
e6e64746-10d5-4dd1-83f6-bcc730f6b408	colis	867bbd1b-110a-470e-8f20-b02bb47529d1	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.975657+00	\N	{"id": "867bbd1b-110a-470e-8f20-b02bb47529d1", "numero": "CLS00000014", "statut": "etiquete", "created_at": "2026-06-15 16:20:36.975657+00:00", "updated_at": "2026-06-15 16:20:36.975657+00:00", "commande_id": "70932ee6-bdba-4e93-b487-e0e51c7452f9", "index_colis": "3"}
9463875e-587d-4325-b3be-063ff6ee8d7a	colis	4a0a17aa-fd5a-4a1c-bca8-0788e764aed6	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:20:36.975657+00	\N	{"id": "4a0a17aa-fd5a-4a1c-bca8-0788e764aed6", "numero": "CLS00000015", "statut": "etiquete", "created_at": "2026-06-15 16:20:36.975657+00:00", "updated_at": "2026-06-15 16:20:36.975657+00:00", "commande_id": "70932ee6-bdba-4e93-b487-e0e51c7452f9", "index_colis": "4"}
340bb857-d4c9-47db-a4a0-3703cf4b6f08	feuilles_route	5afebd2a-5d57-469b-8dc1-1aaa3a437189	update	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	2026-06-15 16:29:07.330988+00	{"livreur_id": "None"}	{"livreur_id": "ef6fb6ab-1b1a-41ea-bf5a-658502d156f7"}
eda38336-2de9-4937-911c-851f3fba2c96	scans_colis	58ba8474-4625-41c9-bdf3-099e9be1fe66	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:26:50.871261+00	\N	{"id": "58ba8474-4625-41c9-bdf3-099e9be1fe66", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "4a0a17aa-fd5a-4a1c-bca8-0788e764aed6", "type_scan": "depot_pad", "created_at": "2026-06-15 16:26:50.871261+00:00", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301", "updated_at": "2026-06-15 16:26:50.871261+00:00"}
5255cb3b-8a8f-410a-9d6a-218392c2eb3d	colis	4a0a17aa-fd5a-4a1c-bca8-0788e764aed6	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:26:50.871261+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "9b9f4153-1b16-4704-975c-8090f9e6e301"}
3a69113a-ac3b-46ca-8020-a1039fca30e8	commandes	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:18.567044+00	\N	{"id": "c7c6368e-e59a-49c9-b59d-1c42c7f6d935", "statut": "creee", "created_at": "2026-06-15 16:43:18.567044+00:00", "updated_at": "2026-06-15 16:43:18.567044+00:00", "reference_id": "C00000054", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
8357e067-951f-4c0b-93b8-c71e8ac8ce1e	lignes_commande	7282c955-27be-4c16-8858-3f47ab3705c2	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:18.567044+00	\N	{"id": "7282c955-27be-4c16-8858-3f47ab3705c2", "verifie": "False", "created_at": "2026-06-15 16:43:18.567044+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:43:18.567044+00:00", "commande_id": "c7c6368e-e59a-49c9-b59d-1c42c7f6d935", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
7e07d74c-0c25-4027-b8a4-bfb4965ed624	lignes_commande	7ac9cea4-44f2-48f4-a660-8a4d39f85212	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:18.567044+00	\N	{"id": "7ac9cea4-44f2-48f4-a660-8a4d39f85212", "verifie": "False", "created_at": "2026-06-15 16:43:18.567044+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:43:18.567044+00:00", "commande_id": "c7c6368e-e59a-49c9-b59d-1c42c7f6d935", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
d9037cb0-2298-4254-9ff9-f39615d2e435	commandes	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:18.644412+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:43:18.653643+00:00"}
d3cacc31-c86e-4ffa-b775-1ea6e2538846	factures	bc33a881-5a97-4eee-a342-ac5d750f0c03	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:18.644412+00	\N	{"id": "bc33a881-5a97-4eee-a342-ac5d750f0c03", "created_at": "2026-06-15 16:43:18.644412+00:00", "montant_ht": "852.58", "updated_at": "2026-06-15 16:43:18.644412+00:00", "commande_id": "c7c6368e-e59a-49c9-b59d-1c42c7f6d935", "montant_ttc": "852.58", "reference_id": "F0000000031", "date_emission": "2026-06-15 16:43:18.690721+00:00"}
5e7a8f0d-65a3-496c-8faf-4ede96331520	creances	3d207881-2cad-4c03-b44d-d92a8e076803	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:18.644412+00	\N	{"id": "3d207881-2cad-4c03-b44d-d92a8e076803", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:43:18.644412+00:00", "facture_id": "bc33a881-5a97-4eee-a342-ac5d750f0c03", "updated_at": "2026-06-15 16:43:18.644412+00:00", "montant_paye": "0", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
4eaf1dda-a0b6-4038-88bd-5a3cb65db339	bons_livraison	af674db5-5919-443c-b929-7bb0fab7e6cf	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:18.644412+00	\N	{"id": "af674db5-5919-443c-b929-7bb0fab7e6cf", "code_barre": "BL00000031", "created_at": "2026-06-15 16:43:18.644412+00:00", "updated_at": "2026-06-15 16:43:18.644412+00:00", "commande_id": "c7c6368e-e59a-49c9-b59d-1c42c7f6d935", "date_emission": "2026-06-15 16:43:18.690721+00:00"}
b8f7af16-e3de-487e-89d1-2b0b9fbb4a01	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:18.644412+00	{"stock_quantity": "11"}	{"stock_quantity": "10"}
51928e55-9e0c-4d89-a82d-1813ee9a1f3e	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:18.644412+00	{"stock_quantity": "67"}	{"stock_quantity": "65"}
2e8a2a18-c4dd-47f8-bfe1-bb0671a105fc	commandes	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:43:19.224925+00	{"preparateur_id": "None"}	{"preparateur_id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62"}
24e2fb58-de05-4c4f-92d3-016d5af3e6d6	caddies_pool	802cd6c5-26bf-4d33-8599-a741f84c0a2c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:43:19.224925+00	{"is_available": "True", "current_commande_id": "None"}	{"is_available": "False", "current_commande_id": "c7c6368e-e59a-49c9-b59d-1c42c7f6d935"}
631f8cd7-61e1-4314-883f-5beeb0f2e6fa	commandes	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:43:19.224925+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
4b0bd479-4a85-4a07-8ae6-ac86143bf56a	lignes_commande	7282c955-27be-4c16-8858-3f47ab3705c2	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:43:19.311316+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "2"}
d410be1d-33a4-4892-9902-c98dd2fb894a	lignes_commande	7ac9cea4-44f2-48f4-a660-8a4d39f85212	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:43:19.344007+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
523f438c-5f01-4679-86fa-9a1f3b84e084	commandes	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:43:19.365924+00	{"visa_preparateur": "None"}	{"visa_preparateur": "Preparateur"}
9bc5e6f4-f9e6-447f-b7ad-a8990caf9f99	commandes	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:43:19.365924+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
bbce7d74-5761-4719-8cf9-c55dbf4981ac	commandes	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:43:19.828194+00	{"camion_id": "None"}	{"camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7"}
280cf6a0-3e99-40bb-8654-89c9a4a69967	commandes	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:43:19.828194+00	{"feuille_route_id": "None"}	{"feuille_route_id": "5afebd2a-5d57-469b-8dc1-1aaa3a437189"}
c9972c74-6fa0-4608-890a-ea780808f990	commandes	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:43:19.876809+00	{"statut": "en_verification"}	{"statut": "prete"}
0cd32d05-3f9d-46d2-9a1b-04864c7da249	commandes	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:43:19.876809+00	{"nb_colis": "None", "visa_controleur": "None"}	{"nb_colis": "3", "visa_controleur": "Controleur"}
47033c37-296c-4868-b11c-9ab3d71c64ea	colis	d0dc8e6f-1b06-4d71-8dac-5d5abae4d120	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:43:19.876809+00	\N	{"id": "d0dc8e6f-1b06-4d71-8dac-5d5abae4d120", "numero": "CLS00000016", "statut": "etiquete", "created_at": "2026-06-15 16:43:19.876809+00:00", "updated_at": "2026-06-15 16:43:19.876809+00:00", "commande_id": "c7c6368e-e59a-49c9-b59d-1c42c7f6d935", "index_colis": "1"}
035a29b6-7b29-450d-8cc1-5e498ccbdfdc	colis	d6fd0be7-837c-43b0-9430-27781bf63503	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:43:19.876809+00	\N	{"id": "d6fd0be7-837c-43b0-9430-27781bf63503", "numero": "CLS00000017", "statut": "etiquete", "created_at": "2026-06-15 16:43:19.876809+00:00", "updated_at": "2026-06-15 16:43:19.876809+00:00", "commande_id": "c7c6368e-e59a-49c9-b59d-1c42c7f6d935", "index_colis": "2"}
0cb37d68-df14-406d-b03d-42678f923696	colis	1e0ede6a-53e5-485f-8fca-ca781bdcbda6	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:43:19.876809+00	\N	{"id": "1e0ede6a-53e5-485f-8fca-ca781bdcbda6", "numero": "CLS00000018", "statut": "etiquete", "created_at": "2026-06-15 16:43:19.876809+00:00", "updated_at": "2026-06-15 16:43:19.876809+00:00", "commande_id": "c7c6368e-e59a-49c9-b59d-1c42c7f6d935", "index_colis": "3"}
168a0282-0fcc-480e-ac07-7f5616b585f8	scans_colis	0ba86321-7610-4df3-9896-dc60b676ce07	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:43:20.45776+00	\N	{"id": "0ba86321-7610-4df3-9896-dc60b676ce07", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "d0dc8e6f-1b06-4d71-8dac-5d5abae4d120", "type_scan": "depot_pad", "created_at": "2026-06-15 16:43:20.457760+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-15 16:43:20.457760+00:00"}
9583d52d-469a-4ef4-9c0a-a24ff9c7c6c0	colis	d0dc8e6f-1b06-4d71-8dac-5d5abae4d120	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:43:20.45776+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
3c36fe0b-af15-4b93-9db4-e5aa12ecce87	scans_colis	4335f790-c968-4559-8856-beefd0e423ba	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:43:20.539115+00	\N	{"id": "4335f790-c968-4559-8856-beefd0e423ba", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "d6fd0be7-837c-43b0-9430-27781bf63503", "type_scan": "depot_pad", "created_at": "2026-06-15 16:43:20.539115+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-15 16:43:20.539115+00:00"}
20617fa3-d273-45a6-96b0-4bf6668ef0ce	colis	d6fd0be7-837c-43b0-9430-27781bf63503	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:43:20.539115+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
1b1e6f31-4dcc-40aa-b916-85a2b5cc4467	scans_colis	9f5f720f-99d1-4410-97d1-cc72fce46f80	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:43:20.571677+00	\N	{"id": "9f5f720f-99d1-4410-97d1-cc72fce46f80", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "1e0ede6a-53e5-485f-8fca-ca781bdcbda6", "type_scan": "depot_pad", "created_at": "2026-06-15 16:43:20.571677+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-15 16:43:20.571677+00:00"}
71d81ab1-c6ce-492b-adea-b5df5ac84520	colis	1e0ede6a-53e5-485f-8fca-ca781bdcbda6	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:43:20.571677+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
a983b783-c60a-4308-a864-662e83a6d12d	scans_colis	9784c2eb-6f42-4206-8992-50e27e66821e	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.051832+00	\N	{"id": "9784c2eb-6f42-4206-8992-50e27e66821e", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "d0dc8e6f-1b06-4d71-8dac-5d5abae4d120", "type_scan": "chargement", "created_at": "2026-06-15 16:43:21.051832+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:43:21.051832+00:00"}
2d46a213-feff-44fe-9d5b-d74479390e95	colis	d0dc8e6f-1b06-4d71-8dac-5d5abae4d120	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.051832+00	{"statut": "sur_pad"}	{"statut": "charge"}
cc9551a4-dca8-455b-bd0f-ed4111b2636d	scans_colis	8faa2893-9430-46a9-a789-6eeaad0398de	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.112805+00	\N	{"id": "8faa2893-9430-46a9-a789-6eeaad0398de", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "d6fd0be7-837c-43b0-9430-27781bf63503", "type_scan": "chargement", "created_at": "2026-06-15 16:43:21.112805+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:43:21.112805+00:00"}
895eb2d8-cd7d-4a86-93a6-ba7eaebb1bb7	colis	d6fd0be7-837c-43b0-9430-27781bf63503	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.112805+00	{"statut": "sur_pad"}	{"statut": "charge"}
b5d4397b-77ea-4364-9369-8e6c6e86a0b9	scans_colis	b074dc1e-c132-40f2-9070-0d66659935ee	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.145062+00	\N	{"id": "b074dc1e-c132-40f2-9070-0d66659935ee", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "1e0ede6a-53e5-485f-8fca-ca781bdcbda6", "type_scan": "chargement", "created_at": "2026-06-15 16:43:21.145062+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:43:21.145062+00:00"}
0ca7aa40-4e3f-43ae-852e-8ea1bb399d91	colis	1e0ede6a-53e5-485f-8fca-ca781bdcbda6	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.145062+00	{"statut": "sur_pad"}	{"statut": "charge"}
b6493f93-78b6-42a5-8c1d-6e5f56ccde1d	commandes	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.268378+00	{"statut": "prete"}	{"statut": "en_route"}
38502199-eb83-47da-baf6-2d617df7d1a9	scans_colis	d1f44a9a-726f-40f2-8156-e51c050b5518	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.308159+00	\N	{"id": "d1f44a9a-726f-40f2-8156-e51c050b5518", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "d0dc8e6f-1b06-4d71-8dac-5d5abae4d120", "type_scan": "livraison", "created_at": "2026-06-15 16:43:21.308159+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:43:21.308159+00:00"}
be1574fc-735c-44ae-a2fd-c2c1e8909a0d	colis	d0dc8e6f-1b06-4d71-8dac-5d5abae4d120	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.308159+00	{"statut": "charge"}	{"statut": "livre"}
f605d073-0cb7-43a5-9346-be9847dae5d0	scans_colis	0e1d383d-92f9-4cb5-907e-c1053bba7d1c	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.353342+00	\N	{"id": "0e1d383d-92f9-4cb5-907e-c1053bba7d1c", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "d6fd0be7-837c-43b0-9430-27781bf63503", "type_scan": "livraison", "created_at": "2026-06-15 16:43:21.353342+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:43:21.353342+00:00"}
1e821e77-3d17-4839-82ca-7b790a2938a8	colis	d6fd0be7-837c-43b0-9430-27781bf63503	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.353342+00	{"statut": "charge"}	{"statut": "livre"}
6281d92f-9470-4c69-8e32-ff465a268787	scans_colis	19b71c24-d246-42a9-9730-d2b80db4500d	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.388009+00	\N	{"id": "19b71c24-d246-42a9-9730-d2b80db4500d", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "1e0ede6a-53e5-485f-8fca-ca781bdcbda6", "type_scan": "livraison", "created_at": "2026-06-15 16:43:21.388009+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:43:21.388009+00:00"}
b7983957-fd94-4eaa-8f0d-04c009cc93ef	colis	1e0ede6a-53e5-485f-8fca-ca781bdcbda6	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:21.388009+00	{"statut": "charge"}	{"statut": "livre"}
967873f0-e2de-44ce-a689-c9a8510d652e	commandes	0b133ab5-eeb5-42b1-8079-3e31ad4f13aa	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:23.151611+00	\N	{"id": "0b133ab5-eeb5-42b1-8079-3e31ad4f13aa", "statut": "creee", "created_at": "2026-06-15 16:43:23.151611+00:00", "updated_at": "2026-06-15 16:43:23.151611+00:00", "reference_id": "C00000055", "montant_total": "397.00", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
0f75ff24-4fdd-4bb4-a503-c141b4d352b3	lignes_commande	ca6b987a-7509-444a-b784-06147ba6c4ab	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:23.151611+00	\N	{"id": "ca6b987a-7509-444a-b784-06147ba6c4ab", "verifie": "False", "created_at": "2026-06-15 16:43:23.151611+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:43:23.151611+00:00", "commande_id": "0b133ab5-eeb5-42b1-8079-3e31ad4f13aa", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
20bb6f9f-6a3e-4a7a-adda-63b2ac7da143	commandes	f619698f-e21f-4f0a-9fc3-e615b19b2d35	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:24.668551+00	\N	{"id": "f619698f-e21f-4f0a-9fc3-e615b19b2d35", "statut": "creee", "created_at": "2026-06-15 16:43:24.668551+00:00", "updated_at": "2026-06-15 16:43:24.668551+00:00", "reference_id": "C00000056", "montant_total": "397.00", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
cf262224-ff24-4fe8-bbaa-503cc3d1847a	lignes_commande	eaf545e9-3d5e-4870-976e-d8ff41dbf25d	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:24.668551+00	\N	{"id": "eaf545e9-3d5e-4870-976e-d8ff41dbf25d", "verifie": "False", "created_at": "2026-06-15 16:43:24.668551+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:43:24.668551+00:00", "commande_id": "f619698f-e21f-4f0a-9fc3-e615b19b2d35", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
ac9165ba-04ee-43df-8a78-869aab69cb2c	commandes	f619698f-e21f-4f0a-9fc3-e615b19b2d35	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:24.710552+00	{"montant_total": "397.00"}	{"montant_total": "992.50"}
942fd14b-dfee-43e2-965d-127ba4e66b4c	lignes_commande	eaf545e9-3d5e-4870-976e-d8ff41dbf25d	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:24.710552+00	{"qte_demandee": "2"}	{"qte_demandee": "5"}
529a3c07-6e22-432b-b749-69530397f4c5	lignes_commande	78473063-efc5-44a4-8ce7-5345dd4ccd57	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:24.767247+00	\N	{"id": "78473063-efc5-44a4-8ce7-5345dd4ccd57", "verifie": "False", "created_at": "2026-06-15 16:43:24.767247+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:43:24.767247+00:00", "commande_id": "f619698f-e21f-4f0a-9fc3-e615b19b2d35", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
00250e1f-06e4-4a7b-bb54-ff2a4a2a6451	commandes	f619698f-e21f-4f0a-9fc3-e615b19b2d35	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:24.767247+00	{"montant_total": "992.50"}	{"lignes": "<app.models.commande.LigneCommande object at 0x000001ADB7C1FC50>", "montant_total": "1448.08"}
d2e28247-499b-4779-8b60-2738dbe96c40	commandes	a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:31.221183+00	{"operatrice_comment": "None"}	{"operatrice_comment": "Quantité erronée, merci de corriger la ligne 1"}
c3e22596-c7d3-4cd5-94e8-97fd7ca03b0e	lignes_commande	78473063-efc5-44a4-8ce7-5345dd4ccd57	delete	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:24.816121+00	{"id": "78473063-efc5-44a4-8ce7-5345dd4ccd57", "exp": "None", "fab": "None", "ppa": "None", "n_lot": "None", "verifie": "False", "remise_pct": "0.00", "commande_id": "f619698f-e21f-4f0a-9fc3-e615b19b2d35", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "qte_prelevee": "None", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}	\N
2e432163-d375-4756-9c3c-74b80f12b7de	commandes	fbceed4c-73b9-475f-9ebc-48f2aed910f9	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:26.219427+00	\N	{"id": "fbceed4c-73b9-475f-9ebc-48f2aed910f9", "statut": "creee", "created_at": "2026-06-15 16:43:26.219427+00:00", "updated_at": "2026-06-15 16:43:26.219427+00:00", "reference_id": "C00000057", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
1967238a-21e2-4837-8bd5-23c2acb64a71	lignes_commande	c9f600b0-a245-4e57-90e9-4bfc86cea201	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:26.219427+00	\N	{"id": "c9f600b0-a245-4e57-90e9-4bfc86cea201", "verifie": "False", "created_at": "2026-06-15 16:43:26.219427+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:43:26.219427+00:00", "commande_id": "fbceed4c-73b9-475f-9ebc-48f2aed910f9", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
74c98d99-3e0b-48ea-8787-70108b0a3409	commandes	fbceed4c-73b9-475f-9ebc-48f2aed910f9	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:26.251427+00	{"statut": "creee"}	{"statut": "annulee"}
43a78b46-d9bd-41b6-9db0-4762d03b2a04	commandes	9d504663-a4f6-4855-bdec-407cfabc199a	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:27.547502+00	\N	{"id": "9d504663-a4f6-4855-bdec-407cfabc199a", "statut": "creee", "created_at": "2026-06-15 16:43:27.547502+00:00", "updated_at": "2026-06-15 16:43:27.547502+00:00", "reference_id": "C00000058", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
2173fb55-8fd6-4ed1-8f4e-dbbd1ca21514	lignes_commande	ee77f140-f7ab-4904-bd59-564c6295027b	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:27.547502+00	\N	{"id": "ee77f140-f7ab-4904-bd59-564c6295027b", "verifie": "False", "created_at": "2026-06-15 16:43:27.547502+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:43:27.547502+00:00", "commande_id": "9d504663-a4f6-4855-bdec-407cfabc199a", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
eff08351-c082-4f67-8431-b4ed08860fed	commandes	9d504663-a4f6-4855-bdec-407cfabc199a	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:27.985656+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:43:27.996310+00:00"}
c6531cd4-fa6c-49f7-afd0-cbebd8b396b2	factures	b9f235d9-8e88-48a3-b54a-2a8d608a53c8	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:27.985656+00	\N	{"id": "b9f235d9-8e88-48a3-b54a-2a8d608a53c8", "created_at": "2026-06-15 16:43:27.985656+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 16:43:27.985656+00:00", "commande_id": "9d504663-a4f6-4855-bdec-407cfabc199a", "montant_ttc": "198.50", "reference_id": "F0000000032", "date_emission": "2026-06-15 16:43:28.020842+00:00"}
1ee00ec3-b622-4020-9b64-76e7ace1048c	creances	2698d758-aad2-44f1-9264-51b946b65cb1	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:27.985656+00	\N	{"id": "2698d758-aad2-44f1-9264-51b946b65cb1", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:43:27.985656+00:00", "facture_id": "b9f235d9-8e88-48a3-b54a-2a8d608a53c8", "updated_at": "2026-06-15 16:43:27.985656+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
e37bd476-89d4-4ec4-9dad-389f9e6ce27c	bons_livraison	563a9d1e-5c07-432f-9483-eefc34b5dbec	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:27.985656+00	\N	{"id": "563a9d1e-5c07-432f-9483-eefc34b5dbec", "code_barre": "BL00000032", "created_at": "2026-06-15 16:43:27.985656+00:00", "updated_at": "2026-06-15 16:43:27.985656+00:00", "commande_id": "9d504663-a4f6-4855-bdec-407cfabc199a", "date_emission": "2026-06-15 16:43:28.020842+00:00"}
166f802e-f7d8-423a-a9f2-b98f44d28695	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:27.985656+00	{"stock_quantity": "65"}	{"stock_quantity": "64"}
e12f61cd-f4f0-43c6-952a-2dcb2ab960e0	commandes	54d4a168-cd3c-4ad7-8531-def1a75875e3	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:29.803905+00	\N	{"id": "54d4a168-cd3c-4ad7-8531-def1a75875e3", "statut": "creee", "created_at": "2026-06-15 16:43:29.803905+00:00", "updated_at": "2026-06-15 16:43:29.803905+00:00", "reference_id": "C00000059", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
7e1719e0-4f57-4b07-ba33-28a98ea9bc13	lignes_commande	f37d5673-e4c2-4b2d-a2da-0dc8c6fac4d6	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:29.803905+00	\N	{"id": "f37d5673-e4c2-4b2d-a2da-0dc8c6fac4d6", "verifie": "False", "created_at": "2026-06-15 16:43:29.803905+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:43:29.803905+00:00", "commande_id": "54d4a168-cd3c-4ad7-8531-def1a75875e3", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
c7f84d33-950d-4577-9184-c866ccb71e78	commandes	54d4a168-cd3c-4ad7-8531-def1a75875e3	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:29.840087+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:43:29.848599+00:00"}
7d07fafb-1085-4cd7-b54e-c91dd1f22b8c	factures	17075960-1745-48e1-ad66-0f1508214537	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:29.840087+00	\N	{"id": "17075960-1745-48e1-ad66-0f1508214537", "created_at": "2026-06-15 16:43:29.840087+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 16:43:29.840087+00:00", "commande_id": "54d4a168-cd3c-4ad7-8531-def1a75875e3", "montant_ttc": "198.50", "reference_id": "F0000000033", "date_emission": "2026-06-15 16:43:29.866499+00:00"}
519f2ab7-6a8c-4dad-9d0e-9d6289b010bb	creances	ac34b4e2-ebb4-420a-a56e-984476235897	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:29.840087+00	\N	{"id": "ac34b4e2-ebb4-420a-a56e-984476235897", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:43:29.840087+00:00", "facture_id": "17075960-1745-48e1-ad66-0f1508214537", "updated_at": "2026-06-15 16:43:29.840087+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
8aa31eca-3d52-45ee-9dff-0580e07c0397	bons_livraison	669507e6-443d-44d4-a364-6011d0ed0d9b	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:29.840087+00	\N	{"id": "669507e6-443d-44d4-a364-6011d0ed0d9b", "code_barre": "BL00000033", "created_at": "2026-06-15 16:43:29.840087+00:00", "updated_at": "2026-06-15 16:43:29.840087+00:00", "commande_id": "54d4a168-cd3c-4ad7-8531-def1a75875e3", "date_emission": "2026-06-15 16:43:29.866499+00:00"}
5bcde08d-7ab1-4d2f-a5b6-a242317f8ce8	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:29.840087+00	{"stock_quantity": "64"}	{"stock_quantity": "63"}
51fe73ca-ecb2-4880-bebb-d1a11daccd37	commandes	a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:31.18495+00	\N	{"id": "a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd", "statut": "creee", "created_at": "2026-06-15 16:43:31.184950+00:00", "updated_at": "2026-06-15 16:43:31.184950+00:00", "reference_id": "C00000060", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
fb7f3e5e-015d-4b4b-8104-06342ab7d869	lignes_commande	41375fc8-b629-4e29-9a1c-04b609bfc8ba	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:31.18495+00	\N	{"id": "41375fc8-b629-4e29-9a1c-04b609bfc8ba", "verifie": "False", "created_at": "2026-06-15 16:43:31.184950+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:43:31.184950+00:00", "commande_id": "a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
59df48e7-9c55-4c2c-80cf-39df0adca937	commandes	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-16 21:30:49.163335+00	{"statut": "en_verification"}	{"statut": "prete"}
18ba2bdb-a226-4ee2-875a-70d959972c21	commandes	a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:31.265314+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:43:31.272025+00:00"}
e28eee16-0c89-4a91-857a-59f37fec7284	factures	ac1b4eee-b02c-42bd-a3cd-3856df14b813	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:31.265314+00	\N	{"id": "ac1b4eee-b02c-42bd-a3cd-3856df14b813", "created_at": "2026-06-15 16:43:31.265314+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 16:43:31.265314+00:00", "commande_id": "a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd", "montant_ttc": "198.50", "reference_id": "F0000000034", "date_emission": "2026-06-15 16:43:31.290620+00:00"}
49142b61-6255-44aa-a5c5-13e0987a81f9	creances	6acf13a0-dcdf-4c18-b3f7-565ab1d8f76b	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:31.265314+00	\N	{"id": "6acf13a0-dcdf-4c18-b3f7-565ab1d8f76b", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:43:31.265314+00:00", "facture_id": "ac1b4eee-b02c-42bd-a3cd-3856df14b813", "updated_at": "2026-06-15 16:43:31.265314+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
761f6ce6-5084-4777-91ac-b24377554971	bons_livraison	5ed5c26e-f9e5-4f2a-bc91-05a9d9427876	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:31.265314+00	\N	{"id": "5ed5c26e-f9e5-4f2a-bc91-05a9d9427876", "code_barre": "BL00000034", "created_at": "2026-06-15 16:43:31.265314+00:00", "updated_at": "2026-06-15 16:43:31.265314+00:00", "commande_id": "a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd", "date_emission": "2026-06-15 16:43:31.290620+00:00"}
7218d983-e595-4419-a6db-671600e8d14f	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:43:31.265314+00	{"stock_quantity": "63"}	{"stock_quantity": "62"}
1a529e6f-4bea-4b2f-b4eb-bcd20764545a	commandes	2a5a4167-cccc-4d00-87b1-0eff74f20216	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:32.672836+00	\N	{"id": "2a5a4167-cccc-4d00-87b1-0eff74f20216", "statut": "creee", "created_at": "2026-06-15 16:43:32.672836+00:00", "updated_at": "2026-06-15 16:43:32.672836+00:00", "reference_id": "C00000061", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
6818211b-5199-4f78-8161-e451864bfd47	lignes_commande	5b03ce82-f035-4ecd-8e8e-954d86c02ce3	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:32.672836+00	\N	{"id": "5b03ce82-f035-4ecd-8e8e-954d86c02ce3", "verifie": "False", "created_at": "2026-06-15 16:43:32.672836+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:43:32.672836+00:00", "commande_id": "2a5a4167-cccc-4d00-87b1-0eff74f20216", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
d9e072fd-a254-40c0-9bfa-51bb9bf79942	commandes	b705c340-b2ca-4528-91b2-f3ca83436d38	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:35.410846+00	\N	{"id": "b705c340-b2ca-4528-91b2-f3ca83436d38", "statut": "creee", "created_at": "2026-06-15 16:43:35.410846+00:00", "updated_at": "2026-06-15 16:43:35.410846+00:00", "reference_id": "C00000062", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
f4ba4396-78d6-4d68-a9f6-18745affa21c	lignes_commande	661be1fa-95fd-40cd-8654-cc14c2a0ebf0	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:43:35.410846+00	\N	{"id": "661be1fa-95fd-40cd-8654-cc14c2a0ebf0", "verifie": "False", "created_at": "2026-06-15 16:43:35.410846+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:43:35.410846+00:00", "commande_id": "b705c340-b2ca-4528-91b2-f3ca83436d38", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
eac921cd-6e79-481d-b27e-d0b12f5f70ba	users	6d4d8a0c-d618-4646-867d-4b833a795014	insert	\N	2026-06-15 16:52:39.014428+00	\N	{"id": "6d4d8a0c-d618-4646-867d-4b833a795014", "nom": "Facturier Demo", "role": "facturier", "email": "facturier@dimed.dz", "is_active": "True", "created_at": "2026-06-15 16:52:39.014428+00:00", "updated_at": "2026-06-15 16:52:39.014428+00:00", "password_hash": "***", "is_email_verified": "True"}
f3c2d690-2361-4ff7-82fa-5508989002ae	users	bd50ef77-a84a-4aaf-9cbe-4cfeb883046f	insert	\N	2026-06-15 16:52:39.014428+00	\N	{"id": "bd50ef77-a84a-4aaf-9cbe-4cfeb883046f", "nom": "Livreur 1", "role": "livreur", "email": "livreur1@dimed.dz", "is_active": "True", "created_at": "2026-06-15 16:52:39.014428+00:00", "updated_at": "2026-06-15 16:52:39.014428+00:00", "password_hash": "***", "is_email_verified": "True"}
afd3190f-2aed-4aff-afc2-75a4431ede7d	users	7d837426-095a-4af0-a2e4-7f83a7872bd6	insert	\N	2026-06-15 16:52:39.014428+00	\N	{"id": "7d837426-095a-4af0-a2e4-7f83a7872bd6", "nom": "Livreur 2", "role": "livreur", "email": "livreur2@dimed.dz", "is_active": "True", "created_at": "2026-06-15 16:52:39.014428+00:00", "updated_at": "2026-06-15 16:52:39.014428+00:00", "password_hash": "***", "is_email_verified": "True"}
bf92fce3-af77-449c-9393-17e74154147d	users	acd6c8b9-f2a7-4901-a7d9-5f4e3805a44e	insert	\N	2026-06-15 16:52:39.014428+00	\N	{"id": "acd6c8b9-f2a7-4901-a7d9-5f4e3805a44e", "nom": "Livreur 3", "role": "livreur", "email": "livreur3@dimed.dz", "is_active": "True", "created_at": "2026-06-15 16:52:39.014428+00:00", "updated_at": "2026-06-15 16:52:39.014428+00:00", "password_hash": "***", "is_email_verified": "True"}
0a3f0fc6-fe46-4ae0-a081-a5d74aa138cc	users	a93c5e03-80cd-462a-87dc-e0477d944ca8	insert	\N	2026-06-15 16:52:39.014428+00	\N	{"id": "a93c5e03-80cd-462a-87dc-e0477d944ca8", "nom": "Livreur 4", "role": "livreur", "email": "livreur4@dimed.dz", "is_active": "True", "created_at": "2026-06-15 16:52:39.014428+00:00", "updated_at": "2026-06-15 16:52:39.014428+00:00", "password_hash": "***", "is_email_verified": "True"}
1d9c666c-5faf-4b90-bc80-9beef9c4190a	users	04a7282f-79fb-4fe7-9523-990906e768ce	insert	\N	2026-06-15 16:52:39.014428+00	\N	{"id": "04a7282f-79fb-4fe7-9523-990906e768ce", "nom": "Livreur 5", "role": "livreur", "email": "livreur5@dimed.dz", "is_active": "True", "created_at": "2026-06-15 16:52:39.014428+00:00", "updated_at": "2026-06-15 16:52:39.014428+00:00", "password_hash": "***", "is_email_verified": "True"}
0474ef2a-a30c-4da8-a002-3abe42ffc6b3	users	ed617636-c060-40c0-81a4-ef2a31ca4f74	insert	\N	2026-06-15 16:52:39.014428+00	\N	{"id": "ed617636-c060-40c0-81a4-ef2a31ca4f74", "nom": "Livreur 6", "role": "livreur", "email": "livreur6@dimed.dz", "is_active": "True", "created_at": "2026-06-15 16:52:39.014428+00:00", "updated_at": "2026-06-15 16:52:39.014428+00:00", "password_hash": "***", "is_email_verified": "True"}
f835711e-a365-4041-b3c0-4cbb8e86a420	users	4cc324b0-8cd9-4d3f-b58f-766c28b1cfdf	insert	\N	2026-06-15 16:52:39.014428+00	\N	{"id": "4cc324b0-8cd9-4d3f-b58f-766c28b1cfdf", "nom": "Livreur 7", "role": "livreur", "email": "livreur7@dimed.dz", "is_active": "True", "created_at": "2026-06-15 16:52:39.014428+00:00", "updated_at": "2026-06-15 16:52:39.014428+00:00", "password_hash": "***", "is_email_verified": "True"}
86500038-402b-4bee-8530-74ce2a2def19	users	c2f4b76f-21f4-4c4e-9c0f-a0a3f9b8d981	insert	\N	2026-06-15 16:52:39.014428+00	\N	{"id": "c2f4b76f-21f4-4c4e-9c0f-a0a3f9b8d981", "nom": "Livreur 8", "role": "livreur", "email": "livreur8@dimed.dz", "is_active": "True", "created_at": "2026-06-15 16:52:39.014428+00:00", "updated_at": "2026-06-15 16:52:39.014428+00:00", "password_hash": "***", "is_email_verified": "True"}
3ae5506c-fcad-4b31-ad00-f23dc46523b4	commandes	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:28.275024+00	\N	{"id": "ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a", "statut": "creee", "created_at": "2026-06-15 16:53:28.275024+00:00", "updated_at": "2026-06-15 16:53:28.275024+00:00", "reference_id": "C00000063", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
43427e91-9194-4ce4-ac74-3f2bf95453bf	lignes_commande	78e566d8-5a6a-40f6-82d0-9e10858202b8	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:28.275024+00	\N	{"id": "78e566d8-5a6a-40f6-82d0-9e10858202b8", "verifie": "False", "created_at": "2026-06-15 16:53:28.275024+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:53:28.275024+00:00", "commande_id": "ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
506d0fe8-1eee-46a3-8387-f99dba4c9a03	lignes_commande	9e54c94b-2cff-469b-97e1-8deb561cdbb6	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:28.275024+00	\N	{"id": "9e54c94b-2cff-469b-97e1-8deb561cdbb6", "verifie": "False", "created_at": "2026-06-15 16:53:28.275024+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:53:28.275024+00:00", "commande_id": "ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
326329b2-04b9-43ca-af60-0fa0a8a3521f	commandes	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:28.367368+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:53:28.381385+00:00"}
82140fe6-8559-428e-83f7-637a24ca4e2a	factures	62097201-b302-4f98-a35f-2046c88d4d1c	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:28.367368+00	\N	{"id": "62097201-b302-4f98-a35f-2046c88d4d1c", "created_at": "2026-06-15 16:53:28.367368+00:00", "montant_ht": "852.58", "updated_at": "2026-06-15 16:53:28.367368+00:00", "commande_id": "ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a", "montant_ttc": "852.58", "reference_id": "F0000000035", "date_emission": "2026-06-15 16:53:28.424281+00:00"}
d88ea0c9-693e-4a23-867b-e46c553273b4	creances	83af5001-8f3b-4114-ae6e-d8c3253764be	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:28.367368+00	\N	{"id": "83af5001-8f3b-4114-ae6e-d8c3253764be", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:53:28.367368+00:00", "facture_id": "62097201-b302-4f98-a35f-2046c88d4d1c", "updated_at": "2026-06-15 16:53:28.367368+00:00", "montant_paye": "0", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
1f843ad3-cae2-4e6a-b29c-794e8c145af9	bons_livraison	ddb2231a-d0b4-4a8f-97d3-d5666ef8a459	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:28.367368+00	\N	{"id": "ddb2231a-d0b4-4a8f-97d3-d5666ef8a459", "code_barre": "BL00000035", "created_at": "2026-06-15 16:53:28.367368+00:00", "updated_at": "2026-06-15 16:53:28.367368+00:00", "commande_id": "ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a", "date_emission": "2026-06-15 16:53:28.424281+00:00"}
8ff0c180-6ef9-4377-97ed-7c1dc93d4fff	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:28.367368+00	{"stock_quantity": "62"}	{"stock_quantity": "60"}
6e891fd6-fdee-45b1-97b0-c44be7743a0f	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:28.367368+00	{"stock_quantity": "10"}	{"stock_quantity": "9"}
7169ee53-614c-42c3-ad40-e90e163da3b2	commandes	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:53:28.989448+00	{"preparateur_id": "None"}	{"preparateur_id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62"}
3104ee55-1393-4043-9e02-c1dfaa49e0a6	caddies_pool	802cd6c5-26bf-4d33-8599-a741f84c0a2c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:53:28.989448+00	{"is_available": "True", "current_commande_id": "None"}	{"is_available": "False", "current_commande_id": "ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a"}
e746e90e-dae6-488d-b080-a4117518f280	commandes	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:53:28.989448+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
14b830b1-8cca-48a7-affa-7c8680aa339e	lignes_commande	78e566d8-5a6a-40f6-82d0-9e10858202b8	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:53:29.105524+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "2"}
662c97cb-7908-40b6-be9c-60875bfe3041	lignes_commande	9e54c94b-2cff-469b-97e1-8deb561cdbb6	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:53:29.140303+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
ac4595ef-83f7-40c3-824d-527c427654f6	commandes	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:53:29.170657+00	{"visa_preparateur": "None"}	{"visa_preparateur": "Preparateur"}
ae29bb35-3d29-4108-9122-7cb3d2b210c1	commandes	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-15 16:53:29.170657+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
059d22ef-12d9-47f2-ad1f-cb0e16b3db4a	commandes	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:53:29.67046+00	{"camion_id": "None"}	{"camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7"}
db03e86f-4182-471a-9ad3-5b047fdc0a52	commandes	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:53:29.67046+00	{"feuille_route_id": "None"}	{"feuille_route_id": "5afebd2a-5d57-469b-8dc1-1aaa3a437189"}
7836434e-e800-4973-b136-82a0045fe85e	commandes	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:53:29.7234+00	{"statut": "en_verification"}	{"statut": "prete"}
4e21505d-5f09-4da4-907f-91f2140b2716	commandes	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:53:29.7234+00	{"nb_colis": "None", "visa_controleur": "None"}	{"nb_colis": "3", "visa_controleur": "Controleur"}
452ba3d1-cbb3-490b-b393-1c87503fe3a4	colis	a7abc6ba-6a76-44b3-a913-a0f834112305	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:53:29.7234+00	\N	{"id": "a7abc6ba-6a76-44b3-a913-a0f834112305", "numero": "CLS00000019", "statut": "etiquete", "created_at": "2026-06-15 16:53:29.723400+00:00", "updated_at": "2026-06-15 16:53:29.723400+00:00", "commande_id": "ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a", "index_colis": "1"}
4d84d06c-862f-463a-b437-fd9366ecb490	colis	f5d79986-28a7-407b-aed0-1a1748e7ce83	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:53:29.7234+00	\N	{"id": "f5d79986-28a7-407b-aed0-1a1748e7ce83", "numero": "CLS00000020", "statut": "etiquete", "created_at": "2026-06-15 16:53:29.723400+00:00", "updated_at": "2026-06-15 16:53:29.723400+00:00", "commande_id": "ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a", "index_colis": "2"}
a420c4f3-4e67-4283-b48f-1a8f2afcabe9	colis	6ccd2d70-222e-429b-ae44-12fdd922daaf	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-15 16:53:29.7234+00	\N	{"id": "6ccd2d70-222e-429b-ae44-12fdd922daaf", "numero": "CLS00000021", "statut": "etiquete", "created_at": "2026-06-15 16:53:29.723400+00:00", "updated_at": "2026-06-15 16:53:29.723400+00:00", "commande_id": "ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a", "index_colis": "3"}
68285a21-021e-44a7-a587-1b72e17a14a0	scans_colis	0dde3709-331d-4469-89e2-46f952ed1dd9	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:53:30.394262+00	\N	{"id": "0dde3709-331d-4469-89e2-46f952ed1dd9", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "a7abc6ba-6a76-44b3-a913-a0f834112305", "type_scan": "depot_pad", "created_at": "2026-06-15 16:53:30.394262+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-15 16:53:30.394262+00:00"}
ba138a6e-15ce-4c5c-adb7-8f19397e2c5e	colis	a7abc6ba-6a76-44b3-a913-a0f834112305	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:53:30.394262+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
e07b2e58-05d1-404e-8352-6f7cd65d4cd9	scans_colis	653477f1-ec95-4d45-94a0-0676d1a1f8a5	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:53:30.492521+00	\N	{"id": "653477f1-ec95-4d45-94a0-0676d1a1f8a5", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "f5d79986-28a7-407b-aed0-1a1748e7ce83", "type_scan": "depot_pad", "created_at": "2026-06-15 16:53:30.492521+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-15 16:53:30.492521+00:00"}
62e004d9-c41b-4db1-8522-1ca318e58a15	colis	f5d79986-28a7-407b-aed0-1a1748e7ce83	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:53:30.492521+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
d25d66f1-4088-48a4-8316-7e5efc9126ab	scans_colis	ee8ba5a0-ba29-4bd2-84c1-6e63e3daa158	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:53:30.529065+00	\N	{"id": "ee8ba5a0-ba29-4bd2-84c1-6e63e3daa158", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "6ccd2d70-222e-429b-ae44-12fdd922daaf", "type_scan": "depot_pad", "created_at": "2026-06-15 16:53:30.529065+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-15 16:53:30.529065+00:00"}
aa52cecf-5e23-4c80-a0d4-9606fc3b52bf	colis	6ccd2d70-222e-429b-ae44-12fdd922daaf	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-15 16:53:30.529065+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
511c3d4e-024b-40da-b98e-f3f08ba208f5	commandes	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-16 21:30:49.163335+00	{"nb_colis": "None", "visa_controleur": "None"}	{"nb_colis": "3", "visa_controleur": "Controleur"}
f69491f5-6f33-4318-aff6-71b2d77a9895	scans_colis	d2cc8636-6dd5-4005-a039-fcf7ebd2cd6b	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.073454+00	\N	{"id": "d2cc8636-6dd5-4005-a039-fcf7ebd2cd6b", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "a7abc6ba-6a76-44b3-a913-a0f834112305", "type_scan": "chargement", "created_at": "2026-06-15 16:53:31.073454+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:53:31.073454+00:00"}
cda294f9-3e07-400b-a5db-bc5ed7349ba7	colis	a7abc6ba-6a76-44b3-a913-a0f834112305	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.073454+00	{"statut": "sur_pad"}	{"statut": "charge"}
56e2b605-42db-4bd3-8cba-8ded7a665e06	scans_colis	7c140737-e7ce-4b64-bebf-c92c7073c3b6	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.155409+00	\N	{"id": "7c140737-e7ce-4b64-bebf-c92c7073c3b6", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "f5d79986-28a7-407b-aed0-1a1748e7ce83", "type_scan": "chargement", "created_at": "2026-06-15 16:53:31.155409+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:53:31.155409+00:00"}
e6a9fb68-f7a4-4197-a5c0-bb946574d6ae	colis	f5d79986-28a7-407b-aed0-1a1748e7ce83	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.155409+00	{"statut": "sur_pad"}	{"statut": "charge"}
eb6c0d6e-2348-4ed5-af56-2c3775a28120	scans_colis	e8645937-7974-40db-9cf7-29a184a540cb	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.210023+00	\N	{"id": "e8645937-7974-40db-9cf7-29a184a540cb", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "6ccd2d70-222e-429b-ae44-12fdd922daaf", "type_scan": "chargement", "created_at": "2026-06-15 16:53:31.210023+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:53:31.210023+00:00"}
2c366abc-6b21-4e9e-960e-79315328f063	colis	6ccd2d70-222e-429b-ae44-12fdd922daaf	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.210023+00	{"statut": "sur_pad"}	{"statut": "charge"}
53ad3836-bcf1-4be8-8ff0-05ec902eb6d4	commandes	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.35922+00	{"statut": "prete"}	{"statut": "en_route"}
e8d8900c-2d97-4df7-83a8-15a846bb93ae	scans_colis	d0382182-bf97-4e03-a0f7-0ce2bd1478a0	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.402926+00	\N	{"id": "d0382182-bf97-4e03-a0f7-0ce2bd1478a0", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "a7abc6ba-6a76-44b3-a913-a0f834112305", "type_scan": "livraison", "created_at": "2026-06-15 16:53:31.402926+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:53:31.402926+00:00"}
ad416235-da24-4f38-bcbc-63bc2a681037	colis	a7abc6ba-6a76-44b3-a913-a0f834112305	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.402926+00	{"statut": "charge"}	{"statut": "livre"}
9896e896-2e2d-4467-bb34-37a28553cbb4	scans_colis	95880cd6-a3da-4f49-b8a6-18a4c9c9fd17	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.449946+00	\N	{"id": "95880cd6-a3da-4f49-b8a6-18a4c9c9fd17", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "f5d79986-28a7-407b-aed0-1a1748e7ce83", "type_scan": "livraison", "created_at": "2026-06-15 16:53:31.449946+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:53:31.449946+00:00"}
07b7daad-df72-47ad-82cb-5d9f53005402	colis	f5d79986-28a7-407b-aed0-1a1748e7ce83	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.449946+00	{"statut": "charge"}	{"statut": "livre"}
2a3db1d3-b707-4857-903e-a2390199e538	scans_colis	91546ad0-5bd9-47e3-99f4-91c6ad878eec	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.491684+00	\N	{"id": "91546ad0-5bd9-47e3-99f4-91c6ad878eec", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "6ccd2d70-222e-429b-ae44-12fdd922daaf", "type_scan": "livraison", "created_at": "2026-06-15 16:53:31.491684+00:00", "pad_tir_id": "None", "updated_at": "2026-06-15 16:53:31.491684+00:00"}
0e320da0-32bb-48b4-b4a6-eff10fbf7be7	colis	6ccd2d70-222e-429b-ae44-12fdd922daaf	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:31.491684+00	{"statut": "charge"}	{"statut": "livre"}
bab0bf3c-106b-4cdb-b3af-66f76252b3a2	commandes	453dcf46-2d66-4bd3-b62d-7fb36a3effc4	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:37.187753+00	\N	{"id": "453dcf46-2d66-4bd3-b62d-7fb36a3effc4", "statut": "creee", "created_at": "2026-06-15 16:53:37.187753+00:00", "updated_at": "2026-06-15 16:53:37.187753+00:00", "reference_id": "C00000064", "montant_total": "397.00", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
68b9d646-8d16-4829-a262-6a65785db45a	lignes_commande	ca9ba7f0-166a-4f58-a63d-de08076cee9b	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:37.187753+00	\N	{"id": "ca9ba7f0-166a-4f58-a63d-de08076cee9b", "verifie": "False", "created_at": "2026-06-15 16:53:37.187753+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:53:37.187753+00:00", "commande_id": "453dcf46-2d66-4bd3-b62d-7fb36a3effc4", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
ac8d7b78-6ddc-4e31-9a1b-8684a6a74ec0	commandes	2fc0b24c-d935-4eac-9157-8563b3a8f368	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:38.572381+00	\N	{"id": "2fc0b24c-d935-4eac-9157-8563b3a8f368", "statut": "creee", "created_at": "2026-06-15 16:53:38.572381+00:00", "updated_at": "2026-06-15 16:53:38.572381+00:00", "reference_id": "C00000065", "montant_total": "397.00", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
bcfd7206-da92-4fa5-9fe2-35f94bd1f464	lignes_commande	02120740-d579-4d16-b8ff-c08751aaf4c6	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:38.572381+00	\N	{"id": "02120740-d579-4d16-b8ff-c08751aaf4c6", "verifie": "False", "created_at": "2026-06-15 16:53:38.572381+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:53:38.572381+00:00", "commande_id": "2fc0b24c-d935-4eac-9157-8563b3a8f368", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
a30cd74e-42f9-4b83-ac93-b7cc84ade899	lignes_commande	02120740-d579-4d16-b8ff-c08751aaf4c6	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:38.610511+00	{"qte_demandee": "2"}	{"qte_demandee": "5"}
96023c29-a428-47cc-a1c8-2ecbda16b349	commandes	2fc0b24c-d935-4eac-9157-8563b3a8f368	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:38.610511+00	{"montant_total": "397.00"}	{"montant_total": "992.50"}
48c29d6b-1882-4567-9ef8-3f226d76b5c6	lignes_commande	c9a24c2f-fde5-4fe8-810e-b59e4591bcd5	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:38.652096+00	\N	{"id": "c9a24c2f-fde5-4fe8-810e-b59e4591bcd5", "verifie": "False", "created_at": "2026-06-15 16:53:38.652096+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:53:38.652096+00:00", "commande_id": "2fc0b24c-d935-4eac-9157-8563b3a8f368", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
f1e9df31-d148-4c63-826c-f789c5b605b4	commandes	2fc0b24c-d935-4eac-9157-8563b3a8f368	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:38.652096+00	{"montant_total": "992.50"}	{"lignes": "<app.models.commande.LigneCommande object at 0x000001E282D04410>", "montant_total": "1448.08"}
574c6fbb-ed42-4164-ab46-98bae6815b0e	commandes	2fc0b24c-d935-4eac-9157-8563b3a8f368	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:38.69785+00	{"lignes": "<app.models.commande.LigneCommande object at 0x000001E282D04E60>", "montant_total": "1448.08"}	{"montant_total": "992.50"}
22a9f26c-c84f-4164-aa11-6508dba2951f	lignes_commande	c9a24c2f-fde5-4fe8-810e-b59e4591bcd5	delete	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:38.69785+00	{"id": "c9a24c2f-fde5-4fe8-810e-b59e4591bcd5", "exp": "None", "fab": "None", "ppa": "None", "n_lot": "None", "verifie": "False", "remise_pct": "0.00", "commande_id": "2fc0b24c-d935-4eac-9157-8563b3a8f368", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "qte_prelevee": "None", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}	\N
cb1393a9-4dc8-4c54-bb15-6f60d2222ae2	commandes	d9a2e9ba-5d30-42c9-a776-f05e2ba3c181	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:40.012486+00	\N	{"id": "d9a2e9ba-5d30-42c9-a776-f05e2ba3c181", "statut": "creee", "created_at": "2026-06-15 16:53:40.012486+00:00", "updated_at": "2026-06-15 16:53:40.012486+00:00", "reference_id": "C00000066", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
4bdb87a2-ca71-4b9c-8917-e05814277ca9	feuilles_route	1685895d-2865-4d2b-b8ae-d58fa87793e5	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-16 21:30:49.028343+00	\N	{"id": "1685895d-2865-4d2b-b8ae-d58fa87793e5", "date": "2026-06-16", "camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7", "compteurs": "{'colis_std': 0, 'sachets_std': 0, 'colis_frg': 0, 'sachets_frg': 0}", "created_at": "2026-06-16 21:30:49.028343+00:00", "updated_at": "2026-06-16 21:30:49.028343+00:00", "chargement_valide": "False"}
584fc78c-6f2a-4764-9aa0-2a9f6c1014dc	lignes_commande	a2733797-c0ab-4409-8ca0-8d439f636017	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:40.012486+00	\N	{"id": "a2733797-c0ab-4409-8ca0-8d439f636017", "verifie": "False", "created_at": "2026-06-15 16:53:40.012486+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:53:40.012486+00:00", "commande_id": "d9a2e9ba-5d30-42c9-a776-f05e2ba3c181", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
42914347-385c-4fe1-b413-c44bf74b2ede	commandes	d9a2e9ba-5d30-42c9-a776-f05e2ba3c181	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:40.060369+00	{"statut": "creee"}	{"statut": "annulee"}
acfd2435-0f44-4ac2-97e4-490f99eec736	commandes	1c82273c-17f9-46c1-984b-ba0d11ce9022	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:41.444322+00	\N	{"id": "1c82273c-17f9-46c1-984b-ba0d11ce9022", "statut": "creee", "created_at": "2026-06-15 16:53:41.444322+00:00", "updated_at": "2026-06-15 16:53:41.444322+00:00", "reference_id": "C00000067", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
ade758f4-4d8e-424d-8e27-30e7450c938f	lignes_commande	1824862c-ee51-4488-b937-e59607e53d6a	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:41.444322+00	\N	{"id": "1824862c-ee51-4488-b937-e59607e53d6a", "verifie": "False", "created_at": "2026-06-15 16:53:41.444322+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:53:41.444322+00:00", "commande_id": "1c82273c-17f9-46c1-984b-ba0d11ce9022", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
6c24a618-bd0c-4367-9e42-5835d650452e	commandes	1c82273c-17f9-46c1-984b-ba0d11ce9022	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:41.885247+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:53:41.893898+00:00"}
309ca26e-9385-4194-9f86-e340095123e0	factures	592ba8bd-ebfa-4cf4-9ecb-eaf0c4f95369	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:41.885247+00	\N	{"id": "592ba8bd-ebfa-4cf4-9ecb-eaf0c4f95369", "created_at": "2026-06-15 16:53:41.885247+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 16:53:41.885247+00:00", "commande_id": "1c82273c-17f9-46c1-984b-ba0d11ce9022", "montant_ttc": "198.50", "reference_id": "F0000000036", "date_emission": "2026-06-15 16:53:41.917583+00:00"}
be773303-733c-4649-8600-c612abdcd9c7	creances	7b0b5387-9832-4f75-b50b-fed1b6db5aa9	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:41.885247+00	\N	{"id": "7b0b5387-9832-4f75-b50b-fed1b6db5aa9", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:53:41.885247+00:00", "facture_id": "592ba8bd-ebfa-4cf4-9ecb-eaf0c4f95369", "updated_at": "2026-06-15 16:53:41.885247+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
a6f33136-4806-4354-bcf7-5489f05d560a	bons_livraison	aa31c5d6-6d13-4cc3-839d-da814a703d05	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:41.885247+00	\N	{"id": "aa31c5d6-6d13-4cc3-839d-da814a703d05", "code_barre": "BL00000036", "created_at": "2026-06-15 16:53:41.885247+00:00", "updated_at": "2026-06-15 16:53:41.885247+00:00", "commande_id": "1c82273c-17f9-46c1-984b-ba0d11ce9022", "date_emission": "2026-06-15 16:53:41.917583+00:00"}
48dcb6f4-1cb2-4089-b253-a72fa6917d35	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:41.885247+00	{"stock_quantity": "60"}	{"stock_quantity": "59"}
4aca43d6-1b55-4dba-bc92-f8afe918225a	commandes	e19fd8f0-1dc2-4dba-ab94-bd32bb9fc2c5	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:43.832536+00	\N	{"id": "e19fd8f0-1dc2-4dba-ab94-bd32bb9fc2c5", "statut": "creee", "created_at": "2026-06-15 16:53:43.832536+00:00", "updated_at": "2026-06-15 16:53:43.832536+00:00", "reference_id": "C00000068", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
5cbd85fc-4a53-4cae-bf74-0a3b827abaa9	lignes_commande	4d93b7d6-56e3-410f-b25c-d22a399cdc38	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:43.832536+00	\N	{"id": "4d93b7d6-56e3-410f-b25c-d22a399cdc38", "verifie": "False", "created_at": "2026-06-15 16:53:43.832536+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:53:43.832536+00:00", "commande_id": "e19fd8f0-1dc2-4dba-ab94-bd32bb9fc2c5", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
378c1de3-acd3-4786-9aba-218e7f1a2c76	commandes	e19fd8f0-1dc2-4dba-ab94-bd32bb9fc2c5	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:43.880048+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:53:43.890221+00:00"}
fbc5196b-8dd8-4055-88d4-51709bca5788	factures	7e944020-3254-4f86-b8f9-3b34636f65b7	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:43.880048+00	\N	{"id": "7e944020-3254-4f86-b8f9-3b34636f65b7", "created_at": "2026-06-15 16:53:43.880048+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 16:53:43.880048+00:00", "commande_id": "e19fd8f0-1dc2-4dba-ab94-bd32bb9fc2c5", "montant_ttc": "198.50", "reference_id": "F0000000037", "date_emission": "2026-06-15 16:53:43.915662+00:00"}
1697cfcf-955c-4326-ac90-795c63f8bac2	creances	fff05989-44b3-458a-a0e3-8dc0504f0fe4	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:43.880048+00	\N	{"id": "fff05989-44b3-458a-a0e3-8dc0504f0fe4", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:53:43.880048+00:00", "facture_id": "7e944020-3254-4f86-b8f9-3b34636f65b7", "updated_at": "2026-06-15 16:53:43.880048+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
6dccb224-eb32-44ef-9c41-399d2880f426	bons_livraison	6966e1ff-f62c-4de7-a93a-ae071793d656	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:43.880048+00	\N	{"id": "6966e1ff-f62c-4de7-a93a-ae071793d656", "code_barre": "BL00000037", "created_at": "2026-06-15 16:53:43.880048+00:00", "updated_at": "2026-06-15 16:53:43.880048+00:00", "commande_id": "e19fd8f0-1dc2-4dba-ab94-bd32bb9fc2c5", "date_emission": "2026-06-15 16:53:43.915662+00:00"}
db46dead-e3ce-4752-9271-fd0e3ff4110b	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:43.880048+00	{"stock_quantity": "59"}	{"stock_quantity": "58"}
aca27702-174c-4e1a-aedc-b1a4ed39c506	commandes	5b7c805d-1652-4f86-997e-88a6cedb2195	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:45.365555+00	\N	{"id": "5b7c805d-1652-4f86-997e-88a6cedb2195", "statut": "creee", "created_at": "2026-06-15 16:53:45.365555+00:00", "updated_at": "2026-06-15 16:53:45.365555+00:00", "reference_id": "C00000069", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
186221ad-2e38-441e-84cf-8caa25228923	lignes_commande	7de443ae-f517-4429-8f0f-64b78c44dcee	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:45.365555+00	\N	{"id": "7de443ae-f517-4429-8f0f-64b78c44dcee", "verifie": "False", "created_at": "2026-06-15 16:53:45.365555+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:53:45.365555+00:00", "commande_id": "5b7c805d-1652-4f86-997e-88a6cedb2195", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
55311eea-e2dd-4917-ba47-eafe3146299a	commandes	5b7c805d-1652-4f86-997e-88a6cedb2195	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:45.403524+00	{"operatrice_comment": "None"}	{"operatrice_comment": "Quantité erronée, merci de corriger la ligne 1"}
66f6b186-fb2f-4c60-aab4-b1e6322e29d9	commandes	5b7c805d-1652-4f86-997e-88a6cedb2195	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:45.454935+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-15 16:53:45.464283+00:00"}
910bb549-9f06-4a64-a670-8fa416c54fd5	factures	e5c33d2f-432b-40f7-b114-67acaa6062fe	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:45.454935+00	\N	{"id": "e5c33d2f-432b-40f7-b114-67acaa6062fe", "created_at": "2026-06-15 16:53:45.454935+00:00", "montant_ht": "198.50", "updated_at": "2026-06-15 16:53:45.454935+00:00", "commande_id": "5b7c805d-1652-4f86-997e-88a6cedb2195", "montant_ttc": "198.50", "reference_id": "F0000000038", "date_emission": "2026-06-15 16:53:45.483194+00:00"}
25bfe879-b4e7-4afd-8bc4-0717378c9da8	creances	19e840a9-94e1-4dd1-b54b-e0aaf6fa811a	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:45.454935+00	\N	{"id": "19e840a9-94e1-4dd1-b54b-e0aaf6fa811a", "statut": "en_attente", "echeance": "2026-07-15", "created_at": "2026-06-15 16:53:45.454935+00:00", "facture_id": "e5c33d2f-432b-40f7-b114-67acaa6062fe", "updated_at": "2026-06-15 16:53:45.454935+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
d6424eea-999d-467c-a727-4873156597af	bons_livraison	b018d880-19c7-4c76-a240-de75d09a1fb6	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:45.454935+00	\N	{"id": "b018d880-19c7-4c76-a240-de75d09a1fb6", "code_barre": "BL00000038", "created_at": "2026-06-15 16:53:45.454935+00:00", "updated_at": "2026-06-15 16:53:45.454935+00:00", "commande_id": "5b7c805d-1652-4f86-997e-88a6cedb2195", "date_emission": "2026-06-15 16:53:45.483194+00:00"}
41a53264-fed0-4736-bb84-05a1f13f60e5	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-15 16:53:45.454935+00	{"stock_quantity": "58"}	{"stock_quantity": "57"}
a32c5f52-06a7-42e9-84eb-cbfa3d763ca6	commandes	84f1e647-a353-47f8-9bdf-ee221e62ca60	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:46.915217+00	\N	{"id": "84f1e647-a353-47f8-9bdf-ee221e62ca60", "statut": "creee", "created_at": "2026-06-15 16:53:46.915217+00:00", "updated_at": "2026-06-15 16:53:46.915217+00:00", "reference_id": "C00000070", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
222527fb-ce1e-491d-ae50-db73606051cc	lignes_commande	1231efcc-bf96-44be-9438-30b648e1de4c	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:46.915217+00	\N	{"id": "1231efcc-bf96-44be-9438-30b648e1de4c", "verifie": "False", "created_at": "2026-06-15 16:53:46.915217+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:53:46.915217+00:00", "commande_id": "84f1e647-a353-47f8-9bdf-ee221e62ca60", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
b91c7704-729d-45c5-9c8e-daf0953d0f6b	commandes	d24acb48-0718-4829-a4ed-fe14a7802da7	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:49.849639+00	\N	{"id": "d24acb48-0718-4829-a4ed-fe14a7802da7", "statut": "creee", "created_at": "2026-06-15 16:53:49.849639+00:00", "updated_at": "2026-06-15 16:53:49.849639+00:00", "reference_id": "C00000071", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
0ac925f0-1d81-4f07-9ed0-111d5692779f	lignes_commande	8fb129ae-cc33-46ed-abba-8be5fe4c1b13	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-15 16:53:49.849639+00	\N	{"id": "8fb129ae-cc33-46ed-abba-8be5fe4c1b13", "verifie": "False", "created_at": "2026-06-15 16:53:49.849639+00:00", "remise_pct": "0.00", "updated_at": "2026-06-15 16:53:49.849639+00:00", "commande_id": "d24acb48-0718-4829-a4ed-fe14a7802da7", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
ad3ad6ef-ff63-4044-997e-175aeed4a0d8	commandes	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:47.175998+00	\N	{"id": "0753f63f-0ee0-4048-8dcb-9622d2bcf2b3", "statut": "creee", "created_at": "2026-06-16 21:30:47.175998+00:00", "updated_at": "2026-06-16 21:30:47.175998+00:00", "reference_id": "C00000072", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
e7febf05-9c2a-4e36-9f7e-57f49812686f	lignes_commande	e3017d8f-da9f-4686-9b18-5fc733ace430	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:47.175998+00	\N	{"id": "e3017d8f-da9f-4686-9b18-5fc733ace430", "verifie": "False", "created_at": "2026-06-16 21:30:47.175998+00:00", "remise_pct": "0.00", "updated_at": "2026-06-16 21:30:47.175998+00:00", "commande_id": "0753f63f-0ee0-4048-8dcb-9622d2bcf2b3", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
cb77d9a6-e267-4c02-984d-823902c58373	lignes_commande	ba2b039e-1b1a-4020-b8ea-ed1c7e684d29	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:47.175998+00	\N	{"id": "ba2b039e-1b1a-4020-b8ea-ed1c7e684d29", "verifie": "False", "created_at": "2026-06-16 21:30:47.175998+00:00", "remise_pct": "0.00", "updated_at": "2026-06-16 21:30:47.175998+00:00", "commande_id": "0753f63f-0ee0-4048-8dcb-9622d2bcf2b3", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
4cd2c277-966d-481e-ab3b-9a165216082f	commandes	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:47.31459+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-16 21:30:47.331255+00:00"}
f1d7cd6b-9cb9-4bdf-8d1a-d140e7b3b908	factures	efad879a-e5af-42e3-83ca-594ca5b5fbfd	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:47.31459+00	\N	{"id": "efad879a-e5af-42e3-83ca-594ca5b5fbfd", "created_at": "2026-06-16 21:30:47.314590+00:00", "montant_ht": "852.58", "updated_at": "2026-06-16 21:30:47.314590+00:00", "commande_id": "0753f63f-0ee0-4048-8dcb-9622d2bcf2b3", "montant_ttc": "852.58", "reference_id": "F0000000039", "date_emission": "2026-06-16 21:30:47.383171+00:00"}
c28305ea-2269-4c24-82c4-7dc101a2d9e9	creances	3a11a80e-d7b2-4b12-9585-03b5cb752071	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:47.31459+00	\N	{"id": "3a11a80e-d7b2-4b12-9585-03b5cb752071", "statut": "en_attente", "echeance": "2026-07-16", "created_at": "2026-06-16 21:30:47.314590+00:00", "facture_id": "efad879a-e5af-42e3-83ca-594ca5b5fbfd", "updated_at": "2026-06-16 21:30:47.314590+00:00", "montant_paye": "0", "montant_total": "852.58", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
f53db9e1-d1a4-43a3-a775-4b467e32ab2d	bons_livraison	c514330f-a18f-4733-b04f-a532e82f72da	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:47.31459+00	\N	{"id": "c514330f-a18f-4733-b04f-a532e82f72da", "code_barre": "BL00000039", "created_at": "2026-06-16 21:30:47.314590+00:00", "updated_at": "2026-06-16 21:30:47.314590+00:00", "commande_id": "0753f63f-0ee0-4048-8dcb-9622d2bcf2b3", "date_emission": "2026-06-16 21:30:47.383171+00:00"}
05a3b841-c7af-4620-b6ca-07bca03240e2	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:47.31459+00	{"stock_quantity": "57"}	{"stock_quantity": "55"}
5af09745-624b-4588-80db-5289ec15b45d	medicaments	592e33a9-acd2-410c-81f2-6cb3f8f17298	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:47.31459+00	{"stock_quantity": "9"}	{"stock_quantity": "8"}
51de5203-c827-40a6-8614-a1a9742315bb	caddies_pool	802cd6c5-26bf-4d33-8599-a741f84c0a2c	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-16 21:30:48.189877+00	{"is_available": "True", "current_commande_id": "None"}	{"is_available": "False", "current_commande_id": "0753f63f-0ee0-4048-8dcb-9622d2bcf2b3"}
ef651215-cad8-4090-a0fc-e3b902fcfe4d	commandes	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-16 21:30:48.189877+00	{"preparateur_id": "None"}	{"preparateur_id": "3fce8dc2-16e0-4ce6-b41c-c0657216eb62"}
646782e1-6106-4f9f-bab3-71bb0893a982	commandes	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-16 21:30:48.189877+00	{"statut": "acceptee"}	{"statut": "en_preparation"}
e3012236-98b6-4519-84f2-6d548a524dd5	lignes_commande	e3017d8f-da9f-4686-9b18-5fc733ace430	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-16 21:30:48.312222+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "2"}
75a670f1-7ad8-49e2-8392-621371b79ab5	lignes_commande	ba2b039e-1b1a-4020-b8ea-ed1c7e684d29	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-16 21:30:48.368152+00	{"verifie": "False", "qte_prelevee": "None"}	{"verifie": "True", "qte_prelevee": "1"}
a59b89eb-c84c-420e-a614-b7e0eb91f10f	commandes	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-16 21:30:48.404165+00	{"visa_preparateur": "None"}	{"visa_preparateur": "Preparateur"}
2c21f989-d73b-413b-9663-a9024f2e9730	commandes	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	update	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	2026-06-16 21:30:48.404165+00	{"statut": "en_preparation"}	{"statut": "en_verification"}
8191fe7b-00bb-49c7-b62b-c94ec0a05ede	commandes	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-16 21:30:49.028343+00	{"camion_id": "None"}	{"camion_id": "0450c96e-c43b-47f9-bdd3-08e5a62b1ae7"}
d29da242-a4ff-4130-ae55-75b9b8aeb29b	commandes	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	update	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-16 21:30:49.028343+00	{"feuille_route_id": "None"}	{"feuille_route_id": "1685895d-2865-4d2b-b8ae-d58fa87793e5"}
96208084-46da-4156-b682-8ba9d338e54b	colis	058f7ef6-861a-4131-ba7e-bae8c323bc91	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-16 21:30:49.163335+00	\N	{"id": "058f7ef6-861a-4131-ba7e-bae8c323bc91", "numero": "CLS00000022", "statut": "etiquete", "created_at": "2026-06-16 21:30:49.163335+00:00", "updated_at": "2026-06-16 21:30:49.163335+00:00", "commande_id": "0753f63f-0ee0-4048-8dcb-9622d2bcf2b3", "index_colis": "1"}
d0eeb15e-bfaa-47b6-bde6-9e7e4c5f4dd9	colis	ee6013e2-ec6b-47ff-bc1b-1aa46d001038	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-16 21:30:49.163335+00	\N	{"id": "ee6013e2-ec6b-47ff-bc1b-1aa46d001038", "numero": "CLS00000023", "statut": "etiquete", "created_at": "2026-06-16 21:30:49.163335+00:00", "updated_at": "2026-06-16 21:30:49.163335+00:00", "commande_id": "0753f63f-0ee0-4048-8dcb-9622d2bcf2b3", "index_colis": "2"}
1fa69d1d-6dee-4eec-8822-167741f44ea5	colis	585ea26a-fbe9-4106-8487-79ce19db4c79	insert	aec28fb7-8dfb-4781-b2b0-932d1a9e891d	2026-06-16 21:30:49.163335+00	\N	{"id": "585ea26a-fbe9-4106-8487-79ce19db4c79", "numero": "CLS00000024", "statut": "etiquete", "created_at": "2026-06-16 21:30:49.163335+00:00", "updated_at": "2026-06-16 21:30:49.163335+00:00", "commande_id": "0753f63f-0ee0-4048-8dcb-9622d2bcf2b3", "index_colis": "3"}
ab9c8f31-7fa9-41fe-b2dc-4a750f52784c	scans_colis	a05a723a-b127-4452-bf07-fcfe5991d56e	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-16 21:30:50.243731+00	\N	{"id": "a05a723a-b127-4452-bf07-fcfe5991d56e", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "585ea26a-fbe9-4106-8487-79ce19db4c79", "type_scan": "depot_pad", "created_at": "2026-06-16 21:30:50.243731+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-16 21:30:50.243731+00:00"}
5a671c05-a9c0-456b-a311-bab0efdcc2cf	colis	585ea26a-fbe9-4106-8487-79ce19db4c79	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-16 21:30:50.243731+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
733331a8-2e00-4855-8dec-9cd67065c300	scans_colis	2d24053c-9e8a-4a33-a141-c5d021f57f0e	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.073653+00	\N	{"id": "2d24053c-9e8a-4a33-a141-c5d021f57f0e", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "585ea26a-fbe9-4106-8487-79ce19db4c79", "type_scan": "chargement", "created_at": "2026-06-16 21:30:51.073653+00:00", "pad_tir_id": "None", "updated_at": "2026-06-16 21:30:51.073653+00:00"}
2d93211b-b105-4470-a921-b72668cab37b	colis	585ea26a-fbe9-4106-8487-79ce19db4c79	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.073653+00	{"statut": "sur_pad"}	{"statut": "charge"}
e50b2b5f-1a37-4071-b847-7790fdc9565d	commandes	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.073653+00	{"statut": "prete"}	{"statut": "en_route"}
e4de5568-49d9-4d78-b60e-1aae9cd5964a	feuilles_route	1685895d-2865-4d2b-b8ae-d58fa87793e5	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.164444+00	{"chargement_valide": "False"}	{"chargement_valide": "True"}
081d5db6-7aec-4967-9f1c-867a6a794562	feuilles_route	1685895d-2865-4d2b-b8ae-d58fa87793e5	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.223299+00	{"signature_chauffeur": "***"}	{"signature_chauffeur": "***"}
14a0986e-348c-413f-a185-8bc28b3a0546	scans_colis	0f1b60dc-c430-46a1-bf5f-62d495c6cb89	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.279256+00	\N	{"id": "0f1b60dc-c430-46a1-bf5f-62d495c6cb89", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "058f7ef6-861a-4131-ba7e-bae8c323bc91", "type_scan": "livraison", "created_at": "2026-06-16 21:30:51.279256+00:00", "pad_tir_id": "None", "updated_at": "2026-06-16 21:30:51.279256+00:00"}
b6f2c533-5147-41d6-a4ac-7fc266807274	colis	058f7ef6-861a-4131-ba7e-bae8c323bc91	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.279256+00	{"statut": "charge"}	{"statut": "livre"}
be14b05e-e1fe-498e-a579-4e0b0afff6fc	scans_colis	da92f0ac-b05e-4fe7-b320-e8e09dabcbeb	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.331775+00	\N	{"id": "da92f0ac-b05e-4fe7-b320-e8e09dabcbeb", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "ee6013e2-ec6b-47ff-bc1b-1aa46d001038", "type_scan": "livraison", "created_at": "2026-06-16 21:30:51.331775+00:00", "pad_tir_id": "None", "updated_at": "2026-06-16 21:30:51.331775+00:00"}
9a312f4c-6214-4fe0-bcdc-9e52f2bfb758	colis	ee6013e2-ec6b-47ff-bc1b-1aa46d001038	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.331775+00	{"statut": "charge"}	{"statut": "livre"}
f2eb06d3-55f1-4a83-b74f-d241e8c29300	scans_colis	47c500e0-b897-4e55-a6d9-6f1432408d21	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.373024+00	\N	{"id": "47c500e0-b897-4e55-a6d9-6f1432408d21", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "585ea26a-fbe9-4106-8487-79ce19db4c79", "type_scan": "livraison", "created_at": "2026-06-16 21:30:51.373024+00:00", "pad_tir_id": "None", "updated_at": "2026-06-16 21:30:51.373024+00:00"}
9de83cef-3f5a-461c-a450-bbdd0084175a	colis	585ea26a-fbe9-4106-8487-79ce19db4c79	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.373024+00	{"statut": "charge"}	{"statut": "livre"}
3229875c-dbf3-4756-9a7e-2909a50337a5	commandes	92980492-7923-4866-89ef-216fcebc8722	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:07.737096+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-16 21:31:07.752910+00:00"}
112075e3-e7cb-411d-b7ad-b40e0b2af2cb	factures	9b6dac7f-b2f8-4b03-b536-bc3cd769c8a9	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:07.737096+00	\N	{"id": "9b6dac7f-b2f8-4b03-b536-bc3cd769c8a9", "created_at": "2026-06-16 21:31:07.737096+00:00", "montant_ht": "198.50", "updated_at": "2026-06-16 21:31:07.737096+00:00", "commande_id": "92980492-7923-4866-89ef-216fcebc8722", "montant_ttc": "198.50", "reference_id": "F0000000040", "date_emission": "2026-06-16 21:31:07.800041+00:00"}
2a858a95-acb4-47ec-99c2-6ef625b0377f	creances	fc481d8f-02f3-4a55-9d0b-f3dd7efc2381	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:07.737096+00	\N	{"id": "fc481d8f-02f3-4a55-9d0b-f3dd7efc2381", "statut": "en_attente", "echeance": "2026-07-16", "created_at": "2026-06-16 21:31:07.737096+00:00", "facture_id": "9b6dac7f-b2f8-4b03-b536-bc3cd769c8a9", "updated_at": "2026-06-16 21:31:07.737096+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
8f21be15-e77a-4468-a7c4-24cd09dcdd38	bons_livraison	40638a0b-0326-4017-9452-14f3248c57ba	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:07.737096+00	\N	{"id": "40638a0b-0326-4017-9452-14f3248c57ba", "code_barre": "BL00000040", "created_at": "2026-06-16 21:31:07.737096+00:00", "updated_at": "2026-06-16 21:31:07.737096+00:00", "commande_id": "92980492-7923-4866-89ef-216fcebc8722", "date_emission": "2026-06-16 21:31:07.800041+00:00"}
533ef07a-a908-47f3-8aab-bc02c96ab433	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:07.737096+00	{"stock_quantity": "55"}	{"stock_quantity": "54"}
4fd91421-f7f9-4c31-9479-1fc46bdc67ee	scans_colis	4b7c80b1-1de8-4407-9d26-6526dcef578f	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-16 21:30:50.062605+00	\N	{"id": "4b7c80b1-1de8-4407-9d26-6526dcef578f", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "058f7ef6-861a-4131-ba7e-bae8c323bc91", "type_scan": "depot_pad", "created_at": "2026-06-16 21:30:50.062605+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-16 21:30:50.062605+00:00"}
664e4d2d-d854-45d3-8cd3-7aefe070c5ab	colis	058f7ef6-861a-4131-ba7e-bae8c323bc91	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-16 21:30:50.062605+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
30cd2ec5-9737-459b-896e-07f29feefe9d	scans_colis	9457b165-8440-43a3-baac-539547efd661	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-16 21:30:50.187503+00	\N	{"id": "9457b165-8440-43a3-baac-539547efd661", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "ee6013e2-ec6b-47ff-bc1b-1aa46d001038", "type_scan": "depot_pad", "created_at": "2026-06-16 21:30:50.187503+00:00", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb", "updated_at": "2026-06-16 21:30:50.187503+00:00"}
4410eda7-7a9c-43eb-85c5-dec607db03ca	colis	ee6013e2-ec6b-47ff-bc1b-1aa46d001038	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-16 21:30:50.187503+00	{"statut": "etiquete", "pad_tir_id": "None"}	{"statut": "sur_pad", "pad_tir_id": "391020b3-c3f0-43b6-814f-f1165e33b8fb"}
21579a71-7b3c-4d4e-a4c9-cafb93d98eb0	scans_colis	216015e8-c875-471d-ac5d-63b9a11ad1d0	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:50.949716+00	\N	{"id": "216015e8-c875-471d-ac5d-63b9a11ad1d0", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "058f7ef6-861a-4131-ba7e-bae8c323bc91", "type_scan": "chargement", "created_at": "2026-06-16 21:30:50.949716+00:00", "pad_tir_id": "None", "updated_at": "2026-06-16 21:30:50.949716+00:00"}
ae6b06a3-6369-404c-b238-08fc1b86aa68	colis	058f7ef6-861a-4131-ba7e-bae8c323bc91	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:50.949716+00	{"statut": "sur_pad"}	{"statut": "charge"}
d47052d9-bd73-4560-9fab-72dd3d4f5040	scans_colis	ad7c121e-4d9d-4016-ae19-2c7f9949d830	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.031995+00	\N	{"id": "ad7c121e-4d9d-4016-ae19-2c7f9949d830", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "ee6013e2-ec6b-47ff-bc1b-1aa46d001038", "type_scan": "chargement", "created_at": "2026-06-16 21:30:51.031995+00:00", "pad_tir_id": "None", "updated_at": "2026-06-16 21:30:51.031995+00:00"}
045707d8-a146-455c-98fb-d9565996908d	colis	ee6013e2-ec6b-47ff-bc1b-1aa46d001038	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.031995+00	{"statut": "sur_pad"}	{"statut": "charge"}
94c1fe94-5b22-403d-a49f-34443044281f	feuilles_route	1685895d-2865-4d2b-b8ae-d58fa87793e5	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:30:51.194318+00	{"signature_expedition": "***"}	{"signature_expedition": "***"}
c8b359f4-c6df-48a8-8bb8-d2d22f080ddb	commandes	5b1e91d7-c0c9-475f-93a8-8de762593946	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:00.838013+00	\N	{"id": "5b1e91d7-c0c9-475f-93a8-8de762593946", "statut": "creee", "created_at": "2026-06-16 21:31:00.838013+00:00", "updated_at": "2026-06-16 21:31:00.838013+00:00", "reference_id": "C00000073", "montant_total": "397.00", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
8e1fb9d6-8d53-4f61-9364-d23ae8c7f7af	lignes_commande	844942b2-1bd7-4fdb-a9a2-3826da37e521	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:00.838013+00	\N	{"id": "844942b2-1bd7-4fdb-a9a2-3826da37e521", "verifie": "False", "created_at": "2026-06-16 21:31:00.838013+00:00", "remise_pct": "0.00", "updated_at": "2026-06-16 21:31:00.838013+00:00", "commande_id": "5b1e91d7-c0c9-475f-93a8-8de762593946", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
a89382c5-7020-430f-a140-98198bd02d80	commandes	e2d05f89-d54e-4c4e-81b4-4fa08d44badc	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:02.934445+00	\N	{"id": "e2d05f89-d54e-4c4e-81b4-4fa08d44badc", "statut": "creee", "created_at": "2026-06-16 21:31:02.934445+00:00", "updated_at": "2026-06-16 21:31:02.934445+00:00", "reference_id": "C00000074", "montant_total": "397.00", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
8ec7a859-552f-49e3-8d8b-e48f495f83ef	lignes_commande	4d7f9e8c-297b-4b57-bd57-894c1467db25	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:02.934445+00	\N	{"id": "4d7f9e8c-297b-4b57-bd57-894c1467db25", "verifie": "False", "created_at": "2026-06-16 21:31:02.934445+00:00", "remise_pct": "0.00", "updated_at": "2026-06-16 21:31:02.934445+00:00", "commande_id": "e2d05f89-d54e-4c4e-81b4-4fa08d44badc", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "2", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
b66d2a93-5547-4143-b856-d30c8e3067ba	lignes_commande	4d7f9e8c-297b-4b57-bd57-894c1467db25	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:02.974685+00	{"qte_demandee": "2"}	{"qte_demandee": "5"}
f90a76ca-6585-486c-a2b8-00c938207f45	commandes	e2d05f89-d54e-4c4e-81b4-4fa08d44badc	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:02.974685+00	{"montant_total": "397.00"}	{"montant_total": "992.50"}
c0b29ab9-2abb-4963-8bb4-fa06202ae510	lignes_commande	72305eb5-0ded-4e65-9fd2-561debe00839	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:03.021209+00	\N	{"id": "72305eb5-0ded-4e65-9fd2-561debe00839", "verifie": "False", "created_at": "2026-06-16 21:31:03.021209+00:00", "remise_pct": "0.00", "updated_at": "2026-06-16 21:31:03.021209+00:00", "commande_id": "e2d05f89-d54e-4c4e-81b4-4fa08d44badc", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}
b15c3170-70ee-4688-bb82-6e73ccf4b71d	commandes	e2d05f89-d54e-4c4e-81b4-4fa08d44badc	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:03.021209+00	{"montant_total": "992.50"}	{"lignes": "<app.models.commande.LigneCommande object at 0x000001ECE767C230>", "montant_total": "1448.08"}
2ee4ccae-6aef-442e-aa22-7e3c40f6940c	commandes	e2d05f89-d54e-4c4e-81b4-4fa08d44badc	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:03.064467+00	{"lignes": "<app.models.commande.LigneCommande object at 0x000001ECE767D040>", "montant_total": "1448.08"}	{"montant_total": "992.50"}
e341d3e4-a696-42f4-9dba-d648939c23c8	lignes_commande	72305eb5-0ded-4e65-9fd2-561debe00839	delete	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:03.064467+00	{"id": "72305eb5-0ded-4e65-9fd2-561debe00839", "exp": "None", "fab": "None", "ppa": "None", "n_lot": "None", "verifie": "False", "remise_pct": "0.00", "commande_id": "e2d05f89-d54e-4c4e-81b4-4fa08d44badc", "designation": "AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH", "qte_demandee": "1", "qte_prelevee": "None", "medicament_id": "592e33a9-acd2-410c-81f2-6cb3f8f17298", "prix_unitaire": "455.58"}	\N
ffba7f57-be34-4dd0-a55c-37156b3b546b	commandes	0007eb5b-90a6-458f-b83f-1581a2c8245a	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:05.128306+00	\N	{"id": "0007eb5b-90a6-458f-b83f-1581a2c8245a", "statut": "creee", "created_at": "2026-06-16 21:31:05.128306+00:00", "updated_at": "2026-06-16 21:31:05.128306+00:00", "reference_id": "C00000075", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
eb04fedc-632d-46c9-9c39-8f54bebf5d99	lignes_commande	c8579d8c-8c7c-49ae-88c4-67b814d26d63	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:05.128306+00	\N	{"id": "c8579d8c-8c7c-49ae-88c4-67b814d26d63", "verifie": "False", "created_at": "2026-06-16 21:31:05.128306+00:00", "remise_pct": "0.00", "updated_at": "2026-06-16 21:31:05.128306+00:00", "commande_id": "0007eb5b-90a6-458f-b83f-1581a2c8245a", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
8a327e22-f4de-46cc-ac0e-05efdb62ccc1	commandes	0007eb5b-90a6-458f-b83f-1581a2c8245a	update	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:05.16546+00	{"statut": "creee"}	{"statut": "annulee"}
5bf93448-edc4-49a2-8b27-ff30ece52f99	commandes	92980492-7923-4866-89ef-216fcebc8722	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:07.168494+00	\N	{"id": "92980492-7923-4866-89ef-216fcebc8722", "statut": "creee", "created_at": "2026-06-16 21:31:07.168494+00:00", "updated_at": "2026-06-16 21:31:07.168494+00:00", "reference_id": "C00000076", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
b846238f-d180-488d-a2ba-b59fdba23a5b	lignes_commande	396a8870-6397-400f-8720-8576d1833228	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:07.168494+00	\N	{"id": "396a8870-6397-400f-8720-8576d1833228", "verifie": "False", "created_at": "2026-06-16 21:31:07.168494+00:00", "remise_pct": "0.00", "updated_at": "2026-06-16 21:31:07.168494+00:00", "commande_id": "92980492-7923-4866-89ef-216fcebc8722", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
49f40cb7-f5b7-44e7-8ea8-2db5a9e20c25	commandes	457419d7-14e1-4dec-844e-2dbeea4821b6	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:10.588289+00	\N	{"id": "457419d7-14e1-4dec-844e-2dbeea4821b6", "statut": "creee", "created_at": "2026-06-16 21:31:10.588289+00:00", "updated_at": "2026-06-16 21:31:10.588289+00:00", "reference_id": "C00000077", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
762986e7-9e48-45b7-a703-1192e48d6396	lignes_commande	1b73f9c2-7ecb-4b32-95b3-191c7ab0edab	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:10.588289+00	\N	{"id": "1b73f9c2-7ecb-4b32-95b3-191c7ab0edab", "verifie": "False", "created_at": "2026-06-16 21:31:10.588289+00:00", "remise_pct": "0.00", "updated_at": "2026-06-16 21:31:10.588289+00:00", "commande_id": "457419d7-14e1-4dec-844e-2dbeea4821b6", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
c81ef75c-2def-4bc7-b545-654312b9b08d	commandes	457419d7-14e1-4dec-844e-2dbeea4821b6	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:10.627181+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-16 21:31:10.637475+00:00"}
749938a5-f73e-496d-9d4f-a47519f2fc3e	factures	16eea11e-d475-438f-8032-f55a85c04ec5	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:10.627181+00	\N	{"id": "16eea11e-d475-438f-8032-f55a85c04ec5", "created_at": "2026-06-16 21:31:10.627181+00:00", "montant_ht": "198.50", "updated_at": "2026-06-16 21:31:10.627181+00:00", "commande_id": "457419d7-14e1-4dec-844e-2dbeea4821b6", "montant_ttc": "198.50", "reference_id": "F0000000041", "date_emission": "2026-06-16 21:31:10.663275+00:00"}
f412254d-9b31-452d-a17d-3f60f5c79ded	creances	30c6143d-1965-4f2d-9a63-c8ae6ea9da60	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:10.627181+00	\N	{"id": "30c6143d-1965-4f2d-9a63-c8ae6ea9da60", "statut": "en_attente", "echeance": "2026-07-16", "created_at": "2026-06-16 21:31:10.627181+00:00", "facture_id": "16eea11e-d475-438f-8032-f55a85c04ec5", "updated_at": "2026-06-16 21:31:10.627181+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
a7dbf4de-6be6-442c-b101-9c535537e184	bons_livraison	1abfbe59-5ac0-4e18-b9f1-33430479d933	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:10.627181+00	\N	{"id": "1abfbe59-5ac0-4e18-b9f1-33430479d933", "code_barre": "BL00000041", "created_at": "2026-06-16 21:31:10.627181+00:00", "updated_at": "2026-06-16 21:31:10.627181+00:00", "commande_id": "457419d7-14e1-4dec-844e-2dbeea4821b6", "date_emission": "2026-06-16 21:31:10.663275+00:00"}
999347a7-5d85-4134-bf89-28231f74ffd0	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:10.627181+00	{"stock_quantity": "54"}	{"stock_quantity": "53"}
65b681bc-4433-4f08-bd16-ecfb5bfcd45e	commandes	a19333cc-805c-43e4-be89-f1aadcc380c5	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:12.831059+00	\N	{"id": "a19333cc-805c-43e4-be89-f1aadcc380c5", "statut": "creee", "created_at": "2026-06-16 21:31:12.831059+00:00", "updated_at": "2026-06-16 21:31:12.831059+00:00", "reference_id": "C00000078", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
96a126c8-700e-46ef-a474-8ace67fd202f	lignes_commande	2913f357-6e97-4002-86b9-c82777aca6a6	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:12.831059+00	\N	{"id": "2913f357-6e97-4002-86b9-c82777aca6a6", "verifie": "False", "created_at": "2026-06-16 21:31:12.831059+00:00", "remise_pct": "0.00", "updated_at": "2026-06-16 21:31:12.831059+00:00", "commande_id": "a19333cc-805c-43e4-be89-f1aadcc380c5", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
7afd5ed4-4c55-4be4-9a83-1fcd2e402f79	commandes	a19333cc-805c-43e4-be89-f1aadcc380c5	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:12.872785+00	{"operatrice_comment": "None"}	{"operatrice_comment": "Quantité erronée, merci de corriger la ligne 1"}
11c3e9ae-4166-40fa-9ba8-cb3ee78b6ade	commandes	a19333cc-805c-43e4-be89-f1aadcc380c5	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:12.935873+00	{"statut": "creee", "operatrice_id": "None", "date_validation": "None"}	{"statut": "acceptee", "operatrice_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "date_validation": "2026-06-16 21:31:12.942518+00:00"}
0ad74394-14ce-4b6b-813f-b88f408f610c	factures	aa05aac0-5db6-4187-80c9-ca6a5efe0834	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:12.935873+00	\N	{"id": "aa05aac0-5db6-4187-80c9-ca6a5efe0834", "created_at": "2026-06-16 21:31:12.935873+00:00", "montant_ht": "198.50", "updated_at": "2026-06-16 21:31:12.935873+00:00", "commande_id": "a19333cc-805c-43e4-be89-f1aadcc380c5", "montant_ttc": "198.50", "reference_id": "F0000000042", "date_emission": "2026-06-16 21:31:12.960676+00:00"}
b32d84a9-744c-45de-823c-b227a924179e	creances	f68da13a-e90d-4a15-8e76-d157bb35d98a	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:12.935873+00	\N	{"id": "f68da13a-e90d-4a15-8e76-d157bb35d98a", "statut": "en_attente", "echeance": "2026-07-16", "created_at": "2026-06-16 21:31:12.935873+00:00", "facture_id": "aa05aac0-5db6-4187-80c9-ca6a5efe0834", "updated_at": "2026-06-16 21:31:12.935873+00:00", "montant_paye": "0", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
1b31e23b-4dab-485f-8541-6322d9d4efee	bons_livraison	f03e9b77-ab70-4c16-af7c-6fd7ab080cae	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:12.935873+00	\N	{"id": "f03e9b77-ab70-4c16-af7c-6fd7ab080cae", "code_barre": "BL00000042", "created_at": "2026-06-16 21:31:12.935873+00:00", "updated_at": "2026-06-16 21:31:12.935873+00:00", "commande_id": "a19333cc-805c-43e4-be89-f1aadcc380c5", "date_emission": "2026-06-16 21:31:12.960676+00:00"}
642f58e0-0f97-4322-b62a-5257c82beeea	medicaments	02787863-90cc-4020-93a4-0fc4bab203c7	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:31:12.935873+00	{"stock_quantity": "53"}	{"stock_quantity": "52"}
ce3265f8-0022-4144-a813-9f449e9c79b0	commandes	e2a62896-8c70-49b0-980a-36481afedbaf	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:15.183821+00	\N	{"id": "e2a62896-8c70-49b0-980a-36481afedbaf", "statut": "creee", "created_at": "2026-06-16 21:31:15.183821+00:00", "updated_at": "2026-06-16 21:31:15.183821+00:00", "reference_id": "C00000079", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
d830535e-7730-42b0-91bf-25587eb6f558	lignes_commande	29dc0676-b24a-417e-99d5-18c3e344c4b7	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:15.183821+00	\N	{"id": "29dc0676-b24a-417e-99d5-18c3e344c4b7", "verifie": "False", "created_at": "2026-06-16 21:31:15.183821+00:00", "remise_pct": "0.00", "updated_at": "2026-06-16 21:31:15.183821+00:00", "commande_id": "e2a62896-8c70-49b0-980a-36481afedbaf", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
09322702-37fa-4a60-8434-f763f2396112	commandes	d7705f0f-c48a-4e3b-b111-42b4a08a8d6e	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:19.484326+00	\N	{"id": "d7705f0f-c48a-4e3b-b111-42b4a08a8d6e", "statut": "creee", "created_at": "2026-06-16 21:31:19.484326+00:00", "updated_at": "2026-06-16 21:31:19.484326+00:00", "reference_id": "C00000080", "montant_total": "198.50", "pharmacien_id": "80b3ae99-edfc-4220-a471-03c5366fb10d"}
f432543d-ac3a-44c2-bfb9-074b194bc92a	lignes_commande	76434d53-922f-4aed-a78b-ada99132a3c8	insert	80b3ae99-edfc-4220-a471-03c5366fb10d	2026-06-16 21:31:19.484326+00	\N	{"id": "76434d53-922f-4aed-a78b-ada99132a3c8", "verifie": "False", "created_at": "2026-06-16 21:31:19.484326+00:00", "remise_pct": "0.00", "updated_at": "2026-06-16 21:31:19.484326+00:00", "commande_id": "d7705f0f-c48a-4e3b-b111-42b4a08a8d6e", "designation": "ALLERTINE. 10MG B/20 COMP. SEC", "qte_demandee": "1", "medicament_id": "02787863-90cc-4020-93a4-0fc4bab203c7", "prix_unitaire": "198.50"}
710e8a52-dff8-4014-b06c-e08e038a9ece	scans_colis	59c2d5e9-0343-4fe4-8ccb-c5c7ae744d5d	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-16 21:32:12.299508+00	\N	{"id": "59c2d5e9-0343-4fe4-8ccb-c5c7ae744d5d", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "4566b695-b2c8-4009-b4a9-4fe8f9b2eb63", "type_scan": "depot_pad", "created_at": "2026-06-16 21:32:12.299508+00:00", "pad_tir_id": "None", "updated_at": "2026-06-16 21:32:12.299508+00:00"}
527a3acf-35a9-4895-a087-3b18a90c41a3	colis	4566b695-b2c8-4009-b4a9-4fe8f9b2eb63	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-16 21:32:12.299508+00	{"statut": "etiquete"}	{"statut": "sur_pad"}
b0f64cdb-6d04-45ee-9846-634507f97304	scans_colis	685f9f71-b593-44bf-8982-80fbb1f4976e	insert	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-16 21:32:12.299508+00	\N	{"id": "685f9f71-b593-44bf-8982-80fbb1f4976e", "user_id": "3fa3d47d-99e0-4ac6-94c1-565354f320eb", "colis_id": "72aef3f2-1486-4cd7-915d-423bde41ef8c", "type_scan": "depot_pad", "created_at": "2026-06-16 21:32:12.299508+00:00", "pad_tir_id": "None", "updated_at": "2026-06-16 21:32:12.299508+00:00"}
1bd6057e-9ddd-4172-b4da-95dd4c8781e3	colis	72aef3f2-1486-4cd7-915d-423bde41ef8c	update	3fa3d47d-99e0-4ac6-94c1-565354f320eb	2026-06-16 21:32:12.299508+00	{"statut": "etiquete"}	{"statut": "sur_pad"}
91fb08fe-862a-4fad-990b-dc88a1520510	scans_colis	9e863740-0ab6-4fe3-ac7f-c72bc6850e20	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:32:13.53334+00	\N	{"id": "9e863740-0ab6-4fe3-ac7f-c72bc6850e20", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "72aef3f2-1486-4cd7-915d-423bde41ef8c", "type_scan": "chargement", "created_at": "2026-06-16 21:32:13.533340+00:00", "pad_tir_id": "None", "updated_at": "2026-06-16 21:32:13.533340+00:00"}
6a3dd5ec-3838-4f34-9b9b-d9a94167d8f7	colis	72aef3f2-1486-4cd7-915d-423bde41ef8c	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:32:13.53334+00	{"statut": "sur_pad"}	{"statut": "charge"}
01e41c17-f341-4c8d-8ff9-80b522bfdafe	commandes	a90de1fe-e8f3-4c96-8107-69eba971d1a8	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:32:13.53334+00	{"statut": "prete"}	{"statut": "en_route"}
b45ca942-af36-4cb9-a470-3c2914c481d5	scans_colis	d107ce54-6e0b-463e-b483-bea4ce78a90a	insert	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:32:13.288592+00	\N	{"id": "d107ce54-6e0b-463e-b483-bea4ce78a90a", "user_id": "5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb", "colis_id": "4566b695-b2c8-4009-b4a9-4fe8f9b2eb63", "type_scan": "chargement", "created_at": "2026-06-16 21:32:13.288592+00:00", "pad_tir_id": "None", "updated_at": "2026-06-16 21:32:13.288592+00:00"}
dffdde93-c19c-4610-aa2f-a9aea6c7723d	colis	4566b695-b2c8-4009-b4a9-4fe8f9b2eb63	update	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	2026-06-16 21:32:13.288592+00	{"statut": "sur_pad"}	{"statut": "charge"}
\.


--
-- Data for Name: bons_livraison; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.bons_livraison (id, commande_id, code_barre, date_emission, created_at, updated_at, created_by) FROM stdin;
51c17462-f70e-4c60-8280-66ce4a9f2161	0bff5c32-f6f8-4986-92ea-b6a8147cba6a	BL00000001	2026-03-26 11:16:20.953454+00	2026-03-26 11:16:20.943614+00	2026-03-26 11:16:20.943614+00	\N
b76ba340-dcf3-43f9-a035-f76ec5145d4f	39c1dfe9-f87e-48b9-82f9-585965bef503	BL00000002	2026-03-26 11:30:31.026851+00	2026-03-26 11:30:31.006884+00	2026-03-26 11:30:31.006884+00	\N
e2d8f61c-1a0b-41e0-8f0a-7ef6a698ff52	8749fa09-b997-45a6-b5be-e9b1f49c23d2	BL00000003	2026-03-26 12:23:05.243816+00	2026-03-26 12:23:05.207857+00	2026-03-26 12:23:05.207857+00	\N
7ea1b8ad-86b0-4950-802e-574557efb8a7	f61d715f-0444-45bc-b848-927210e1a0b9	BL00000004	2026-03-30 17:59:59.739572+00	2026-03-30 17:59:59.728342+00	2026-03-30 17:59:59.728342+00	\N
7a4aad92-2261-4b6c-8851-da453567547f	dbbca1b4-1782-4fd5-9255-9e458cdbd550	BL00000005	2026-04-01 13:41:23.362026+00	2026-04-01 13:41:23.351868+00	2026-04-01 13:41:23.351868+00	\N
71f71c05-3c15-4dc8-aac4-c0a1fcd4df2e	106039b7-a430-4ce3-ae3a-e85ecdc1efa5	BL00000006	2026-04-01 15:54:31.57234+00	2026-04-01 15:54:31.561759+00	2026-04-01 15:54:31.561759+00	\N
6439bc85-0c90-4afd-be79-3cf1ebf01783	3f80e2e0-8be4-44f0-981e-95810dc3d429	BL00000007	2026-04-01 15:59:21.577759+00	2026-04-01 15:59:21.568905+00	2026-04-01 15:59:21.568905+00	\N
0940927f-befd-4379-9a0f-5f9143bb60d7	fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07	BL00000008	2026-04-07 11:48:49.91804+00	2026-04-07 11:48:49.89656+00	2026-04-07 11:48:49.89656+00	\N
3668ec4c-1a02-471d-8fb8-34d9dd49f836	96fdb118-00e1-4720-b8f9-2f3b30e58611	BL00000009	2026-04-13 10:25:08.006986+00	2026-04-13 10:25:07.989227+00	2026-04-13 10:25:07.989227+00	\N
4e03caca-cab0-4aae-833d-ec4a30121c37	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	BL00000010	2026-04-13 11:37:17.585242+00	2026-04-13 11:37:17.560937+00	2026-04-13 11:37:17.560937+00	\N
e9c2857c-d295-43aa-b05f-cd39a3d2a006	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	BL00000011	2026-04-13 12:29:26.864601+00	2026-04-13 12:29:26.819267+00	2026-04-13 12:29:26.819267+00	\N
79ebb877-e3f2-4770-8a1a-7865805d6cb2	9bf827a6-b240-4200-a206-40f132b84460	BL00000012	2026-04-13 12:31:54.660401+00	2026-04-13 12:31:54.62788+00	2026-04-13 12:31:54.62788+00	\N
58e244ff-f20b-4c00-849a-858a87f286bc	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	BL00000013	2026-04-13 12:31:59.779069+00	2026-04-13 12:31:59.749756+00	2026-04-13 12:31:59.749756+00	\N
434a215a-8ce2-487e-b190-a23d4476be50	2c2e82ab-d610-4c51-9d96-3975c65d03db	BL00000014	2026-04-13 13:37:52.402595+00	2026-04-13 13:37:52.390464+00	2026-04-13 13:37:52.390464+00	\N
66d0894a-8f18-47cc-9a1a-719488053e77	48615e40-3d72-40e0-924d-fa4ea9ae3604	BL00000015	2026-04-13 13:40:16.120704+00	2026-04-13 13:40:16.112649+00	2026-04-13 13:40:16.112649+00	\N
75f6ecbe-65e2-441d-bc3d-19fbe64a183b	f513fe06-a0cf-44fa-838f-5453e98790b5	BL00000016	2026-04-13 13:40:21.311974+00	2026-04-13 13:40:21.303155+00	2026-04-13 13:40:21.303155+00	\N
52495748-0209-41e3-a0d4-6e440e880754	6e7ffbab-0205-4987-b782-0f9dfae7d304	BL00000017	2026-04-13 20:14:14.444203+00	2026-04-13 20:14:14.410049+00	2026-04-13 20:14:14.410049+00	\N
bfc31af4-042d-4a87-aea7-91452dbb7784	18a1fd87-3e0b-477f-a337-39709652df94	BL00000018	2026-04-13 20:21:23.188874+00	2026-04-13 20:21:23.16632+00	2026-04-13 20:21:23.16632+00	\N
4d42e6ef-924d-4552-8214-b113d301d7fa	81b6516c-629b-4d80-82d5-24a7801ae726	BL00000019	2026-04-13 20:21:37.469809+00	2026-04-13 20:21:37.447254+00	2026-04-13 20:21:37.447254+00	\N
5920fdbd-2226-4415-9299-115cac7a731c	7646e2c0-c917-471f-98a8-29c2fc69479b	BL00000020	2026-06-15 15:50:25.4822+00	2026-06-15 15:50:25.440264+00	2026-06-15 15:50:25.440264+00	\N
796dbf15-725f-44b6-a688-921c61992f4d	3f8b751f-b7e4-4caf-a7f1-66a3cc2f9f5e	BL00000021	2026-06-15 15:50:34.356499+00	2026-06-15 15:50:34.331446+00	2026-06-15 15:50:34.331446+00	\N
1a2643b5-3f16-44c1-a0f5-dca71cdb0fb3	bdb4d02b-fdb8-481a-949a-1793843e552b	BL00000022	2026-06-15 15:50:36.360829+00	2026-06-15 15:50:36.337415+00	2026-06-15 15:50:36.337415+00	\N
e0a57ccb-ea71-414e-bca3-421f229068ac	712e33d3-a45d-4ec6-82e1-488c453c04af	BL00000023	2026-06-15 15:50:37.869143+00	2026-06-15 15:50:37.850071+00	2026-06-15 15:50:37.850071+00	\N
ac7e0e60-55c3-4bb2-b936-99a47617d21f	634eadc7-857c-4ff9-8163-5b54a9eb0dda	BL00000024	2026-06-15 15:51:37.080196+00	2026-06-15 15:51:37.056864+00	2026-06-15 15:51:37.056864+00	\N
2927e86d-d1a3-4f25-8c20-3c964935825b	b457ab88-16a4-423c-a37c-7c9373b01e00	BL00000025	2026-06-15 16:03:55.072684+00	2026-06-15 16:03:55.016795+00	2026-06-15 16:03:55.016795+00	\N
53cdf81f-3a93-4c4d-9e1a-e766e05bdbef	53b0ca21-ecda-4875-8b88-45e6a4426f74	BL00000026	2026-06-15 16:04:07.405483+00	2026-06-15 16:04:07.367451+00	2026-06-15 16:04:07.367451+00	\N
ab458bf0-c55f-41df-aa54-84b40c8cdc45	7e3dbefd-9e34-4af7-8137-bd435e68555e	BL00000027	2026-06-15 16:04:10.082811+00	2026-06-15 16:04:10.056726+00	2026-06-15 16:04:10.056726+00	\N
686b33f9-bca7-4dd3-a611-d3d14693642d	afd7ad6c-776b-4c2c-9c6a-ce0134c65366	BL00000028	2026-06-15 16:04:12.37994+00	2026-06-15 16:04:12.349117+00	2026-06-15 16:04:12.349117+00	\N
ab7b768b-8e0b-492a-9e15-0a97ed8854a2	a90de1fe-e8f3-4c96-8107-69eba971d1a8	BL00000029	2026-06-15 16:04:51.819051+00	2026-06-15 16:04:51.786482+00	2026-06-15 16:04:51.786482+00	\N
85891160-aa45-408f-af07-ec6f79743fed	70932ee6-bdba-4e93-b487-e0e51c7452f9	BL00000030	2026-06-15 16:14:02.797822+00	2026-06-15 16:14:02.696749+00	2026-06-15 16:14:02.696749+00	\N
af674db5-5919-443c-b929-7bb0fab7e6cf	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	BL00000031	2026-06-15 16:43:18.690721+00	2026-06-15 16:43:18.644412+00	2026-06-15 16:43:18.644412+00	\N
563a9d1e-5c07-432f-9483-eefc34b5dbec	9d504663-a4f6-4855-bdec-407cfabc199a	BL00000032	2026-06-15 16:43:28.020842+00	2026-06-15 16:43:27.985656+00	2026-06-15 16:43:27.985656+00	\N
669507e6-443d-44d4-a364-6011d0ed0d9b	54d4a168-cd3c-4ad7-8531-def1a75875e3	BL00000033	2026-06-15 16:43:29.866499+00	2026-06-15 16:43:29.840087+00	2026-06-15 16:43:29.840087+00	\N
5ed5c26e-f9e5-4f2a-bc91-05a9d9427876	a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd	BL00000034	2026-06-15 16:43:31.29062+00	2026-06-15 16:43:31.265314+00	2026-06-15 16:43:31.265314+00	\N
ddb2231a-d0b4-4a8f-97d3-d5666ef8a459	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	BL00000035	2026-06-15 16:53:28.424281+00	2026-06-15 16:53:28.367368+00	2026-06-15 16:53:28.367368+00	\N
aa31c5d6-6d13-4cc3-839d-da814a703d05	1c82273c-17f9-46c1-984b-ba0d11ce9022	BL00000036	2026-06-15 16:53:41.917583+00	2026-06-15 16:53:41.885247+00	2026-06-15 16:53:41.885247+00	\N
6966e1ff-f62c-4de7-a93a-ae071793d656	e19fd8f0-1dc2-4dba-ab94-bd32bb9fc2c5	BL00000037	2026-06-15 16:53:43.915662+00	2026-06-15 16:53:43.880048+00	2026-06-15 16:53:43.880048+00	\N
b018d880-19c7-4c76-a240-de75d09a1fb6	5b7c805d-1652-4f86-997e-88a6cedb2195	BL00000038	2026-06-15 16:53:45.483194+00	2026-06-15 16:53:45.454935+00	2026-06-15 16:53:45.454935+00	\N
c514330f-a18f-4733-b04f-a532e82f72da	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	BL00000039	2026-06-16 21:30:47.383171+00	2026-06-16 21:30:47.31459+00	2026-06-16 21:30:47.31459+00	\N
40638a0b-0326-4017-9452-14f3248c57ba	92980492-7923-4866-89ef-216fcebc8722	BL00000040	2026-06-16 21:31:07.800041+00	2026-06-16 21:31:07.737096+00	2026-06-16 21:31:07.737096+00	\N
1abfbe59-5ac0-4e18-b9f1-33430479d933	457419d7-14e1-4dec-844e-2dbeea4821b6	BL00000041	2026-06-16 21:31:10.663275+00	2026-06-16 21:31:10.627181+00	2026-06-16 21:31:10.627181+00	\N
f03e9b77-ab70-4c16-af7c-6fd7ab080cae	a19333cc-805c-43e4-be89-f1aadcc380c5	BL00000042	2026-06-16 21:31:12.960676+00	2026-06-16 21:31:12.935873+00	2026-06-16 21:31:12.935873+00	\N
\.


--
-- Data for Name: caddies; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.caddies (id, commande_id, numero, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: caddies_pool; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.caddies_pool (id, numero, is_available, current_commande_id, created_at, created_by, updated_at, updated_by) FROM stdin;
08f653aa-226d-4636-914f-af3a1b697948	C02	t	\N	2026-04-13 14:14:49.646408+00	\N	\N	\N
09d5f80e-fd16-4a2a-a408-b05ebdc95ba8	C04	t	\N	2026-04-13 14:14:49.646408+00	\N	\N	\N
5ba21c9b-467c-4314-ab02-4866682ef651	C05	t	\N	2026-04-13 14:14:49.646408+00	\N	\N	\N
703045ad-f7cf-4bd3-8050-169592fe9c32	C06	t	\N	2026-04-13 14:14:49.646408+00	\N	\N	\N
277e0a19-10ac-43c9-9d0d-bcf1becde75a	C07	t	\N	2026-04-13 14:14:49.646408+00	\N	\N	\N
04679469-bcb6-4b2d-a172-d5cbc61e1754	C08	t	\N	2026-04-13 14:14:49.646408+00	\N	\N	\N
89405b14-49e1-4c21-ad02-78f4c9ec451e	C09	t	\N	2026-04-13 14:14:49.646408+00	\N	\N	\N
3da494aa-631c-446c-b044-2382d7c9104a	C10	t	\N	2026-04-13 14:14:49.646408+00	\N	\N	\N
39c5bd49-2abb-4d81-905a-f28ad3bc3b4c	C03	t	\N	2026-04-13 14:14:49.646408+00	\N	2026-04-13 20:22:02.525036+00	\N
802cd6c5-26bf-4d33-8599-a741f84c0a2c	C01	t	\N	2026-04-13 14:14:49.646408+00	\N	2026-06-16 21:30:48.404165+00	\N
\.


--
-- Data for Name: camions; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.camions (id, nom, plaque, created_at, updated_at, created_by) FROM stdin;
0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	Ligne 1 - Alger Centre	00100-101-16	2026-04-01 13:48:20.74562+00	2026-04-01 13:48:20.74562+00	\N
1c2411aa-1f09-4c5d-8360-96180f6b4c54	Ligne 2 - Bab El Oued	00100-102-16	2026-04-01 13:48:20.74562+00	2026-04-01 13:48:20.74562+00	\N
172c10e2-3ad9-4147-a305-aab91c7e9345	Ligne 3 - Hussein Dey	00100-103-16	2026-04-01 13:48:20.74562+00	2026-04-01 13:48:20.74562+00	\N
7785e358-83c4-41e6-9e6b-db5ded7b6e97	Ligne 4 - Kouba	00100-104-16	2026-04-01 13:48:20.74562+00	2026-04-01 13:48:20.74562+00	\N
15c29ee0-253e-49fb-ac13-57ca40706d2a	Ligne 5 - Bir Mourad Raïs	00100-105-16	2026-04-01 13:48:20.74562+00	2026-04-01 13:48:20.74562+00	\N
c0836d0b-47bc-4304-a1e0-b954fe2e99da	Ligne 6 - Bab Ezzouar	00100-106-16	2026-04-01 13:48:20.74562+00	2026-04-01 13:48:20.74562+00	\N
6b9d9b8f-05c2-494c-90f7-7b767d1fe335	Ligne 7 - Rouiba	00100-107-16	2026-04-01 13:48:20.74562+00	2026-04-01 13:48:20.74562+00	\N
02bd12de-6e8e-4957-9491-97eb88c75942	Ligne 8 - Blida	00100-108-09	2026-04-01 13:48:20.74562+00	2026-04-01 13:48:20.74562+00	\N
\.


--
-- Data for Name: colis; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.colis (id, numero, commande_id, index_colis, statut, pad_tir_id, created_at, updated_at, created_by) FROM stdin;
a7abc6ba-6a76-44b3-a913-a0f834112305	CLS00000019	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	1	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:53:29.7234+00	2026-06-15 16:53:31.402926+00	\N
f5d79986-28a7-407b-aed0-1a1748e7ce83	CLS00000020	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	2	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:53:29.7234+00	2026-06-15 16:53:31.449946+00	\N
6ccd2d70-222e-429b-ae44-12fdd922daaf	CLS00000021	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	3	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:53:29.7234+00	2026-06-15 16:53:31.491684+00	\N
36b6616e-a0f9-4224-89b2-f744dcca9174	CLS00000001	7646e2c0-c917-471f-98a8-29c2fc69479b	1	livre	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 15:50:26.816689+00	2026-06-15 15:50:28.336848+00	\N
e934bb2d-0bc6-4d1f-a884-7f8649193733	CLS00000002	7646e2c0-c917-471f-98a8-29c2fc69479b	2	livre	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 15:50:26.816689+00	2026-06-15 15:50:28.373533+00	\N
3d1422e6-0ffc-4370-9678-4ee429565578	CLS00000003	7646e2c0-c917-471f-98a8-29c2fc69479b	3	livre	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 15:50:26.816689+00	2026-06-15 15:50:28.404734+00	\N
058f7ef6-861a-4131-ba7e-bae8c323bc91	CLS00000022	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	1	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-16 21:30:49.163335+00	2026-06-16 21:30:51.279256+00	\N
ee6013e2-ec6b-47ff-bc1b-1aa46d001038	CLS00000023	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	2	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-16 21:30:49.163335+00	2026-06-16 21:30:51.331775+00	\N
9865055c-ae07-4449-9fa9-393ae8e05984	CLS00000007	b457ab88-16a4-423c-a37c-7c9373b01e00	1	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:03:56.63148+00	2026-06-15 16:03:58.45238+00	\N
321c323c-856f-4ffe-a108-6d3dffeffc4d	CLS00000008	b457ab88-16a4-423c-a37c-7c9373b01e00	2	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:03:56.63148+00	2026-06-15 16:03:58.495277+00	\N
1427f0c3-ba2d-4ef2-a865-79b32a844edf	CLS00000009	b457ab88-16a4-423c-a37c-7c9373b01e00	3	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:03:56.63148+00	2026-06-15 16:03:58.5357+00	\N
feb38818-c5b5-4275-8122-482af5cabff9	CLS00000004	634eadc7-857c-4ff9-8163-5b54a9eb0dda	1	etiquete	\N	2026-06-15 15:51:40.249629+00	2026-06-15 15:51:57.90683+00	\N
77f65be3-db67-4a40-8aa7-eca7c8917770	CLS00000005	634eadc7-857c-4ff9-8163-5b54a9eb0dda	2	etiquete	\N	2026-06-15 15:51:40.249629+00	2026-06-15 16:03:31.551987+00	\N
e8524629-231b-47a9-924c-90c318a566c3	CLS00000006	634eadc7-857c-4ff9-8163-5b54a9eb0dda	3	etiquete	\N	2026-06-15 15:51:40.249629+00	2026-06-15 16:03:31.551987+00	\N
2de3edd1-5302-4617-82c9-244ddb424b2e	CLS00000012	70932ee6-bdba-4e93-b487-e0e51c7452f9	1	sur_pad	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 16:20:36.975657+00	2026-06-15 16:26:50.871261+00	\N
4661cc5f-1c47-4c92-9bb3-9c8b8c2fd8db	CLS00000013	70932ee6-bdba-4e93-b487-e0e51c7452f9	2	sur_pad	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 16:20:36.975657+00	2026-06-15 16:26:50.871261+00	\N
867bbd1b-110a-470e-8f20-b02bb47529d1	CLS00000014	70932ee6-bdba-4e93-b487-e0e51c7452f9	3	sur_pad	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 16:20:36.975657+00	2026-06-15 16:26:50.871261+00	\N
4a0a17aa-fd5a-4a1c-bca8-0788e764aed6	CLS00000015	70932ee6-bdba-4e93-b487-e0e51c7452f9	4	sur_pad	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 16:20:36.975657+00	2026-06-15 16:26:50.871261+00	\N
585ea26a-fbe9-4106-8487-79ce19db4c79	CLS00000024	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	3	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-16 21:30:49.163335+00	2026-06-16 21:30:51.373024+00	\N
4566b695-b2c8-4009-b4a9-4fe8f9b2eb63	CLS00000010	a90de1fe-e8f3-4c96-8107-69eba971d1a8	1	charge	\N	2026-06-15 16:04:55.104675+00	2026-06-16 21:32:13.288592+00	\N
d0dc8e6f-1b06-4d71-8dac-5d5abae4d120	CLS00000016	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	1	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:43:19.876809+00	2026-06-15 16:43:21.308159+00	\N
d6fd0be7-837c-43b0-9430-27781bf63503	CLS00000017	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	2	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:43:19.876809+00	2026-06-15 16:43:21.353342+00	\N
1e0ede6a-53e5-485f-8fca-ca781bdcbda6	CLS00000018	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	3	livre	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:43:19.876809+00	2026-06-15 16:43:21.388009+00	\N
72aef3f2-1486-4cd7-915d-423bde41ef8c	CLS00000011	a90de1fe-e8f3-4c96-8107-69eba971d1a8	2	charge	\N	2026-06-15 16:04:55.104675+00	2026-06-16 21:32:13.53334+00	\N
\.


--
-- Data for Name: colis_lignes; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.colis_lignes (id, colis_id, ligne_commande_id, quantite, created_at, updated_at, created_by) FROM stdin;
\.


--
-- Data for Name: commandes; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.commandes (id, reference_id, pharmacien_id, operatrice_id, statut, montant_total, commercial, date_validation, created_at, updated_at, created_by, camion_id, signature_pharmacien, motif_echec, nb_colis, visa_preparateur, visa_controleur, feuille_route_id, preparateur_id, operatrice_comment) FROM stdin;
f513fe06-a0cf-44fa-838f-5453e98790b5	C00000024	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	prete	397.00	Fatima Operatrice	2026-04-13 13:40:21.306133+00	2026-04-13 13:36:09.730856+00	2026-04-13 20:17:41.725641+00	\N	7785e358-83c4-41e6-9e6b-db5ded7b6e97	\N	\N	\N	Preparateur	Controleur	7ea42bcb-2193-47f0-a179-57d7cded6983	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	\N
19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	C00000019	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	livree	198.50	Fatima Operatrice	2026-04-13 11:37:17.566052+00	2026-04-13 11:36:57.533086+00	2026-04-13 13:10:54.607044+00	\N	1c2411aa-1f09-4c5d-8360-96180f6b4c54	\\x89504e470d0a1a0a0000000d4948445200000190000000c80806000000c615b7e200001a5249444154785eed9d0bb04ed5fbc71f926b7eb9954beed788a95c52a4c6e436e552864aa826535251866e94db74bf0d2a4d1a74218a91933128b7724b8584925c53642a458910ffffb37efffdfedf739c73bcef3e7bbf7bafbd3f6ba6e9cc397badf53c9f6779bfef5e9767153af5bf4528108000042000813409144240d224c6e31080000420600820200c0408400002107045000171858d4a1080000420808030062000010840c0150104c415362a41000210800002c2188000042000015704101057d8a80401084000020808630002108000045c1140405c61a312042000010820208c0108400002107045000171858d4a1080000420808030062000010840c0150104c415362a41000210800002c2188000042000015704101057d8a80401084000020808630002108000045c1140405c61a312042000010820208c0108400002107045000171858d4a1080000420808030062000010840c0150104c415362a41000210800002c2188000042000015704101057d8a80401084000020808630002108000045c1140405c61a312042000010820208c0108400002107045000171858d4a1080000420808030062000010840c0150104c415362a41000210800002c2188000042000015704101057d8a80401084000020808630002108000045c1140405c61a312042000010820208c0108400002107045000171858d4a1080000420808030062000010840c0150104c415362a41000210800002c2180825812a55aa24ec2a56ac98b46fdf5e264e9c184a5b310a0271258080c435f221f75b05a450a142d9ac3c75ea94e87fe79c738edc72cb2d327af4e8907b8179108836010424daf1b5d6bb640151d1d0929ba0e8efcf3df75c193870a0dc73cf3dd6fa8be110b09100026263d4626073f5ead5e5df7fff356f1c7bf7ee9503070e48efdebd65f3e6cd72e2c4893c054545a67cf9f2327cf870b9e9a69b62400a1721101c01042438f6f49c0f81ebaebb4ebefaeaab8480e4f6e8d5575f2d3b76ec304293f3ed449f3ffffcf365fdfaf5708600047c228080f80496660b46e0e4c99352b56a55230c83060d92871f7e38df063ffbec33b9fffefbe5a79f7e328252b87061233e6fbffdb6b46bd7ae60c6501b0210c89540ec05242b2b4b060f1e2c478e1cc9f55bac7e08e92ea0575e79453a77eecc30ca2001671da454a952b275ebd6b47abee0820b12d35c3ffef8635a7579180210488d40ac04e4c61b6f94952b579a6fa6c925b7e98f9cf89c3afa7f7d5ebf1d2f5ab448fef39fffa4469aa7d22650ad5a35d13711671d249d069e7bee3919376e9ca9d2a95327993469523ad5791602104881406405a471e3c6f2db6fbf657babc84b2892c5e1acb3ce923265cac8b163c7e4afbffe4a203c53dd22458ac81d77dc21a3468d4a013b8fa442a06ddbb6e6cdc38d8068fbb56bd7967ffef9c775fd546ce41908c49980f502327efc7879f1c517cd077ef2877c6e1ff8c96f1ece7982575f7d553a74e870c6313063c60c19366c5862aaeb4c82a20d962e5d5a3ef8e00369d4a8d119dbe781d309e8d453cb962dcd1f9e7efa69b9f5d65bd3c2b46fdf3e69debcb9a9e3661a2cadce7818023124608d80e837499d8a70be913ab1ca6ffa2959306ad5aa254b962c31eb195e15fd40d336937701e57556416dd1b79b8b2fbe58e6cd9be79509916fc75907295bb6ac6cdab4296d7fbb75eb265f7ef9a5a9a7d35aba1598020108784320b402a2dfda7ffffdf733be5528069d27d70f6efd903efbecb3e5f6db6f973163c67843288d568e1e3d2a4d9b36953ffef823b1cea2bb817296e429b392254bca0b2fbc2037dc70431a3dc5e7d1e40385bac3ca4df1a20d37fd5207025127104a0169ddbab5ecdab52bcf0f5efd837e08972b574e56ad5a654e2287b58c1d3b56f4bfe3c78f274425bfe935f54b3ff0d6ae5d1b5697326ad715575c213ffcf04381d631a64e9d2a0f3df490f992d1a4491359b06041467da0330844954028054445a1478f1ed9de3ef48355b7dcb668d1c2fa58e8dbc6175f7c61de9c9c92dfd457d1a245cda96a9d82895b514ed75f7fbd717be6cc99d2aa552b57082ebcf042f9f3cf3f0b2444ae3aa61204224c209402e2f0d66fe22a1cce3490934c4fdf4ebc5ccb083abe1b366c3073f3bffefa6bc257b5293f51d105fa3973e6c46281be72e5ca864ba54a955cbf99e91b60cd9a354da8559077eedc1974d8e91f02d61308b58038749d4361c9b4a3fe21a0b99c74ea257977595e82e2fc5eb72e2f5cb8d0fa4199d301afd630faf5eb9798bed253eb3aad45810004dc13b04240d4bd8d1b374ac78e1d8da7ce07a6be9154ac583116f98e3481a0e687d29d48c9bbcbf25a4fd1674a9428214f3df594dc7cf3cdee4748086a5e72c925f2cb2fbf7832fde41c4e54b7dc2eca8700092640201404ac111087d6238f3c22efbcf38ef93071765ee9dfba74e922afbffe7a28a066ca88b973e7cad0a143e5d0a1438685c3235954729eba57c1fde4934fac3a41af27fe6fbbed368375cd9a35260b80dba2f5bb77ef6eaaeb9bede79f7feeb629ea4120f604ac131027627a4af9bbefbecbf636a21f964f3cf184e854455ccb800103cc39139df3778424afa92f65a427e835c58b6e250e7371a6b1ead4a9239f7efa69814cd5c3857ac850c7cbecd9b3e5f2cb2f2f507b5486405c09582b204ec0f403253911a27e28e862ebba75ebe21ad36c7eebc1cbfefdfb9ff10066f2d914dd16bd65cb9650f1f33a39a223482aae245b0c55a831c62202d60b88c35aa735920f14eaeff52222cae904de7cf34d73d0f2efbfff36a7e3f32aceae37fd906dd8b0a12c5ebc38309c7ab0f4e0c1839eac83a81323468c482458ecdab5abbcf6da6b81f946c710b0954064044403a07746e8fa48f2da886ed78cd2965fbf065a9f3e7dccda882ed69f69ea4bffaebbe0468e1c694efd67a2e8bd1e8f3efaa8e9eadb6fbff5640da7468d1a89db0d756bb86631a0400002a913889480386ee7dcf64b0ea4d40784f3a42e5c3ffef8e3e6bc849ec1c86b81def9bdbead28f7f9f3e7cb79e79d977e8729d470a69d74579617f9c4543434eb81164dcbafc244810004522710490151f7f5f059f2ce24bdde54af48a5b827f0cc33cfc8c48913cd9a9396dcf27ce9ef752a51ffa6dfe8df7df75dd7a7c7735aea08884ebb697a132f8ade56a8c2a102a82967744301050210488d40640544ddaf57af9e1c3e7c38f1ed593f2474f70dc51b027a1ff9934f3e690e2fe69791587b53f6055d47a95fbfbe89a7dbfb41f2f2daab838ade50a51508d84320d202a261d083747a1d6df256560e90f9374075ad42b704ebc13fe70d30b93767b797aea1bcf1c61bd2be7dfb948dd17b5f5e7ae925cf0544dfaaf42230b55773ad698a180a04207066029117100741ce7511dd8514e7f322671e1ade3c3179f264193d7a74b673294ecbc9871cebd6ad9bd2f90ee76d41cf0169aa17af8af6ef4ccde9fd213a054a810004f227101b01510c3945444f65735e2473ff44f4035ad3d16cdbb62d914920b753f3bac6a15363b9dd40e82456d4f595dc52febbf546b7083b3747162f5e5cb66fdfeeb629ea412036046225201ad5060d1a64bbeb5c7fc7945630e35da7a474e15a17dd9dd43439df4ef4f79abf6af9f2e5663bb673cfb9d6f17a3dab57af5e89b7a0c71e7b4cf4543f050210c89b40ec044451e8b75b5d1749de45848804fbcf4417e12fbdf452f9edb7df4e13936451d12c03fbf7ef37bff22366c96fa97eb41f2c657a8780b7046229200ec2e4dd37fabb61c386c9bdf7deeb2d615a73454093444e9f3e3ddf5b1cfbf6ed2bbab5d8cba2e74beebcf34eb3a0ee45de2d2f6da32d08848d40ac054483a1e74334a1a07320ae7cf9f226753c255c04f4464127eb70b2657ebc25e8b5b7070e1c30dd2c59b2c44c7b52200081d309c45e4014897e40e875a7c9a7aabd9e5f67f0794340ef4459bf7e7d22567ee53b73a6b2bc3cb4e80d015a814078082020ff170b4d033f61c2846ce9e1fdfa700a4ff8edb4447370e919122d7ec5486f2c9c356b96e9432fe4d2057f0a0420909d0002926344e4dceaabd79eea8709255c04f40dd1efb31ad5ab573727ecb5f83155162ea2580381f4092020b930cb29229a1c903c5ae90f2edb6be89d28d75c738d71a35cb972ac8dd91e50ecf79c000292075227ef52f29ff916eaf9f80b7d83ad5ab592ddbb771b3bf5e4bb9e80a7400002ff258080e43312745baf5ebee49c96d6436d1b366cf02d5d3983329c04381b12ceb86055f00410901462c0ba480a9022fc88de56a89b2cb474ead429719361845dc63508a44400014909d3e979b4581749115c441e7352a8a83bdf7cf38de8bdf11408c49d000292c608208f561ab022f6a8eefa6adebcb9f1aa448912262124050271278080a43902745de4adb7de4ad4d2a47e5f7ffd35eb226972b4f1f16eddba89a67ad7c235c93646109bbd268080b8249a7c65ae8a88164eafbb8469513516d42d0a16a6fa4e0001290062bd4f44535d24efd2d2e6f6ecd9637e4f891e01bde35d133d6accf5fe908f3ffe387a4ee2110452248080a4082aafc7341becb871e3b25ddfeadcb4b77af56aa951a346017ba07ad808686247cd9da665e5ca9552b366cdb099883d10c8080104c423cc9a3769e0c081a709897e537defbdf7e4ca2baff4a8279a099ac0f1e3c713a2e1f5cd8841fb46ff1048870002920ead149eddbc79b3b46bd7ee3421d17592975f7e597af6ec99422b3c127602c9c916f567cd99468140dc0820203e465c6fcfd35b0f93d748747a4be7d0870c19e263cf349d0902245bcc0465fa083301042403d1d19d3b39effcd637127d1b193f7e7c062ca00b3f08ac59b346ba77ef6e9ad65d79ce165f3ffaa24d088491000292c1a8e4f646a2ddb768d142b2b2b23268095d79454063e7dc49327bf66c69d9b2a5574dd30e04424f0001092044ce1b8976eddc82a83fd7aa55cbeceaa1d84580db0bed8a17d67a470001f18e65da2de916df63c78e2516dc9dedbf152a5430a7db297610d053e9ba955b4b8f1e3d123fdb613d5642c03d0104c43d3bcf6aea9bc7d1a3474f1392e2c58bcb8e1d3b3ceb8786fc23a06741747baf965dbb76896eefa54020ea0410901045b85ebd7af2f7df7f2716dc9d379222458ac80f3ffc10224b31252701158dd6ad5b9b5f972e5d5af436430a04a24e00010961849b356b96c8abe5ac91e8ff754bb0a649a184934072b245bd43a46bd7aee13414ab20e0110104c423907e34d3be7d7bd183895a9cb324246ef483b4776d56a95225112bae40f68e2b2d8593000212ceb864b3aa77efdeb274e9d2d3844445453fa41c71b1c095c89b386ddab4c4a974bd3f84edd9910f79ac1d44402c0afff0e1c365ca9429d984c45927d15bf2ca9429639137d135b56eddba72e4c811e3a01e2ed44386140844910002626154df7efb6d79f8e187734ddcb870e14269dcb8b1855e45c7e483070f9a54ef5a8a152bc64ebae884164f721040402c1e125f7cf18559a8d5c575a7e81b89ae93e8ad891d3b76b4d83bbb4defd7af9f2c58b0c038f1d8638fc9800103ec7608eb21900b01042402c3e2d0a14352bf7efd5c13378e1a354afaf7ef1f012fed7381db0bed8b1916a7470001498f57e89fce2b03f0a04183e4d1471f0dbdfd513250373ef4e9d3c7b8a4590756ad5a1525f7f005028280447410e876522dc93bb4746aebaaabae32175c513243a049932672e0c001d3d9e2c58b456f33a440202a041090a844320f3ff2ca00ac535ecb962d8bb8f7e1708f648be1880356784f0001f19e69285bac56ad9a9c3871e2b47c5b152b5694f5ebd787d2e6a8183562c40899346992714717d7c78c191315d7f023e6041090980d80bc3200972c5952b66ddb16331a997357b9ab806be1847ae6b8d393bf0410107ff986b67512376636349a5cf19a6bae319d962b574e366edc985903e80d023e1040407c806a5393175d7491fcfefbefc6641237fa1bb9366dda240e154e9d3a55dab66deb6f87b40e019f0920203e03b6a5794d45be73e7ce8490e80f7a28d1b9aed5163fc26e276743c21e21ec4b870002920ead183cdba54b1759bb766dc25304c4dba0ebcd857a83a1167d2399316386b71dd01a0432480001c9206cba828012a853a78eb981528b26c13cf7dc730103012b09202056860da36d26b06fdf3ed154ef5a4a9428c1ee379b831973db1190980f00dc0f8640af5ebde4d34f3f359deb9496def94281806d041010db2286bd9121e02ca8b3592132218d9d230848ec428ec36121f0e1871f26d2bc376cd850162d5a1416d3b003022911404052c2c44310f087800a87a6e3d7b272e54aa959b3a63f1dd12a047c208080f800952621902a81e3c78f2744a3489122b27bf7ee54abf21c0402278080041e020c883b81fbefbf5f66cd9a6530906c31eea3c12eff1110bbe285b5112550b56a5573f25f0bc916231ae408ba85804430a8b8641f81356bd648f7eedd8de17a874b723600fbbcc1e2b8104040e21269fc0c3d81cb2ebb2cf1f6317bf66c69d9b265e86dc6c078134040e21d7fbc0f1901e76c48e1c28565cf9e3d21b30e7320909d0002c28880408808e8a9744db8a8a553a74e899b0c436422a640204100016130402064046ad5aa25c78e1d3356eddab54bce3efbec9059883910f82f010484910081901150d1d0fb59b4942e5d5af436430a04c2480001096354b029f604ba75eb265f7ef9a5e1f0da6baf49d7ae5d63cf0400e1238080842f265804014380648b0c84b0134040c21e21ec8b2d8169d3a6c9430f3d64fcd7fb43b2b2b262cb02c7c349000109675cb00a028640fdfaf5e5f0e1c3e6679dd2aa5cb9326420101a0208486842812110389dc0c18307a551a346e60fba1b4b17d82910080b0104242c91c00e08e441a06fdfbeb264c912f3573d23d2a3470f584120140410905084012320903f816ad5aac9c99327a564c992f2fdf7df830b02a120808084220c180181fc098c1d3b569e7ffe79f3d082050ba4499326208340e0041090c043800110488d80b3adb77cf9f2f2f5d75fa75689a720e0230104c447b8340d012f09f4e9d347962e5d6a9adcbc79b3942953c6cbe6690b0269134040d2464605080447c0790b69d0a04162613d386be839ee041090b88f00fcb78a40dbb66d65ebd6adc6666e2eb42a7491341601896458712aaa04fef8e30fb9e8a28b8c7beddab593b7de7a2baaaee297050410100b828489104826a03bb00e1c38c05b08c32270020848e021c00008a44760e3c68de6b2292d0f3ef8a03cf0c003e935c0d310f0880002e211489a81402609d4a953478e1e3d4a7a934c42a7afd30820200c0a08584860e6cc9989378f2953a648870e1d2cf402936d278080d81e41ec8f2d0127bd49a952a5123bb3620b03c70321808004829d4e21507002a3478f968913279a8656ac58217a973a0502992480806492367d41c06302cec1c24a952ac9dab56b3d6e9de620903f0104841102018b09f4ecd95356ad5a653cd8be7dbb142f5edc626f30dd360208886d11c35e08e420e0bc85e8f910cdd44b8140a608202099224d3f10f08940ab56ad64f7eedda675d29bf804996673258080303020603981e4f426ddba759309132658ee11e6db420001b12552d809817c08e8bde97a7f3a6f210c934c12404032499bbe20e013015d48d705752d63c68c917efdfaf9d413cd42e0ff0920208c06084484809e033976ec18e94d22124f1bdc40406c8812364220050293264d92112346982735d5892eae5320e0270104c44fbab40d810c1370d29b942e5d5ab66cd992e1dee92e6e041090b8451c7f234d60e8d0a1327dfa74e3e3ba75eba462c58a91f617e78225808004cb9fde21e039812a55aa48a14285a46ad5aab266cd1acfdba7410838041010c602042246a06bd7ae89bc587ac0b048912211f31077c2420001094b24b003021e113871e284d4a851c3b4d6bc7973c9cacaf2a8659a814076020808230202112470d9659799b426a74e9d92bd7bf746d0435c0a030104240c51c00608784c60fffefdd2b46953d3ea5d77dd2523478ef4b8079a83800802c22880404409346cd8500e1d3a24850b17963d7bf644d44bdc0a92000212247dfa86808f0492d39b8c1d3b3691eac4c72e693a6604109098051c77e345a066cd9a72fcf871295ab4a8ecdcb9335ecee3adef041010df11d301048223909cde442f9bd24ba72810f08a0002e21549da8140480938371696295346366fde1c522b31cb460208888d51c36608a441e0eebbef96b973e79a1a2a202a24140878410001f182226d4020e4049cb7104df9be62c58a905b8b79b61040406c89147642a000043a74e89098bee2def40280a46a36020808030202312070f4e851a953a78ef1b475ebd6f2fefbefc7c06b5cf49b0002e23761da87404808346bd64c7efef967630d6f2121098ae5662020960710f321902a81eddbb74b9b366d4caa774d6da2294e281028080104a420f4a80b01cb08d4af5f5f0e1f3e6c52bc6baa770a040a42000129083dea42c032027ac154f7eedd8dd57a7be1e0c1832df30073c3440001095334b005021920a07784ecdbb78f248b19601df52e1090a84718ff209083802ea0eb7d215a3a77ee2cafbffe3a8c20e08a0002e20a1b95206037816bafbd56366cd8609cd0248b9a6c91028174092020e912e379084480c0912347a46eddbac693162d5ac89c397322e0152e649a00029269e2f40781901048ce91b57efd7a39fffcf343621966d8420001b12552d809011f0854af5e5dfefdf75fa95dbbb62c5fbedc871e6832ca041090284717df2070060293274f96c71f7fdc3cb56cd932a957af1ecc20903201042465543c08816812d0b5105d13a950a14262613d9a9ee295d7041010af89d21e042c23b070e142b9e38e3b8cd5f3e6cd934b2eb9c4320f30372802084850e4e917022121b067cf1eb9fcf2cb8d35595959a2070d291048850002920a259e81404409689af7fbeebb4fe6cf9f2f65cb96954d9b3645d453dcf2830002e20755da84802504860c19223366cc30d6f6e9d3479e7df6594b2cc7cc30104040c210056c804040043efae82379eaa9a7e49f7ffe91d5ab57076405ddda4a0001b13572d80d0108402060020848c001a07b08400002b61240406c8d1c764300021008980002127000e81e02108080ad0410105b2387dd1080000402268080041c00ba87000420602b0104c4d6c861370420008180092020010780ee21000108d84a0001b13572d80d0108402060020848c001a07b08400002b61240406c8d1c764300021008980002127000e81e02108080ad0410105b2387dd1080000402268080041c00ba87000420602b0104c4d6c861370420008180092020010780ee21000108d84ae07f003a0b983fcdb39b2f0000000049454e44ae426082	\N	1	Preparateur	Controleur	9e74bad5-c9e7-445b-ad23-9e38baa4cf04	\N	\N
6082713a-d865-4e27-8a42-5bfedaa5c38d	C00000004	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	annulee	3691.50	Fatima Operatrice	\N	2026-03-26 11:04:24.277773+00	2026-03-26 11:30:47.484064+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07	C00000017	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_preparation	397.00	Fatima Operatrice	2026-04-07 11:48:49.901105+00	2026-04-07 11:48:01.080345+00	2026-04-13 12:16:42.036629+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
506905ec-c6d4-4c53-896e-3732e50f183b	C00000008	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	annulee	2151.58	Fatima Operatrice	\N	2026-03-26 12:22:32.284605+00	2026-03-26 12:23:12.881797+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
02d29f6f-7320-46de-9910-18a4a137f9fc	C00000009	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	annulee	1448.08	Fatima Operatrice	\N	2026-03-26 12:27:45.079296+00	2026-03-30 10:36:45.117185+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
39c1dfe9-f87e-48b9-82f9-585965bef503	C00000007	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_verification	6445.58	Fatima Operatrice	2026-03-26 11:30:31.016091+00	2026-03-26 11:29:21.70522+00	2026-03-30 11:31:15.049448+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
0bff5c32-f6f8-4986-92ea-b6a8147cba6a	C00000006	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_verification	198.50	Fatima Operatrice	2026-03-26 11:16:20.948245+00	2026-03-26 11:15:16.104921+00	2026-03-30 11:31:15.925571+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8749fa09-b997-45a6-b5be-e9b1f49c23d2	C00000005	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_verification	198.50	Fatima Operatrice	2026-03-26 12:23:05.23856+00	2026-03-26 11:04:39.866189+00	2026-03-30 11:31:25.491792+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
dbbca1b4-1782-4fd5-9255-9e458cdbd550	C00000013	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_verification	1600.11	Fatima Operatrice	2026-04-01 13:41:23.355428+00	2026-04-01 13:40:17.726588+00	2026-04-01 13:52:07.375652+00	\N	\N	\N	\N	1	Preparateur	\N	\N	\N	\N
106039b7-a430-4ce3-ae3a-e85ecdc1efa5	C00000014	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_verification	1700.22	Fatima Operatrice	2026-04-01 15:54:31.566159+00	2026-04-01 15:52:14.19294+00	2026-04-13 10:25:53.595996+00	\N	\N	\N	\N	1	Preparateur	\N	\N	\N	\N
f61d715f-0444-45bc-b848-927210e1a0b9	C00000010	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_verification	200.15	Fatima Operatrice	2026-03-30 17:59:59.730903+00	2026-03-30 17:58:54.571366+00	2026-04-01 14:15:30.158331+00	\N	\N	\N	\N	1	Preparateur	\N	\N	\N	\N
2c2e82ab-d610-4c51-9d96-3975c65d03db	C00000026	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_preparation	1038.80	Fatima Operatrice	2026-04-13 13:37:52.39389+00	2026-04-13 13:36:22.779086+00	2026-04-13 13:38:44.48995+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
be9e9a4e-ca96-4d21-ba90-b920221f2efc	C00000027	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	annulee	5990.00	Fatima Operatrice	\N	2026-04-13 13:36:37.303887+00	2026-04-13 13:40:12.116127+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	C00000022	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	prete	3604.50	Fatima Operatrice	2026-04-13 12:31:59.758077+00	2026-04-13 12:22:03.897684+00	2026-04-13 12:42:15.448184+00	\N	7785e358-83c4-41e6-9e6b-db5ded7b6e97	\N	\N	1	Preparateur	Controleur	7ea42bcb-2193-47f0-a179-57d7cded6983	\N	\N
48615e40-3d72-40e0-924d-fa4ea9ae3604	C00000025	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	prete	1366.74	Fatima Operatrice	2026-04-13 13:40:16.115625+00	2026-04-13 13:36:13.593355+00	2026-04-13 13:43:23.170466+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	\N	1	Preparateur	Controleur	f969c5ec-cc7e-4f7f-a504-a5a893c143f3	\N	\N
9bf827a6-b240-4200-a206-40f132b84460	C00000015	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_preparation	397.00	Fatima Operatrice	2026-04-13 12:31:54.636993+00	2026-04-01 15:58:51.958055+00	2026-04-13 13:06:05.124521+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	C00000023	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	prete	5019.32	Fatima Operatrice	2026-04-13 12:29:26.832473+00	2026-04-13 12:26:13.735977+00	2026-04-13 13:07:42.020693+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	\N	1	Administrator	Administrator	f969c5ec-cc7e-4f7f-a504-a5a893c143f3	\N	\N
3f80e2e0-8be4-44f0-981e-95810dc3d429	C00000016	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	prete	1366.74	Fatima Operatrice	2026-04-01 15:59:21.572491+00	2026-04-01 15:59:03.371038+00	2026-04-13 12:15:51.720845+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	\N	1	Administrator	Controleur	f969c5ec-cc7e-4f7f-a504-a5a893c143f3	\N	\N
96fdb118-00e1-4720-b8f9-2f3b30e58611	C00000018	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	livree	794.00	Fatima Operatrice	2026-04-13 10:25:07.994238+00	2026-04-13 10:11:11.642963+00	2026-04-13 13:10:48.252423+00	\N	1c2411aa-1f09-4c5d-8360-96180f6b4c54	\\x89504e470d0a1a0a0000000d4948445200000190000000c80806000000c615b7e2000017ad49444154785eeddd09f04fd5ffc7f177bf6c43a194752c1189c85a3165294b68c83669d1c86821831495b52629646bd14c0d6a8c658ad2265b4a64275b48194bf8b6d8da1452ffdee7ffbbdfdffd7e7db7cfc73d9fcfbde7f33c33bf213e9f7bee799cfbfbbedc7bee39e7827ffe2d424100010410402046810b089018c5f8380208208080112040b8101040000104e2122040e262e34b08208000020408d70002082080405c0204485c6c7c09010410408000e11a4000010410884b8000898b8d2f218000020810205c0308208000027109102071b1f125041040000102846b0001041040202e0102242e36be84000208204080700d2080000208c4254080c4c5c69710400001040810ae010410400081b8040890b8d8f812020820800001c23580000208201097000112171b5f42000104102040b8061040000104e2122040e262e34b08208000020408d70002082080405c0204485c6c7c09010410408000e11a4000010410884b8000898b8d2f218000020810205c0308208000027109102071b1f1250410400081d007489932654c2f8d1831427af7ee4d8f2180000208844420d401d2a2450bd9b973e73954b56ad592850b17868490d340000104525320d401a25d52ae5c39f9e79f7fe4820b2ec8d043fa675a8a152b9665c8a46677d26a041040207102a10f10a558b76e9db46fdf5efef39fff1899acc24403a560c182327efc78e9dcb973e204a909010410485181480488bf6f3a75ea24ab57af4e0f91ecee4cf4cf5bb56a25d3a74f4fd1aea5d9082080805d81c805889fa379f3e6b26bd7ae6cc3443fab7726fabf92254bcafaf5eba54081027645393a020820902202910e107f1fd5ab574fd2d2d2720d13fd8e3eea9a3973a6346edc3845ba996622800002c10b3813207e9aabaeba4a7ef9e5171326991f71799ff306e1f5bfbb76ed2a93274f0e5e9723228000020e0b3819205e7f1d3870409a346922a74e9dca314cfcfd5bbe7c7959b3668dc35d4ed31040008160049c0e103fd1a79f7e2af7dc738ffcfdf7dfb98689777752a85021f9f0c30fa5468d1ac1687314041040c021819409107f9fe99b5943860c317f94d3632efd7b6f103e5fbe7cd2ab572f193972a443dd4f5310400081f805523240fc5cc3870f9769d3a6993fca6ac2a2ffb3fe71932a55aac88a152be297e79b08208040c405523e40fcfdd7bd7b7759b66c599ec2c47f7752b4685159b2648954a85021e29703a78f000208e45d8000c9c6aa5dbb76f2e5975fa6ff6d766f73791ff0ee4e2ebcf042e9d7af9f0c1a3428efbdc02711400081080a102079e8b4468d1ac9fefdfbcd27739af99ef971977eb661c386327ffefc3cd4c247104000816809102031f657eddab5e5c89123e784897f7c2473d0b0f0638cc87c1c010422214080c4d94dbffdf69be8ec77fd35abc0f0ee54320fccfb1f753df7dc73e6d5620a0208201045010224805ed3b1928e1d3bcae9d3a7b37ccca57fa8f34fb4782b0a67aeb669d3a6326bd6ac00ce8643208000028911204002767ee79d77cc20ba171899ef44bc3b10fd35739878734e4a942821dbb76f0ff8cc381c02082010ac000112ac6786a3bdf8e28bf2fcf3cf9bf92559dd79f8c74db21b9cd7098f7dfbf6b578961c1a010410884f800089cf2de66f75ebd6cd4c3cf44223abd782b39bc8a87733ba72f0bc79f362ae972f20800002b60408105bb2b91cb7478f1e66f2614e81e23f84f7b94b2fbd94c75b49ea33aa4500818c02044848ae88071e78c02cdce82f392d459f3f7f7ef9e4934fe4ca2baf0c490b380d04104835010224a43dfee0830f9a40c9697d2eefae44177a7ce28927a44f9f3e216d0da78500022e0a102011e9d5471e7944e6cc9993e38e8bda14ffc0bc37787ff1c5178bdee10c1c383022ade5341140200a020448147a298b731c3c78b0cc983123db792559352bf36c79fd8caedda5fb9d8c1b374e74963d05010410c8ab00019257a9107f4eef2c66cf9e9de5de2639bd2a9cb949dee332ff778a172f6e66cb7bfba78498c1e953d35d322fbae822b9e69a6b9c6e278d8b96000112adfecaf16c77efde2db7dc728b9c3d7b36fd51971706f7dd779fac5bb74e76edda257ffdf597f97bfff84a6eab0d67f578ac408102e6ee4537d9bae1861b1c920c5f532a57ae6cb666d657c1f5f71404c220408084a1172c9c43d5aa55e5f7df7fcfb07ab00686aedf95f96d2fad7ecc98313275ea54f31dff2c7a2f64720b18ffebc8fa7b7d4b4c275276e8d0c142eb52ef903d7bf694458b16499d3a75e4a38f3e4a3d005a1c4a01022494dd12dc49b56cd9d2cc1bf1cf84d71ff0458a14916fbef9264f15ad5cb95274e7c63d7bf6c8993367cc77fc773039858bb73c8b8eb554ac5851962f5f2efad6182536819f7efa499a376f2ec78f1f171dffeadfbf7f6c07e0d308581020402ca086f190dea0bb7f0f78ef2dad050b16c43d807ef2e44979e69967cc2cf95f7ffd35c31d4f4ef358f4eff44e272d2d2d8c5ca13ca7c58b178b3e8ad4a277238c8784b29b52eaa4089094ea6e317711baf2affef0f62ff4a80c3af744c733822aba11d7debd7b33dcfd640e95d2a54bcbc68d1b83aad2f9e3e8ebdc6fbdf5969940aa777314049229408024533fc97557ab56cd8c79f88bde95e8bf6cf55fbb4117bd5b69d3a68d7974e6ddfd1c3a7428e86a9c3e9eee3fa38fb20e1f3e2c0f3df49079b448412059020448b2e443546febd6ad65dbb66de68cfc77253a4ef2d5575f89be6d45098fc0860d1bd25f4e78efbdf7a4418306e13939ce24a504089094eaee9c1b3b6cd83099366dda3941a2a1f2f1c71fc73d4e0271f0024f3df594bcfefaeb52b66c59f328ab70e1c2c157c21111c8458000e1123947e08b2fbe105d7ede7b9d573fe0bd4da583b8a3478f462dc902bafb658b162dcc9896f6d5f8f1e3937c46549f8a0204482af67a0c6dae5ebdba79bbca3f4b5d7faf13087535604af20476ecd821b7de7aab99383a73e64c69d6ac59f24e869a5352800049c96e8fbdd1eddab513ddfb5d8b7f9c4497d7d079268c93c46e1ac437264d9a64d631d37d627496ba2e3d43412051020448a2a41da967d4a8513265ca94738244270ace9f3f5fead7afef484ba3d10c7dccd8b66d5bf31244ab56ad64faf4e9d13871ced2090102c4896e4c7c23d6af5f2f9d3b774e5f574bcfc07bccd5bd7b77b3173c253102fbf6ed939b6fbed9ac953579f264e9d2a54b622aa6969417204052fe12387f001d0fd12536bc59eede80bbaec7f5f9e79f9f7f051c21578137de7843860e1d6a56ec55f352a54ae5fa1d3e80c0f90a1020e72bc8f7d3056ebbed3633abdcbf5c8a3e62d1f9249b376f363fdc28f604f4ce63f5ead5a22b00cc9d3bd75e451c1981ff0a10205c0a810be86bbe2fbdf4d2390b38ea828ebaabe28d37de18789d1c50e4871f7e90264d9a88ce56d7b12a6fdd2c6c10b0254080d892e5b86616bb0ef0ea0abe99d7ddbae38e3b64e2c48928052cf0c1071f98254e0a162c28cb962d934a952a055c038743e07f020408574342046ad5aa25478f1e3575794bc1ebef7573245d2e9e129c409f3e7d44973851735d69d9bf947f70b5702404fefdfff2bf039eff008140a204f4cd2d7d4eef0589feaa9760a1428564ebd6ad8c9304d0113af1531f65fdf8e38f3268d020193060400047e510089c2b408070552445e085175e900913269c13247a77a26b3ce9a32f4afc02ab56ad92ae5dbb8acecf59b870a15939808240d0020448d0a21c2f2601dda35d27c079fbb47b7724fa6ba74e9de4e5975f8ee9787cf87f0243860c9137df7c53aa54a9224b972e65b5002e8ec0050890c0493960bc02d98d93942b574e74e2222536813ffffcd34c30dcbf7fbfd92c6cc48811b11d804f23908b0001c225123a017df4a22b026bf1bfbda5eb6d6ddab4c9acfb44c99b808e2be9e3401d6762ef90bc99f1a9bc0b102079b7e2930916d0c757cf3df75cfa1229fec75bafbdf69ae8c4454aee0263c78e354b9cb07748ee567c2236010224362f3e9d04017d04a36f15e9388957bce552f45fd753a74e4dc25945a74a75d365df77eedcc9de21d1e9b6489c290112896ee2243d81ba75eb9ad753fdfb93e8df952953c62ca342c95ae0db6fbf351b50e9a44ef60ee12a094a8000094a92e324544067b2ebfe175afce3243a035be799942e5d3aa1e71385caf4b1dfd34f3fcdde2151e8ac889c230112918ee234b316d03ddc870f1f7ece3889868aaec7a5af0253fe5f40efda3a74e860eed4d83b84ab220801022408458e9174017dac75fdf5d79b3d3132afbbd5ba756b365afa6f0f1d3a74c8bcdaab0b2e12b049bf6c237f020448e4bb9006641668d8b0a11c3c7830c3fe241a2a254b964cdf963795d5de7efb6db3bc097b87a4f255104cdb0990601c394a0805eebefb6eb3226de6fd49749c44375daa50a14208cf3a31a7a44bbd2f5ebc98bd4312c3ed6c2d0488b35d4bc33c015dcee3c9279f34ffe97fbca5bfd77926f7de7b6fca619d3871426ebae9263976ec187b87a45cef07d7600224384b8e147201fd61d9a04103d1d56af3e7cf6fe695e4cb97cf9c75b366cd64d6ac59216f41b0a7f7d9679f89dea5b17748b0aea974340224957a9bb61a015d5b4b8b6eb7ebdf2b43df52bafcf2cb65cb962d2923f5d8638fc9ecd9b3a55ebd7aa29b5151108845800089458bcf3a21a07721696969a62dbaa1d59e3d7bcceffd8fb77419745d4a455f7b75b99c3c79529a366d2a870f1f96c183074bfffefd5d6e2e6d0b588000091894c34543c0bb0bd1bb0efde1a98faff45fe3fe20d1dfebdf57af5edd0cc6bb5a74a5e3db6fbfdd344f07d66bd6ace96a536957c0020448c0a01c2e1a02fafcffaebbee4abfeb58b26489d974491f6be9af3a4ee22f1a24fad6d69a356ba2d1c018cff2d9679f952953a648d5aa55456d2808e4458000c98b129f7152a077efde6689736f8f76fd21aaafb77aa563c78eb26eddba7382e4e1871f96a143873a67a2130cbffefa6b519761c38639d73e1a14bc000112bc29478c90806ef7dab367cff410d1556b7579147f19376e9c4c9c3831fd6e45ff4e43473fa74b82b85274b55e5d7051cbbbefbe2bd75d779d2b4da31d960408104bb01c363a02df7fffbdf96179f6ec5933e651be7c7959bb76ed390d1833668c4c9a3429c3c444dde46af9f2e5ce4c4a7ce5955764f4e8d1ec1d129dcb37a9674a8024959fcac324a05beaea5c112dbadaef840913b23cbd6eddba9999ecfeb7b674df716f75e030b5299e73d137cf366cd860c688f4ee8b824076020408d706023e81c68d1b9b3dc4f54e64d1a245a2a1925dd1b9137af7e20f92a2458bcaae5dbb226d7ae0c00169debcb9e89eea3366cc308b2f5210c84a8000e1ba40c027a08fb12a55aa64dec62a52a488ecdebd3b579fabafbe5a7efef9e70c4152a850213346a233dca3587472a1bed6ac132bf5adace2c58b47b1199cb3650102c43230878f9e80eed83768d02013087a47a2abd7e6a5b46bd74e366dda943ebb5def6274a99411234648af5ebdf27288507d461f61e9f80e7b8784aa5b4275320448a8ba8393098b802ebea88b306a885c7bedb5b260c1823c9f9acee69e376f9eb98bf15e11d65f75dda9b163c7e6f938c9fee0d1a347cd828b7a77a5b3f2f5b5660a027e010284eb01816c04a64e9d6aee1eb4c41a22fa1d7da349dfdcd2451bfde324ba5f89ce3f8942d171207dcd99bd43a2d05b893f470224f1e6d41821019d9d3d6ad42813003ad6b174e9d298cf5e7f08ebe43c1d94f60749c58a15cddb5cba3270984bbf7efdcc1d55a3468d64eedcb9613e55ce2dc102044882c1a92e7a027a173179f264f3c3bf7efdfaf2fefbefc7d5089de5ddbe7d7bb34c8a3f4874805a57c2d55781c358f47c9b346922ba6db0ced6efd1a347184f93734a820001920474aa8c9e803ecad2475a7ab7b06fdfbef36a80ae80ab6f677df7dd771906dcc3fce6d6aa55aba46bd7aeec1d725e3defde970910f7fa94165910d01ffafa084b57e6d547524195acdedcd2a5e4478e1c19ba37b7bc10d5b931fa52817f2f95a03c384eb404089068f517679b4401bd632856ac98e864c1a08bbeb9e5bd2e1cd637b7740c475fe9d5fd531e7ffc71d1b1114a6a0b1020a9ddffb43e64023ad6327efcf873dedcd25780c3b0acc8f6eddba575ebd6468dbd434276f124e174089024a0532502b909e823a23e7dfac8e9d3a7d307dcf59191fecbbf6fdfbeb97dddeadfeb1a611a72ec1d6295391207274022d14d9c64aa0ae806567af7f1c71f7fa44f4ad41580758e898e9f24a3e804c9b66ddbcab66ddb4cc8b9b8374a325ca358270112c55ee39c534e40e75f0c1c3830fdd1962e93a293fbf4cf6bd7ae9d700f7d134d17593c75ea949914a9fbcc53524f800049bd3ea7c51116f0b69ef59aa04152aa5429d12d792fbbecb284b66cfaf4e966e7c2b265cb9a35b30a172e9cd0faa92cf9020448f2fb8033402066812e5dba88cecdf04f48ac56ad9a2c5bb62ca1afd77adbfeeaac7a3d1f4a6a091020a9d5dfb4d621015d63ab69d3a6b277efde0c41a24b8ee8d2238928ba46d8912347a466cd9ae6ad2c4a6a091020a9d5dfb4d641011d8f68d3a64d863d49b499b657ff7df4d14765ce9c39e68e4707fbcb952be7a02e4dca498000e1fa40c011015de8f1fefbef3703dbdea32dfde13e64c810b398639065cb962de64d2c2d3a0e12f4f1833c578e654f8000b167cb9111488ac0abafbe6a5610f68a0eb407fdea6f8d1a35cc1dcf15575c212b57ae4c4a3ba934f9020448f2fb803340c08ac080010332eca618d4abbf3cbab2d25d913c280112c96ee3a411c8bb803e6adabc79738681f60a152a98718b58cb8e1d3ba465cb96e66bac8715ab9e7b9f2740dceb535a8440960275ebd6357b7af88bde95e878892e257fc9259788064b9d3a75ccd2edbafa70e6a22bf11e3b764c2a57ae2c2b56ac403ac505089014bf00687e6a09ac5fbf5eeebcf34ed1e5e9b57883ed592968b8e8d2f21a2e254a9410fdef83070f9ab7aed6ae5d6b261052525b800049edfea7f5292ea08fb174fec6c68d1bcd0657c78f1f973367ce98b0c8aef0e82ac52f1a5ff30910ae050410c85260e1c2856666fbd6ad5b252d2d4d4e9c386156e08d675f7888dd142040dcec575a8500020858172040ac135301020820e0a60001e266bfd22a041040c0ba0001629d980a104000013705081037fb955621800002d6050810ebc45480000208b8294080b8d9afb40a010410b02e40805827a602041040c04d0102c4cd7ea55508208080750102c43a3115208000026e0a10206ef62bad42000104ac0b1020d689a9000104107053800071b35f6915020820605d8000b14e4c05082080809b0204889bfd4aab10400001eb02048875622a40000104dc142040dcec575a8500020858172040ac135301020820e0a60001e266bfd22a041040c0ba0001629d980a104000013705081037fb955621800002d6050810ebc45480000208b8294080b8d9afb40a010410b02e40805827a602041040c04d0102c4cd7ea55508208080750102c43a3115208000026e0a10206ef62bad42000104ac0b1020d689a9000104107053800071b35f6915020820605d8000b14e4c05082080809b0204889bfd4aab10400001eb02048875622a40000104dc142040dcec575a8500020858172040ac135301020820e0a60001e266bfd22a041040c0ba0001629d980a104000013705081037fb955621800002d6050810ebc45480000208b8294080b8d9afb40a010410b02e40805827a602041040c04d0102c4cd7ea55508208080750102c43a3115208000026e0a10206ef62bad42000104ac0b1020d689a9000104107053800071b35f6915020820605d8000b14e4c05082080809b0204889bfd4aab10400001eb02048875622a40000104dc142040dcec575a8500020858172040ac135301020820e0a60001e266bfd22a041040c0ba0001629d980a104000013705081037fb955621800002d6050810ebc45480000208b8294080b8d9afb40a010410b02e40805827a602041040c04d0102c4cd7ea55508208080750102c43a3115208000026e0a10206ef62bad42000104ac0b1020d689a9000104107053800071b35f6915020820605d8000b14e4c05082080809b0204889bfd4aab10400001eb02048875622a40000104dc142040dcec575a8500020858172040ac135301020820e0a60001e266bfd22a041040c0ba0001629d980a104000013705081037fb955621800002d6050810ebc45480000208b8294080b8d9afb40a010410b02e40805827a602041040c04d0102c4cd7ea55508208080750102c43a3115208000026e0a10206ef62bad42000104ac0b1020d689a9000104107053800071b35f6915020820605d8000b14e4c05082080809b0204889bfd4aab10400001eb02048875622a40000104dc14f83f47b2b130d12f99b80000000049454e44ae426082	\N	1	Administrator	Administrator	9e74bad5-c9e7-445b-ad23-9e38baa4cf04	\N	\N
7a976530-4b36-4705-8bf7-ce1168928a19	C00000029	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	397.00	\N	\N	2026-04-13 20:20:12.673589+00	2026-04-13 20:20:12.673589+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
81b6516c-629b-4d80-82d5-24a7801ae726	C00000030	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	911.16	\N	2026-04-13 20:21:37.453007+00	2026-04-13 20:20:19.723784+00	2026-04-13 20:21:37.447254+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6e7ffbab-0205-4987-b782-0f9dfae7d304	C00000028	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	livree	852.58	\N	2026-04-13 20:14:14.419314+00	2026-04-13 20:11:54.635136+00	2026-04-13 20:24:24.873207+00	\N	1c2411aa-1f09-4c5d-8360-96180f6b4c54	\\x89504e470d0a1a0a0000000d4948445200000190000000c80806000000c615b7e20000178049444154785eeddd6fb0555303c7f195484a09d50da5a474bbddca4d7feead4412217fca6d18066330e3355e99f1c21be385578c196318c38c6946122915f91b1129657453ba9594ae4849fea4f43cbffdccdecfdaa773ef3d679f75ef397bafef9a31ccd3d9fbecf55967fa3d6baf7f5d8effb7180a020820800002450a7421408a14e3e30820800002810001c20f01010410402091000192888d8b104000010408107e03082080000289040890446c5c84000208204080f01b4000010410482440802462e32204104000010284df00020820804022010224111b1721800002081020fc0610400001041209102089d8b808010410408000e13780000208209048800049c4c64508208000020408bf0104104000814402044822362e42000104102040f80d20800002082412204012b17111020820800001c26f00010410402091000192888d8b104000010408107e03082080000289040890446c5c84000208204080f01b4000010410482440802462e32204104000010284df00020820804022010224111b1721800002081020fc0610400001041209102089d8b808010410408000e13780000208209048800049c4c64508208000020408bf0104104000814402a90c90fbefbfdff4ebd7cf5c7ef9e5c13f5dbb764d54792e4200010410482e90ba00d9b56b97a9afaf8f6adcad5bb72848142683070f4eaec1950820800002050ba42e4054b32fbef8c27cf0c107c13f5f7df555acb235353551a04c9932a560083e8800020820509c402a03c4aee28f3ffe1885c9871f7e680e1d3a14fd71efdebd63bd93aaaaaae274f8340208208040ab02a90f90dc9aad5ab5ca2848d43b696a6a8afdf1b871e38240b9ecb2cbccf8f1e3f9592080000208942090b900b12d76ecd811f54e1428fffcf34ff4c7fdfbf70f82241c88efd3a74f098c5c8a000208f82790e900b19bf3e8d1a3b130d9be7d7bacb51b1a1aa230a9adadf5ef97408d114000812205bc09905c97cd9b374781a2d75e76193468506ceca47bf7ee45b2f27104104020fb02de0688ddb4bffffe7bac77a281f9b074e9d2251626c3860dcbfeaf821a228000020508102079903435389c26ac29c376193e7c782c500a30e6230820804026050890769af5e79f7f0ec2249cd9b57ffffee88ad34e3b2d162603070ecce48f844a21800002f9040890227f176bd6ac897a271b376e8c5d3d7af4e8689ab006e5290820804096050890125a77f7eeddb1b1933ffef823badb99679e199b26acbdbb28082080409604081087ad19bee6d22baf2d5bb6c4eeac858be19a93baba3a87dfcaad10400081f20810201de4be6ddbb658efe4df7fff8dbe69c08001b1b1935ebd7a75d053705b041040a0e30408908eb38deefcf7df7fc7c2e4fbefbf8f7debd4a953a34019397264273c115f81000208942e4080946e58f41dbef9e69b285056af5e1dbb7ec89021b1dec929a79c52f4fdb900010410e80c0102a43394dbf88e83070fc6a609b7b4b4449f3ef9e493636172c1051794f969f97a041040e0ff02044885fd1ad6ad5b17f54ebefcf2cbd8d35557574733bba64d9b56614fcee32080806f02044805b7f84f3ffd141b3b516f252c3d7bf68cf54ece3df7dc0aae098f8600025914204052d4aa1a2f09b758d1388a5dc68e1d1b05cac4891353542b1e150104d22a4080a4b4e534932b0c13fd5b33bdc272f6d967c77a27679d75564a6bc963974be091471e09cecf79fcf1c7cbf5087c6f0a0408901434527b8fa835267698680d8a5d264d9a1405ca983163dabb1d7feea180f67c9b33678ed1216cf69aa5071f7cd03cf0c0031e8a50e542040890429452f619ad820f0345abe3ed72de79e7c57a273d7af44859ed785c1702c78f1f378f3efaa879f9e5978dbd054feebdb55d0f0581d60408908cff36f49783bdc5ca0f3ffc10ab7178acaffe3d62c4888c6bf85b3dbd8e7aecb1c7ccc2850bcdafbffe1aeb65d82a279d7492d19105cb972f37ddba75f3178c9a1724408014c4949d0f7dfdf5d751efe4b3cf3e8b55ecc20b2f8c6d00d9b56bd7ec54dcb39afcf9e79fe689279e300b162c303a82403d8ed6cae9a79f6eeebaeb2ef3f0c30f7ba644754b1520404a154cf1f5fa7fa2f6d889de838745ffef33dcfc51ff1e3c78708a6b9afd476f6a6a32cf3cf38c59bc78b1397af468ab3d0c9db0a9bdd766ce9c699e7cf2c9ecc350c30e1520403a94375d37d7e98b61a0e85446bbd4d4d444813265ca9474552c434fabb541afbdf69a59b26489d164091dc76c0f7ae7565581a11e8602e3a9a79eca900455a9040102a4125aa1029f41e7c2dbbd13fd451596debd7bc77a27555555155883743fd2b163c78c0e2c7bf6d9678d7624d8b76f9f3972e448bb95d218861699ce9831c33cfdf4d3ed7e9e0f20508a0001528a9e47d7ae5ab52a0a94cd9b37c76a3e6edcb828502eb9e4128f54dc545561fdca2baf9865cb9605d3680f1f3edc66af42dfaa9e858e54d60e049a00a1310c8d615110e84c0102a433b533f25ddbb76f8f6d00a9193e61e9dfbf7fac7772c6196764a4d6a557433d08bd267ce185178c5e116accc9b66bed1bb4a9a64eb81c356a94696c6c0cd66b5010a8040102a4125a21c5cfa0bf00ed69c20a17bb4c9e3c393a27beb6b636c5352deed1355d5a6b2c56ae5c6976eedc69342baaadb18ab057a1753983060d32d3a74f3777df7db7d1ba1d0a02952a4080546acba4f4b9f47a2b1c3bd16b2fbbe82f467b6657f7eedd535acbff3fb682e1934f3e312fbdf492d114694d99d52ca8f68ace79d11633dac36cdebc79e6da6baf6def12fe1c818a1320402aae49b2f3401a78b707e2f5ae3f2c7a876f87c9b061c32abee2ea49bcf8e28b419d76edda15f42ada5a5fa10a69505bbd0a4d83beeaaaabcc3df7dc13bc8ea22090050102240bad98923ae8bd7f18281a0bb08b563fdb8152ce2a29f8de7bef3d337ffe7cb369d32673e0c081827a155a3ba38d2cebeaeaccadb7de1acc84a2209065010224cbad5bc175d300b2dd3bd1a2c6b06876911d2603070eecb09a3437379be79e7bce7cfcf1c766cf9e3de6afbffe2aa857a1b5153a2152af9eeebdf75e9385d7711d86cc8d332b408064b669d355316dab12068ac612ec327af4e82850eaebeb13554cbd88152b5698575f7dd5689c46877369ad455b45afd9d4abe8d7af9f99306182b9edb6db8c2605501040e07f020408bf848a13d00c26854938bbcbde2d56e30776efa46fdfbec1f3eb3c145df7f9e79f9bb56bd79aad5bb71a8db9a8675348af42fb7e698b0fada5b8fefaebcd7df7dd57712e3c100295264080545a8bf03c27082848d47b50a86820db2e1aa4d640767b83d9e13561af62c0800146bd99db6fbfddb0f8911f1d02c9040890646e5ce558407b3c7dfbedb7c194581dd7ab13177ff9e5976055b6d69a141a107a2c858ac624d45b39e79c738c16335e79e595e6ce3bef74fcd4dc0e01bf050810bfdbbf536aaf05747abdb47efdfae0159382420715e9f592a6c216b26ec2ee416865b606da15109a22ab5e8502c8de4d589f9f3a756af4ba6be4c8919d5257be04019f0408109f5abb0c757de8a18782e9b08596f015936639697c63c890214683e8e3c78f0f5e35b57582a27a2ee140fcead5ab635fa9fbd863275ac847410081d2040890d2fcb8ba1d01adb2cefdcb5c972828c26d3baebefa6aa37fb42adb55d12c2b7b9ab07a2861510fc60e134dc7a5208040f1020448f1665c51a4c0ebafbf1e0c826b519e06c1f36d2078eaa9a706eb2a1a1a1a82cd025d0f6c6b4bf4706697fedb2ed5d5d551a05c7ae9a545d68e8f23e0af0001e26fdb97ade61a03d1a148da2bebbbefbe0b06ca738ba6d56a234105c9ecd9b3cd15575ce1ec8cee969696d80690eaad8445afcec2de89b649d776e9140410c82f4080f0cb28bb805680bff9e69be6dd77df0d7a29f6aa74fbe1b4a06fcc9831c19e525a01aecd085d14bd620b5f77691cc52e175f7c71744efcc489135d7c1df7402033020448669a323b153974e850f0ca6bf9f2e5c1b9197bf7eecd3b8d57272386af9f6ebae92627e7b66bfab03d76a2058a61d13e57f6d889ab00cb4ecb5113df040810df5a3c85f5d51a908f3efac82c5ebc389806ac9d70f38da368edc7d0a1438dce6c9f3b776ed05b29a568fab11d263a83dc2e93264d8a02a5d4ef2ae539b9168172091020e592e77b4b12d07e56dad74a9b20ea2f767bbb93f0c69a6da58d18350558db93e890268dad242d5bb66c890245abe3eda2f11abb77d2d674e3a4dfcf7508549a000152692dc2f32412d04245f550b40d7b535353b0057b6ed1d4611db9abe9c29a367ccd35d704abd493140596dd3bd1c248bb68003e0c948b2eba28c957700d02152f4080547c13f180490434b36ad9b265c158ca860d1b8295eaf9b643e9d3a78fd12a75f54e348e92f408d98d1b3746d384b5b3b05db441a3dd3bd1562b1404b220408064a115a943bb021acf78fffdf783d95e3acc4a3d967c5ba8e8d593fec2d7384a636363102ec5161d6b6b9f136f6fb1a2f52ef634619d54484120ad0204485a5b8ee72e5940e78e2c5cb830d8c071fbf6edc1be5cb9455b9ee82c774de1bde1861b8229bdc5160556f8ba4bb3caec52535313058a428b82409a04089034b516cfdaa1029ac2ab55f3eaa968b1a3bdc030fc628da3682b78ad0f99356b56f08f161f165a7446893d76a2e373c3a269c9f6abaeaaaaaa426fcbe710288b0001521676be340d025ad0b874e952f3ce3bef188d71d8fb69d9cfaf5d81478d1a15ac96bff1c61b838029b468357e18289a59669771e3c64581e27a6b97429f8fcf21d0960001c2ef038102053466b272e5ca2054b49f96c651f21d8bdbb3674f336cd830a37db5b499a4febb90a2d76876efc41ea3d1ec31bb779274f65821cfc167102854800029548acf21904760ddba7566d1a245e6d34f3f0dc651747c6e6ed1b9eae79f7fbed1c243cdf42ae45c752d94b4c364c78e1db1dbea1e61a0a8f74341a01c02044839d4f9cecc0ae82f7a6d14a959581a47d1b62cb945d3787552625d5d5db0a797f6f6d201596d15ad6d096776e9b5975d144ef6cc2eadc8a720d0190204486728f31dde0ae8585e4d1dd6ab2fcdfaca3d353184d13e5bea49e8e85dcdf6d2c691ad150dbcdbbd130dcc8745e1a43009173216fafaccdb06a2e22509102025f1713102c5091c3972c4bcfdf6dbe6adb7de327afda59d88f38da368669756b04f9b362d588fd2d6a1579a1a1c068aa60cdb65f8f0e1b1b193e29e964f23d0b60001c22f0481320b6883488da3ac59b3c6e81598bd0370f8685a80a86379ebebeb837194d6b696570fc7ee9dd85be3eb35993d10af7dc228089422408094a2c7b508748040737373b051a47620deba75abb1d78a845fa74d2175d895a6fa5e77dd75c1384abe73deb5ad4a18287a8566179d351f068a82898240b1020448b1627c1e814e16d8b76f9f79e38d378203b774e095c655f2158d9bd4d6d69a99336706bb0fe79e57a269c776efc45e79afb52c76efa46fdfbe9d5c4bbe2e8d0204481a5b8d67f65a40538575d896368b5cbf7ebdd120baf6faca2dbd7af53223468c0882e1e69b6f0ea612db250c13cdeed256f5769930614214285a754f41209f0001c2ef02810c08683f2ff552349eb273e74ea3c1fadca2e9bd1a8c6f68683073e6cc095e7f854567d3db1b40da81a429c7f6346105130501091020fc0e10c8a080c64e348ea235230a87c3870f9f504b1db8a5edebb54dcaecd9b383575f9a06ac417cfb5597f608b38b56d887d38493ec569c416e6fab448078dbf454dc278196969660a3488da36cdab4c9d8b3b342076d14a971141dcfab41798da36883478dbb8481b27af5ea189b6686d96327f906f27d72f6adae04886f2d4e7d11f8af804e54d45a148da5681dc9debd7bf31eb8a53db7aaababa37114ad4fb17b27f60693ead1d861d2d6da151a211b02044836da915a2050b280c640742cb01623eab595f6e3ca2d5a4b3274e8d0e0c0adb973e706632d61a06861a45dc2e051a8e8b517257b020448f6da941a21e04440fb6f691c4503f4dbb66d0b7a2db945bd0e1db8a5595b0a097b13c8df7efb2dfab87a2e76ef4403f394f40b1020e96f436a8040a70868bab0368ad4815b0a9703070e9cf0bd1a47d1415863c78e0d8e0656a068dc44e32876d1d4e03050143e94740a1020e96c379e1a81b20b6885fc92254bcc8a152bcc860d1b8203b78e1f3f7ec273f5e9d32778eda5334db486455bdfdbdbb568d1a2bd0164ee02c8b257940768558000e1c7810002ce04b4ebb04265eddab566d7ae5dc63e142bfc921e3d7a04bd14ad27d16c307dce2e3a3725ec9d684618a572050890ca6d1b9e0c81d40be82860bdf6d2388a0edcb2b74f092ba77114cdf6d21460cd06b38bd6a9d863270a1f4ae508102095d3163c09029917d8bd7b773030af995b3a70ebe0c18327d459e3289aeda5d761b981132e6054a868bb7b4a79050890f2faf3ed08782da0995a9a3aac3352b45bb0368ecc378ea25e4aeeeb300dd2dbbd13ada2a774ae0001d2b9de7c1b0208b421a0f0d0a0bcc651b4ae443d967ce328eaa5d841a3f352ec30c9dd3812f48e1120403ac695bb22808023010589c65174b689c6513493abbda2e381c340993c79727b1fe7cf130a102009e1b80c0104ca23a0595b0b162c08760fd636f4f682c57c4fa481f719336698e9d3a707a1a2196014370204881b47ee8200026512d082466d14a929c41a47d1b1be6d15ad9cd74691b366cd0a7622a62417204092db7125020854a0c0b163c782c3b6962e5d1a1cb8b567cf1ea3ff2d5fd1d461cde6bae5965b4c636363309d9852b8000152b8159f440081940aac59b326e8a584e328f9368a54d5f4ba4b679cdc71c71d66debc7929ad6de73d3601d279d67c13020854888006e3358ea2195ffa6f7b6b95f0119f7ffef9e03517a5750102845f070208782fb07fff7e337ffe7cb368d122d3dcdc6c344d588b1d355e422140f80d20800002083816a007e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b10001e21894db21800002be081020beb434f5440001041c0b10208e41b91d020820e08b0001e24b4b534f041040c0b1c07f00ec44bc3f489d32ba0000000049454e44ae426082	\N	\N	Preparateur	Controleur	9e74bad5-c9e7-445b-ad23-9e38baa4cf04	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	\N
18a1fd87-3e0b-477f-a337-39709652df94	C00000031	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	retournee	397.00	\N	2026-04-13 20:21:23.171205+00	2026-04-13 20:20:29.891498+00	2026-04-13 20:24:38.920928+00	\N	1c2411aa-1f09-4c5d-8360-96180f6b4c54	\N	k	\N	Preparateur	Controleur	9e74bad5-c9e7-445b-ad23-9e38baa4cf04	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	\N
9eac02e4-6c72-4e43-8eab-9a03d0b97c26	C00000032	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	200.22	\N	\N	2026-04-14 22:04:13.281688+00	2026-04-14 22:04:13.281688+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
634eadc7-857c-4ff9-8163-5b54a9eb0dda	C00000042	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	prete	852.58	\N	2026-06-15 15:51:37.064921+00	2026-06-15 15:51:36.801539+00	2026-06-15 15:51:40.249629+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	\N	3	Preparateur	Controleur	5afebd2a-5d57-469b-8dc1-1aaa3a437189	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	\N
712e33d3-a45d-4ec6-82e1-488c453c04af	C00000039	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 15:50:37.853567+00	2026-06-15 15:50:37.758943+00	2026-06-15 15:50:37.850071+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	Quantité erronée, merci de corriger la ligne 1
4557c818-1e9d-4727-b43e-bcc5492248d6	C00000040	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	198.50	\N	\N	2026-06-15 15:50:39.320869+00	2026-06-15 15:50:39.320869+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
846e1200-4c52-443a-8e39-3c7e1a60e6d0	C00000041	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	198.50	\N	\N	2026-06-15 15:50:41.907222+00	2026-06-15 15:50:41.907222+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7646e2c0-c917-471f-98a8-29c2fc69479b	C00000033	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_route	852.58	\N	2026-06-15 15:50:25.453265+00	2026-06-15 15:50:25.373796+00	2026-06-15 15:50:28.296602+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	\N	3	Preparateur	Controleur	5afebd2a-5d57-469b-8dc1-1aaa3a437189	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	\N
e7b4011b-5ed7-4f24-9ad2-2a04312b074e	C00000034	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	397.00	\N	\N	2026-06-15 15:50:29.721159+00	2026-06-15 15:50:29.721159+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
28b1f7b8-fe5e-45df-8bb4-c41ac4843a4c	C00000035	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	992.50	\N	\N	2026-06-15 15:50:31.065853+00	2026-06-15 15:50:31.175989+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
74e329cd-12fa-4a22-ac80-9c24b5d0e375	C00000036	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	annulee	198.50	\N	\N	2026-06-15 15:50:32.488775+00	2026-06-15 15:50:32.538317+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3f8b751f-b7e4-4caf-a7f1-66a3cc2f9f5e	C00000037	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 15:50:34.336875+00	2026-06-15 15:50:33.9261+00	2026-06-15 15:50:34.331446+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
bdb4d02b-fdb8-481a-949a-1793843e552b	C00000038	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 15:50:36.343251+00	2026-06-15 15:50:36.296772+00	2026-06-15 15:50:36.337415+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
53b0ca21-ecda-4875-8b88-45e6a4426f74	C00000047	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 16:04:07.376717+00	2026-06-15 16:04:06.904612+00	2026-06-15 16:04:07.367451+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
b457ab88-16a4-423c-a37c-7c9373b01e00	C00000043	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_route	852.58	\N	2026-06-15 16:03:55.033887+00	2026-06-15 16:03:54.94945+00	2026-06-15 16:03:58.401873+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	\N	3	Preparateur	Controleur	5afebd2a-5d57-469b-8dc1-1aaa3a437189	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	\N
06a1f38a-7a9b-4821-9370-040ff3df9e56	C00000044	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	397.00	\N	\N	2026-06-15 16:04:00.515329+00	2026-06-15 16:04:00.515329+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7e3dbefd-9e34-4af7-8137-bd435e68555e	C00000048	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 16:04:10.06422+00	2026-06-15 16:04:10.006973+00	2026-06-15 16:04:10.056726+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
e23d80e3-a890-4a3a-801a-b2b74b3e07d6	C00000045	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	992.50	\N	\N	2026-06-15 16:04:02.638432+00	2026-06-15 16:04:02.774949+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
17f6af5e-4fd3-468b-8f54-1a522a6328da	C00000046	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	annulee	198.50	\N	\N	2026-06-15 16:04:04.809129+00	2026-06-15 16:04:04.852021+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
40505262-756a-49d3-9366-d9b9feb92cd6	C00000051	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	198.50	\N	\N	2026-06-15 16:04:18.57493+00	2026-06-15 16:04:18.57493+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
afd7ad6c-776b-4c2c-9c6a-ce0134c65366	C00000049	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 16:04:12.361571+00	2026-06-15 16:04:12.237768+00	2026-06-15 16:04:12.349117+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	Quantité erronée, merci de corriger la ligne 1
5913d330-9751-4b2e-b4d8-1696ce89b897	C00000050	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	198.50	\N	\N	2026-06-15 16:04:14.558401+00	2026-06-15 16:04:14.558401+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
c7c6368e-e59a-49c9-b59d-1c42c7f6d935	C00000054	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_route	852.58	\N	2026-06-15 16:43:18.653643+00	2026-06-15 16:43:18.567044+00	2026-06-15 16:43:21.268378+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	\N	3	Preparateur	Controleur	5afebd2a-5d57-469b-8dc1-1aaa3a437189	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	\N
70932ee6-bdba-4e93-b487-e0e51c7452f9	C00000053	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	prete	1688.63	\N	2026-06-15 16:14:02.731244+00	2026-06-15 16:12:09.835448+00	2026-06-15 16:20:36.975657+00	\N	1c2411aa-1f09-4c5d-8360-96180f6b4c54	\N	\N	4	Preparateur	Controleur	777b09a3-e9bf-42bb-9187-bc037bf8af6e	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	\N
0b133ab5-eeb5-42b1-8079-3e31ad4f13aa	C00000055	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	397.00	\N	\N	2026-06-15 16:43:23.151611+00	2026-06-15 16:43:23.151611+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
f619698f-e21f-4f0a-9fc3-e615b19b2d35	C00000056	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	992.50	\N	\N	2026-06-15 16:43:24.668551+00	2026-06-15 16:43:24.816121+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
fbceed4c-73b9-475f-9ebc-48f2aed910f9	C00000057	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	annulee	198.50	\N	\N	2026-06-15 16:43:26.219427+00	2026-06-15 16:43:26.251427+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9d504663-a4f6-4855-bdec-407cfabc199a	C00000058	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 16:43:27.99631+00	2026-06-15 16:43:27.547502+00	2026-06-15 16:43:27.985656+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
54d4a168-cd3c-4ad7-8531-def1a75875e3	C00000059	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 16:43:29.848599+00	2026-06-15 16:43:29.803905+00	2026-06-15 16:43:29.840087+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd	C00000060	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 16:43:31.272025+00	2026-06-15 16:43:31.18495+00	2026-06-15 16:43:31.265314+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	Quantité erronée, merci de corriger la ligne 1
2a5a4167-cccc-4d00-87b1-0eff74f20216	C00000061	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	198.50	\N	\N	2026-06-15 16:43:32.672836+00	2026-06-15 16:43:32.672836+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
b705c340-b2ca-4528-91b2-f3ca83436d38	C00000062	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	198.50	\N	\N	2026-06-15 16:43:35.410846+00	2026-06-15 16:43:35.410846+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
92980492-7923-4866-89ef-216fcebc8722	C00000076	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-16 21:31:07.75291+00	2026-06-16 21:31:07.168494+00	2026-06-16 21:31:07.737096+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
457419d7-14e1-4dec-844e-2dbeea4821b6	C00000077	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-16 21:31:10.637475+00	2026-06-16 21:31:10.588289+00	2026-06-16 21:31:10.627181+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
a19333cc-805c-43e4-be89-f1aadcc380c5	C00000078	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-16 21:31:12.942518+00	2026-06-16 21:31:12.831059+00	2026-06-16 21:31:12.935873+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	Quantité erronée, merci de corriger la ligne 1
e2a62896-8c70-49b0-980a-36481afedbaf	C00000079	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	198.50	\N	\N	2026-06-16 21:31:15.183821+00	2026-06-16 21:31:15.183821+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
d7705f0f-c48a-4e3b-b111-42b4a08a8d6e	C00000080	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	198.50	\N	\N	2026-06-16 21:31:19.484326+00	2026-06-16 21:31:19.484326+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	C00000063	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_route	852.58	\N	2026-06-15 16:53:28.381385+00	2026-06-15 16:53:28.275024+00	2026-06-15 16:53:31.35922+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	\N	3	Preparateur	Controleur	5afebd2a-5d57-469b-8dc1-1aaa3a437189	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	\N
453dcf46-2d66-4bd3-b62d-7fb36a3effc4	C00000064	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	397.00	\N	\N	2026-06-15 16:53:37.187753+00	2026-06-15 16:53:37.187753+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
a90de1fe-e8f3-4c96-8107-69eba971d1a8	C00000052	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_route	852.58	\N	2026-06-15 16:04:51.794467+00	2026-06-15 16:04:51.475748+00	2026-06-16 21:32:13.53334+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	\N	2	Preparateur	Controleur	5afebd2a-5d57-469b-8dc1-1aaa3a437189	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	\N
2fc0b24c-d935-4eac-9157-8563b3a8f368	C00000065	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	992.50	\N	\N	2026-06-15 16:53:38.572381+00	2026-06-15 16:53:38.69785+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
d9a2e9ba-5d30-42c9-a776-f05e2ba3c181	C00000066	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	annulee	198.50	\N	\N	2026-06-15 16:53:40.012486+00	2026-06-15 16:53:40.060369+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1c82273c-17f9-46c1-984b-ba0d11ce9022	C00000067	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 16:53:41.893898+00	2026-06-15 16:53:41.444322+00	2026-06-15 16:53:41.885247+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
e19fd8f0-1dc2-4dba-ab94-bd32bb9fc2c5	C00000068	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 16:53:43.890221+00	2026-06-15 16:53:43.832536+00	2026-06-15 16:53:43.880048+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5b7c805d-1652-4f86-997e-88a6cedb2195	C00000069	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	acceptee	198.50	\N	2026-06-15 16:53:45.464283+00	2026-06-15 16:53:45.365555+00	2026-06-15 16:53:45.454935+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	Quantité erronée, merci de corriger la ligne 1
84f1e647-a353-47f8-9bdf-ee221e62ca60	C00000070	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	198.50	\N	\N	2026-06-15 16:53:46.915217+00	2026-06-15 16:53:46.915217+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
d24acb48-0718-4829-a4ed-fe14a7802da7	C00000071	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	198.50	\N	\N	2026-06-15 16:53:49.849639+00	2026-06-15 16:53:49.849639+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	C00000072	80b3ae99-edfc-4220-a471-03c5366fb10d	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	en_route	852.58	\N	2026-06-16 21:30:47.331255+00	2026-06-16 21:30:47.175998+00	2026-06-16 21:30:51.073653+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	\N	3	Preparateur	Controleur	1685895d-2865-4d2b-b8ae-d58fa87793e5	3fce8dc2-16e0-4ce6-b41c-c0657216eb62	\N
5b1e91d7-c0c9-475f-93a8-8de762593946	C00000073	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	397.00	\N	\N	2026-06-16 21:31:00.838013+00	2026-06-16 21:31:00.838013+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
e2d05f89-d54e-4c4e-81b4-4fa08d44badc	C00000074	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	creee	992.50	\N	\N	2026-06-16 21:31:02.934445+00	2026-06-16 21:31:03.064467+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
0007eb5b-90a6-458f-b83f-1581a2c8245a	C00000075	80b3ae99-edfc-4220-a471-03c5366fb10d	\N	annulee	198.50	\N	\N	2026-06-16 21:31:05.128306+00	2026-06-16 21:31:05.16546+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: creances; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.creances (id, pharmacien_id, facture_id, montant_total, montant_paye, statut, echeance, created_at, updated_at, created_by) FROM stdin;
c9e75bb7-acc9-41c1-a09f-3d27d6eeb2b2	80b3ae99-edfc-4220-a471-03c5366fb10d	046d60a0-8f87-4529-a5c3-7dfafef7dc89	852.58	0.00	en_attente	2026-07-15	2026-06-15 15:50:25.440264+00	2026-06-15 15:50:25.440264+00	\N
c3ba29be-1f17-4bde-80e2-a2646ed34db2	80b3ae99-edfc-4220-a471-03c5366fb10d	36da2157-5f10-44ff-af9a-d9cca814d0ef	198.50	0.00	en_attente	2026-07-15	2026-06-15 15:50:34.331446+00	2026-06-15 15:50:34.331446+00	\N
d070fdf9-7784-4036-9393-3ce27a558207	80b3ae99-edfc-4220-a471-03c5366fb10d	77f5887f-3062-44fe-bfa1-c778a8b6e8e1	198.50	0.00	en_attente	2026-07-15	2026-06-15 15:50:36.337415+00	2026-06-15 15:50:36.337415+00	\N
6f346a45-b7b2-429c-9697-c92e153684cd	80b3ae99-edfc-4220-a471-03c5366fb10d	e91fc11a-f8c2-4977-8d51-04e9efdf4288	198.50	0.00	en_attente	2026-07-15	2026-06-15 15:50:37.850071+00	2026-06-15 15:50:37.850071+00	\N
f1ed1bd1-0fb9-421f-8cf5-9b02d20c8129	80b3ae99-edfc-4220-a471-03c5366fb10d	70f35145-f5af-4763-907b-acc82e696f46	852.58	0.00	en_attente	2026-07-15	2026-06-15 15:51:37.056864+00	2026-06-15 15:51:37.056864+00	\N
0bb1f412-e3bd-4edd-b974-af7c1afaef02	80b3ae99-edfc-4220-a471-03c5366fb10d	905ea0a2-811c-4610-85ba-7c45e9b74124	852.58	0.00	en_attente	2026-07-15	2026-06-15 16:03:55.016795+00	2026-06-15 16:03:55.016795+00	\N
ce68b54e-76ce-4f0f-838c-0191ce205ea7	80b3ae99-edfc-4220-a471-03c5366fb10d	916b66d7-ef8d-4016-86db-d1c21b95e4ac	198.50	0.00	en_attente	2026-07-15	2026-06-15 16:04:07.367451+00	2026-06-15 16:04:07.367451+00	\N
c0f369ea-97e2-4192-a844-ad158d6851b3	80b3ae99-edfc-4220-a471-03c5366fb10d	2da19ffc-1863-43e7-8606-9c32287eee54	198.50	0.00	en_attente	2026-07-15	2026-06-15 16:04:10.056726+00	2026-06-15 16:04:10.056726+00	\N
89e42005-8e22-4562-812b-02b100466d58	80b3ae99-edfc-4220-a471-03c5366fb10d	b294d7fb-9f0e-4565-b577-e06b7ce9735c	198.50	0.00	en_attente	2026-07-15	2026-06-15 16:04:12.349117+00	2026-06-15 16:04:12.349117+00	\N
e480aff8-9d2d-4b8c-9a1f-6abde50d4161	80b3ae99-edfc-4220-a471-03c5366fb10d	cbdeddeb-90ad-4a39-a18a-22d6fe271001	852.58	0.00	en_attente	2026-07-15	2026-06-15 16:04:51.786482+00	2026-06-15 16:04:51.786482+00	\N
bdead561-912d-4c66-a819-2c2ab91d5560	80b3ae99-edfc-4220-a471-03c5366fb10d	73fb6564-1952-4140-b828-cd51002bad57	1688.63	0.00	en_attente	2026-07-15	2026-06-15 16:14:02.696749+00	2026-06-15 16:14:02.696749+00	\N
3d207881-2cad-4c03-b44d-d92a8e076803	80b3ae99-edfc-4220-a471-03c5366fb10d	bc33a881-5a97-4eee-a342-ac5d750f0c03	852.58	0.00	en_attente	2026-07-15	2026-06-15 16:43:18.644412+00	2026-06-15 16:43:18.644412+00	\N
2698d758-aad2-44f1-9264-51b946b65cb1	80b3ae99-edfc-4220-a471-03c5366fb10d	b9f235d9-8e88-48a3-b54a-2a8d608a53c8	198.50	0.00	en_attente	2026-07-15	2026-06-15 16:43:27.985656+00	2026-06-15 16:43:27.985656+00	\N
ac34b4e2-ebb4-420a-a56e-984476235897	80b3ae99-edfc-4220-a471-03c5366fb10d	17075960-1745-48e1-ad66-0f1508214537	198.50	0.00	en_attente	2026-07-15	2026-06-15 16:43:29.840087+00	2026-06-15 16:43:29.840087+00	\N
6acf13a0-dcdf-4c18-b3f7-565ab1d8f76b	80b3ae99-edfc-4220-a471-03c5366fb10d	ac1b4eee-b02c-42bd-a3cd-3856df14b813	198.50	0.00	en_attente	2026-07-15	2026-06-15 16:43:31.265314+00	2026-06-15 16:43:31.265314+00	\N
83af5001-8f3b-4114-ae6e-d8c3253764be	80b3ae99-edfc-4220-a471-03c5366fb10d	62097201-b302-4f98-a35f-2046c88d4d1c	852.58	0.00	en_attente	2026-07-15	2026-06-15 16:53:28.367368+00	2026-06-15 16:53:28.367368+00	\N
7b0b5387-9832-4f75-b50b-fed1b6db5aa9	80b3ae99-edfc-4220-a471-03c5366fb10d	592ba8bd-ebfa-4cf4-9ecb-eaf0c4f95369	198.50	0.00	en_attente	2026-07-15	2026-06-15 16:53:41.885247+00	2026-06-15 16:53:41.885247+00	\N
fff05989-44b3-458a-a0e3-8dc0504f0fe4	80b3ae99-edfc-4220-a471-03c5366fb10d	7e944020-3254-4f86-b8f9-3b34636f65b7	198.50	0.00	en_attente	2026-07-15	2026-06-15 16:53:43.880048+00	2026-06-15 16:53:43.880048+00	\N
19e840a9-94e1-4dd1-b54b-e0aaf6fa811a	80b3ae99-edfc-4220-a471-03c5366fb10d	e5c33d2f-432b-40f7-b114-67acaa6062fe	198.50	0.00	en_attente	2026-07-15	2026-06-15 16:53:45.454935+00	2026-06-15 16:53:45.454935+00	\N
3a11a80e-d7b2-4b12-9585-03b5cb752071	80b3ae99-edfc-4220-a471-03c5366fb10d	efad879a-e5af-42e3-83ca-594ca5b5fbfd	852.58	0.00	en_attente	2026-07-16	2026-06-16 21:30:47.31459+00	2026-06-16 21:30:47.31459+00	\N
fc481d8f-02f3-4a55-9d0b-f3dd7efc2381	80b3ae99-edfc-4220-a471-03c5366fb10d	9b6dac7f-b2f8-4b03-b536-bc3cd769c8a9	198.50	0.00	en_attente	2026-07-16	2026-06-16 21:31:07.737096+00	2026-06-16 21:31:07.737096+00	\N
30c6143d-1965-4f2d-9a63-c8ae6ea9da60	80b3ae99-edfc-4220-a471-03c5366fb10d	16eea11e-d475-438f-8032-f55a85c04ec5	198.50	0.00	en_attente	2026-07-16	2026-06-16 21:31:10.627181+00	2026-06-16 21:31:10.627181+00	\N
f68da13a-e90d-4a15-8e76-d157bb35d98a	80b3ae99-edfc-4220-a471-03c5366fb10d	aa05aac0-5db6-4187-80c9-ca6a5efe0834	198.50	0.00	en_attente	2026-07-16	2026-06-16 21:31:12.935873+00	2026-06-16 21:31:12.935873+00	\N
\.


--
-- Data for Name: factures; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.factures (id, reference_id, commande_id, date_emission, montant_ht, montant_ttc, created_at, updated_at, created_by) FROM stdin;
385fdfc5-aac8-4ee7-8200-4cb87191099d	F0000000001	0bff5c32-f6f8-4986-92ea-b6a8147cba6a	2026-03-26 11:16:20.953454+00	198.50	198.50	2026-03-26 11:16:20.943614+00	2026-03-26 11:16:20.943614+00	\N
515ed173-8943-4982-9095-18dbb6ffdae4	F0000000002	39c1dfe9-f87e-48b9-82f9-585965bef503	2026-03-26 11:30:31.026851+00	6445.58	6445.58	2026-03-26 11:30:31.006884+00	2026-03-26 11:30:31.006884+00	\N
c0939582-1194-4bd3-82c0-198162364b7e	F0000000003	8749fa09-b997-45a6-b5be-e9b1f49c23d2	2026-03-26 12:23:05.243816+00	198.50	198.50	2026-03-26 12:23:05.207857+00	2026-03-26 12:23:05.207857+00	\N
310fd98f-4df3-44dc-aba8-e5b245ab9ad4	F0000000004	f61d715f-0444-45bc-b848-927210e1a0b9	2026-03-30 17:59:59.739572+00	200.15	200.15	2026-03-30 17:59:59.728342+00	2026-03-30 17:59:59.728342+00	\N
8f2a34eb-6468-49ab-a65d-2a5d5505fac6	F0000000005	dbbca1b4-1782-4fd5-9255-9e458cdbd550	2026-04-01 13:41:23.362026+00	1600.11	1600.11	2026-04-01 13:41:23.351868+00	2026-04-01 13:41:23.351868+00	\N
9ab4d7db-3372-431a-9d16-62bf5560b1f0	F0000000006	106039b7-a430-4ce3-ae3a-e85ecdc1efa5	2026-04-01 15:54:31.57234+00	1700.22	1700.22	2026-04-01 15:54:31.561759+00	2026-04-01 15:54:31.561759+00	\N
907d247c-c0be-4b56-b8df-db9c8f8cca2b	F0000000007	3f80e2e0-8be4-44f0-981e-95810dc3d429	2026-04-01 15:59:21.577759+00	1366.74	1366.74	2026-04-01 15:59:21.568905+00	2026-04-01 15:59:21.568905+00	\N
36435051-5689-46eb-a657-69d75d186aa8	F0000000008	fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07	2026-04-07 11:48:49.91804+00	397.00	397.00	2026-04-07 11:48:49.89656+00	2026-04-07 11:48:49.89656+00	\N
e78fb4f8-980a-42bd-8a0d-189b6621bd74	F0000000009	96fdb118-00e1-4720-b8f9-2f3b30e58611	2026-04-13 10:25:08.006986+00	794.00	794.00	2026-04-13 10:25:07.989227+00	2026-04-13 10:25:07.989227+00	\N
5a948b84-b9c8-4226-bfc1-f78fd99c1752	F0000000010	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	2026-04-13 11:37:17.585242+00	198.50	198.50	2026-04-13 11:37:17.560937+00	2026-04-13 11:37:17.560937+00	\N
ab9f0288-c002-40d2-928e-8e79405e105c	F0000000011	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	2026-04-13 12:29:26.864601+00	5019.32	5019.32	2026-04-13 12:29:26.819267+00	2026-04-13 12:29:26.819267+00	\N
9563b234-afc2-406f-9e6d-1969ae1ff186	F0000000012	9bf827a6-b240-4200-a206-40f132b84460	2026-04-13 12:31:54.660401+00	397.00	397.00	2026-04-13 12:31:54.62788+00	2026-04-13 12:31:54.62788+00	\N
05413a45-651f-4684-be6b-e1f4dcc8c0dd	F0000000013	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	2026-04-13 12:31:59.779069+00	3604.50	3604.50	2026-04-13 12:31:59.749756+00	2026-04-13 12:31:59.749756+00	\N
6f405a65-22c1-460d-ac7e-75990c540497	F0000000014	2c2e82ab-d610-4c51-9d96-3975c65d03db	2026-04-13 13:37:52.402595+00	1038.80	1038.80	2026-04-13 13:37:52.390464+00	2026-04-13 13:37:52.390464+00	\N
c094a7f2-98c5-4320-b43b-0bbe49812bb5	F0000000015	48615e40-3d72-40e0-924d-fa4ea9ae3604	2026-04-13 13:40:16.120704+00	1366.74	1366.74	2026-04-13 13:40:16.112649+00	2026-04-13 13:40:16.112649+00	\N
2f986d6e-4075-4560-b4d2-6ed37b9c5f4f	F0000000016	f513fe06-a0cf-44fa-838f-5453e98790b5	2026-04-13 13:40:21.311974+00	397.00	397.00	2026-04-13 13:40:21.303155+00	2026-04-13 13:40:21.303155+00	\N
1ca1f1f2-5024-410c-98bf-50f870134326	F0000000017	6e7ffbab-0205-4987-b782-0f9dfae7d304	2026-04-13 20:14:14.444203+00	852.58	852.58	2026-04-13 20:14:14.410049+00	2026-04-13 20:14:14.410049+00	\N
80c2ab2f-a695-471d-81b9-6f6238505c24	F0000000018	18a1fd87-3e0b-477f-a337-39709652df94	2026-04-13 20:21:23.188874+00	397.00	397.00	2026-04-13 20:21:23.16632+00	2026-04-13 20:21:23.16632+00	\N
7fc27e9e-9a6c-4d37-a39c-191626f13d8e	F0000000019	81b6516c-629b-4d80-82d5-24a7801ae726	2026-04-13 20:21:37.469809+00	911.16	911.16	2026-04-13 20:21:37.447254+00	2026-04-13 20:21:37.447254+00	\N
046d60a0-8f87-4529-a5c3-7dfafef7dc89	F0000000020	7646e2c0-c917-471f-98a8-29c2fc69479b	2026-06-15 15:50:25.4822+00	852.58	852.58	2026-06-15 15:50:25.440264+00	2026-06-15 15:50:25.440264+00	\N
36da2157-5f10-44ff-af9a-d9cca814d0ef	F0000000021	3f8b751f-b7e4-4caf-a7f1-66a3cc2f9f5e	2026-06-15 15:50:34.356499+00	198.50	198.50	2026-06-15 15:50:34.331446+00	2026-06-15 15:50:34.331446+00	\N
77f5887f-3062-44fe-bfa1-c778a8b6e8e1	F0000000022	bdb4d02b-fdb8-481a-949a-1793843e552b	2026-06-15 15:50:36.360829+00	198.50	198.50	2026-06-15 15:50:36.337415+00	2026-06-15 15:50:36.337415+00	\N
e91fc11a-f8c2-4977-8d51-04e9efdf4288	F0000000023	712e33d3-a45d-4ec6-82e1-488c453c04af	2026-06-15 15:50:37.869143+00	198.50	198.50	2026-06-15 15:50:37.850071+00	2026-06-15 15:50:37.850071+00	\N
70f35145-f5af-4763-907b-acc82e696f46	F0000000024	634eadc7-857c-4ff9-8163-5b54a9eb0dda	2026-06-15 15:51:37.080196+00	852.58	852.58	2026-06-15 15:51:37.056864+00	2026-06-15 15:51:37.056864+00	\N
905ea0a2-811c-4610-85ba-7c45e9b74124	F0000000025	b457ab88-16a4-423c-a37c-7c9373b01e00	2026-06-15 16:03:55.072684+00	852.58	852.58	2026-06-15 16:03:55.016795+00	2026-06-15 16:03:55.016795+00	\N
916b66d7-ef8d-4016-86db-d1c21b95e4ac	F0000000026	53b0ca21-ecda-4875-8b88-45e6a4426f74	2026-06-15 16:04:07.405483+00	198.50	198.50	2026-06-15 16:04:07.367451+00	2026-06-15 16:04:07.367451+00	\N
2da19ffc-1863-43e7-8606-9c32287eee54	F0000000027	7e3dbefd-9e34-4af7-8137-bd435e68555e	2026-06-15 16:04:10.082811+00	198.50	198.50	2026-06-15 16:04:10.056726+00	2026-06-15 16:04:10.056726+00	\N
b294d7fb-9f0e-4565-b577-e06b7ce9735c	F0000000028	afd7ad6c-776b-4c2c-9c6a-ce0134c65366	2026-06-15 16:04:12.37994+00	198.50	198.50	2026-06-15 16:04:12.349117+00	2026-06-15 16:04:12.349117+00	\N
cbdeddeb-90ad-4a39-a18a-22d6fe271001	F0000000029	a90de1fe-e8f3-4c96-8107-69eba971d1a8	2026-06-15 16:04:51.819051+00	852.58	852.58	2026-06-15 16:04:51.786482+00	2026-06-15 16:04:51.786482+00	\N
73fb6564-1952-4140-b828-cd51002bad57	F0000000030	70932ee6-bdba-4e93-b487-e0e51c7452f9	2026-06-15 16:14:02.797822+00	1688.63	1688.63	2026-06-15 16:14:02.696749+00	2026-06-15 16:14:02.696749+00	\N
bc33a881-5a97-4eee-a342-ac5d750f0c03	F0000000031	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	2026-06-15 16:43:18.690721+00	852.58	852.58	2026-06-15 16:43:18.644412+00	2026-06-15 16:43:18.644412+00	\N
b9f235d9-8e88-48a3-b54a-2a8d608a53c8	F0000000032	9d504663-a4f6-4855-bdec-407cfabc199a	2026-06-15 16:43:28.020842+00	198.50	198.50	2026-06-15 16:43:27.985656+00	2026-06-15 16:43:27.985656+00	\N
17075960-1745-48e1-ad66-0f1508214537	F0000000033	54d4a168-cd3c-4ad7-8531-def1a75875e3	2026-06-15 16:43:29.866499+00	198.50	198.50	2026-06-15 16:43:29.840087+00	2026-06-15 16:43:29.840087+00	\N
ac1b4eee-b02c-42bd-a3cd-3856df14b813	F0000000034	a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd	2026-06-15 16:43:31.29062+00	198.50	198.50	2026-06-15 16:43:31.265314+00	2026-06-15 16:43:31.265314+00	\N
62097201-b302-4f98-a35f-2046c88d4d1c	F0000000035	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	2026-06-15 16:53:28.424281+00	852.58	852.58	2026-06-15 16:53:28.367368+00	2026-06-15 16:53:28.367368+00	\N
592ba8bd-ebfa-4cf4-9ecb-eaf0c4f95369	F0000000036	1c82273c-17f9-46c1-984b-ba0d11ce9022	2026-06-15 16:53:41.917583+00	198.50	198.50	2026-06-15 16:53:41.885247+00	2026-06-15 16:53:41.885247+00	\N
7e944020-3254-4f86-b8f9-3b34636f65b7	F0000000037	e19fd8f0-1dc2-4dba-ab94-bd32bb9fc2c5	2026-06-15 16:53:43.915662+00	198.50	198.50	2026-06-15 16:53:43.880048+00	2026-06-15 16:53:43.880048+00	\N
e5c33d2f-432b-40f7-b114-67acaa6062fe	F0000000038	5b7c805d-1652-4f86-997e-88a6cedb2195	2026-06-15 16:53:45.483194+00	198.50	198.50	2026-06-15 16:53:45.454935+00	2026-06-15 16:53:45.454935+00	\N
efad879a-e5af-42e3-83ca-594ca5b5fbfd	F0000000039	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	2026-06-16 21:30:47.383171+00	852.58	852.58	2026-06-16 21:30:47.31459+00	2026-06-16 21:30:47.31459+00	\N
9b6dac7f-b2f8-4b03-b536-bc3cd769c8a9	F0000000040	92980492-7923-4866-89ef-216fcebc8722	2026-06-16 21:31:07.800041+00	198.50	198.50	2026-06-16 21:31:07.737096+00	2026-06-16 21:31:07.737096+00	\N
16eea11e-d475-438f-8032-f55a85c04ec5	F0000000041	457419d7-14e1-4dec-844e-2dbeea4821b6	2026-06-16 21:31:10.663275+00	198.50	198.50	2026-06-16 21:31:10.627181+00	2026-06-16 21:31:10.627181+00	\N
aa05aac0-5db6-4187-80c9-ca6a5efe0834	F0000000042	a19333cc-805c-43e4-be89-f1aadcc380c5	2026-06-16 21:31:12.960676+00	198.50	198.50	2026-06-16 21:31:12.935873+00	2026-06-16 21:31:12.935873+00	\N
\.


--
-- Data for Name: feuilles_route; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.feuilles_route (id, date, ligne, n_rotation, compteurs, signature_expedition, signature_chauffeur, created_at, updated_at, created_by, camion_id, livreur_id, chargement_valide) FROM stdin;
f969c5ec-cc7e-4f7f-a504-a5a893c143f3	2026-04-13	\N	\N	{"colis_frg": 0, "colis_std": 0, "sachets_frg": 0, "sachets_std": 0}	\N	\N	2026-04-13 12:15:51.671095+00	2026-04-13 12:15:51.671095+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	f
7ea42bcb-2193-47f0-a179-57d7cded6983	2026-04-13	\N	\N	{"colis_frg": 0, "colis_std": 0, "sachets_frg": 0, "sachets_std": 0}	\N	\N	2026-04-13 12:42:15.386114+00	2026-04-13 12:42:15.386114+00	\N	7785e358-83c4-41e6-9e6b-db5ded7b6e97	\N	f
9e74bad5-c9e7-445b-ad23-9e38baa4cf04	2026-04-13	\N	\N	{"colis_frg": 0, "colis_std": 0, "sachets_frg": 0, "sachets_std": 0}	\\x89504e470d0a1a0a0000000d4948445200000190000000c80806000000c615b7e20000175d49444154785eed9d7bb04ed51bc71fd7248d92492e07c749145108dd268a3049431a06a5c91499cc344991421a638cd1f4c398728e1974c1942e68488929868c4b724fe290831cf507720bbf9ef56b9ddf76bceff1dae7bdacbdf767cd98739c77afb59ee7f3acd9df77ddcb5cf8270909021080000420708504ca202057488cc72100010840c010404068081080000420e08b0002e20b1b9920000108400001a10d4000021080802f0208882f6c64820004200001048436000108400002be082020beb0910902108000041010da000420000108f8228080f8c246260840000210404068031080000420e08b0002e20b1b9920000108400001a10d4000021080802f0208882f6c64820004200001048436000108400002be082020beb0910902108000041010da000420000108f8228080f8c246260840000210404068031080000420e08b0002e20b1b9920000108400001a10d4000021080802f0208882f6c64820004200001048436000108400002be082020beb0910902108000041010da000420000108f8228080f8c246260840000210404068031080000420e08b0002e20b1b9920000108400001a10d4000021080802f0208882f6c64820004200001048436000108400002be082020beb0910902108000041010da000420000108f8228080f8c246260840000210404068031080000420e08b0002e20b1b9920000108400001a10d4000021080802f0208882f6c64820004200001048436000108400002be082020beb0910902108000041010da000420000108f8228080f8c246260840000210404068031080000420e08b0002e20b1b9920000108400001a10d4000021080802f0208882f6c64820004200001048436000108400002be082020beb0910902108000041010da000420000108f8228080f8c246260840000210404068031080000420e08b0002e20b1b9920000108400001a10d4000021080802f0208882f6c64820004200001048436000108400002be082020beb0910902108000041010da000420000108f8228080f8c2462608049bc080010364d1a24552ae5c392953a68c1c387020d80e617d4608202019c14ea510480f8159b366c9881123e4c2850ba642150bfd573ce9e7050505e9318a5a42430001094d287124ea04ead5ab2767ce9cb94820628985e56445e5fcf9f372e8d0a1a8e3c37f1f0410101fd0c802814c123876ec98346edcb8a857616d8927165628bc36d3dbc86404c3533702129e58e2490809ac5bb74eba75eb5634fce41d8a8a350c65ffa6bd8ab265cbcae4c993a567cf9e2124834b2e1040405c88023640e01f022fbef8a2cc9933c70c41e9e4b626158c787316f673fd59b56a5551b1a952a50a2c219036020848da50531104fe4fa043870eb279f366d34bd06445229e58d89e87feccc9c99155ab5681130219278080643c04181076024d9b3695c2c2c28b5640c5130afdbb0e3f69d29f8f3efaa8e4e5e5851d11fe0594000212d0c061b69b04b2b3b3e5d4a95309f52aac07564c468d1a2503070e74d331ac82400c020808cd02020912e8dbb7afac5cb9524e9f3e6d869e7438c90e41696f21de1e0b2ddece65d89f6cdc4b103a8f394d0001713a3c18970e02eddbb797ddbb779b3d145618540cbc13d825eda7f0da587cc96cf9f2e565dfbe7de970833a209076020848da9153613a087cf2c927326edc383972e4889c3b77cef40e62ad684a54186c2f22566fc296ab2ba07efef9e774b8471d1070820002e2441830225102bad475c99225a29be9f4c56d5fde5e8188b7f435561dde1e43f161263b2ca5bd88871e7a4866ce9c99a8993c078148104040421ee6f1e3c78b7e1bd7a32a62bd70adfbf6055c7c38c67e43f7be947598e7aaabae92060d1ac8fdf7df2f3af99b689a366d9a2c58b0407efdf5573979f2a49c3d7bd60c1bd9d547f17a0a5e3b13adcbbbe9ceda6f37d869af44f74ebcf1c61bd2af5fbf448be4390840c0430001096873183b76accc9f3fdf2c0ff50a437177ae6488a63428621d97e12d2f597614afc7db6b50215261b8e9a69be495575e913e7dfa94c625f24200029721808038d644468e1c299f7ffeb9fcf9e79f45ab7cec508a9f6fe125b957d2b11899c2527c48a9780f497768df70c30dd2a64d1b993e7d7aa6cca45e0840e01f02088843cda056ad5a318fad70c844634abc5e807e56d206b958bd94d2f64cbc3d106b9b77d8cdbbd4567b28d75f7fbd346ad448de7fff7db9faeaab5d438b3d1008140104c4a170c51390cb0d0fc57a717a5fa27669aa1deaf2fedffeae65684fa742850a86887ed3af5cb9b2f9a72fdd5b6eb9451e7bec31b9f5d65ba56eddba49a1a6f5e97e8861c386c9962d5bccc4b80e41fdfdf7df17eda9f0cebff8595a1bcfd8785cade8585efab362c58a4670ead4a923bd7bf796679f7d36290c280402412680803816bdefbfffbee89bb18a40eddab5cd983ee95202ba30e0cd37df3487081e3d7ad4ec002fde2389b508c096549ade4f49e2535cbcf5ffbae8a0468d1ad2b9736779e18517a45ab56a84140281278080043e8438e097c05b6fbd25cb962d93fdfbf79bdde5da232abea33cde92e064888f77e55bf15e967743a3f606f54b448b162de4e5975f36bda04a952af9759b7c10481a010424692829284a04740e45ffe5e7e79be5c83af4e6151fefc207af50944678bc4395b607144f78ece7daf3b9e69a6bcc05544f3ffdb4399c910481641140409245927220902001dd07f3c1071fc8ce9d3be58f3ffe289af3f10a44f1df933deca69b2367cf9e2deddab54bd06a1e83c0a50410105a0504024660c08001f2d34f3fc9efbfff5ed4f3f1f67e626d0a55178bf77ebcf338baa972fbf6ed012381b999268080643a02d40f813412e8dab5ab6cd8b0a1a8c658436a3a1ca793fd1cdd92c6c004b42a0424a081c36c089496c0debd7be581071eb8e414623b7c667fea84fed4a953a57bf7eea5ad92fc21238080842ca0b80301bf04468f1e2db9b9b9317b27de49fbebaebb8ee12ebf9043960f01095940710702c922a057f1ea24bf4ddee12eeffc49972e5d64c68c19c9aa9672024400010950b0a264eabbefbe2bdf7efbad39b537272747e6cd9b1725f79df3554f0cd0f3c75438ec89c65e23ada0e89e95c58b178b8a0f29fc041090f0c7d8190f75d5d0bdf7de6b96adea31eefa228a95e29da7d5bf7f7fd1e3e94999273068d02059b870e1251b2fad6536b67ac9d6ae5dbb326f3016a48400029212ac141a8b40b20e8bfcf0c30fd9bfe05813d3b3d28e1f3f6eac8ab55cd8f65074d27eeedcb98e598f397e0920207ec991ef8a09dc79e79d72f8f0e18b5e30f6c5a287156667679ba18f2953a65c54b61eb6a8a2e13d634a7758efd9b3e78a6d2043ea09e8f2dfd75e7beda2db22630d77e9ea2ebd76587b96a4601240408219b7405b5daf5e3d338455d2c636dd297dd75d77994bb36cd2db0f77efde7d9190d4ac5953d6af5f1f681e6137be43870eb275ebd6a2b8c58abbfe4d4f7ed6ddf92a2ca4601040408211a7505aa9435a36c53b23cabbda475f2c3aa16e0f3fb479f5998e1d3bcaac59b342c9294c4e9d3973c6dcc7a23f631d5469ffa69b1975d2fe8b2fbe0893fba1f30501095d4883eb50ebd6adcdfd205ed18837a1eebd28ca7aac13b73a24f2cc33cf041742c42c1f356a94e4e5e519afe3c5da22d17d2a03070e8c1821b7dd4540dc8e4fe4adebd4a9936cdbb6cdacdcb22f99924eb42d7e4aad3d174a2fcad263d0f5ae74bd188be426019d03d3bb5d6c8ce30d73ea1c980e6732dc95d938222099e54fed3e08f4e9d347befbee3bb384b4f8304822c7a5c7ba0c4af3d963cff5b45c921b04b2b2b262c659adb371d4f9b27dfbf6b96170c4ac40402216f0b0bbdba3470f59b366cd252bbdacd0242230de9793fd5df3e92639bddeb77dfbf6f29ffffc27ec289df34f174c681c62f54a0a0a0a9cb3370a062120518872047db4df5cad00785f30bd7af5928d1b379a7d0bf65bacf7a59488c878f379afd1d5e5c8faa21b3e7c384365a56877ba6c5b19ea64fae5165828733d1892947e020848fa9953639a08d8fd08f605a413f489a4c2c242e9d9b3a7b96d50ef59b7c9afc878ebb4cb5575ac5f6f34d49dda2491b163c7caf4e9d38b4e272869f184f2aa5fbfbeac5ebd1a7419268080643800549f5a023aa4f5c30f3f984aaa55ab269b376f4e4a857a9ffaa79f7e2a2a36de09fee262515265b1e662f4793b54a60b08264e9c98147b5d2b64e8d0a13267ce9c8be6b04ada17c4818dae45f07ff620206ec605ab924840bfadeac6454d3a019f8e97f289132764f0e0c1e65bb2feeebd23fd4a44469f8d25343a6c53bb76edc0ac2aebdbb7af2c5fbebcc8f578626197673ff1c413f2ce3bef24b11550542a082020a9a04a99ce11d097ad4d4b972e95264d9a64dc46ed198d1831c29c381c6f63dd95ccc7141726ddd97dfbedb7cba44993cc3131e94cf7dd779ffcf2cb2f45cb6c4bea5da85d43860c312c48c1228080042b5e58eb93c08a152b44bf05db6ff44159b53361c20473f8a0ee8d8875fc8bfa73399149c75059ab56adcc26506bcfe58ea979fbedb7cd3c1329d804109060c70febaf80c0934f3e69ee18d194ccf9902b3021e98fdaa1325dbaacabca923d54663760befaeaabd2ad5b3763bfd6d3b2654b3976ec58913ff1ceb7527b74b84d0fc8b4f9930e810233460001c9187a2ace0481060d1ac8e9d3a7cdbc827e039e3c797226cc487b9deddab5339bed4e9e3c19f3a57fb95e8cedb9d9cc25f53058569bf6f066ac42042463e8a9385304ecbd242a227a29927e9b8e7ab2abcaf40a5b9d8fb147c05cee48116558b56a55d9b16347d41146d27f042492618fb6d33a8cd5af5f3ff392d4219683070f461b4882deeb1cd2dab56b4587b5f47c3212041010da402409e8a9ae8b162d32beeb6a25ae5d8d6433c0e9521240404a0990ecc125d0b06143f9ebafbf8c035dbb7695f7de7b2fb8ce60390432400001c90074aa748780777f889ec2cb7c883bb1c112f7092020eec7080b534840afc3f52e2f4df4bcac149a44d110080c01042430a1c2d05411f0ce87e84545ba339c0401085c9e00027279463c1101027ae4872e61d5f4e0830f9a937249108040c90410105a0804fe2560f787e87ff53e0add7c47820004e2134040681d10f897c0d6ad5be5e1871f2ee2c17c084d0302f4406803104898c0b061c3e4a38f3e32cfeb86396eba4b181d0f4690003d9008061d974b26e09d0f69d3a68db9388a0401085c4a0001a15540200601effe10dd60a81b0d491080c0c50410105a04046210d8bf7fbfb46ddb96f9105a07044a208080d03c201087c0983163243737d77c5abe7c79c9cfcf87150420e0218080d01c205002013ddae4d0a143e68966cd9ac9e2c58be1050108fc4b0001a12940e03204bcf3217a156baf5ebd60060108fc430001a11940e03204b407e23d6471cf9e3de69a561204a24e0001897a0bc0ff84084c9a3449b4f7a1a96cd9b2a293ec2408449d000212f51680ff0913b8fbeebbcdbde29a980f49181b0f8698000212e2e0e25af209d4a95347f41e704dda2be9ddbb77f22ba144080484000212904061a63b04eca18b2a24050505ee188625104833010424cdc0a92ef804e6ce9d2b43870e358e301f12fc78e2817f0208887f76e48c3081be7dfbca8a152b0c81ba75ebcaead5ab234c03d7a34a0001896ae4f1bbd4046ebef9663979f2a429e7a9a79e92f1e3c797ba4c0a804090082020418a16b63a47c0bbc970e9d2a5d2a44913e76cc42008a48a0002922ab2941b0902ebd7af976eddba15f9ca255491083b4efe4b0001a12940a09404468c1821b367cf36a554ae5c5976edda55ca12c90e8160104040821127ac749c807793a1dea5ae77aa93201076020848d8238c7f692390959525e7cf9f37f5b1c9306dd8a928830410900cc2a7ea7011282c2c94e6cd9b1739b569d326a95ebd7ab89cc41b0878082020340708249180779361b972e58acece4a621514050167082020ce840243c242c0bbc9b061c386451b0ec3e21f7e40c0124040680b104801819c9c1c3975ea9429f9f9e79f97d75f7f3d05b5502404324b0001c92c7f6a0f310136198638b8b866082020340408a488009b0c530496629d21808038130a0c092301ef26c32a55aac8ce9d3bc3e8263e4594000212d1c0e376fa08b0c9307daca929bd041090f4f2a6b68812d023dfcf9d3b67bc679361441b4108dd46404218545c728fc0c18307a555ab564586e979597a6e1609024126808004397ad81e2802b9b9b93266cc186373f9f2e5253f3f3f50f6632c048a134040681310482381eeddbbcbdab56b4d8d6c324c2378aa4a090104242558291402f109b0c990d611160208485822891f8122c026c340850b63e3104040681a10c80001361966003a55269d00029274a4140881c4087837195e7bedb5b263c78ec432f214041c218080381208cc882681162d5ac8e1c3878df35dba7491bcbcbc6882c0eb401240400219368c0e13813a75eac8850b178c4bd3a74f97471e79244ceee14b88092020210e2eae0583009b0c831127acbc94000242ab80800304bc9b0cb9c9d081806042420410908430f11004524f4087ae7efcf14753d190214364f8f0e1a9af941a20500a02084829e0911502c92650bf7e7d397bf6ac54a85041f6eedd9bece2290f02492580802415278541a07404bef9e61be9dfbfbf2964ead4a9a2479f9020e02a0104c4d5c860576409d85e48c58a1565cf9e3d91e580e3ee134040dc8f1116468cc0ecd9b34537196afaecb3cfa475ebd6112380bb41218080042552d8192902f6022aaec18d54d803e72c0212b890617014088c1b374ea64d9b665c5db972a564676747c16d7c0c180104246001c3dce810b027f656ab564d366fde1c1dc7f13430041090c0840a43a34660d0a041b270e142e3f6860d1ba4468d1a514380bf8e1340401c0f10e6459b80ed85646565c99a356ba20d03ef9d2380803817120c82c0ff093cfef8e345c2b17bf76ea954a9127820e00c0104c499506008046213b0bd90c68d1bcbb265cbc0040167082020ce84024320109b40870e1d64fbf6ede6c303070e800902ce1040409c0905864020368153a74e494e4e8ef9f09e7bee918f3ffe18541070820002e244183002022513d0dde8dafbd08ba70a0a0ac00501270820204e84012320503201bdf656afbfd5d4af5f3f99306102c8209071020848c643800110488c40d3a64de5cf3fff943265cac86fbffd9658269e82400a09202029844bd1104826816ddbb649c78e1d4d9183070f9691234726b378ca82c015134040ae181919209039028d1a3592e3c78f1b03589195b93850f3ff082020b404080488c0f2e5cbcd1c88a6ce9d3bcb8c193302643da6868d000212b688e24fe809dc71c71d72e4c811e3e7ba75eba466cd9aa1f71907dd248080b81917ac82405c02858585d2bc7973f3f98d37de281b376e84160432420001c908762a8540e908e804facc99334d2113274e943e7dfa94ae407243c0070104c40734b240c00502ba3b5d77a9972d5b56f6efdfef8249d81031020848c4028ebbe121a03715f6ead5cb38d4b66d5b993f7f7e789cc393401040400211268c84406c029d3a75922d5bb6980fbffefa6bb9edb6db400581b4114040d2869a8a20907c02e7ce9d937af5ea9933b2aa56ad2abad990048174114040d2459a7a20902202797979327af46853fad0a143e5a5975e4a514d140b818b092020b40808848040b366cde4e8d1a3e69cacfcfc7c2957ae5c08bcc205d7092020ae4708fb2090008183070f4aab56adcc937ae8e2575f7d95402e1e8140e9082020a5e3476e083843e0b9e79e932fbffcd2d8b360c10269d9b2a533b6614838092020e18c2b5e4594407676b69c397346aa57af2e9b366d8a2805dc4e170104245da4a907026920909b9b2b63c68c317320fbf6ed4b438d54116502084894a38fefa12370fefc79c9caca327ead5ab54aead7af1f3a1f71c81d0208883bb1c012082485803dad57e744ecf2dea4144c211028460001a14940206404060c18204b962c1115123ba91e321771c7110208882381c00c08248bc0bc79f3cc66c21e3d7ac894295392552ce540e0120208088d0202212370e2c4095111d11b0b6bd5aa1532ef70c7250208884bd1c0160840000201228080042858980a010840c0250208884bd1c0160840000201228080042858980a010840c0250208884bd1c0160840000201228080042858980a010840c0250208884bd1c0160840000201228080042858980a010840c0250208884bd1c0160840000201228080042858980a010840c02502ff05db32d23061d933ff0000000049454e44ae426082	\\x89504e470d0a1a0a0000000d4948445200000190000000c80806000000c615b7e2000017cf49444154785eed9d0bb095d3fbc79fd2bda654e8265dc96542745122b70a6550224a85714988d0456e91482e3109698a29992e28e516522edda552b9a526914ca324a3a4f87996ff3aff77bf67ef73daebec7df6dafbfdac99e674ce79d7bb9ef579d6ecef59b7e729f1cfbf45281080000420008124099440409224c6e31080000420600820200c040840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a312042000010820208c010840000210702280803861a35254096cdebc596ebef96659bf7ebdecdab54baa56ad2a2b57ae8c2a0efa1d71020848c4074054bb3f72e448993b77ae6cdab449f6ecd923fbf7ef9712254a181cfaf5efbfffcefb3ec8c83e13e6f6cf3fff981fe9577da666cd9ab262c58aa8e2a5df1121808044c4d1b9d8cd8d1b37ca881123cc07f58e1d3be4afbffe321ffcfacf0a81fd6a3fe0833f2f0e26daae6d5b85a55ab56ab266cd9ae2689a36209076020848da11d34032049a366d2abffcf24b5e153b1b087ff0279a0924d3565054ecccc1d6b71ffc071d749054aa54490e3ffc70e9d0a1830c1a34285f1303060c90e9d3a7cbbe7dfbf2095741f6d8598ef6a57af5eab27af5ea64cce75908649c000292711760c0c9279f2c5bb66c314b3fc90a83fde00f8b81522d59b264de9252a952a5a462c58ad2b87163b9eebaeba473e7ce6907af7b25afbffe7accf2586133a0e0ec49ff5fa3460d59b56a55da6da50108b81040405ca851a7c804dab46923ba04154f348262a00dd9ef753650b66c59b30cd4ac593319376e5c91edc8c40b6ebcf146993d7b76523396201315963a75eac8679f7d9609f3691302ffbf42f0efc0fc6ff78f02813413183e7cb88c1d3bd60882ce0e6cb1cb45fab3d1a3474bb76eddd26c899fafefdbb7afcc9933c7ece504f914b6711fe4a8c2b27cf9723f3b88553947801948ceb9d4df0ed5aa552b9f70a8b52d5bb694993367fa6b78862debd3a78f7cf0c10766292c580a5aee0bff5da8c2b26cd9b20cf784e6738d0002926b1ef5b83f471c718459b689f7c117fcc0ab5fbfbe1194c30e3bcce3de64deb45ebd7ac9bc79f3f24e9d598b0e64c662f78ef470c0d2a54b33df192cc84a02084856ba2dbb8d1e356a948c1933c62cd524fad00b1e7fad5cb9b24c9e3c595ab46891dd1d2f26eb7bf6ec291f7ef861dede91158b648445457ce1c285c56431cd642b0104245b3d974376ebf2cc0d37dc20bffffebbe955611bebba91fee28b2f4abb76ed728842fabb72e9a597caa2458bcc5298dd870a1f5f0e5a11bcbf927eeb625bd0b6f5b040952a5564ddba75a2072828fe114040fcf30916fd4ba055ab56a261430a5a96b11f70bae1dcbd7b7779ecb1c760e740400f2d2c59b2246f4618bc91eff0ba9457090a9915be1f7ef821e5edf0c2e4092020c933a3460608f4eedddb6c24876f9987ff62b61f30a79c728a59f62a5fbe7c06accd8d26bb74e962f64774c6123c15561cbd0b86922968cf4c6dfbf9e79f8bc324da884300016158642581091326c8b061c364efdebd055e40b47fbdea86fcac59b3a45ebd7a59d9df281b7dfef9e79bcb94f14445fdab9750299921808064863bada6814093264dcc3e4aa2b5fbe0492f0d4f3265ca1469debc791a2ce195e926a07f08d83f1e109074d34efc7e042473ec6939cd04ce3cf34cf9e69b6f0a15141596d2a54bcb2db7dc2277dc71479aade2f510c81d020848eef8929e144260f0e0c13269d2a4b84b215a35bc59ab4b27e3c78f872b042090800002c2d0882c8177de79c71c1fb6f751e245e40dc239fae8a365c68c19261617050210f8f7c83db1b0180610f88fc0eeddbb4d58957038f9209fe00547cd46f8da6baf890a8b96db6fbf5d5e79e515d1902d043a64544581000212052fd3476702679f7db6b9c896e86e4470633e78dc547fae1bf5ba07438140ae12404072d5b3f42b2d041e7cf04179fef9e70bbc8f129eb1682e12dd4bd184541408e41201042497bc495f8a9dc0b66ddb442f2deaf2d78144c73dfef8e34dc87615150a04b29d000292ed1ec47e2f08d4ae5ddb08882e79ad5dbb36ef725ba2b85e76e94b2314eb3e8a865ba74020db082020d9e631ecf59240a3468d64cf9e3d2674cafaf5eb636cbcf2ca2b4d189644517183fb28152a5490a953a78aa6f9a540c077020888ef1ec2beac20d0a3470f993f7fbe1189826e46ab380c1830204f4ce2752e781fa55fbf7e72d75d776505038c8c1e0104247a3ea7c769226097a12eb8e00279eeb9e70a6da571e3c6f2c71f7f14b877a22fb10122efb9e71eb9fefaeb0b7d2f0f40a0b8082020c5459a76729ec059679d255f7ffdb5d920dfb469d301f7f7a4934e92ad5bb7e609899d81c45bf2b23f7bf3cd37e5c4134f3ce036781002e9208080a4832aef8c24816fbffd56ce38e30cd3f7a79f7e5aba76ed9a14878e1d3bcaead5abf3e58dd78df87080487ba151132d69f6c1238f3c32a9b6781802a9208080a48222ef80c0ff11d05be9bb76ed92ead5ab1b31702943860c91975e7ac954b547835530347fb9e6beb0a15782bfd367cb9429238b172f969a356bba344b1d08244d0001491a1915209098c0c48913e5eebbef360f680e8b430e39c419976eb86b74609b444b5fa442a2b1b8060e1c2843870e957dfbf6e59bb1e873e5ca953302a6b7e1291048170104245d64796f6409d4ad5bd77ce8eb51dc37de78a3c81c54082ebae822734c3838eb5091983973a639223c6ad4a8bc7682cfd8902a5f7df51579c58bec095e102680803026209062029a9ffde38f3f366ffdf1c71f53faf6a64d9b9a608f4191d07d10cd077fd96597995989ce826c093ea7ffd71991ce8c2810480501042415147907040204342ba26647d4a2e1e2f5f86daa8b9ef8d25945781f44c5eb89279e30cd5d75d555a221ebc3b7e1ed86bc5e7eb442976afb785f34082020d1f033bd2c6602ba7ca54773e3dd4c4fa5299a45f1d5575f8d79a52e9f1d7becb16669cb960b2fbc50962d5b66be0d470d564169d6ac99bcf5d65ba9348d7745800002120127d3c5e227f0fefbef4befdebd4dc3ba0f92eed02463c78e95112346c4645b5421295bb6acbcf0c20bd2be7dfb3c087ad4d886990f8b893ea4c121353e170502851140400a23c4ef21e048a0418306b277ef5ea95fbfbe7cfae9a78e6f49aeda279f7c221a7bebcf3fffcc37d3d0bb220b162c8879a10adb4f3ffd147766a23f54e1b1478a93b384a7a3400001898297e9634608dc79e79d3265ca14d3f6c68d1bcd3d8de22cad5ab592efbfff3e660f4497abf4a6fcc89123e5f2cb2f8f3147efb0ecdcb933dff3f6a12baeb8c26cd65320600920208c0508a491808d8fd5a9532719376e5c1a5b4afc6a4db33b68d0207367247cc457c3c92f59b224a6f2f6eddba5458b16f9729c04d3f96a404815484ab4092020d1f63fbd4f338173ce3947befcf24b7307436703992e6ddbb6950d1b361833c24781f5d262fffefd634cd4d0f4da075d8a0bd7d1ef4b962c299aa5514f7c51a2470001899ecfe9713112286a7cac7499aac118fbf6ed2bfbf7efcf6bc21eefd5bb22ba9752b972e598e6f567ba8c159cc9d8076cc4e0679f7d56341a31251a04109068f8995e6690c031c71c23bffdf69b54ad5a55d6ac5993414be237ad411cbff8e28b9819869d6d5c7df5d5f2c0030fe4aba8a7b4f408b10db3125e1ad319d7b469d3a44d9b36def5178352470001491d4bde0481b80482f1b1962e5dea6dfada850b178a26c60a9ee0b2b3129d8de8d1640de8182e1a79f8d1471f35b399e0a5455b5743ae68dd860d1b3242728c000292630ea53b7e12b0f1b13487872e1ff95ef484d6471f7d149339d1e622b9f8e28b65cc983171bba0b7eec78f1f9fb7bf12be29af297b35b6977ea5643f010424fb7d480fb280804d79aba6a63a3e563abbbf72e54ae9d2a54b4c20476d4fc5444560c68c1909135b5d73cd35e6767bbc502a5a5f67359a808b92bd041090ecf51d96671181607c2c4d4b7befbdf76691f5ff997aedb5d71a41b033112b24fabdde6ed7e3c2898a4613d6e3c2f1c4447f76e8a1878a8a1525bb082020d9e52faccd62027ab762cb962d2657c777df7d97b53d51db75e35df3b96b092e53e96549bd3c59d0e67961a154e2dd98cf5a58396e380292e30ea67bfe10d063b01a725d4baee434d7cb842fbffc723e21d1594938a0633c4f84f3c1db67eca5c5e6cd9bcbecd9b3fd712296c41040401810102846027a12494f39e907672e7d30ea129d7ed8eb71e57080c6d2a54b9b1028ddba754b485a2f2aea01835f7ffd35468cec32997e3df5d45365faf4e9c5e82d9a2a8c00025218217e0f811412183e7cb8e8653b2d3e1fe92d4a97f524d6840913e2ee95c40b9d126e4b45440576f7eedd09e372e9c67ea2936045b19dbac911404092e3c5d3102832013b0b69ddbab539c594ab456723ba176233288643a7e84102dd982fa8e805c7ce9d3b9b502af1ee98685d0d9bfff0c30fe72a46affb858078ed1e8ccb45024f3ef9645e54db5c9d8584fdf6d4534f99bced7a733d7c37444f606966c470e894f03b3441569f3e7df2c2af846fbfebf303070e94db6ebb2d17878d977d4240bc740b46e53a81a8cc42c27ed4fd1f9d95847390d8585a8942a784dfa37b21b7de7aab5926d31216250df2f8c8238f48cf9e3d737d2865b47f084846f1d378540944711612f6b5664abcfffefbf3ed95e87355aa543137e175765258d199cde8d1a3f38989d6b3c2a47b321d3a7428ec55fc3e4902084892c0781c02a92210d559483c7e9a4677d3a64d71f73992d9301f3c78b04c9a34c93411efc2a306799c356b56da530ca76a8cf8fe1e04c4770f615fce12d0bf9af5af67fda05bb46891d4ab572f67fb7aa01d8b97fcca8a41c58a1545f741f424d78114dd2f79f7dd77cda3baa4658bbd6352be7c79733bfe40663907d25e149f4140a2e875faec0d81c68d1b9be3aa2a1e73e6cc916ad5aa79635ba60d39fdf4d345135a6909ef71b46bd7aec0d02961dbcf3bef3c132a255e28157d56c54943ed972d5b36d3ddceaaf61190ac7217c6e61a01cd56a8d9fc366fde2c9a3744f36c14761a29d71814d61f9bfc2a9cc84a6712fa81af37e193c93ba2cb65363b64f8d223411e0bf346ecef1190e478f13404524e60c78e1dd2bd7b77f317f009279c60021652e21338f7dc734d38f878b392e38e3b4ede7befbda4d029ef6ddbb6c5bc4fbfb1a7bb6ad4a8219f7ffe7952ef8cd2c3084894bc4d5fbd25b06bd72ee9d5ab9709b2182f9dacb78667c8b078c9afec077fa952a5e4f1c71f2f30744ad8ec3d7bf698502a7af931284e413139eaa8a364fefcf919eab19fcd22207efa05ab224a60fbf6edec8324e97b9dbd2d58b020eefe86ee2de9018564cad6ad5ba56ddbb6f9a20d5b31d1d949ab56ad64e6cc99c9bc36279f454072d2ad740a02d1239028f9959d51dc77df7d85864e09535bbe7cb974edda355f28157dcee683d7cdfea953a7460ff8bf3d464022e9763a0d81dc269028f995f65af735162f5e9cf489ab79f3e69965462b1ce19361fa6e8d38ac615ba2521090a8789a7e422082040a4a7ea538341c8ac6cf4ab64c9e3c59060d1a9430948abe4f4fd73df4d043c9be3aab9e4740b2ca5d180b0108b8124894fc4adf57b56a55b341ee72a970e4c89131b38e78411e870e1d2a37dd7493abe9ded64340bc750d86410002e920a0c77675df62e7ce9de6f5e1a5a81e3d7a9808012e456734d3a64d8b79af7e638f05eb8d783d21663353bab4e1531d04c4276f600b042050ac04342789065a8c1766be52a54ae6a495a6e675292a44898efdda208fba14a639e2b3b52020d9ea39ec86000452462051f22b3b7be8d8b1a34c9c38d1b9bdf6eddbcbba75eb62023cda77ab986890c7b7df7e5b9a366deadc46262a222099a04e9b108080b704e225bfb21ff665ca94912953a624153a25dcd1962d5b9ad03589e272952b57ce24d8aa53a78eb78cac610888f72ec24008402013040a4a7ea5f66818149d3514a5e88c4353fe6a09c7e5d29f6990470ddda291837d2c08888f5ec1260840c02b02cf3cf38c8c183122ee1254e9d2a565ecd8b1d2a953a722d9dca44913134a25decc4497b9ead6ad2b9a02d9a78280f8e40d6c810004bc27d0ba75ebbc68bed6589b63a451a346269659518bbe47c3fc8767261a7d78c3860d457d7dcaea23202943c98b20008128112828f9951ed71d326488f4ebd7afc8481a346820ba9c6697b8748f442f48fa5010101fbc800d108040561338edb4d3f23ed4c3f74a6ad5aa251a3db8a8c9aa829bea7af151c3ff67ba202099f600ed4300023943c026bfdabf7f7f4c9f6c7ef6fefdfb3b854eb12f0b8a88c6f45ab1624546d9212019c54fe3108040ae1228288deec1071f6cee85b894dab56b9be52c15a54c27bc42405c3c481d084000020748a0a0e4572a04975c72c90145f0d5535eab56adca776b7ecb962d076849ea1f434052cf943742000210884b40c542135cd9252dfb907e5fa1420559bf7e7d5e3d7d56c3ce87c3c7eb0336b696665fb4f9dd33811c01c90475da840004224fa061c386e6a8ae9ed80a0a89fd7ff06261503474037deddab55ef04340bc7003464000025125a07943e6ce9d1b7756a24cf4a2629f3e7d64d8b061de214240bc7309064100025125a0b312bdf3a11be5cb962df31e0302e2bd8b3010021080809f0410103ffd825510800004bc27808078ef220c84000420e0270104c44fbf601504200001ef092020debb080321000108f8490001f1d32f5805010840c07b020888f72ec240084000027e124040fcf40b5641000210f09e0002e2bd8b3010021080809f0410103ffd825510800004bc27808078ef220c84000420e0270104c44fbf601504200001ef092020debb080321000108f8490001f1d32f5805010840c07b020888f72ec240084000027e124040fcf40b5641000210f09e0002e2bd8b3010021080809f0410103ffd825510800004bc27808078ef220c84000420e0270104c44fbf601504200001ef092020debb080321000108f8490001f1d32f5805010840c07b020888f72ec240084000027e124040fcf40b5641000210f09e0002e2bd8b3010021080809f0410103ffd825510800004bc27808078ef220c84000420e0270104c44fbf601504200001ef092020debb080321000108f8490001f1d32f5805010840c07b020888f72ec240084000027e124040fcf40b5641000210f09e0002e2bd8b3010021080809f0410103ffd825510800004bc27808078ef220c84000420e0270104c44fbf601504200001ef092020debb080321000108f8490001f1d32f5805010840c07b020888f72ec240084000027e124040fcf40b5641000210f09e0002e2bd8b3010021080809f04fe07f45e953f142de8730000000049454e44ae426082	2026-04-13 12:03:09.043002+00	2026-04-13 13:10:27.975336+00	\N	1c2411aa-1f09-4c5d-8360-96180f6b4c54	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	t
777b09a3-e9bf-42bb-9187-bc037bf8af6e	2026-06-15	\N	\N	{"colis_frg": 0, "colis_std": 0, "sachets_frg": 0, "sachets_std": 0}	\N	\N	2026-06-15 16:20:36.882739+00	2026-06-15 16:20:36.882739+00	\N	1c2411aa-1f09-4c5d-8360-96180f6b4c54	\N	f
5afebd2a-5d57-469b-8dc1-1aaa3a437189	2026-06-15	\N	\N	{"colis_frg": 0, "colis_std": 0, "sachets_frg": 0, "sachets_std": 0}	\\x89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000d4944415478da6364f8cf500f00038601805a347d6b0000000049454e44ae426082	\\x89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000d4944415478da6364f8cf500f00038601805a347d6b0000000049454e44ae426082	2026-06-15 15:50:26.736619+00	2026-06-15 16:29:07.330988+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	t
1685895d-2865-4d2b-b8ae-d58fa87793e5	2026-06-16	\N	\N	{"colis_frg": 0, "colis_std": 0, "sachets_frg": 0, "sachets_std": 0}	\\x89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000d4944415478da6364f8cf500f00038601805a347d6b0000000049454e44ae426082	\\x89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000d4944415478da6364f8cf500f00038601805a347d6b0000000049454e44ae426082	2026-06-16 21:30:49.028343+00	2026-06-16 21:30:51.223299+00	\N	0450c96e-c43b-47f9-bdd3-08e5a62b1ae7	\N	t
\.


--
-- Data for Name: lignes_commande; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.lignes_commande (id, commande_id, medicament_id, designation, qte_demandee, prix_unitaire, n_lot, created_at, updated_at, created_by, qte_prelevee, verifie, remise_pct, fab, exp, ppa) FROM stdin;
efe513cc-eae7-494e-8d03-8c64a0873620	f513fe06-a0cf-44fa-838f-5453e98790b5	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	L0001-26	2026-04-13 13:36:09.730856+00	2026-04-13 20:16:58.172148+00	\N	2	t	0.00	\N	\N	\N
d3c49026-4013-489f-a38a-4449cbee15cd	02d29f6f-7320-46de-9910-18a4a137f9fc	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	5	198.50	L0001-26	2026-03-26 12:27:45.079296+00	2026-03-26 12:27:45.079296+00	\N	\N	f	0.00	\N	\N	\N
24a9669a-4617-4ea8-aa40-093540123489	96fdb118-00e1-4720-b8f9-2f3b30e58611	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	4	198.50	L0001-26	2026-04-13 10:11:11.642963+00	2026-04-13 12:16:36.343232+00	\N	4	t	0.00	\N	\N	\N
b2ee230b-9def-49b7-a218-34e15dd7e7b4	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	L0001-26	2026-04-13 11:36:57.533086+00	2026-04-13 11:57:36.592188+00	\N	1	t	0.00	\N	\N	\N
0c7e9412-7c38-4a48-9c2f-a12be4950c66	8749fa09-b997-45a6-b5be-e9b1f49c23d2	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	L0001-26	2026-03-26 11:04:39.866189+00	2026-03-26 11:04:39.866189+00	\N	\N	f	0.00	\N	\N	\N
dbd086e4-3616-4600-9d2d-3455f9854acc	0bff5c32-f6f8-4986-92ea-b6a8147cba6a	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	L0001-26	2026-03-26 11:15:16.104921+00	2026-03-26 11:15:16.104921+00	\N	\N	f	0.00	\N	\N	\N
3c301701-ce0c-4dde-b616-1bcf9476ca17	fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	L0001-26	2026-04-07 11:48:01.080345+00	2026-04-07 11:48:01.080345+00	\N	\N	f	0.00	\N	\N	\N
928178ad-2374-419a-96de-0c2762b8b95d	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	4	198.50	L0001-26	2026-04-13 12:26:13.735977+00	2026-04-13 12:32:21.725392+00	\N	4	t	0.00	\N	\N	\N
40eecbb5-12eb-4c3c-a11f-b229ac64f6c2	506905ec-c6d4-4c53-896e-3732e50f183b	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	L0001-26	2026-03-26 12:22:32.284605+00	2026-03-26 12:22:32.284605+00	\N	\N	f	0.00	\N	\N	\N
42774df1-877b-468e-a7a7-18a226d71e63	9bf827a6-b240-4200-a206-40f132b84460	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	L0001-26	2026-04-01 15:58:51.958055+00	2026-04-01 15:58:51.958055+00	\N	\N	f	0.00	\N	\N	\N
648eb1fb-1340-4544-8b0a-4277571ecc78	6082713a-d865-4e27-8a42-5bfedaa5c38d	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	5	198.50	L0001-26	2026-03-26 11:04:24.277773+00	2026-03-26 11:04:24.277773+00	\N	\N	f	0.00	\N	\N	\N
4449c85f-cabb-4600-9670-79338b497c55	dbbca1b4-1782-4fd5-9255-9e458cdbd550	2022fa77-0632-475d-8ff3-40ebb1869f4a	DOLIPRANE. 1000MG B/8 COMP	1	100.11	L0072-26	2026-04-01 13:40:17.726588+00	2026-04-01 13:51:55.338346+00	\N	1	t	0.00	\N	\N	\N
7de8a0c4-4300-4c44-ab5b-1af712b686f6	f61d715f-0444-45bc-b848-927210e1a0b9	2022fa77-0632-475d-8ff3-40ebb1869f4a	DOLIPRANE. 1000MG B/8 COMP	1	100.11	L0072-26	2026-03-30 17:58:54.571366+00	2026-04-01 13:31:17.247379+00	\N	1	t	0.00	\N	\N	\N
ba742d17-fc37-4dcf-bc42-c7b66eefc92c	106039b7-a430-4ce3-ae3a-e85ecdc1efa5	2022fa77-0632-475d-8ff3-40ebb1869f4a	DOLIPRANE. 1000MG B/8 COMP	2	100.11	L0072-26	2026-04-01 15:52:14.19294+00	2026-04-01 16:08:29.240516+00	\N	2	t	0.00	\N	\N	\N
925c988b-d4ea-4fee-a629-4c4c807a5b70	506905ec-c6d4-4c53-896e-3732e50f183b	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	1	455.58	L0002-26	2026-03-26 12:22:32.284605+00	2026-03-26 12:22:32.284605+00	\N	\N	f	0.00	\N	\N	\N
adb88674-e1b5-40a2-8e3a-a3b20a829524	48615e40-3d72-40e0-924d-fa4ea9ae3604	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	3	455.58	L0002-26	2026-04-13 13:36:13.593355+00	2026-04-13 13:40:33.451234+00	\N	3	t	0.00	\N	\N	\N
f5df1af1-0fb5-4a1c-9a92-aea12585a54a	39c1dfe9-f87e-48b9-82f9-585965bef503	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	1	455.58	L0002-26	2026-03-26 11:29:21.70522+00	2026-03-26 11:29:21.70522+00	\N	\N	f	0.00	\N	\N	\N
766e821a-2c9d-4dcf-a06b-f24231001170	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	4	455.58	L0002-26	2026-04-13 12:26:13.735977+00	2026-04-13 13:06:22.049945+00	\N	4	t	0.00	\N	\N	\N
9d62371b-49bb-482c-afc5-9d307d5c0eb9	3f80e2e0-8be4-44f0-981e-95810dc3d429	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	3	455.58	L0002-26	2026-04-01 15:59:03.371038+00	2026-04-01 16:07:58.233106+00	\N	3	t	0.00	\N	\N	\N
32227cd1-4816-4294-b5a3-1b87db43927e	02d29f6f-7320-46de-9910-18a4a137f9fc	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	1	455.58	L0002-26	2026-03-26 12:27:45.079296+00	2026-03-26 12:27:45.079296+00	\N	\N	f	0.00	\N	\N	\N
14d5f54e-ee77-40ed-b820-a49120fc9088	2c2e82ab-d610-4c51-9d96-3975c65d03db	5e57f1e4-b43f-45ba-aadc-c6d1b7533292	ASPEC. 100MG B/98 COMP. SEC	4	259.70	L0008-26	2026-04-13 13:36:22.779086+00	2026-04-13 13:38:49.823483+00	\N	4	t	0.00	\N	\N	\N
60766ac0-3aec-448c-9656-b2ae56626d89	39c1dfe9-f87e-48b9-82f9-585965bef503	72dcd068-d94c-4c76-9dca-3ddace1e5962	APROVASC 150MG/5MG  B/30 COMP. PELLI	3	1497.50	L0003-26	2026-03-26 11:29:21.70522+00	2026-03-26 11:29:21.70522+00	\N	\N	f	0.00	\N	\N	\N
5011d0c0-95e6-4d53-ac14-061e87b65dfe	506905ec-c6d4-4c53-896e-3732e50f183b	72dcd068-d94c-4c76-9dca-3ddace1e5962	APROVASC 150MG/5MG  B/30 COMP. PELLI	1	1497.50	L0003-26	2026-03-26 12:22:32.284605+00	2026-03-26 12:22:32.284605+00	\N	\N	f	0.00	\N	\N	\N
69c98964-6bb7-416e-b786-22dc6db35e79	6082713a-d865-4e27-8a42-5bfedaa5c38d	72dcd068-d94c-4c76-9dca-3ddace1e5962	APROVASC 150MG/5MG  B/30 COMP. PELLI	1	1497.50	L0003-26	2026-03-26 11:04:24.277773+00	2026-03-26 11:04:24.277773+00	\N	\N	f	0.00	\N	\N	\N
61ea4cf4-92d8-458a-a4cf-83abc64e99ef	be9e9a4e-ca96-4d21-ba90-b920221f2efc	72dcd068-d94c-4c76-9dca-3ddace1e5962	APROVASC 150MG/5MG  B/30 COMP. PELLI	4	1497.50	L0003-26	2026-04-13 13:36:37.303887+00	2026-04-13 13:36:37.303887+00	\N	\N	f	0.00	\N	\N	\N
066d7516-e62f-45c8-ad25-6b4553492b7a	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	7435046b-fc3b-4c8e-9041-9c1e886aa102	APROVEL. 150MG B/28 COMP. PELLI	3	1201.50	L0005-26	2026-04-13 12:22:03.897684+00	2026-04-13 12:33:02.433328+00	\N	3	t	0.00	\N	\N	\N
d3915e19-fa90-4cfa-aae5-4c3dd2b4656c	6082713a-d865-4e27-8a42-5bfedaa5c38d	7435046b-fc3b-4c8e-9041-9c1e886aa102	APROVEL. 150MG B/28 COMP. PELLI	1	1201.50	L0005-26	2026-03-26 11:04:24.277773+00	2026-03-26 11:04:24.277773+00	\N	\N	f	0.00	\N	\N	\N
96085a31-fae0-433c-a940-f8b409db7675	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	7435046b-fc3b-4c8e-9041-9c1e886aa102	APROVEL. 150MG B/28 COMP. PELLI	2	1201.50	L0005-26	2026-04-13 12:26:13.735977+00	2026-04-13 13:06:23.691267+00	\N	2	t	0.00	\N	\N	\N
d64022fc-da5e-4cb7-9039-f87aedc26fc4	f61d715f-0444-45bc-b848-927210e1a0b9	7ef1546e-cce2-4f28-a931-bf8d45a40cf6	DOLIPRANE. 500MG B/16 COMP	1	100.04	L0077-26	2026-03-30 17:58:54.571366+00	2026-04-01 13:31:18.521771+00	\N	1	t	0.00	\N	\N	\N
a051e1ec-b013-4f00-998d-2916462efcbd	106039b7-a430-4ce3-ae3a-e85ecdc1efa5	ebaf3ac2-f1e4-4790-a80e-2f4a23f49a69	BANDELETTES ON CALL  EXTRA -1 TEST B/50	1	1500.00	L0015-26	2026-04-01 15:52:14.19294+00	2026-04-01 16:08:27.947427+00	\N	1	t	0.00	\N	\N	\N
c3c874a3-436e-493a-8c80-ce1c3405939b	dbbca1b4-1782-4fd5-9255-9e458cdbd550	ebaf3ac2-f1e4-4790-a80e-2f4a23f49a69	BANDELETTES ON CALL  EXTRA -1 TEST B/50	1	1500.00	L0015-26	2026-04-01 13:40:17.726588+00	2026-04-01 13:51:54.090058+00	\N	1	t	0.00	\N	\N	\N
c0801d80-246d-4722-a678-2928a0a48676	39c1dfe9-f87e-48b9-82f9-585965bef503	ec9ea5cf-4731-4d28-b580-f45b357b1aa2	APROVASC 300MG/10MG B/30 COMP. PELLI.SEC	1	1497.50	L0004-26	2026-03-26 11:29:21.70522+00	2026-03-26 11:29:21.70522+00	\N	\N	f	0.00	\N	\N	\N
bf6c5dc4-6d96-4c7f-ad2a-eb77d4fef2f6	6e7ffbab-0205-4987-b782-0f9dfae7d304	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	1	455.58	\N	2026-04-13 20:11:54.635136+00	2026-04-13 20:15:41.867116+00	\N	1	t	0.00	\N	\N	\N
2e2814a3-d91c-4559-95ca-c50b0181bf8c	6e7ffbab-0205-4987-b782-0f9dfae7d304	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-04-13 20:11:54.635136+00	2026-04-13 20:15:46.217308+00	\N	2	t	0.00	\N	\N	\N
3dddd6ce-bd8a-40c0-8446-de4f4fcdc4b2	7a976530-4b36-4705-8bf7-ce1168928a19	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-04-13 20:20:12.673589+00	2026-04-13 20:20:12.673589+00	\N	\N	f	0.00	\N	\N	\N
78aa0c58-eb76-436d-9e5a-52f6ec554db9	81b6516c-629b-4d80-82d5-24a7801ae726	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	2	455.58	\N	2026-04-13 20:20:19.723784+00	2026-04-13 20:20:19.723784+00	\N	\N	f	0.00	\N	\N	\N
3544cf1b-52a8-4436-9ed7-ec64a9fda282	18a1fd87-3e0b-477f-a337-39709652df94	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-04-13 20:20:29.891498+00	2026-04-13 20:21:54.781807+00	\N	2	t	0.00	\N	\N	\N
4af15eb0-92e6-47c4-88a4-b6358c755023	9eac02e4-6c72-4e43-8eab-9a03d0b97c26	2022fa77-0632-475d-8ff3-40ebb1869f4a	DOLIPRANE. 1000MG B/8 COMP	2	100.11	\N	2026-04-14 22:04:13.281688+00	2026-04-14 22:04:13.281688+00	\N	\N	f	0.00	\N	\N	\N
e8863803-cf96-486b-b12b-ff36734d10db	7646e2c0-c917-471f-98a8-29c2fc69479b	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-15 15:50:25.373796+00	2026-06-15 15:50:26.252872+00	\N	2	t	0.00	\N	\N	\N
67571d1f-8d3b-48b3-b22b-95141657a2ef	7646e2c0-c917-471f-98a8-29c2fc69479b	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	1	455.58	\N	2026-06-15 15:50:25.373796+00	2026-06-15 15:50:26.283267+00	\N	1	t	0.00	\N	\N	\N
3995f748-e345-4056-8ea9-426e0511a6c2	e7b4011b-5ed7-4f24-9ad2-2a04312b074e	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-15 15:50:29.721159+00	2026-06-15 15:50:29.721159+00	\N	\N	f	0.00	\N	\N	\N
462c6f24-d437-4327-bfea-f2817d42b25f	28b1f7b8-fe5e-45df-8bb4-c41ac4843a4c	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	5	198.50	\N	2026-06-15 15:50:31.065853+00	2026-06-15 15:50:31.096699+00	\N	\N	f	0.00	\N	\N	\N
ed20ed63-8b72-446a-a420-87369615e8b5	74e329cd-12fa-4a22-ac80-9c24b5d0e375	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 15:50:32.488775+00	2026-06-15 15:50:32.488775+00	\N	\N	f	0.00	\N	\N	\N
574f1a95-0250-4131-a960-bc4daefce52e	3f8b751f-b7e4-4caf-a7f1-66a3cc2f9f5e	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 15:50:33.9261+00	2026-06-15 15:50:33.9261+00	\N	\N	f	0.00	\N	\N	\N
596b65ab-9337-4f5f-a178-7e608431c1d7	bdb4d02b-fdb8-481a-949a-1793843e552b	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 15:50:36.296772+00	2026-06-15 15:50:36.296772+00	\N	\N	f	0.00	\N	\N	\N
09acc7ad-d731-4983-9f0c-85097f365ef7	712e33d3-a45d-4ec6-82e1-488c453c04af	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 15:50:37.758943+00	2026-06-15 15:50:37.758943+00	\N	\N	f	0.00	\N	\N	\N
e3c06ff5-0fe6-4c3a-8e6d-dbe78fc09a2a	4557c818-1e9d-4727-b43e-bcc5492248d6	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 15:50:39.320869+00	2026-06-15 15:50:39.320869+00	\N	\N	f	0.00	\N	\N	\N
51a417dd-952a-4fd7-8df4-acf287bce530	846e1200-4c52-443a-8e39-3c7e1a60e6d0	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 15:50:41.907222+00	2026-06-15 15:50:41.907222+00	\N	\N	f	0.00	\N	\N	\N
84e4f913-dd9c-4918-8adc-0dbca4703900	634eadc7-857c-4ff9-8163-5b54a9eb0dda	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-15 15:51:36.801539+00	2026-06-15 15:51:38.826652+00	\N	1	t	0.00	\N	\N	\N
a6d4f103-fb36-481c-a0da-acc55cf1dda4	634eadc7-857c-4ff9-8163-5b54a9eb0dda	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	1	455.58	\N	2026-06-15 15:51:36.801539+00	2026-06-15 15:51:38.963431+00	\N	1	t	0.00	\N	\N	\N
4623a9dd-d41e-4487-b795-25997fda5acb	b457ab88-16a4-423c-a37c-7c9373b01e00	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-15 16:03:54.94945+00	2026-06-15 16:03:55.875812+00	\N	2	t	0.00	\N	\N	\N
e500ce49-19d5-4799-ac51-89c496b238e6	b457ab88-16a4-423c-a37c-7c9373b01e00	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	1	455.58	\N	2026-06-15 16:03:54.94945+00	2026-06-15 16:03:55.912383+00	\N	1	t	0.00	\N	\N	\N
930bc2e5-8a56-4385-8d16-ddd393e48e48	06a1f38a-7a9b-4821-9370-040ff3df9e56	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-15 16:04:00.515329+00	2026-06-15 16:04:00.515329+00	\N	\N	f	0.00	\N	\N	\N
c5cfa8f5-191f-4247-836e-11e602684b44	e23d80e3-a890-4a3a-801a-b2b74b3e07d6	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	5	198.50	\N	2026-06-15 16:04:02.638432+00	2026-06-15 16:04:02.67498+00	\N	\N	f	0.00	\N	\N	\N
3c32c3b9-f362-4e37-a54c-ccfb7d4f57a6	17f6af5e-4fd3-468b-8f54-1a522a6328da	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:04:04.809129+00	2026-06-15 16:04:04.809129+00	\N	\N	f	0.00	\N	\N	\N
d0e53ff0-c1ef-45a3-bf64-724ae6d65fff	53b0ca21-ecda-4875-8b88-45e6a4426f74	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:04:06.904612+00	2026-06-15 16:04:06.904612+00	\N	\N	f	0.00	\N	\N	\N
bb329d26-f833-434e-bc60-fb6b97fd51bb	7e3dbefd-9e34-4af7-8137-bd435e68555e	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:04:10.006973+00	2026-06-15 16:04:10.006973+00	\N	\N	f	0.00	\N	\N	\N
8e75487e-7798-459b-9d91-bf2f78b01b07	afd7ad6c-776b-4c2c-9c6a-ce0134c65366	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:04:12.237768+00	2026-06-15 16:04:12.237768+00	\N	\N	f	0.00	\N	\N	\N
6e9a75db-0b86-4ee8-a3a1-47e2285db9bf	5913d330-9751-4b2e-b4d8-1696ce89b897	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:04:14.558401+00	2026-06-15 16:04:14.558401+00	\N	\N	f	0.00	\N	\N	\N
d185de14-cc16-41e7-a05f-72ad71b23edd	40505262-756a-49d3-9366-d9b9feb92cd6	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:04:18.57493+00	2026-06-15 16:04:18.57493+00	\N	\N	f	0.00	\N	\N	\N
0769b497-f3ce-4e1b-887a-cea724ccd950	a90de1fe-e8f3-4c96-8107-69eba971d1a8	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-15 16:04:51.475748+00	2026-06-15 16:04:53.693065+00	\N	1	t	0.00	\N	\N	\N
fda13102-756e-4fac-8026-ee784d4324a5	a90de1fe-e8f3-4c96-8107-69eba971d1a8	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	1	455.58	\N	2026-06-15 16:04:51.475748+00	2026-06-15 16:04:53.822503+00	\N	1	t	0.00	\N	\N	\N
78e566d8-5a6a-40f6-82d0-9e10858202b8	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-15 16:53:28.275024+00	2026-06-15 16:53:29.105524+00	\N	2	t	0.00	\N	\N	\N
9e54c94b-2cff-469b-97e1-8deb561cdbb6	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	1	455.58	\N	2026-06-15 16:53:28.275024+00	2026-06-15 16:53:29.140303+00	\N	1	t	0.00	\N	\N	\N
204c3a7d-2dc8-4fb7-bc1e-57490e63e96b	70932ee6-bdba-4e93-b487-e0e51c7452f9	31b2d93c-67d9-4b01-98ec-c4c1130fc635	BIOCABASTINE 0,05℅ FL/5ML COLLYRE	1	380.41	\N	2026-06-15 16:12:09.835448+00	2026-06-15 16:20:36.259666+00	\N	0	t	0.00	\N	\N	\N
3b8c1adf-c358-4229-a40d-f6f48230246a	70932ee6-bdba-4e93-b487-e0e51c7452f9	bd0ee39a-b886-4631-8dd9-50e77aef7b27	BIOFENAC. 100MG B/10 SUPPO	1	107.40	\N	2026-06-15 16:12:09.835448+00	2026-06-15 16:20:36.358585+00	\N	0	t	0.00	\N	\N	\N
11a85157-854d-4c78-b93b-1ca890b9bdce	70932ee6-bdba-4e93-b487-e0e51c7452f9	6ef1aae9-5d86-46ca-ae3e-dcd15e0ffceb	BIOPAMOX. 250MG/5ML FL/60ML PDRE.P.SUSP.	2	200.41	\N	2026-06-15 16:12:09.835448+00	2026-06-15 16:20:36.471429+00	\N	0	t	0.00	\N	\N	\N
34ac5d2b-6707-47f1-b7da-8ea9471fc223	70932ee6-bdba-4e93-b487-e0e51c7452f9	3e947b0c-090b-468e-a135-344ba0de8b6a	CALCIDOSE 500MG B/30 SH	2	400.00	\N	2026-06-15 16:12:09.835448+00	2026-06-15 16:20:36.520681+00	\N	0	t	0.00	\N	\N	\N
7282c955-27be-4c16-8858-3f47ab3705c2	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-15 16:43:18.567044+00	2026-06-15 16:43:19.311316+00	\N	2	t	0.00	\N	\N	\N
7ac9cea4-44f2-48f4-a660-8a4d39f85212	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	1	455.58	\N	2026-06-15 16:43:18.567044+00	2026-06-15 16:43:19.344007+00	\N	1	t	0.00	\N	\N	\N
ca6b987a-7509-444a-b784-06147ba6c4ab	0b133ab5-eeb5-42b1-8079-3e31ad4f13aa	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-15 16:43:23.151611+00	2026-06-15 16:43:23.151611+00	\N	\N	f	0.00	\N	\N	\N
eaf545e9-3d5e-4870-976e-d8ff41dbf25d	f619698f-e21f-4f0a-9fc3-e615b19b2d35	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	5	198.50	\N	2026-06-15 16:43:24.668551+00	2026-06-15 16:43:24.710552+00	\N	\N	f	0.00	\N	\N	\N
c9f600b0-a245-4e57-90e9-4bfc86cea201	fbceed4c-73b9-475f-9ebc-48f2aed910f9	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:43:26.219427+00	2026-06-15 16:43:26.219427+00	\N	\N	f	0.00	\N	\N	\N
ee77f140-f7ab-4904-bd59-564c6295027b	9d504663-a4f6-4855-bdec-407cfabc199a	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:43:27.547502+00	2026-06-15 16:43:27.547502+00	\N	\N	f	0.00	\N	\N	\N
f37d5673-e4c2-4b2d-a2da-0dc8c6fac4d6	54d4a168-cd3c-4ad7-8531-def1a75875e3	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:43:29.803905+00	2026-06-15 16:43:29.803905+00	\N	\N	f	0.00	\N	\N	\N
41375fc8-b629-4e29-9a1c-04b609bfc8ba	a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:43:31.18495+00	2026-06-15 16:43:31.18495+00	\N	\N	f	0.00	\N	\N	\N
5b03ce82-f035-4ecd-8e8e-954d86c02ce3	2a5a4167-cccc-4d00-87b1-0eff74f20216	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:43:32.672836+00	2026-06-15 16:43:32.672836+00	\N	\N	f	0.00	\N	\N	\N
661be1fa-95fd-40cd-8654-cc14c2a0ebf0	b705c340-b2ca-4528-91b2-f3ca83436d38	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:43:35.410846+00	2026-06-15 16:43:35.410846+00	\N	\N	f	0.00	\N	\N	\N
ca9ba7f0-166a-4f58-a63d-de08076cee9b	453dcf46-2d66-4bd3-b62d-7fb36a3effc4	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-15 16:53:37.187753+00	2026-06-15 16:53:37.187753+00	\N	\N	f	0.00	\N	\N	\N
02120740-d579-4d16-b8ff-c08751aaf4c6	2fc0b24c-d935-4eac-9157-8563b3a8f368	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	5	198.50	\N	2026-06-15 16:53:38.572381+00	2026-06-15 16:53:38.610511+00	\N	\N	f	0.00	\N	\N	\N
a2733797-c0ab-4409-8ca0-8d439f636017	d9a2e9ba-5d30-42c9-a776-f05e2ba3c181	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:53:40.012486+00	2026-06-15 16:53:40.012486+00	\N	\N	f	0.00	\N	\N	\N
1824862c-ee51-4488-b937-e59607e53d6a	1c82273c-17f9-46c1-984b-ba0d11ce9022	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:53:41.444322+00	2026-06-15 16:53:41.444322+00	\N	\N	f	0.00	\N	\N	\N
4d93b7d6-56e3-410f-b25c-d22a399cdc38	e19fd8f0-1dc2-4dba-ab94-bd32bb9fc2c5	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:53:43.832536+00	2026-06-15 16:53:43.832536+00	\N	\N	f	0.00	\N	\N	\N
7de443ae-f517-4429-8f0f-64b78c44dcee	5b7c805d-1652-4f86-997e-88a6cedb2195	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:53:45.365555+00	2026-06-15 16:53:45.365555+00	\N	\N	f	0.00	\N	\N	\N
1231efcc-bf96-44be-9438-30b648e1de4c	84f1e647-a353-47f8-9bdf-ee221e62ca60	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:53:46.915217+00	2026-06-15 16:53:46.915217+00	\N	\N	f	0.00	\N	\N	\N
8fb129ae-cc33-46ed-abba-8be5fe4c1b13	d24acb48-0718-4829-a4ed-fe14a7802da7	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-15 16:53:49.849639+00	2026-06-15 16:53:49.849639+00	\N	\N	f	0.00	\N	\N	\N
e3017d8f-da9f-4686-9b18-5fc733ace430	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-16 21:30:47.175998+00	2026-06-16 21:30:48.312222+00	\N	2	t	0.00	\N	\N	\N
ba2b039e-1b1a-4020-b8ea-ed1c7e684d29	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	592e33a9-acd2-410c-81f2-6cb3f8f17298	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	1	455.58	\N	2026-06-16 21:30:47.175998+00	2026-06-16 21:30:48.368152+00	\N	1	t	0.00	\N	\N	\N
844942b2-1bd7-4fdb-a9a2-3826da37e521	5b1e91d7-c0c9-475f-93a8-8de762593946	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	2	198.50	\N	2026-06-16 21:31:00.838013+00	2026-06-16 21:31:00.838013+00	\N	\N	f	0.00	\N	\N	\N
4d7f9e8c-297b-4b57-bd57-894c1467db25	e2d05f89-d54e-4c4e-81b4-4fa08d44badc	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	5	198.50	\N	2026-06-16 21:31:02.934445+00	2026-06-16 21:31:02.974685+00	\N	\N	f	0.00	\N	\N	\N
c8579d8c-8c7c-49ae-88c4-67b814d26d63	0007eb5b-90a6-458f-b83f-1581a2c8245a	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-16 21:31:05.128306+00	2026-06-16 21:31:05.128306+00	\N	\N	f	0.00	\N	\N	\N
396a8870-6397-400f-8720-8576d1833228	92980492-7923-4866-89ef-216fcebc8722	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-16 21:31:07.168494+00	2026-06-16 21:31:07.168494+00	\N	\N	f	0.00	\N	\N	\N
1b73f9c2-7ecb-4b32-95b3-191c7ab0edab	457419d7-14e1-4dec-844e-2dbeea4821b6	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-16 21:31:10.588289+00	2026-06-16 21:31:10.588289+00	\N	\N	f	0.00	\N	\N	\N
2913f357-6e97-4002-86b9-c82777aca6a6	a19333cc-805c-43e4-be89-f1aadcc380c5	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-16 21:31:12.831059+00	2026-06-16 21:31:12.831059+00	\N	\N	f	0.00	\N	\N	\N
29dc0676-b24a-417e-99d5-18c3e344c4b7	e2a62896-8c70-49b0-980a-36481afedbaf	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-16 21:31:15.183821+00	2026-06-16 21:31:15.183821+00	\N	\N	f	0.00	\N	\N	\N
76434d53-922f-4aed-a78b-ada99132a3c8	d7705f0f-c48a-4e3b-b111-42b4a08a8d6e	02787863-90cc-4020-93a4-0fc4bab203c7	ALLERTINE. 10MG B/20 COMP. SEC	1	198.50	\N	2026-06-16 21:31:19.484326+00	2026-06-16 21:31:19.484326+00	\N	\N	f	0.00	\N	\N	\N
\.


--
-- Data for Name: medicaments; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.medicaments (id, code_article, designation, dci, dosage, forme, ppa, fabricant, created_at, updated_at, created_by, stock_quantity, image_path, featured) FROM stdin;
2022fa77-0632-475d-8ff3-40ebb1869f4a	100469	DOLIPRANE. 1000MG B/8 COMP	\N	\N	\N	100.11	PROPHARMAL	2026-03-26 10:46:23.86055+00	2026-04-01 15:54:31.561759+00	\N	124	\N	f
6bf0f9f2-b32b-4531-a5dc-70fe95d22122	102601	D-THREE 200 000UI/ML B/1AMP SOL.INJ	\N	\N	\N	154.98	BIOTHERA SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	87	\N	f
ceb9eb32-2a7d-4dc2-9067-108dd35a3898	103595	DOLYC. 1000MG B/10 COMP	\N	\N	\N	107.08	MERINAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	83	\N	f
e69ff623-2b32-4abf-8680-b87723647fa3	102155	BANDELETTES REACTIVES BIONIME  B/50	\N	\N	\N	1500.00	EXPENSIMED -SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	83	\N	f
88b5e910-42ac-4730-accc-794716afcc99	103549	ZECUF. 100MG/60MG FL/120ML SIROP	\N	\N	\N	164.80	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	164	\N	f
ab1d5e9a-449a-4c78-bb6b-ca1e8f5fbec6	102230	AUGMENTIN ADU. 1G/125MG B/12 SH	\N	\N	\N	859.66	AT PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	46	\N	f
c36818db-9d37-461d-bdea-ac71158aa847	100895	ZETA. 0,02 T/15G CREME	\N	\N	\N	137.13	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	27	\N	f
7ef1546e-cce2-4f28-a931-bf8d45a40cf6	100457	DOLIPRANE. 500MG B/16 COMP	\N	\N	\N	100.04	PROPHARMAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	26	\N	f
27f929f9-3c52-4cdd-be09-d8fdde335b39	103846	FRADENE. 20MG/ML B/2AMP SOL.INJ	\N	\N	\N	123.50	PROVIVO	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	60	\N	f
9a7837b7-4dbf-4fc5-ad18-374b0c0841c1	102118	BANDELETTES VITAL CHECK MS-2  B/50	\N	\N	\N	1500.00	VITAL CARE	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	4	\N	f
1565fc1f-0c0b-4225-acd2-b0e16db57b96	100462	DOLIPRANE. 200MG B/10 SUPPO	\N	\N	\N	124.06	PROPHARMAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	44	\N	f
8a6f23ce-73e7-4884-9157-bd6d68e9512b	103461	CLOVIRAX. 0,05 T/2G CREME. DERM	\N	\N	\N	122.36	PHARMALLIANCE LABORATOIRES	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	24	\N	f
e25a1819-0bbc-43b2-9593-d3bde568bda3	101402	CLOFENAL. 75MG/3ML B/2AMP SOL.INJ	\N	\N	\N	97.77	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	157	\N	f
52a18303-30a4-46b4-82ab-ca088a49e938	103675	MEPRENAL 40MG/2ML B/1+1 SOL.INJ	\N	\N	\N	206.05	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	54	\N	f
03a5a254-31f1-46fc-9a3c-7398d332c479	103862	VITAMINE D3 RAZES 200 000UI/ML B/1 SOL.I	\N	\N	\N	126.43	PROVIVO	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	130	\N	f
aa72e0d2-f3cb-4145-8b11-ab07d834ad4e	102594	THERANOX 6000UI ANTI-XA 60MG/0,6ML B/2 S	\N	\N	\N	1167.57	BIOTHERA SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	156	\N	f
4c601da5-4d3a-4a92-8e8b-bc7cd970b7d7	100996	EFFERALGAN PEDIATRIQUE 3℅ FL/150ML SOL.B	\N	\N	\N	223.08	PROPHARMAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	194	\N	f
111a069a-3bf3-4c20-b9ed-3d501863c434	102578	HARUFEN  PATCH B/7	\N	\N	\N	244.65	NEOMEDIC	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	117	\N	f
2751de35-dd4c-48cf-a2ec-83b4ae3d399e	100906	ZETA PLUS. 0,1%/2% T/15G CREME	\N	\N	\N	210.00	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	43	\N	f
e159e6cd-d383-4ac3-a955-68c205f6bde5	101456	CLOMYCINE. 0,03 T/15G PDE.DERM	\N	\N	\N	130.00	SAIDAL  SPA DISTRIBUTION	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	49	\N	f
d54e9418-743e-4640-97cf-0ca9ec070608	102210	CLAMOXYL. 250MG/5ML FL/60ML PDRE.P.SUSP.	\N	\N	\N	200.41	AT PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	126	\N	f
a06dc368-e687-467f-91b9-45a088de1d5f	103109	RINONIDE 64ΜG/DOSE /120 DOSE FL/15ML SPR	\N	\N	\N	649.61	GENERIC LAB SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	196	\N	f
3679cb2b-e8e9-4d33-9ec4-32e070e6557d	100345	NEUROVIT. 250MG/250MG B/20 COMP	\N	\N	\N	203.34	SAIDAL  SPA DISTRIBUTION	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	11	\N	f
c6c70da4-4f84-4f76-907c-5fd86517cb7a	100360	CLOMYCINE. 0,01 T/5G PDE.OPHT	\N	\N	\N	154.04	SAIDAL  SPA DISTRIBUTION	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	70	\N	f
e7dd4896-e4c1-40e9-b39a-2c05dc9d4e67	103710	SULPIRIDE MERINAL. 50MG B/30 GLES	\N	\N	\N	154.01	MERINAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	14	\N	f
5cbe1185-ccc4-4607-96bc-3620ea2e5ba8	102586	INDOCOLLYRE. 0,1% FL/5ML COLLYRE	\N	\N	\N	371.96	LDM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	183	\N	f
20cd80d6-ab26-4775-977b-98d72fa83438	100900	VAVO SHAMPOO. 0,02 FL/100ML SHAMP	\N	\N	\N	537.50	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	106	\N	f
881ad61b-eb1a-4bbf-89a8-aead96014bf5	101155	NOVOFORMINE. 850MG B/30 COMP. PELLI	\N	\N	\N	145.10	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	62	\N	f
4c558dc1-93d8-4dad-ba93-8d00338f89fe	102090	BIOVEX ADULTES. 500MG/200MG/25MG B/8 SH	\N	\N	\N	328.19	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	100	\N	f
f2ffd93d-9452-411e-8761-0c6dab585eac	103446	KENACORTYL RETARD 40MG/ML B/1ML SUSP.INJ	\N	\N	\N	397.49	SARL COPERDIS	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	117	\N	f
8a063409-4eec-4c69-a64d-e324ecbf0cf3	102589	THERACORT 40MG/ML B/1AMP SUSP.INJ	\N	\N	\N	201.98	BIOTHERA SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	161	\N	f
8b49c481-0b8c-4fd6-8854-c4fec4484b71	105216	PROCTOLON NEO 400/40 MG B/8 SUPPO	\N	\N	\N	877.25	SALEM LABORATOIRE SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	165	\N	f
9dcccb2a-7b0f-4fea-b604-9e92d121fcbe	100083	LAXADYL. 10MG B/6 SUPPO	\N	\N	\N	220.69	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	25	\N	f
37c51961-338d-45ec-81f6-20a5ee475c86	103836	TOPLEXIL. 0,33MG/ML FL/150ML SIROP	\N	\N	\N	187.83	PROPHARMAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	4	\N	f
d28edd13-f03d-41a5-985e-626fc9e22aa8	100284	BANDELETTES PRECIGO  B/50 TEST	\N	\N	\N	1500.00	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	54	\N	f
e1d4f0a0-3b16-4fb9-a70e-174e94c547ed	102128	BANDELETTE DIAGNO-CHECK SENS  B/50 TEST	\N	\N	\N	1500.00	NEOMEDIC	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	195	\N	f
48a02c65-af24-4a5c-91b5-9b0cb660b686	102569	CEBESINE. 0,4% FL/10ML COLLYRE	\N	\N	\N	277.07	LDM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	55	\N	f
6aca0dd5-6e3a-48a8-8373-e3c17e21b741	100999	EFFERALGAN VIT C. 500MG/200MG B/16 COMP.	\N	\N	\N	219.12	PROPHARMAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	122	\N	f
718e574e-aff6-4e31-a887-2a142d7fbf5b	102575	CARTEOL LP. 0,02 FL/3ML COLLYRE	\N	\N	\N	645.56	LDM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	111	\N	f
b16a1713-398c-48a0-9212-4911b0c409b8	100677	LIPANTHYL. 160MG B/30 COMP	\N	\N	\N	978.42	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	102	\N	f
63a54387-c2d8-49ef-8ef5-972c0e1fa35c	103311	TERBINAN. 0,01 T/15G CREME	\N	\N	\N	207.49	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	153	\N	f
a2034563-fd1b-4cc3-8e5d-217deebe5977	102590	LIPOSIC. 0,2% T/10G GEL.OPHT	\N	\N	\N	330.61	LDM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	113	\N	f
3dec0f6d-bd43-4826-bda9-224016a1216e	100181	PHENOXAL. 100MG B/20 COMP. SEC	\N	\N	\N	199.98	BIOGALENIC SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	152	\N	f
1cc0c15a-e7e6-4789-906b-5e4783200168	103530	APTAMIL PEPTI JUNIOR.  B/400G PDRE.P.SOL	\N	\N	\N	1285.18	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	96	\N	f
c466daaa-d5a4-4610-b810-458353d45263	100894	ZETA. 0,02 T/15G PDE	\N	\N	\N	156.68	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	89	\N	f
ebaf3ac2-f1e4-4790-a80e-2f4a23f49a69	102265	BANDELETTES ON CALL  EXTRA -1 TEST B/50	\N	\N	\N	1500.00	CYTOLAB	2026-03-26 10:46:23.86055+00	2026-04-01 15:54:31.561759+00	\N	75	\N	t
dc79af65-ce69-4b42-8a33-aa0ec4813825	100364	CAMPHO-BIOTIC ENF. 0,04G/0,05G/0,02G /0,	\N	\N	\N	112.84	SAIDAL  SPA DISTRIBUTION	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	122	\N	f
97960dea-f0cd-4dab-9efc-9936d7b12737	103318	CLOTASOL 0,05℅ T/45G CREME	\N	\N	\N	381.99	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	192	\N	f
07bed11f-ad1b-4b14-b442-a6434e07c748	100103	GYNOMIX 300MG B/1 OV	\N	\N	\N	396.00	SALEM LABORATOIRE SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	124	\N	f
f2e819c3-9380-4537-bd11-286dd2263274	101173	LOCOID. 0,1% T/30G CREME	\N	\N	\N	452.92	AT PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	195	\N	f
ddb60ae4-703f-40c9-975f-1310f11aea22	102733	FLUDEX LP. 1,5MG B/30 COMP. ENRO	\N	\N	\N	598.50	LDM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	83	\N	f
6f6d653e-1b45-442a-9fc0-79094297f312	102638	MICROBAN 2℅ T/15G PDE	\N	\N	\N	436.55	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	48	\N	f
af1dce31-cec9-4fda-9329-0d712504057c	101835	IBUTHOL 5%-3%  T/50G GEL	\N	\N	\N	415.01	NOVAPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	52	\N	f
5324d9c2-76ab-47ae-9315-762c637ab9c9	101320	LAMOGINE. 100MG B/30 COMP. SEC	\N	\N	\N	1699.92	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	142	\N	f
67fa873a-35b0-4fe6-b298-b16ad881a6fd	103708	KIETYL. 6MG B/30 COMP. QUADRI.SEC	\N	\N	\N	241.73	MERINAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	64	\N	f
ebd03bee-a78b-42fc-8b71-080d8212d153	103382	MELAZA 1G B/15 SUPPO	\N	\N	\N	2919.01	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	116	\N	f
31b2d93c-67d9-4b01-98ec-c4c1130fc635	102606	BIOCABASTINE 0,05℅ FL/5ML COLLYRE	\N	\N	\N	380.41	BIOTHERA SPA	2026-03-26 10:46:23.86055+00	2026-06-15 16:14:02.696749+00	\N	194	\N	f
152e22ac-2097-4928-b645-6b1df6e80f60	100128	COEXPANDOL 400MG/20MG B/16 COMP	\N	\N	\N	119.81	BIOGALENIC SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	128	\N	f
6eb24a03-0742-4a48-98a0-7ccde1425db8	105308	MEGAMYLASE SIROP FL125 ML	\N	\N	\N	187.12	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	157	\N	f
0029ee37-f901-46a4-9eb5-d41d164c8103	102620	THERAFRESH 0,2℅ FL/10ML COLLYRE	\N	\N	\N	998.07	BIOTHERA SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	15	\N	f
78fbc574-ac4f-4397-9540-395592946b0c	101950	NEBCAR 5MG B/30 COMP QUAD SECAB	\N	\N	\N	597.50	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	65	\N	f
1edb4fdf-1c7c-4847-b8bd-f6164f1d75e5	100113	CLORAXENE. 10MG B/30 GLES	\N	\N	\N	199.79	SALEM LABORATOIRE SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	90	\N	f
26ed47f8-74cd-4e69-a321-4f5475c54f6f	102868	MONCITRA 30MG B/30 COMP. PELLI	\N	\N	\N	1425.92	SARL BIG DIS	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	166	\N	f
68ff5893-3b79-4bac-973c-4d64e66be1ec	104988	ZOLAMIDE FREE 20MG/ML FL/5ML COLLYRE	\N	\N	\N	682.53	GENERIC LAB SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	119	\N	f
8f35a066-02b3-4fb9-bd3f-a14b782e7386	102083	DIAGLINIDE. 1MG B/30 COMP	\N	\N	\N	367.50	BIOCARE SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	97	\N	f
484c5892-982e-4cc1-95ec-b43985ed3190	101190	LEXIN. 1G B/12 COMP	\N	\N	\N	510.62	HIKMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	92	\N	f
5e57f1e4-b43f-45ba-aadc-c6d1b7533292	103169	ASPEC. 100MG B/98 COMP. SEC	\N	\N	\N	259.70	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-04-13 13:37:52.390464+00	\N	10	\N	f
8c963051-9879-44c3-a9f6-2ecec552d375	100289	DEXERYL CRE AVEC TVA  T/250G CREME. DERM	\N	\N	\N	1099.00	AT PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	123	\N	f
ea848d2f-888b-4158-867e-6f5a220ada4c	102577	FRAKIDEX. 630 000UI FL/5ML COLLYRE	\N	\N	\N	213.26	LDM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	195	\N	f
b1353279-83a9-4d7a-a6a8-c3481da6139c	103593	CO-DOLYC 500MG/30MG B/20 COMP	\N	\N	\N	215.82	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	156	\N	f
712985a6-5d7c-4a44-a374-6645167d4989	104738	ZYDEX 1% gel ophtalmique T/5G	\N	\N	\N	484.01	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	192	\N	f
6ecd7702-e826-4279-b480-59afa6a97df7	100454	TELFAST 120 MG B/15  COMP.PELLI	\N	\N	\N	226.50	PROPHARMAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	117	\N	f
e42c1764-5523-4ed4-b52d-290fdd10e7e0	101691	CUTACNYL 10% T/40G GEL	\N	\N	\N	264.40	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	193	\N	f
524c5fb4-4f2c-49f2-8432-90ca2cc013f9	100587	XAMADOL. 325MG/37,5MG B/20 COMP. PELLI	\N	\N	\N	333.35	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	75	\N	f
e119e611-bac0-4f7c-b95e-4355da3dbc7a	100964	DEPRETINE. 20MG B/30 COMP	\N	\N	\N	1596.00	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	33	\N	f
d3332ba8-f855-40cc-bf1c-ebf8bc2a4724	105208	CORONOL PLUS 1MG/ML+3MG/ML FL/5ML COLL	\N	\N	\N	342.18	GENERIC LAB SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	26	\N	f
d301b519-7d97-4df6-8b7f-99321a9965b3	103292	BETSOL. 0,5MG/ML FL/15ML LOT.DERM	\N	\N	\N	199.32	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	162	\N	f
9b849738-afb3-4307-95f7-9910c1d4ba70	103603	XYDOL GYN. 100MG B/20 COMP. PELLI	\N	\N	\N	255.00	MERINAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	3	\N	f
88c8d3b9-c187-425c-a2cc-9b5c81d9c75d	101048	TAMSIR  LP. 0,4MG B/30 GLES	\N	\N	\N	1497.50	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	97	\N	f
26e04ec4-2950-43fa-a436-c48ce8879994	100898	INFECTOBAN. 0,02 T/15G PDE	\N	\N	\N	357.50	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	105	\N	f
d7783e41-91bd-4ed5-bcb4-f4bd32cacbaf	103038	LEVOTHYROX. 75µG B/30 COMP. SEC	\N	\N	\N	177.17	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	94	\N	f
8bfe8acf-0e1f-434a-8a60-e914f0e992ad	102448	POLYGYNAX. 35 000UI/35 000UI/100 000UI B	\N	\N	\N	669.21	UPC DISTRIBUTION	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	102	\N	f
fc7ee691-a366-4fbc-8860-99d1d2c30057	100383	OVESTIN. 0,5MG B/15 OV	\N	\N	\N	835.45	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	127	\N	f
6931e056-2b2a-4744-8592-83d154258514	103505	NOZINAN. 0,04 FL/30ML GTTES. BUV	\N	\N	\N	248.31	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	198	\N	f
d2b0aba9-adbb-4681-b337-a10389693607	101045	DAKTAZOL 2℅ GEL.BUCC T/40G	\N	\N	\N	312.02	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	131	\N	f
5aa3d706-712c-4be2-85f3-6eb0acb33019	102738	DIAMICRON. 30MG B/30 COMP. LM	\N	\N	\N	509.78	LDM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	99	\N	f
a8728fbc-a1b2-440c-9c45-6588fb304429	104035	VIBAC 1,5% FL/10ML COLLYRE	\N	\N	\N	392.86	GENERIC LAB SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	144	\N	f
f507348c-1f33-490f-ad91-45d0bc56b281	100097	PROCTOLON. 120MG/10MG B/10 SUPPO	\N	\N	\N	341.88	SALEM LABORATOIRE SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	198	\N	f
e67fa525-e8f5-490d-a37d-0abc1ed84664	101660	BLOPRESS PLUS 8MG/12,5MG B/30 COMP. SEC	\N	\N	\N	1610.47	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	182	\N	f
ccabfbea-b88d-4ecc-adbd-f39e307f633f	105042	KOPROFEN  2,5% T/60G GEL	\N	\N	\N	314.93	LDM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	31	\N	f
c5066342-35e2-4e77-a282-e03f94f8e9d7	103044	GLUCOPHAGE 850MG B/90 COMP. PELLI	\N	\N	\N	440.30	AT PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	76	\N	f
74b28038-7f09-4e38-94de-8663150fbb77	100307	GECTAPEN. 1 000 000UI B/1 PDRE.P.SOL.INJ	\N	\N	\N	142.70	SAIDAL  SPA DISTRIBUTION	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	3	\N	f
96f86264-21b4-4624-93c2-a84ab4a73eb5	101097	CETALGINE. 300MG B/10 SUPPO	\N	\N	\N	141.16	SALEM LABORATOIRE SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	159	\N	f
89d5ed34-a1ae-4c0d-a081-e57a52bf52ef	103121	BIOCLAV ADULTES. 1G/125MG B/12 SH	\N	\N	\N	737.35	BIOCARE SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	7	\N	f
c78104d2-46d5-49ee-b6ab-151900cea1e8	102902	SAPRAMOL. 300MG B/12 SH	\N	\N	\N	115.32	PROVIVO	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	198	\N	f
c4e77422-c7f3-4011-88b1-55232d4bf98c	101534	COBAMINE. 1000µG/ML B/5AMP SOL.INJ	\N	\N	\N	220.00	SAIDAL  SPA DISTRIBUTION	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	147	\N	f
d4a4f866-09a2-48ae-9899-356112e99296	103640	VOLTUM 2℅ T/50G EMULGEL	\N	\N	\N	191.90	PHARMALLIANCE LABORATOIRES	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	129	\N	f
c459f9ab-45f0-4f9d-a550-390cbc27e360	100559	ATACAND EL-DJAZAIR 16MG B/30 COMP. SEC	\N	\N	\N	1287.50	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	48	\N	f
22a9bb22-6149-41d7-952c-06a41a5836ed	104207	HIMOXYL. 250MG/5ML FL/60ML PDRE.SUS.BUV	\N	\N	\N	197.40	EURL GENIS	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	89	\N	f
60b3d23b-7a49-42c2-8dc1-e63a13d8a224	102587	BIOLESTENE CHRONODOSE 5.7MG/ML  B/1AMP S	\N	\N	\N	187.91	BIOTHERA SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	76	\N	f
23b8d8a5-22e8-4197-a44f-f77df51a9427	100162	TRIMEBUTINE-B 0,787G/100G FL/250ML SUSP.	\N	\N	\N	311.52	BIOGALENIC SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	178	\N	f
0e0413b5-fdaf-42a8-8a3f-f61af8cef26e	101229	ZOMAX. 40MG/ML FL/30ML PDRE.P.SUSP.BUV	\N	\N	\N	855.64	HIKMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	34	\N	f
36f4b481-e00d-4014-8fd6-e1a159aaf576	100904	LOCAZONE 0,1℅ T/15G CREME.CUTANEE	\N	\N	\N	203.49	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	159	\N	f
85d79d5d-ba26-46aa-9647-ff79261c7994	101304	VALENS 10MG B/30 COMP. PELLI	\N	\N	\N	2422.50	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	58	\N	f
01c4ce47-9509-4f19-b702-3ddd606cb25a	101735	METHOTREXATE EBEWE. 2,5MG B/50 COMP	\N	\N	\N	965.75	AT PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	142	\N	f
f8e8d8ec-5b27-435a-aa18-228df987e4de	101223	ZOMAX 40MG/ML FL/15ML PDRE.P.SUSP.BUV	\N	\N	\N	427.81	HIKMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	78	\N	f
4037461d-2650-43ff-8df4-9da73f02300f	102091	URICARE. 3G B/1 SH	\N	\N	\N	748.57	BIOCARE SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	180	\N	f
4a43a972-ce5f-40d6-8fac-3618867c2664	104092	ROSUVIA 10MG COMP. PELLI B/30	\N	\N	\N	835.10	MERINAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	85	\N	f
18d2e53e-ed6b-4135-8400-e5a2fa88ca71	100547	DEPAKINE CHRONO. 500MG B/30 COMP. PELLI.	\N	\N	\N	1089.18	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	44	\N	f
953c0383-c8f4-4314-89e6-cadfb7808947	100482	DONICORT 64µG/DOSE FL/120DOSES SUSP.NAS	\N	\N	\N	649.61	BIOGALENIC SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	91	\N	f
413704c7-8e5d-445c-8b46-84b61cfd1169	101897	LEMOD SOLU. 40MG B/1 PDRE.P.SOL.INJ	\N	\N	\N	206.05	GEO PHARM PRODUCTION	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	23	\N	f
2f816437-9c70-4901-a2d9-f661737a90a1	100693	SMECTA. 3G B/30 SH	\N	\N	\N	406.61	AT PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	185	\N	f
3e947b0c-090b-468e-a135-344ba0de8b6a	103700	CALCIDOSE 500MG B/30 SH	\N	\N	\N	400.00	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-06-15 16:14:02.696749+00	\N	77	\N	f
8e1cde62-bb09-4d9c-bef5-9e81ac6622d7	102099	HUMEX RHUME. 500MG/60MG B/12 COMP	\N	\N	\N	340.67	UNILAB	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	51	\N	f
c256cc07-1613-449a-a081-865b4cd18362	100860	GLYCERINE GPA BéBé B/10 SUPPO	\N	\N	\N	175.00	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	156	\N	f
3ff2fa32-995b-42c8-aa98-9418cdd9ccbb	103614	XYDOL. 200MG B/20 COMP. PELLI	\N	\N	\N	122.36	MERINAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	20	\N	f
6a2e419e-eef6-4531-aa32-7182f1647503	100471	DOLIPRANE 2.4% SANS SUCRE. 120MG/5ML FL/	\N	\N	\N	165.63	PROPHARMAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	187	\N	f
37b0ceb3-ff58-4610-b493-915df2b6e67f	102866	CARDULAR. 2MG B/20 COMP. SEC	\N	\N	\N	547.50	UPJOHN SAIDAL PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	145	\N	f
5034e666-f53b-45b3-ad91-478d389082f4	103674	SPACYL 80MG B/20 COMP. ORO.DISP	\N	\N	\N	343.20	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	22	\N	f
ce67703d-1b3a-4f61-8ddd-b7073630ef7e	103359	DAPROSAL 0.05%/3% T/15G PDE.DERM	\N	\N	\N	118.98	PHYSIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	172	\N	f
8ee5677b-e5db-46f0-b33a-cc6773ce2822	100586	PAROL 300MG B/10 SUPPO	\N	\N	\N	141.16	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	193	\N	f
148fbdbe-1912-47e8-a68f-9116dfe183e2	100376	RHUMAFED. 2,5MG/50MG/300MG B/20 COMP. SE	\N	\N	\N	160.00	SAIDAL  SPA DISTRIBUTION	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	81	\N	f
0a5b47a1-87a0-4c55-afd8-cd50997fc5e6	100644	CRONOLONE TRIAMCINOLONE NEO 0,1℅+0,35℅ T	\N	\N	\N	462.32	GENERIC LAB SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	18	\N	f
f8168f08-94ca-47d5-8b60-e542663b07bd	101295	GLINIX. 2MG B/30 COMP	\N	\N	\N	387.50	HIKMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	112	\N	f
1446c26d-4837-4291-bad7-4acca0c651b0	103464	CLOVIRAX. 0,05 T/10G CREME. DERM	\N	\N	\N	279.28	PHARMALLIANCE LABORATOIRES	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	110	\N	f
e9ecc48f-388d-4304-9d48-0ea710cdcc43	101477	BETASONE 0,1℅ T/15G PDE.DERM	\N	\N	\N	146.24	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	150	\N	f
06eb2f49-2bb8-430a-a1d0-d0119dac0071	101162	NOVOFORMINE. 1000MG B/30 COMP. PELLI	\N	\N	\N	170.90	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	182	\N	f
2edde32f-67a8-4ab3-a810-59d65a3932f1	103362	PHYSIOLONE 1MG/ML FL/60ML SOL.BUV	\N	\N	\N	492.00	PHYSIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	34	\N	f
6988420b-5aae-4f37-b42b-c1960597571e	102156	SINECOD 0.15%. 1,5MG/ML FL/200ML SIROP	\N	\N	\N	312.02	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	156	\N	f
1ea308e2-43bb-4381-bf59-ef378ee8482e	101963	DIVIDO. 75MG B/20 CAPS.LP	\N	\N	\N	546.48	EURL TABUK	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	26	\N	f
473b8bb5-8018-4b2f-ab5e-ad44ef8e42e7	103079	ATRYLINE. 25MG B/60 COMP. ENRO	\N	\N	\N	282.49	GENERIC LAB SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	159	\N	f
83eb3b93-8e45-4673-b414-a77b3999bbb1	103216	OLANZA. 10MG B/28 COMP. PELLI	\N	\N	\N	2541.58	BEKER LABORATOIRES	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	168	\N	f
052e7836-f493-48b6-a4a6-7cfbf1c9fa71	103844	DICLAMID. 75MG/3ML B/2AMP SOL.INJ	\N	\N	\N	98.10	PROVIVO	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	44	\N	f
b918e0e8-ae78-4421-9846-b06c0ebfa335	103063	NAGOXIN. 0,25MG B/30 COMP. SEC	\N	\N	\N	200.41	GENERIC LAB SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	136	\N	f
5de5ae08-5390-4c43-902b-da95cd27194f	100865	AROVAN. 10MG B/30 COMP. PELLI	\N	\N	\N	835.10	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	27	\N	f
7435046b-fc3b-4c8e-9041-9c1e886aa102	100485	APROVEL. 150MG B/28 COMP. PELLI	\N	\N	\N	1201.50	SANOFI AVENTIS  SPA	2026-03-26 10:46:23.86055+00	2026-04-13 12:31:59.749756+00	\N	32	\N	f
4a8921b4-7955-472d-91f3-d77d0b4e70dc	102197	CICATRINE 5MG B/10 OVULES GYNECO	\N	\N	\N	1189.88	SALEM LABORATOIRE SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	132	\N	f
172ef723-7572-4360-ba73-71b60206190e	103340	LOMAC. 20MG B/15 GLES	\N	\N	\N	208.40	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	111	\N	f
14b55f14-7697-4007-9c0b-3dfaf4990871	101695	CUTACNYL 2,5% T/40G GEL	\N	\N	\N	245.42	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	180	\N	f
95e4b260-b2de-4657-a568-6f10481c4a65	103391	POLYVAX  B/12 OV	\N	\N	\N	532.50	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	40	\N	f
8a418e73-4323-4fa2-ab33-d6c42c78bbea	101226	ZOMAX 40MG/ML FL/22.5ML PDRE.P.SUSP.BUV	\N	\N	\N	594.00	HIKMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	47	\N	f
e7a05b83-3400-4dd3-947f-20dfc1a0c2f1	101898	SARCAND. 16MG B/30 COMP	\N	\N	\N	1287.50	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	175	\N	f
d5d2a015-c492-492a-bef6-b1425165ff2a	104672	BIOPAMOX 1G B/8 SH	\N	\N	\N	199.89	BIOCARE SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	115	\N	f
6ca85bf4-69cb-4172-8f25-9c7405e02b24	102669	GLARUS 100UI/ML B/5STYLO SOL.INJ SER.PRE	\N	\N	\N	6260.43	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	181	\N	f
4812aaae-f518-46b7-8cce-d277d958a2c1	104986	FLIXODIS 0,05℅ B/120DOSE SPRAY.NAS	\N	\N	\N	688.50	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	5	\N	f
c46a46be-f2b5-4609-9563-3f1b583cec60	101585	RHINODIS 64µG/DOSE FL/120DOSES SOL.NAS	\N	\N	\N	649.44	INPHA MEDIS SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	178	\N	f
dac665c6-7a27-4915-a2c7-c7e0f097d00f	101174	DIGESTAT. 100MG B/10 SUPPO	\N	\N	\N	210.00	SALEM LABORATOIRE SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	84	\N	f
ee5bcc2e-98b8-470d-a111-310f96e52425	102857	ZOLOFT. 50MG B/14 GLES	\N	\N	\N	599.50	UPJOHN SAIDAL PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	170	\N	f
ab13b2e4-c0c3-443c-bc5d-79959ddda161	101645	AZITHROMYCINE  NS 500MG COMP. PELLI.SEC	\N	\N	\N	549.94	PHARMIDAL SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	154	\N	f
9616350b-6010-407d-a0af-e24f0b6735c5	103716	COTRIMOXAL FORTE 160MG B/20 COMP	\N	\N	\N	297.49	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	61	\N	f
a277aa77-32c3-466b-b829-be57a731ca6a	101937	DILACARD. 6,25MG B/30 COMP	\N	\N	\N	693.72	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	39	\N	f
d66e3aa0-1ebd-4ec1-919d-9905e9dc3fa3	100206	PREZIVA. 10MG B/40 COMP	\N	\N	\N	174.30	BIOGALENIC SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	10	\N	f
ba23a7c2-5caa-4999-8c95-63db832edb54	101798	DERMOCONAZOLE 2%  T/20G CREME	\N	\N	\N	228.93	NOVAPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	8	\N	f
7e5d5112-6e77-4cdd-99c3-e0e6daeae119	103753	NEOCARDIL 40MG B/50 COMP. PELLI.SEC	\N	\N	\N	395.57	NEOMEDIC	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	164	\N	f
4db77aad-b63f-4d60-a06d-387911960116	103652	SEBUTOL. 200MG B/30 COMP. PELLI	\N	\N	\N	350.75	MERINAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	133	\N	f
4eb13f82-85cf-44a9-b75e-4c799f9048a9	103493	DOMPERONE. 10MG B/40 COMP	\N	\N	\N	258.90	PHARMALLIANCE LABORATOIRES	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	18	\N	f
a5b4ea63-cca6-49f3-87e5-6ecb6cd17ec0	100464	DOLIPRANE. 300MG B/10 SUPPO	\N	\N	\N	141.16	PROPHARMAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	93	\N	f
002bf55d-20b7-40f8-b285-344ae637253b	102808	CELEBREX. 200MG B/15 GLES	\N	\N	\N	679.50	UPJOHN SAIDAL PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	2	\N	f
e5080ce5-f87b-45b9-b80d-c09129dfb92a	100460	DOLIPRANE. 150MG B/10 SUPPO	\N	\N	\N	124.06	PROPHARMAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	34	\N	f
d70fd4c8-795b-4175-9f07-5d4969cc205e	104968	DYDROGYN 10MG B/10 COMP	\N	\N	\N	416.56	UPC IMPORTATION	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	35	\N	f
51772893-c6ac-46e1-8f1e-29f7eb37d1f4	102719	PRETERAX ARGININE. 2,5MG/0,625MG B/30 CO	\N	\N	\N	524.62	LDM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	152	\N	f
5f3cbd0e-44e4-4833-b8e2-39c4b3cbc8a6	101418	PRIXAM. 20MG/ML B/2 SOL.INJ.IM	\N	\N	\N	117.50	SAIDAL  SPA DISTRIBUTION	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
cf502a80-748d-4c4c-a829-384cd4f28632	103308	FUCIDINE. 0,02 T/15G PDE.DERM	\N	\N	\N	201.96	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
7c9fcf31-23dd-4a53-aebc-1e497c5a8dcc	102272	ISOPERIDOL. 2MG/ML FL/20ML SOL.BUV.GTTES	\N	\N	\N	113.79	ISOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
473d9ce3-b656-4539-9de1-bc68e43f94b5	102219	CLAMOXYL. 500MG/5ML FL/60ML PDRE.P.SUSP.	\N	\N	\N	272.33	AT PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
66ab38b5-6dcb-4757-9015-2cf3630e2059	100189	PARKIDYL. 5MG B/20 COMP. SEC	\N	\N	\N	199.98	BIOGALENIC SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
5a22b2a5-3180-404e-9340-87e5928feb15	101037	TABIFLEX COOL 1℅ T/50G EMULGEL	\N	\N	\N	161.34	EL KENDI SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
5513c45a-7ba0-4b71-9fd1-83b81677074d	100476	MOMENEX 50µG/DOSE SPRAY.NAS FL/120DOSE	\N	\N	\N	746.50	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
265d9f6e-50d3-4478-93f4-84aaa900acdb	103097	CHIBROGEN 0.3% FL/5ML COLLYRE	\N	\N	\N	353.11	GENERIC LAB SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
14c4de2e-b376-4b15-b198-a443cc528ce9	103088	ZOLIDRATE 10MG COMP. PELLI B/20	\N	\N	\N	252.48	GENERIC LAB SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
6c34c012-7915-4776-a07f-39eb6adc4c34	100180	CARBIMOL 200MG B/30 COMP	\N	\N	\N	258.50	BIOGALENIC SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
8f75d14b-4f8b-4f51-8ab6-5178684ec719	103591	DOLYC. 500MG B/20 COMP	\N	\N	\N	120.00	MERINAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
c0c4e9eb-b124-4649-8603-ec2090d9b779	105238	TRAVADROP  FREE 40µG/ML COLLYRE FL/2.5ML	\N	\N	\N	1611.65	GENERIC LAB SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
256a4ce1-c8c0-43c6-a760-fa83b811553b	102837	DEBRIDAT. 200MG B/30 COMP. PELLI	\N	\N	\N	271.50	UPJOHN SAIDAL PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
b8887577-7eed-4b52-8d41-06acdfe166a2	100968	DEPRETINE. 10MG B/30 COMP	\N	\N	\N	884.90	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
90200f27-9a7f-471d-9328-f060d1c24891	104940	ZOLOFT 50MG B/28 GLES	\N	\N	\N	980.49	UPJOHN SAIDAL PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
bd9da9fc-b681-4350-9efa-27960a2367ef	102270	ISOPTYL. 40MG/ML FL/20ML SOL.BUV.GTTES	\N	\N	\N	117.80	ISOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
700422a9-c456-455f-a379-2a1e5ea5e6dc	103086	ORZEPAM. 2,5MG B/30 COMP. SEC	\N	\N	\N	197.50	GENERIC LAB SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
014f117c-c473-42a8-9436-1d764d393cf7	102885	RHINATHIOL ADU. 0,05 FL/125ML SIROP	\N	\N	\N	156.77	PROPHARMAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
bec9aaab-341b-43ba-90ca-879287313958	103173	AZITHROMYCINE BEKER. 500MG B/3 COMP. PEL	\N	\N	\N	501.61	BEKER LABORATOIRES	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
0de5f9dd-0cae-4ddd-a7e0-35dc57ebd1db	102642	KETONYX 2.5%  T/50G GEL	\N	\N	\N	262.43	ONYX SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
7c0d3e06-83ea-44e0-a8b3-2a75b7cc692e	103037	LEVOTHYROX. 25µG B/30 COMP. SEC	\N	\N	\N	112.34	AT PHARMA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
a77bf257-0ccd-4a19-9bd6-e6e12e2075e6	105336	GLARUS PLUS 300UI/ML B/3 STYLO CT 1.5ML	\N	\N	\N	5559.84	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
ec9ea5cf-4731-4d28-b580-f45b357b1aa2	100505	APROVASC 300MG/10MG B/30 COMP. PELLI.SEC	\N	\N	\N	1497.50	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
fa79823a-56dc-49d4-8066-411a1961632b	103612	INICOX 200MG B/12 GLES	\N	\N	\N	543.59	MERINAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
05afce1d-1090-4542-9656-152249a6a3b0	101134	NIFLUMENE SALEM. 400MG B/8 SUPPO	\N	\N	\N	218.50	SALEM LABORATOIRE SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
08ca1341-1e22-4565-aba2-4b531b908fb9	102211	MICROGYNON 30. 0,15MG/0,03MG B/3*21 DRAG	\N	\N	\N	285.43	SOMEDIAL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
f1b74f45-18f0-4aaa-b552-faff0cdf32cc	100849	BUDECORT. 200µG/DOSE FL/200DOSES PDRE.P.	\N	\N	\N	949.86	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
6ccade22-6a58-4328-a8ad-56aee1df6935	104414	PROSTACARE 5MG B/30 COMP. PELLI	\N	\N	\N	1430.06	BIOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
e05026da-2f54-4e7f-890e-aec8779a2bf2	103768	NEOFERON 80MG B/30 COMP. PELLI	\N	\N	\N	380.16	NEOMEDIC	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
72dcd068-d94c-4c76-9dca-3ddace1e5962	100501	APROVASC 150MG/5MG  B/30 COMP. PELLI	\N	\N	\N	1497.50	SANOFI AVENTIS  SPA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
bd05e4e7-ed79-463a-b0bc-88bea0e00146	103016	PROSTASIR LP. 0,4MG B/30 GLES	\N	\N	\N	1252.75	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
bd7b8de8-7fa4-4263-a9ec-b6ab31e8853a	105172	DERMAZOLE   0,02 T/20G CREME	\N	\N	\N	228.94	PHARMAGHREB LABORATOIRES	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
b341e09b-3c3a-4c2f-a8bc-a94f44e1b79a	100643	NEWFINE  T/50G APP.CUTANEE	\N	\N	\N	350.00	NEW GALINICA SARL	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
aec61c3d-971c-4b13-a145-28834d0bff3e	102239	ISOMEDINE. 0,1% FL/50ML SOL.DERM	\N	\N	\N	139.49	ISOPHARM	2026-03-26 10:46:23.86055+00	2026-03-26 10:46:23.86055+00	\N	0	\N	f
592e33a9-acd2-410c-81f2-6cb3f8f17298	101260	AMOCLAN 8:1 ENFTS. 500MG/62,5MG B/14 SH	\N	\N	\N	455.58	HIKMA	2026-03-26 10:46:23.86055+00	2026-06-16 21:30:47.31459+00	\N	8	\N	f
02787863-90cc-4020-93a4-0fc4bab203c7	101371	ALLERTINE. 10MG B/20 COMP. SEC	\N	\N	\N	198.50	SAIDAL  SPA DISTRIBUTION	2026-03-26 10:46:23.86055+00	2026-06-16 21:31:12.935873+00	\N	52	\N	f
6ef1aae9-5d86-46ca-ae3e-dcd15e0ffceb	103096	BIOPAMOX. 250MG/5ML FL/60ML PDRE.P.SUSP.	\N	\N	\N	200.41	BIOCARE SPA	2026-03-26 10:46:23.86055+00	2026-06-15 16:14:02.696749+00	\N	185	\N	f
bd0ee39a-b886-4631-8dd9-50e77aef7b27	103246	BIOFENAC. 100MG B/10 SUPPO	\N	\N	\N	107.40	SPA DIMED AZAZGA	2026-03-26 10:46:23.86055+00	2026-06-15 16:14:02.696749+00	\N	183	\N	f
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.notifications (id, user_id, commande_id, type, message, read, created_at) FROM stdin;
53db4bb1-b922-42cc-90a7-1566070cb964	80b3ae99-edfc-4220-a471-03c5366fb10d	0bff5c32-f6f8-4986-92ea-b6a8147cba6a	acceptee	Commande C00000006 acceptée	f	2026-03-26 11:16:21.014858+00
eea6ac3c-0712-4611-9b3d-ae886ed8bc06	80b3ae99-edfc-4220-a471-03c5366fb10d	39c1dfe9-f87e-48b9-82f9-585965bef503	acceptee	Commande C00000007 acceptée	f	2026-03-26 11:30:31.07914+00
c89b0278-08a4-4bcf-98bb-834465124f2d	80b3ae99-edfc-4220-a471-03c5366fb10d	39c1dfe9-f87e-48b9-82f9-585965bef503	en_preparation	Commande C00000007 en préparation	f	2026-03-26 12:01:54.234914+00
eb31056c-f9f8-43d5-98c7-4f9c469c016c	80b3ae99-edfc-4220-a471-03c5366fb10d	0bff5c32-f6f8-4986-92ea-b6a8147cba6a	en_preparation	Commande C00000006 en préparation	f	2026-03-26 12:04:57.288014+00
3f975ef1-e40b-46ac-b70e-df96f3dd33e7	80b3ae99-edfc-4220-a471-03c5366fb10d	8749fa09-b997-45a6-b5be-e9b1f49c23d2	acceptee	Commande C00000005 acceptée	f	2026-03-26 12:23:05.280848+00
7afcb1fe-c8e3-483e-b62d-79df165d4b34	80b3ae99-edfc-4220-a471-03c5366fb10d	8749fa09-b997-45a6-b5be-e9b1f49c23d2	en_preparation	Commande C00000005 en préparation	f	2026-03-30 11:31:17.276073+00
0bf727b0-b178-49d7-b873-c7502b400c87	80b3ae99-edfc-4220-a471-03c5366fb10d	f61d715f-0444-45bc-b848-927210e1a0b9	acceptee	Commande C00000010 acceptée	f	2026-03-30 17:59:59.843359+00
aa5b9c02-6d8b-4053-8e18-eb266c70fc14	80b3ae99-edfc-4220-a471-03c5366fb10d	f61d715f-0444-45bc-b848-927210e1a0b9	en_preparation	Commande C00000010 en préparation	f	2026-03-30 18:01:39.023167+00
936cf259-2fd9-4d06-a6d7-adf3c0eac92c	80b3ae99-edfc-4220-a471-03c5366fb10d	dbbca1b4-1782-4fd5-9255-9e458cdbd550	acceptee	Commande C00000013 acceptée	f	2026-04-01 13:41:23.403181+00
ccd73b4a-937d-497c-a58e-414c77e32263	80b3ae99-edfc-4220-a471-03c5366fb10d	dbbca1b4-1782-4fd5-9255-9e458cdbd550	en_preparation	Commande C00000013 en préparation	f	2026-04-01 13:51:50.55436+00
2e405fca-53a6-441c-b089-bd563996ff0d	80b3ae99-edfc-4220-a471-03c5366fb10d	106039b7-a430-4ce3-ae3a-e85ecdc1efa5	acceptee	Commande C00000014 acceptée	f	2026-04-01 15:54:31.615845+00
f995787a-2d97-4a0f-9a17-9849d8787779	80b3ae99-edfc-4220-a471-03c5366fb10d	3f80e2e0-8be4-44f0-981e-95810dc3d429	acceptee	Commande C00000016 acceptée	f	2026-04-01 15:59:21.601756+00
df564560-c453-4f07-ae43-983f3edfd0ac	80b3ae99-edfc-4220-a471-03c5366fb10d	3f80e2e0-8be4-44f0-981e-95810dc3d429	en_preparation	Commande C00000016 en préparation	f	2026-04-01 16:07:53.161604+00
37f8bd75-96ff-40a3-805a-962efc476fc8	80b3ae99-edfc-4220-a471-03c5366fb10d	106039b7-a430-4ce3-ae3a-e85ecdc1efa5	en_preparation	Commande C00000014 en préparation	f	2026-04-01 16:08:10.56089+00
2a83d406-b3a5-4a61-b12e-61b104907aa1	80b3ae99-edfc-4220-a471-03c5366fb10d	fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07	acceptee	Commande C00000017 acceptée	f	2026-04-07 11:48:50.088446+00
b02b1379-6dc3-4736-a106-c635f39ef776	80b3ae99-edfc-4220-a471-03c5366fb10d	96fdb118-00e1-4720-b8f9-2f3b30e58611	acceptee	Commande C00000018 acceptée	f	2026-04-13 10:25:08.061239+00
ef9a7dfe-4edf-4ff2-97ab-c265a192a208	80b3ae99-edfc-4220-a471-03c5366fb10d	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	acceptee	Commande C00000019 acceptée	f	2026-04-13 11:37:17.775723+00
9123a3ae-7ed8-47d7-9743-5116d7451026	80b3ae99-edfc-4220-a471-03c5366fb10d	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	en_preparation	Commande C00000019 en préparation	f	2026-04-13 11:57:33.609567+00
87445810-bc07-4af3-a6d4-9d6baf8e8e83	80b3ae99-edfc-4220-a471-03c5366fb10d	96fdb118-00e1-4720-b8f9-2f3b30e58611	en_preparation	Commande C00000018 en préparation	f	2026-04-13 12:16:31.929537+00
e08284af-dcae-4508-a694-9e461b11b6cd	80b3ae99-edfc-4220-a471-03c5366fb10d	fc503d8a-06ee-4c1b-a604-7c0cfc2cbb07	en_preparation	Commande C00000017 en préparation	f	2026-04-13 12:16:42.044061+00
dea6c0eb-dcd4-44bd-80ef-d674830d4fb0	80b3ae99-edfc-4220-a471-03c5366fb10d	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	acceptee	Commande C00000023 acceptée	f	2026-04-13 12:29:27.025448+00
e95dd2e0-ef3d-4802-a68c-968ba0df7085	80b3ae99-edfc-4220-a471-03c5366fb10d	9bf827a6-b240-4200-a206-40f132b84460	acceptee	Commande C00000015 acceptée	f	2026-04-13 12:31:54.764487+00
b5729d9c-0dbd-44ac-8dd3-1e5ef9f2b18e	80b3ae99-edfc-4220-a471-03c5366fb10d	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	acceptee	Commande C00000022 acceptée	f	2026-04-13 12:31:59.874635+00
1068d086-db81-4e67-9a52-63d4e8e01e89	80b3ae99-edfc-4220-a471-03c5366fb10d	870c4e4e-0ac5-47e6-9ad5-ad018343b8cd	en_preparation	Commande C00000023 en préparation	f	2026-04-13 12:32:17.701262+00
2c81037c-3486-4f56-8178-6645bd9c6adf	80b3ae99-edfc-4220-a471-03c5366fb10d	17c3ce0d-4a8e-4b70-8872-30d5b906bfe7	en_preparation	Commande C00000022 en préparation	f	2026-04-13 12:32:42.475659+00
a58b7098-18c2-4219-9f61-201261767a3e	80b3ae99-edfc-4220-a471-03c5366fb10d	9bf827a6-b240-4200-a206-40f132b84460	en_preparation	Commande C00000015 en préparation	f	2026-04-13 13:06:05.203596+00
0a4b04ea-ee72-4a90-98be-64c61e2f5e30	80b3ae99-edfc-4220-a471-03c5366fb10d	96fdb118-00e1-4720-b8f9-2f3b30e58611	en_route	Commande C00000018 en cours de livraison	f	2026-04-13 13:10:38.051709+00
b7655cf1-620c-423c-be0e-be51c9400bdc	80b3ae99-edfc-4220-a471-03c5366fb10d	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	en_route	Commande C00000019 en cours de livraison	f	2026-04-13 13:10:38.093962+00
7293b2fb-9b71-4ffc-b1ff-878c82503fcb	80b3ae99-edfc-4220-a471-03c5366fb10d	96fdb118-00e1-4720-b8f9-2f3b30e58611	livree	Commande C00000018 livrée	f	2026-04-13 13:10:48.265265+00
20f67f90-e920-4b91-b5f0-ee6e11fa1032	80b3ae99-edfc-4220-a471-03c5366fb10d	19dd4b84-c4cb-4603-a8bb-5a9a1aa356b6	livree	Commande C00000019 livrée	f	2026-04-13 13:10:54.626906+00
7a3e4f5e-5172-443b-9ad0-59543c440747	80b3ae99-edfc-4220-a471-03c5366fb10d	2c2e82ab-d610-4c51-9d96-3975c65d03db	acceptee	Commande C00000026 acceptée	f	2026-04-13 13:37:52.463593+00
3a75ecc2-b672-45e7-9d25-e13e5cb77d41	80b3ae99-edfc-4220-a471-03c5366fb10d	2c2e82ab-d610-4c51-9d96-3975c65d03db	en_preparation	Commande C00000026 en préparation	f	2026-04-13 13:38:44.494998+00
32780aae-d342-41d5-8093-f0c3c4651242	80b3ae99-edfc-4220-a471-03c5366fb10d	48615e40-3d72-40e0-924d-fa4ea9ae3604	acceptee	Commande C00000025 acceptée	f	2026-04-13 13:40:16.164249+00
7fa58268-8d4b-4472-97eb-d3456ab668f7	80b3ae99-edfc-4220-a471-03c5366fb10d	f513fe06-a0cf-44fa-838f-5453e98790b5	acceptee	Commande C00000024 acceptée	f	2026-04-13 13:40:21.354887+00
70aa47a7-e6a3-4135-816e-fbabc5d876ad	80b3ae99-edfc-4220-a471-03c5366fb10d	48615e40-3d72-40e0-924d-fa4ea9ae3604	en_preparation	Commande C00000025 en préparation	f	2026-04-13 13:40:29.369044+00
58c882c2-2ad2-4ffc-a851-3b6c0d286708	80b3ae99-edfc-4220-a471-03c5366fb10d	6e7ffbab-0205-4987-b782-0f9dfae7d304	acceptee	Commande C00000028 acceptée	f	2026-04-13 20:14:14.650008+00
0a196185-f507-425b-aaad-ff886e5003ef	80b3ae99-edfc-4220-a471-03c5366fb10d	6e7ffbab-0205-4987-b782-0f9dfae7d304	en_preparation	Commande C00000028 en préparation	f	2026-04-13 20:15:23.55511+00
7b0463e7-dc47-497d-8a39-a97749748dd5	80b3ae99-edfc-4220-a471-03c5366fb10d	f513fe06-a0cf-44fa-838f-5453e98790b5	en_preparation	Commande C00000024 en préparation	f	2026-04-13 20:16:55.754845+00
e30f2b09-97f1-4572-9bb0-0a57c52eb630	80b3ae99-edfc-4220-a471-03c5366fb10d	18a1fd87-3e0b-477f-a337-39709652df94	acceptee	Commande C00000031 acceptée	f	2026-04-13 20:21:23.291572+00
abf3c421-31f8-489c-8fa3-a499d5ebb015	80b3ae99-edfc-4220-a471-03c5366fb10d	81b6516c-629b-4d80-82d5-24a7801ae726	acceptee	Commande C00000030 acceptée	f	2026-04-13 20:21:37.58144+00
91f012c7-3c25-4915-87fa-ad0489155642	80b3ae99-edfc-4220-a471-03c5366fb10d	18a1fd87-3e0b-477f-a337-39709652df94	en_preparation	Commande C00000031 en préparation	f	2026-04-13 20:21:49.406644+00
c83167c0-bf2a-4367-8d6c-7d98413e31c9	80b3ae99-edfc-4220-a471-03c5366fb10d	18a1fd87-3e0b-477f-a337-39709652df94	en_route	Commande C00000031 en cours de livraison	f	2026-04-13 20:22:47.308153+00
9dff1a4a-1023-4e76-9614-a00386601e0c	80b3ae99-edfc-4220-a471-03c5366fb10d	6e7ffbab-0205-4987-b782-0f9dfae7d304	en_route	Commande C00000028 en cours de livraison	f	2026-04-13 20:24:15.65648+00
ab7870a7-5663-4e17-84ea-b4cf6cabb423	80b3ae99-edfc-4220-a471-03c5366fb10d	6e7ffbab-0205-4987-b782-0f9dfae7d304	livree	Commande C00000028 livrée	f	2026-04-13 20:24:24.901595+00
4113e472-d5c0-406c-8eb0-edfecafa9ee3	80b3ae99-edfc-4220-a471-03c5366fb10d	7646e2c0-c917-471f-98a8-29c2fc69479b	acceptee	Commande C00000033 acceptée	f	2026-06-15 15:50:25.638123+00
c708c523-4407-4d39-b198-452a9373c617	80b3ae99-edfc-4220-a471-03c5366fb10d	7646e2c0-c917-471f-98a8-29c2fc69479b	en_preparation	Commande C00000033 en préparation	f	2026-06-15 15:50:26.18508+00
3432a817-5f5f-465e-8775-a58078671e76	80b3ae99-edfc-4220-a471-03c5366fb10d	7646e2c0-c917-471f-98a8-29c2fc69479b	commande_chargee	Commande C00000033 chargée dans le camion	f	2026-06-15 15:50:28.189166+00
9ad91ff1-b86b-4665-8b8e-d8ef4f858cc6	80b3ae99-edfc-4220-a471-03c5366fb10d	7646e2c0-c917-471f-98a8-29c2fc69479b	en_route	Commande C00000033 en cours de livraison	f	2026-06-15 15:50:28.314129+00
c1c157e8-1c9b-4789-9cb6-4949a5fac72e	80b3ae99-edfc-4220-a471-03c5366fb10d	3f8b751f-b7e4-4caf-a7f1-66a3cc2f9f5e	acceptee	Commande C00000037 acceptée	f	2026-06-15 15:50:34.424437+00
c88105e5-7ba4-433b-be0a-d520b806a5b6	80b3ae99-edfc-4220-a471-03c5366fb10d	bdb4d02b-fdb8-481a-949a-1793843e552b	acceptee	Commande C00000038 acceptée	f	2026-06-15 15:50:36.431061+00
995c1756-5b5c-45a7-b780-4770c8c06eee	80b3ae99-edfc-4220-a471-03c5366fb10d	712e33d3-a45d-4ec6-82e1-488c453c04af	refusee	Commande C00000039 refusee : Quantité erronée, merci de corriger la ligne 1	f	2026-06-15 15:50:37.807666+00
522de9c8-84a2-44ff-abea-e56f4309d241	80b3ae99-edfc-4220-a471-03c5366fb10d	712e33d3-a45d-4ec6-82e1-488c453c04af	acceptee	Commande C00000039 acceptée	f	2026-06-15 15:50:37.946248+00
4be1e786-9b2a-4c65-9f79-f7e06ab4e3e3	80b3ae99-edfc-4220-a471-03c5366fb10d	634eadc7-857c-4ff9-8163-5b54a9eb0dda	acceptee	Commande C00000042 acceptée	f	2026-06-15 15:51:37.156763+00
22c3fc23-3a20-459c-93cb-0404f62124b4	80b3ae99-edfc-4220-a471-03c5366fb10d	634eadc7-857c-4ff9-8163-5b54a9eb0dda	en_preparation	Commande C00000042 en préparation	f	2026-06-15 15:51:38.11798+00
22046682-100e-4abd-b9ee-9ebea8978af8	80b3ae99-edfc-4220-a471-03c5366fb10d	b457ab88-16a4-423c-a37c-7c9373b01e00	acceptee	Commande C00000043 acceptée	f	2026-06-15 16:03:55.270556+00
ceb8e628-1c98-4262-a9cc-019a3717ba86	80b3ae99-edfc-4220-a471-03c5366fb10d	b457ab88-16a4-423c-a37c-7c9373b01e00	en_preparation	Commande C00000043 en préparation	f	2026-06-15 16:03:55.805185+00
5a2566f1-4809-417b-92bd-d1930fffa43c	80b3ae99-edfc-4220-a471-03c5366fb10d	b457ab88-16a4-423c-a37c-7c9373b01e00	commande_chargee	Commande C00000043 chargée dans le camion	f	2026-06-15 16:03:58.294891+00
aae52ba2-8b1d-4554-90fc-5d856d4cc610	80b3ae99-edfc-4220-a471-03c5366fb10d	b457ab88-16a4-423c-a37c-7c9373b01e00	en_route	Commande C00000043 en cours de livraison	f	2026-06-15 16:03:58.42485+00
7abe2bea-e756-4cf4-af46-9a41b995affb	80b3ae99-edfc-4220-a471-03c5366fb10d	53b0ca21-ecda-4875-8b88-45e6a4426f74	acceptee	Commande C00000047 acceptée	f	2026-06-15 16:04:07.52919+00
10b3ef37-cc77-43b2-9fe7-0880fa0704b5	80b3ae99-edfc-4220-a471-03c5366fb10d	7e3dbefd-9e34-4af7-8137-bd435e68555e	acceptee	Commande C00000048 acceptée	f	2026-06-15 16:04:10.171752+00
d650cefd-0916-41d1-9199-28896313ce26	80b3ae99-edfc-4220-a471-03c5366fb10d	afd7ad6c-776b-4c2c-9c6a-ce0134c65366	refusee	Commande C00000049 refusee : Quantité erronée, merci de corriger la ligne 1	f	2026-06-15 16:04:12.290061+00
dc36b932-da97-4c70-adfa-9b0c5e1c14fe	80b3ae99-edfc-4220-a471-03c5366fb10d	afd7ad6c-776b-4c2c-9c6a-ce0134c65366	acceptee	Commande C00000049 acceptée	f	2026-06-15 16:04:12.483802+00
c571dff9-ef03-4a10-a690-fe552e994fc4	80b3ae99-edfc-4220-a471-03c5366fb10d	a90de1fe-e8f3-4c96-8107-69eba971d1a8	acceptee	Commande C00000052 acceptée	f	2026-06-15 16:04:51.928457+00
8c63ff05-7979-4d24-b9f2-719348c7b638	80b3ae99-edfc-4220-a471-03c5366fb10d	a90de1fe-e8f3-4c96-8107-69eba971d1a8	en_preparation	Commande C00000052 en préparation	f	2026-06-15 16:04:53.17709+00
7b854c98-25f6-42a1-82dd-67fd6fee9d04	80b3ae99-edfc-4220-a471-03c5366fb10d	70932ee6-bdba-4e93-b487-e0e51c7452f9	acceptee	Commande C00000053 acceptée	f	2026-06-15 16:14:02.962329+00
f25ca17a-1aed-463c-8480-f6af7dd676c6	80b3ae99-edfc-4220-a471-03c5366fb10d	70932ee6-bdba-4e93-b487-e0e51c7452f9	en_preparation	Commande C00000053 en préparation	f	2026-06-15 16:15:35.053692+00
c353e36b-4e93-4298-9876-74dc047e1b8c	80b3ae99-edfc-4220-a471-03c5366fb10d	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	acceptee	Commande C00000054 acceptée	f	2026-06-15 16:43:18.804167+00
0fa09684-1373-4843-86e0-0e1db644d539	80b3ae99-edfc-4220-a471-03c5366fb10d	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	en_preparation	Commande C00000054 en préparation	f	2026-06-15 16:43:19.264389+00
97e3a30c-5fb9-4e8f-a9ed-f625630d95ed	80b3ae99-edfc-4220-a471-03c5366fb10d	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	commande_chargee	Commande C00000054 chargée dans le camion	f	2026-06-15 16:43:21.169979+00
531a9dd8-e392-4b18-9a85-14fad57e236c	80b3ae99-edfc-4220-a471-03c5366fb10d	c7c6368e-e59a-49c9-b59d-1c42c7f6d935	en_route	Commande C00000054 en cours de livraison	f	2026-06-15 16:43:21.28877+00
87743d0b-139f-4af1-84ca-90486e81bfa2	80b3ae99-edfc-4220-a471-03c5366fb10d	9d504663-a4f6-4855-bdec-407cfabc199a	acceptee	Commande C00000058 acceptée	f	2026-06-15 16:43:28.103118+00
12d22504-9f76-4da6-9328-326dd951ec74	80b3ae99-edfc-4220-a471-03c5366fb10d	54d4a168-cd3c-4ad7-8531-def1a75875e3	acceptee	Commande C00000059 acceptée	f	2026-06-15 16:43:29.932483+00
fa4c87dd-7226-475a-98dc-21a76286341d	80b3ae99-edfc-4220-a471-03c5366fb10d	a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd	refusee	Commande C00000060 refusee : Quantité erronée, merci de corriger la ligne 1	f	2026-06-15 16:43:31.231924+00
54ba9cc1-141b-49d3-b6bf-dea24c89df42	80b3ae99-edfc-4220-a471-03c5366fb10d	a849bccb-fcb6-4b8c-82ef-0e46ca89c5fd	acceptee	Commande C00000060 acceptée	f	2026-06-15 16:43:31.358954+00
ffefba03-ffff-4cf0-9b89-063051b03548	80b3ae99-edfc-4220-a471-03c5366fb10d	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	acceptee	Commande C00000063 acceptée	f	2026-06-15 16:53:28.532061+00
7e236c88-e912-42d5-9e16-f8bb8d824934	80b3ae99-edfc-4220-a471-03c5366fb10d	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	en_preparation	Commande C00000063 en préparation	f	2026-06-15 16:53:29.041054+00
ac850c83-0068-4ce8-ab28-a90318d63d88	6d4d8a0c-d618-4646-867d-4b833a795014	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	commande_controlee	Commande C00000063 contrôlée — 3 colis, étiquettes QR à imprimer/coller	f	2026-06-15 16:53:29.779869+00
a0ae1be9-8cec-4355-9712-3730c8a106f5	80b3ae99-edfc-4220-a471-03c5366fb10d	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	commande_chargee	Commande C00000063 chargée dans le camion	f	2026-06-15 16:53:31.238597+00
b7c3065a-a8d7-4d29-8975-b9209d698def	80b3ae99-edfc-4220-a471-03c5366fb10d	ad4f35e7-6d9f-4d78-9a68-a26a75a25e0a	en_route	Commande C00000063 en cours de livraison	f	2026-06-15 16:53:31.37842+00
524be826-ff8c-42e8-88d2-d16833c253cd	80b3ae99-edfc-4220-a471-03c5366fb10d	1c82273c-17f9-46c1-984b-ba0d11ce9022	acceptee	Commande C00000067 acceptée	f	2026-06-15 16:53:42.006805+00
7975c04b-0654-4109-a54d-739b21961334	80b3ae99-edfc-4220-a471-03c5366fb10d	e19fd8f0-1dc2-4dba-ab94-bd32bb9fc2c5	acceptee	Commande C00000068 acceptée	f	2026-06-15 16:53:43.998199+00
8f103330-b15a-4b25-8cf1-2f4f3e0d0738	80b3ae99-edfc-4220-a471-03c5366fb10d	5b7c805d-1652-4f86-997e-88a6cedb2195	refusee	Commande C00000069 refusee : Quantité erronée, merci de corriger la ligne 1	f	2026-06-15 16:53:45.417578+00
7f985ec7-8258-4fa2-9d46-4c290438b899	80b3ae99-edfc-4220-a471-03c5366fb10d	5b7c805d-1652-4f86-997e-88a6cedb2195	acceptee	Commande C00000069 acceptée	f	2026-06-15 16:53:45.549405+00
980bdbf0-7031-40b4-a84a-3b839b3a8f9e	80b3ae99-edfc-4220-a471-03c5366fb10d	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	acceptee	Commande C00000072 acceptée	f	2026-06-16 21:30:47.633935+00
b74d8627-8623-4550-9e5c-b2b6f5488ea0	80b3ae99-edfc-4220-a471-03c5366fb10d	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	en_preparation	Commande C00000072 en préparation	f	2026-06-16 21:30:48.241983+00
4c2ef60e-8a00-4b90-ab5c-d2925e028a74	6d4d8a0c-d618-4646-867d-4b833a795014	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	commande_controlee	Commande C00000072 contrôlée — 3 colis, étiquettes QR à imprimer/coller	f	2026-06-16 21:30:49.253975+00
c6f3bbaf-9496-4180-a828-d07579d7a356	80b3ae99-edfc-4220-a471-03c5366fb10d	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	en_route	Commande C00000072 en cours de livraison	f	2026-06-16 21:30:51.115836+00
c12a0c38-1ce4-44e8-b69c-c33d58327cb3	80b3ae99-edfc-4220-a471-03c5366fb10d	0753f63f-0ee0-4048-8dcb-9622d2bcf2b3	commande_en_livraison	Commande C00000072 chargée — en cours de livraison	f	2026-06-16 21:30:51.11816+00
af759f77-2884-49ca-8b73-3a6d4decbdb5	80b3ae99-edfc-4220-a471-03c5366fb10d	92980492-7923-4866-89ef-216fcebc8722	acceptee	Commande C00000076 acceptée	f	2026-06-16 21:31:07.942864+00
06252db6-be9b-4020-818f-31ced68b7bb1	80b3ae99-edfc-4220-a471-03c5366fb10d	457419d7-14e1-4dec-844e-2dbeea4821b6	acceptee	Commande C00000077 acceptée	f	2026-06-16 21:31:10.783488+00
44cecac0-8435-47b7-b36d-0c32f26837a4	80b3ae99-edfc-4220-a471-03c5366fb10d	a19333cc-805c-43e4-be89-f1aadcc380c5	refusee	Commande C00000078 refusee : Quantité erronée, merci de corriger la ligne 1	f	2026-06-16 21:31:12.882307+00
83358248-53e0-4910-99f0-707517bafc1f	80b3ae99-edfc-4220-a471-03c5366fb10d	a19333cc-805c-43e4-be89-f1aadcc380c5	acceptee	Commande C00000078 acceptée	f	2026-06-16 21:31:13.069677+00
678344eb-bc42-4165-bff4-c2fb6a9d0d6a	80b3ae99-edfc-4220-a471-03c5366fb10d	a90de1fe-e8f3-4c96-8107-69eba971d1a8	en_route	Commande C00000052 en cours de livraison	f	2026-06-16 21:32:13.572393+00
140ceffb-deb0-49ff-acb5-7bb090a18fee	80b3ae99-edfc-4220-a471-03c5366fb10d	a90de1fe-e8f3-4c96-8107-69eba971d1a8	commande_en_livraison	Commande C00000052 chargée — en cours de livraison	f	2026-06-16 21:32:13.575466+00
\.


--
-- Data for Name: pads_tir; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.pads_tir (id, code, nom, actif, created_at, updated_at, created_by) FROM stdin;
9b9f4153-1b16-4704-975c-8090f9e6e301	PAD-01	Pad de tir 1	t	2026-06-15 15:48:45.610871+00	2026-06-15 15:48:45.610871+00	\N
391020b3-c3f0-43b6-814f-f1165e33b8fb	PAD-02	Pad de tir 2	t	2026-06-15 15:48:45.610871+00	2026-06-15 15:48:45.610871+00	\N
36c04a24-b7a0-4364-b0fe-1add06993c7d	PAD-03	Pad de tir 3	t	2026-06-15 15:48:45.610871+00	2026-06-15 15:48:45.610871+00	\N
ad8f839b-fb6c-48ff-a2cb-f1e1ee8e9d8a	PAD-04	Pad de tir 4	t	2026-06-15 15:48:45.610871+00	2026-06-15 15:48:45.610871+00	\N
5a08c991-0c82-47c4-ab81-a45cc7d59f72	PAD-05	Pad de tir 5	t	2026-06-15 15:48:45.610871+00	2026-06-15 15:48:45.610871+00	\N
209192b7-ff15-454a-94f5-59ad34127535	PAD-06	Pad de tir 6	t	2026-06-15 15:48:45.610871+00	2026-06-15 15:48:45.610871+00	\N
\.


--
-- Data for Name: reclamations; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.reclamations (id, pharmacien_id, commande_id, motif, description, statut, resolution, created_at, updated_at, created_by) FROM stdin;
\.


--
-- Data for Name: scans_colis; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.scans_colis (id, colis_id, type_scan, user_id, pad_tir_id, created_at, updated_at, created_by) FROM stdin;
364a24bb-5a68-43d0-97a0-c9aab8580bfd	36b6616e-a0f9-4224-89b2-f744dcca9174	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 15:50:27.441693+00	2026-06-15 15:50:27.441693+00	\N
4b097f81-b2eb-4402-8a2d-b888d09799c3	e934bb2d-0bc6-4d1f-a884-7f8649193733	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 15:50:27.523369+00	2026-06-15 15:50:27.523369+00	\N
e5bff6ab-489a-438e-95b8-607483df4088	3d1422e6-0ffc-4370-9678-4ee429565578	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 15:50:27.555517+00	2026-06-15 15:50:27.555517+00	\N
8df2a5e4-e5de-490b-86b2-602eec33a2df	36b6616e-a0f9-4224-89b2-f744dcca9174	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 15:50:28.054764+00	2026-06-15 15:50:28.054764+00	\N
442bd1d7-16a9-44b9-868b-6c1a1abc03f4	e934bb2d-0bc6-4d1f-a884-7f8649193733	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 15:50:28.116399+00	2026-06-15 15:50:28.116399+00	\N
48822627-a4cc-4c7f-b583-60691a5f1b1b	3d1422e6-0ffc-4370-9678-4ee429565578	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 15:50:28.160721+00	2026-06-15 15:50:28.160721+00	\N
ede6269c-b142-4e9f-b03f-5b124a2d844a	36b6616e-a0f9-4224-89b2-f744dcca9174	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 15:50:28.336848+00	2026-06-15 15:50:28.336848+00	\N
36f28599-44ee-4578-81a7-7f804f6985b5	e934bb2d-0bc6-4d1f-a884-7f8649193733	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 15:50:28.373533+00	2026-06-15 15:50:28.373533+00	\N
56d01f24-7f96-4876-888d-ded1675db5e2	3d1422e6-0ffc-4370-9678-4ee429565578	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 15:50:28.404734+00	2026-06-15 15:50:28.404734+00	\N
170a62fd-fe37-448d-8922-da12b6f67eed	feb38818-c5b5-4275-8122-482af5cabff9	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 15:51:57.90683+00	2026-06-15 15:51:57.90683+00	\N
366ee6d4-803d-447f-a910-e5d2f65da8d0	feb38818-c5b5-4275-8122-482af5cabff9	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 16:03:31.551987+00	2026-06-15 16:03:31.551987+00	\N
510c7946-9904-4a1e-94bc-642011a7961f	77f65be3-db67-4a40-8aa7-eca7c8917770	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 16:03:31.551987+00	2026-06-15 16:03:31.551987+00	\N
07e1194a-87d0-4bfb-9267-3dd36f775ff9	e8524629-231b-47a9-924c-90c318a566c3	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 16:03:31.551987+00	2026-06-15 16:03:31.551987+00	\N
28b50659-e01c-4771-b51b-0c13d3381358	9865055c-ae07-4449-9fa9-393ae8e05984	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:03:57.434243+00	2026-06-15 16:03:57.434243+00	\N
90512f54-dcfc-4f6e-8109-8f6e1a5a7d22	321c323c-856f-4ffe-a108-6d3dffeffc4d	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:03:57.512846+00	2026-06-15 16:03:57.512846+00	\N
07f28dca-4c58-40de-8b72-ba58801bce60	1427f0c3-ba2d-4ef2-a865-79b32a844edf	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:03:57.554686+00	2026-06-15 16:03:57.554686+00	\N
9031aee7-2e1b-485f-8804-e535b8eb0f32	9865055c-ae07-4449-9fa9-393ae8e05984	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:03:58.151013+00	2026-06-15 16:03:58.151013+00	\N
37ce594a-0acb-45d5-b0f9-63ab742fa222	321c323c-856f-4ffe-a108-6d3dffeffc4d	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:03:58.224351+00	2026-06-15 16:03:58.224351+00	\N
cfd51e9a-c545-4eb7-912a-a871fbc30883	1427f0c3-ba2d-4ef2-a865-79b32a844edf	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:03:58.26844+00	2026-06-15 16:03:58.26844+00	\N
77933e11-a42c-4424-9047-a7e0aa827c9b	9865055c-ae07-4449-9fa9-393ae8e05984	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:03:58.45238+00	2026-06-15 16:03:58.45238+00	\N
bdbd593b-5e20-4b27-9546-8ec56088c945	321c323c-856f-4ffe-a108-6d3dffeffc4d	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:03:58.495277+00	2026-06-15 16:03:58.495277+00	\N
31807036-40b5-4f15-a20b-f51167eef59a	1427f0c3-ba2d-4ef2-a865-79b32a844edf	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:03:58.5357+00	2026-06-15 16:03:58.5357+00	\N
8f44b835-def6-4dbe-a86d-e7b23d8a3df7	2de3edd1-5302-4617-82c9-244ddb424b2e	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 16:26:50.871261+00	2026-06-15 16:26:50.871261+00	\N
6cd0a172-5eb6-4b5a-8f43-2c63ac55d245	4661cc5f-1c47-4c92-9bb3-9c8b8c2fd8db	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 16:26:50.871261+00	2026-06-15 16:26:50.871261+00	\N
b8104947-7867-4ab6-854b-8e6616837562	867bbd1b-110a-470e-8f20-b02bb47529d1	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 16:26:50.871261+00	2026-06-15 16:26:50.871261+00	\N
58ba8474-4625-41c9-bdf3-099e9be1fe66	4a0a17aa-fd5a-4a1c-bca8-0788e764aed6	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	9b9f4153-1b16-4704-975c-8090f9e6e301	2026-06-15 16:26:50.871261+00	2026-06-15 16:26:50.871261+00	\N
0ba86321-7610-4df3-9896-dc60b676ce07	d0dc8e6f-1b06-4d71-8dac-5d5abae4d120	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:43:20.45776+00	2026-06-15 16:43:20.45776+00	\N
4335f790-c968-4559-8856-beefd0e423ba	d6fd0be7-837c-43b0-9430-27781bf63503	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:43:20.539115+00	2026-06-15 16:43:20.539115+00	\N
9f5f720f-99d1-4410-97d1-cc72fce46f80	1e0ede6a-53e5-485f-8fca-ca781bdcbda6	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:43:20.571677+00	2026-06-15 16:43:20.571677+00	\N
9784c2eb-6f42-4206-8992-50e27e66821e	d0dc8e6f-1b06-4d71-8dac-5d5abae4d120	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:43:21.051832+00	2026-06-15 16:43:21.051832+00	\N
8faa2893-9430-46a9-a789-6eeaad0398de	d6fd0be7-837c-43b0-9430-27781bf63503	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:43:21.112805+00	2026-06-15 16:43:21.112805+00	\N
b074dc1e-c132-40f2-9070-0d66659935ee	1e0ede6a-53e5-485f-8fca-ca781bdcbda6	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:43:21.145062+00	2026-06-15 16:43:21.145062+00	\N
d1f44a9a-726f-40f2-8156-e51c050b5518	d0dc8e6f-1b06-4d71-8dac-5d5abae4d120	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:43:21.308159+00	2026-06-15 16:43:21.308159+00	\N
0e1d383d-92f9-4cb5-907e-c1053bba7d1c	d6fd0be7-837c-43b0-9430-27781bf63503	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:43:21.353342+00	2026-06-15 16:43:21.353342+00	\N
19b71c24-d246-42a9-9730-d2b80db4500d	1e0ede6a-53e5-485f-8fca-ca781bdcbda6	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:43:21.388009+00	2026-06-15 16:43:21.388009+00	\N
0dde3709-331d-4469-89e2-46f952ed1dd9	a7abc6ba-6a76-44b3-a913-a0f834112305	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:53:30.394262+00	2026-06-15 16:53:30.394262+00	\N
653477f1-ec95-4d45-94a0-0676d1a1f8a5	f5d79986-28a7-407b-aed0-1a1748e7ce83	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:53:30.492521+00	2026-06-15 16:53:30.492521+00	\N
ee8ba5a0-ba29-4bd2-84c1-6e63e3daa158	6ccd2d70-222e-429b-ae44-12fdd922daaf	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-15 16:53:30.529065+00	2026-06-15 16:53:30.529065+00	\N
d2cc8636-6dd5-4005-a039-fcf7ebd2cd6b	a7abc6ba-6a76-44b3-a913-a0f834112305	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:53:31.073454+00	2026-06-15 16:53:31.073454+00	\N
7c140737-e7ce-4b64-bebf-c92c7073c3b6	f5d79986-28a7-407b-aed0-1a1748e7ce83	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:53:31.155409+00	2026-06-15 16:53:31.155409+00	\N
e8645937-7974-40db-9cf7-29a184a540cb	6ccd2d70-222e-429b-ae44-12fdd922daaf	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:53:31.210023+00	2026-06-15 16:53:31.210023+00	\N
d0382182-bf97-4e03-a0f7-0ce2bd1478a0	a7abc6ba-6a76-44b3-a913-a0f834112305	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:53:31.402926+00	2026-06-15 16:53:31.402926+00	\N
95880cd6-a3da-4f49-b8a6-18a4c9c9fd17	f5d79986-28a7-407b-aed0-1a1748e7ce83	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:53:31.449946+00	2026-06-15 16:53:31.449946+00	\N
91546ad0-5bd9-47e3-99f4-91c6ad878eec	6ccd2d70-222e-429b-ae44-12fdd922daaf	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-15 16:53:31.491684+00	2026-06-15 16:53:31.491684+00	\N
4b7c80b1-1de8-4407-9d26-6526dcef578f	058f7ef6-861a-4131-ba7e-bae8c323bc91	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-16 21:30:50.062605+00	2026-06-16 21:30:50.062605+00	\N
9457b165-8440-43a3-baac-539547efd661	ee6013e2-ec6b-47ff-bc1b-1aa46d001038	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-16 21:30:50.187503+00	2026-06-16 21:30:50.187503+00	\N
a05a723a-b127-4452-bf07-fcfe5991d56e	585ea26a-fbe9-4106-8487-79ce19db4c79	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	391020b3-c3f0-43b6-814f-f1165e33b8fb	2026-06-16 21:30:50.243731+00	2026-06-16 21:30:50.243731+00	\N
216015e8-c875-471d-ac5d-63b9a11ad1d0	058f7ef6-861a-4131-ba7e-bae8c323bc91	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-16 21:30:50.949716+00	2026-06-16 21:30:50.949716+00	\N
ad7c121e-4d9d-4016-ae19-2c7f9949d830	ee6013e2-ec6b-47ff-bc1b-1aa46d001038	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-16 21:30:51.031995+00	2026-06-16 21:30:51.031995+00	\N
2d24053c-9e8a-4a33-a141-c5d021f57f0e	585ea26a-fbe9-4106-8487-79ce19db4c79	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-16 21:30:51.073653+00	2026-06-16 21:30:51.073653+00	\N
0f1b60dc-c430-46a1-bf5f-62d495c6cb89	058f7ef6-861a-4131-ba7e-bae8c323bc91	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-16 21:30:51.279256+00	2026-06-16 21:30:51.279256+00	\N
da92f0ac-b05e-4fe7-b320-e8e09dabcbeb	ee6013e2-ec6b-47ff-bc1b-1aa46d001038	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-16 21:30:51.331775+00	2026-06-16 21:30:51.331775+00	\N
47c500e0-b897-4e55-a6d9-6f1432408d21	585ea26a-fbe9-4106-8487-79ce19db4c79	livraison	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-16 21:30:51.373024+00	2026-06-16 21:30:51.373024+00	\N
59c2d5e9-0343-4fe4-8ccb-c5c7ae744d5d	4566b695-b2c8-4009-b4a9-4fe8f9b2eb63	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	\N	2026-06-16 21:32:12.299508+00	2026-06-16 21:32:12.299508+00	\N
685f9f71-b593-44bf-8982-80fbb1f4976e	72aef3f2-1486-4cd7-915d-423bde41ef8c	depot_pad	3fa3d47d-99e0-4ac6-94c1-565354f320eb	\N	2026-06-16 21:32:12.299508+00	2026-06-16 21:32:12.299508+00	\N
d107ce54-6e0b-463e-b483-bea4ce78a90a	4566b695-b2c8-4009-b4a9-4fe8f9b2eb63	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-16 21:32:13.288592+00	2026-06-16 21:32:13.288592+00	\N
9e863740-0ab6-4fe3-ac7f-c72bc6850e20	72aef3f2-1486-4cd7-915d-423bde41ef8c	chargement	5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	\N	2026-06-16 21:32:13.53334+00	2026-06-16 21:32:13.53334+00	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.users (id, email, password_hash, role, nom, adresse, secteur, is_active, created_at, updated_at, created_by, telephone, google_id, oauth_provider, is_email_verified) FROM stdin;
3fa3d47d-99e0-4ac6-94c1-565354f320eb	magasinier@dimed.dz	$2b$12$IDMgDZxZ5PyTlRpLnOrqAuNN8FD0cvk83jksF5FGuvgxlkkfRofDy	magasinier	Magasinier Demo	\N	\N	t	2026-06-15 15:49:18.853118+00	2026-06-15 15:49:18.853118+00	\N	\N	\N	\N	t
9f334b50-59fc-4c16-8635-e9f29c46cdf7	admin@dimed.dz	$2b$12$3p4nwG4e651Mo4DemyiPouvvGZShNHa0hOVbI10EAUqHi43vm4yNS	admin	Administrator	\N	\N	t	2026-03-26 10:08:48.259648+00	2026-03-26 10:08:48.259648+00	\N	\N	\N	local	t
3fce8dc2-16e0-4ce6-b41c-c0657216eb62	preparateur@dimed.dz	$2b$12$3p4nwG4e651Mo4DemyiPouvvGZShNHa0hOVbI10EAUqHi43vm4yNS	preparateur	Preparateur			t	2026-03-26 10:56:38.10231+00	2026-03-30 18:02:43.167792+00	\N	\N	\N	local	t
aec28fb7-8dfb-4781-b2b0-932d1a9e891d	controleur@dimed.dz	$2b$12$3p4nwG4e651Mo4DemyiPouvvGZShNHa0hOVbI10EAUqHi43vm4yNS	controleur	Controleur			t	2026-03-26 10:56:38.10231+00	2026-04-01 13:53:16.766284+00	\N	\N	\N	local	t
ef6fb6ab-1b1a-41ea-bf5a-658502d156f7	livreur@dimed.dz	$2b$12$3p4nwG4e651Mo4DemyiPouvvGZShNHa0hOVbI10EAUqHi43vm4yNS	livreur	Livreur			t	2026-03-26 10:56:38.10231+00	2026-04-01 13:59:36.291782+00	\N	\N	\N	local	t
64ee5bf2-f92a-48d4-87f4-e6aff7d163ec	benamara.hicham.2003@gmail.com	$2b$12$3p4nwG4e651Mo4DemyiPouvvGZShNHa0hOVbI10EAUqHi43vm4yNS	admin	Hicham Benamara	\N	\N	t	2026-04-07 11:48:44.494156+00	2026-04-07 11:48:44.494156+00	\N	\N	\N	local	t
80b3ae99-edfc-4220-a471-03c5366fb10d	pharmacien@dimed.dz	$2b$12$3p4nwG4e651Mo4DemyiPouvvGZShNHa0hOVbI10EAUqHi43vm4yNS	pharmacien	Pharmacie 1	Rue des Frères Bouadou, Bir Mourad Rais, Alger	Alger Centre	t	2026-03-26 10:56:38.10231+00	2026-04-01 12:55:59.354216+00	\N	+213 21 54 78 90	\N	local	t
5c6eb7bc-b7e6-48b9-a2be-749e3b1c2dcb	operatrice@dimed.dz	$2b$12$3p4nwG4e651Mo4DemyiPouvvGZShNHa0hOVbI10EAUqHi43vm4yNS	operatrice	Fatima Operatrice	\N	\N	t	2026-03-26 10:56:38.10231+00	2026-03-26 10:56:38.10231+00	\N	+213 21 54 79 01	\N	local	t
6d4d8a0c-d618-4646-867d-4b833a795014	facturier@dimed.dz	$2b$12$lqv9.1u2qZl/B.el2rNXueLXPElbem5r9.s/UJ.8JnhWRmBX3BV46	facturier	Facturier Demo	\N	\N	t	2026-06-15 16:52:39.014428+00	2026-06-15 16:52:39.014428+00	\N	\N	\N	\N	t
bd50ef77-a84a-4aaf-9cbe-4cfeb883046f	livreur1@dimed.dz	$2b$12$KwGueGaU.7e6jQvNM4kDpOQ3v57fILqiHZDUuKFakj2Ps25450LY6	livreur	Livreur 1	\N	\N	t	2026-06-15 16:52:39.014428+00	2026-06-15 16:52:39.014428+00	\N	\N	\N	\N	t
7d837426-095a-4af0-a2e4-7f83a7872bd6	livreur2@dimed.dz	$2b$12$VrumNs/4w7OSDY9KYpHpzOmcxNE9Krqtbgl2w6Lxnn8OskUQ.7cte	livreur	Livreur 2	\N	\N	t	2026-06-15 16:52:39.014428+00	2026-06-15 16:52:39.014428+00	\N	\N	\N	\N	t
acd6c8b9-f2a7-4901-a7d9-5f4e3805a44e	livreur3@dimed.dz	$2b$12$t8CLQ0ipIPMlltW3MtLdg.RSi/EfyrE84iRl1XSWGmBfv7aRNQSLG	livreur	Livreur 3	\N	\N	t	2026-06-15 16:52:39.014428+00	2026-06-15 16:52:39.014428+00	\N	\N	\N	\N	t
a93c5e03-80cd-462a-87dc-e0477d944ca8	livreur4@dimed.dz	$2b$12$Qa/I0d.5Oy7MI6sqAR91suklY1cgiEGih37p/wEAnS9asevdasIVy	livreur	Livreur 4	\N	\N	t	2026-06-15 16:52:39.014428+00	2026-06-15 16:52:39.014428+00	\N	\N	\N	\N	t
04a7282f-79fb-4fe7-9523-990906e768ce	livreur5@dimed.dz	$2b$12$nzrHwf/fhbDkB8JhhVjNvOAKtVOSxLgxpm7mSBbz2kLynqZ0Wg9Wy	livreur	Livreur 5	\N	\N	t	2026-06-15 16:52:39.014428+00	2026-06-15 16:52:39.014428+00	\N	\N	\N	\N	t
ed617636-c060-40c0-81a4-ef2a31ca4f74	livreur6@dimed.dz	$2b$12$zPCN/FbE7Qd1prsdbnGG1ewEzsA3QVo1zmjhEl3p.swmEQqyjbXgG	livreur	Livreur 6	\N	\N	t	2026-06-15 16:52:39.014428+00	2026-06-15 16:52:39.014428+00	\N	\N	\N	\N	t
4cc324b0-8cd9-4d3f-b58f-766c28b1cfdf	livreur7@dimed.dz	$2b$12$tZkjiKOcf2i6ssbfVj0t2.bwiFkmP/8dFtneYgwMTgWxSO5G7esLi	livreur	Livreur 7	\N	\N	t	2026-06-15 16:52:39.014428+00	2026-06-15 16:52:39.014428+00	\N	\N	\N	\N	t
c2f4b76f-21f4-4c4e-9c0f-a0a3f9b8d981	livreur8@dimed.dz	$2b$12$eSHCr0tv2GUKLj86q9Nee.ca8SxMeSVjGw1NB.i2i.aUuSsFuIg0W	livreur	Livreur 8	\N	\N	t	2026-06-15 16:52:39.014428+00	2026-06-15 16:52:39.014428+00	\N	\N	\N	\N	t
\.


--
-- Data for Name: vignettes; Type: TABLE DATA; Schema: public; Owner: dimed
--

COPY public.vignettes (id, commande_id, ligne_id, filename, extracted_exp, extracted_raw, uploaded_by, created_at, updated_at, created_by, extracted_lot, extracted_fab, extracted_ppa, extracted_designation) FROM stdin;
\.


--
-- Name: bl_seq; Type: SEQUENCE SET; Schema: public; Owner: dimed
--

SELECT pg_catalog.setval('public.bl_seq', 42, true);


--
-- Name: colis_seq; Type: SEQUENCE SET; Schema: public; Owner: dimed
--

SELECT pg_catalog.setval('public.colis_seq', 24, true);


--
-- Name: commande_seq; Type: SEQUENCE SET; Schema: public; Owner: dimed
--

SELECT pg_catalog.setval('public.commande_seq', 80, true);


--
-- Name: facture_seq; Type: SEQUENCE SET; Schema: public; Owner: dimed
--

SELECT pg_catalog.setval('public.facture_seq', 42, true);


--
-- Name: prelevement_seq; Type: SEQUENCE SET; Schema: public; Owner: dimed
--

SELECT pg_catalog.setval('public.prelevement_seq', 1, false);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: arrivages arrivages_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.arrivages
    ADD CONSTRAINT arrivages_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: bons_livraison bons_livraison_code_barre_key; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.bons_livraison
    ADD CONSTRAINT bons_livraison_code_barre_key UNIQUE (code_barre);


--
-- Name: bons_livraison bons_livraison_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.bons_livraison
    ADD CONSTRAINT bons_livraison_pkey PRIMARY KEY (id);


--
-- Name: caddies caddies_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.caddies
    ADD CONSTRAINT caddies_pkey PRIMARY KEY (id);


--
-- Name: caddies_pool caddies_pool_numero_key; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.caddies_pool
    ADD CONSTRAINT caddies_pool_numero_key UNIQUE (numero);


--
-- Name: caddies_pool caddies_pool_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.caddies_pool
    ADD CONSTRAINT caddies_pool_pkey PRIMARY KEY (id);


--
-- Name: camions camions_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.camions
    ADD CONSTRAINT camions_pkey PRIMARY KEY (id);


--
-- Name: camions camions_plaque_key; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.camions
    ADD CONSTRAINT camions_plaque_key UNIQUE (plaque);


--
-- Name: colis_lignes colis_lignes_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.colis_lignes
    ADD CONSTRAINT colis_lignes_pkey PRIMARY KEY (id);


--
-- Name: colis colis_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.colis
    ADD CONSTRAINT colis_pkey PRIMARY KEY (id);


--
-- Name: commandes commandes_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.commandes
    ADD CONSTRAINT commandes_pkey PRIMARY KEY (id);


--
-- Name: commandes commandes_reference_id_key; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.commandes
    ADD CONSTRAINT commandes_reference_id_key UNIQUE (reference_id);


--
-- Name: creances creances_facture_id_key; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.creances
    ADD CONSTRAINT creances_facture_id_key UNIQUE (facture_id);


--
-- Name: creances creances_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.creances
    ADD CONSTRAINT creances_pkey PRIMARY KEY (id);


--
-- Name: factures factures_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.factures
    ADD CONSTRAINT factures_pkey PRIMARY KEY (id);


--
-- Name: factures factures_reference_id_key; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.factures
    ADD CONSTRAINT factures_reference_id_key UNIQUE (reference_id);


--
-- Name: feuilles_route feuilles_route_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.feuilles_route
    ADD CONSTRAINT feuilles_route_pkey PRIMARY KEY (id);


--
-- Name: lignes_commande lignes_commande_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.lignes_commande
    ADD CONSTRAINT lignes_commande_pkey PRIMARY KEY (id);


--
-- Name: medicaments medicaments_code_article_key; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.medicaments
    ADD CONSTRAINT medicaments_code_article_key UNIQUE (code_article);


--
-- Name: medicaments medicaments_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.medicaments
    ADD CONSTRAINT medicaments_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: pads_tir pads_tir_code_key; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.pads_tir
    ADD CONSTRAINT pads_tir_code_key UNIQUE (code);


--
-- Name: pads_tir pads_tir_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.pads_tir
    ADD CONSTRAINT pads_tir_pkey PRIMARY KEY (id);


--
-- Name: reclamations reclamations_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.reclamations
    ADD CONSTRAINT reclamations_pkey PRIMARY KEY (id);


--
-- Name: scans_colis scans_colis_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.scans_colis
    ADD CONSTRAINT scans_colis_pkey PRIMARY KEY (id);


--
-- Name: colis uq_colis_commande_index; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.colis
    ADD CONSTRAINT uq_colis_commande_index UNIQUE (commande_id, index_colis);


--
-- Name: colis_lignes uq_colis_lignes_colis_ligne; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.colis_lignes
    ADD CONSTRAINT uq_colis_lignes_colis_ligne UNIQUE (colis_id, ligne_commande_id);


--
-- Name: colis uq_colis_numero; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.colis
    ADD CONSTRAINT uq_colis_numero UNIQUE (numero);


--
-- Name: feuilles_route uq_feuilles_route_camion_date; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.feuilles_route
    ADD CONSTRAINT uq_feuilles_route_camion_date UNIQUE (camion_id, date);


--
-- Name: users uq_users_google_id; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uq_users_google_id UNIQUE (google_id);


--
-- Name: vignettes uq_vignettes_ligne_id; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.vignettes
    ADD CONSTRAINT uq_vignettes_ligne_id UNIQUE (ligne_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vignettes vignettes_pkey; Type: CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.vignettes
    ADD CONSTRAINT vignettes_pkey PRIMARY KEY (id);


--
-- Name: idx_medicaments_designation_trgm; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX idx_medicaments_designation_trgm ON public.medicaments USING gin (designation public.gin_trgm_ops);


--
-- Name: ix_arrivages_date; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_arrivages_date ON public.arrivages USING btree (date_arrivage);


--
-- Name: ix_audit_log_entity_id; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_audit_log_entity_id ON public.audit_log USING btree (entity_id);


--
-- Name: ix_audit_log_entity_type; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_audit_log_entity_type ON public.audit_log USING btree (entity_type);


--
-- Name: ix_caddies_commande_id; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_caddies_commande_id ON public.caddies USING btree (commande_id);


--
-- Name: ix_caddies_numero; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_caddies_numero ON public.caddies USING btree (numero);


--
-- Name: ix_caddies_pool_current_commande_id; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_caddies_pool_current_commande_id ON public.caddies_pool USING btree (current_commande_id);


--
-- Name: ix_caddies_pool_is_available; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_caddies_pool_is_available ON public.caddies_pool USING btree (is_available);


--
-- Name: ix_colis_commande_id; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_colis_commande_id ON public.colis USING btree (commande_id);


--
-- Name: ix_colis_lignes_colis_id; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_colis_lignes_colis_id ON public.colis_lignes USING btree (colis_id);


--
-- Name: ix_colis_numero; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_colis_numero ON public.colis USING btree (numero);


--
-- Name: ix_commandes_preparateur_id; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_commandes_preparateur_id ON public.commandes USING btree (preparateur_id);


--
-- Name: ix_commandes_reference_id; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_commandes_reference_id ON public.commandes USING btree (reference_id);


--
-- Name: ix_medicaments_code_article; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_medicaments_code_article ON public.medicaments USING btree (code_article);


--
-- Name: ix_notifications_user_unread; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_notifications_user_unread ON public.notifications USING btree (user_id, read, created_at DESC);


--
-- Name: ix_scans_colis_colis_id; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_scans_colis_colis_id ON public.scans_colis USING btree (colis_id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_google_id; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_users_google_id ON public.users USING btree (google_id);


--
-- Name: ix_vignettes_commande_id; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_vignettes_commande_id ON public.vignettes USING btree (commande_id);


--
-- Name: ix_vignettes_ligne_id; Type: INDEX; Schema: public; Owner: dimed
--

CREATE INDEX ix_vignettes_ligne_id ON public.vignettes USING btree (ligne_id);


--
-- Name: arrivages arrivages_medicament_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.arrivages
    ADD CONSTRAINT arrivages_medicament_id_fkey FOREIGN KEY (medicament_id) REFERENCES public.medicaments(id);


--
-- Name: bons_livraison bons_livraison_commande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.bons_livraison
    ADD CONSTRAINT bons_livraison_commande_id_fkey FOREIGN KEY (commande_id) REFERENCES public.commandes(id);


--
-- Name: caddies caddies_commande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.caddies
    ADD CONSTRAINT caddies_commande_id_fkey FOREIGN KEY (commande_id) REFERENCES public.commandes(id) ON DELETE CASCADE;


--
-- Name: caddies_pool caddies_pool_current_commande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.caddies_pool
    ADD CONSTRAINT caddies_pool_current_commande_id_fkey FOREIGN KEY (current_commande_id) REFERENCES public.commandes(id) ON DELETE SET NULL;


--
-- Name: colis colis_commande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.colis
    ADD CONSTRAINT colis_commande_id_fkey FOREIGN KEY (commande_id) REFERENCES public.commandes(id);


--
-- Name: colis_lignes colis_lignes_colis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.colis_lignes
    ADD CONSTRAINT colis_lignes_colis_id_fkey FOREIGN KEY (colis_id) REFERENCES public.colis(id);


--
-- Name: colis_lignes colis_lignes_ligne_commande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.colis_lignes
    ADD CONSTRAINT colis_lignes_ligne_commande_id_fkey FOREIGN KEY (ligne_commande_id) REFERENCES public.lignes_commande(id);


--
-- Name: colis colis_pad_tir_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.colis
    ADD CONSTRAINT colis_pad_tir_id_fkey FOREIGN KEY (pad_tir_id) REFERENCES public.pads_tir(id);


--
-- Name: commandes commandes_operatrice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.commandes
    ADD CONSTRAINT commandes_operatrice_id_fkey FOREIGN KEY (operatrice_id) REFERENCES public.users(id);


--
-- Name: commandes commandes_pharmacien_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.commandes
    ADD CONSTRAINT commandes_pharmacien_id_fkey FOREIGN KEY (pharmacien_id) REFERENCES public.users(id);


--
-- Name: creances creances_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.creances
    ADD CONSTRAINT creances_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: creances creances_facture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.creances
    ADD CONSTRAINT creances_facture_id_fkey FOREIGN KEY (facture_id) REFERENCES public.factures(id) ON DELETE CASCADE;


--
-- Name: creances creances_pharmacien_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.creances
    ADD CONSTRAINT creances_pharmacien_id_fkey FOREIGN KEY (pharmacien_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: factures factures_commande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.factures
    ADD CONSTRAINT factures_commande_id_fkey FOREIGN KEY (commande_id) REFERENCES public.commandes(id);


--
-- Name: feuilles_route feuilles_route_livreur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.feuilles_route
    ADD CONSTRAINT feuilles_route_livreur_id_fkey FOREIGN KEY (livreur_id) REFERENCES public.users(id);


--
-- Name: commandes fk_commandes_camion_id; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.commandes
    ADD CONSTRAINT fk_commandes_camion_id FOREIGN KEY (camion_id) REFERENCES public.camions(id);


--
-- Name: commandes fk_commandes_feuille_route_id; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.commandes
    ADD CONSTRAINT fk_commandes_feuille_route_id FOREIGN KEY (feuille_route_id) REFERENCES public.feuilles_route(id);


--
-- Name: commandes fk_commandes_preparateur_id_users; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.commandes
    ADD CONSTRAINT fk_commandes_preparateur_id_users FOREIGN KEY (preparateur_id) REFERENCES public.users(id);


--
-- Name: feuilles_route fk_feuilles_route_camion_id; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.feuilles_route
    ADD CONSTRAINT fk_feuilles_route_camion_id FOREIGN KEY (camion_id) REFERENCES public.camions(id);


--
-- Name: lignes_commande lignes_commande_commande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.lignes_commande
    ADD CONSTRAINT lignes_commande_commande_id_fkey FOREIGN KEY (commande_id) REFERENCES public.commandes(id);


--
-- Name: lignes_commande lignes_commande_medicament_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.lignes_commande
    ADD CONSTRAINT lignes_commande_medicament_id_fkey FOREIGN KEY (medicament_id) REFERENCES public.medicaments(id);


--
-- Name: notifications notifications_commande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_commande_id_fkey FOREIGN KEY (commande_id) REFERENCES public.commandes(id);


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: reclamations reclamations_commande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.reclamations
    ADD CONSTRAINT reclamations_commande_id_fkey FOREIGN KEY (commande_id) REFERENCES public.commandes(id) ON DELETE CASCADE;


--
-- Name: reclamations reclamations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.reclamations
    ADD CONSTRAINT reclamations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: reclamations reclamations_pharmacien_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.reclamations
    ADD CONSTRAINT reclamations_pharmacien_id_fkey FOREIGN KEY (pharmacien_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: scans_colis scans_colis_colis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.scans_colis
    ADD CONSTRAINT scans_colis_colis_id_fkey FOREIGN KEY (colis_id) REFERENCES public.colis(id);


--
-- Name: scans_colis scans_colis_pad_tir_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.scans_colis
    ADD CONSTRAINT scans_colis_pad_tir_id_fkey FOREIGN KEY (pad_tir_id) REFERENCES public.pads_tir(id);


--
-- Name: scans_colis scans_colis_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.scans_colis
    ADD CONSTRAINT scans_colis_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: vignettes vignettes_commande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.vignettes
    ADD CONSTRAINT vignettes_commande_id_fkey FOREIGN KEY (commande_id) REFERENCES public.commandes(id) ON DELETE CASCADE;


--
-- Name: vignettes vignettes_ligne_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.vignettes
    ADD CONSTRAINT vignettes_ligne_id_fkey FOREIGN KEY (ligne_id) REFERENCES public.lignes_commande(id) ON DELETE SET NULL;


--
-- Name: vignettes vignettes_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dimed
--

ALTER TABLE ONLY public.vignettes
    ADD CONSTRAINT vignettes_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict e4jCiL8lHw6TtVH3re2HumdyL2w8ZSYTcpdGgmDkmIAONjfczZOUY6FbT4x6dX9

