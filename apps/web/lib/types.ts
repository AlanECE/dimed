export type UserRole =
	| "admin"
	| "pharmacien"
	| "operatrice"
	| "preparateur"
	| "controleur"
	| "livreur";

export type SignupRole = Exclude<UserRole, "admin">;

export type UserResponse = {
	id: string;
	email: string;
	nom: string;
	role: string;
	adresse: string | null;
	secteur: string | null;
	telephone: string | null;
	is_active: boolean;
	is_email_verified: boolean;
	oauth_provider: string | null;
};

export type UpdateProfileRequest = {
	nom?: string;
	adresse?: string;
	secteur?: string;
	telephone?: string;
};

export type SignupPayload = {
	nom: string;
	email: string;
	password: string;
	role: SignupRole;
	adresse?: string;
	secteur?: string;
	telephone?: string;
};

export type GoogleAuthPayload = {
	credential: string;
	role?: SignupRole;
	adresse?: string;
	secteur?: string;
	telephone?: string;
};

export type ChangePasswordRequest = {
	current_password: string;
	new_password: string;
};

export type MedicamentResponse = {
	id: string;
	code_article: string;
	designation: string;
	dci: string | null;
	dosage: string | null;
	forme: string | null;
	ppa: number;
	fabricant: string | null;
	stock_quantity: number;
	image_path: string | null;
	featured: boolean;
};

export type LigneResponse = {
	id: string;
	medicament_id: string;
	designation: string;
	qte_demandee: number;
	prix_unitaire: number;
	remise_pct: number;
	n_lot: string | null;
	fab: string | null;
	exp: string | null;
	ppa: string | null;
};

export type UpdateRemisesRequest = {
	lines: { ligne_id: string; remise_pct: number }[];
};

export type CaddiePoolResponse = {
	id: string;
	numero: string;
	is_available: boolean;
	current_commande_ref: string | null;
};

export type OrderResponse = {
	id: string;
	reference_id: string;
	statut: string;
	montant_total: number;
	pharmacien_id: string;
	operatrice_id: string | null;
	preparateur_id: string | null;
	preparateur_nom: string | null;
	commercial: string | null;
	created_at: string;
	date_validation: string | null;
	camion_id: string | null;
	camion_nom: string | null;
	pharmacien_nom: string | null;
	pharmacien_email: string | null;
	operatrice_comment: string | null;
	caddie_pool: CaddiePoolResponse | null;
};

export type OrderDetailResponse = OrderResponse & {
	lignes: LigneResponse[];
};

export type PaginatedResponse<T> = {
	total: number;
	limit: number;
	offset: number;
	items: T[];
};

export type CamionResponse = {
	id: string;
	nom: string;
	plaque: string;
	created_at: string;
};

export type NotificationResponse = {
	id: string;
	commande_id: string;
	type: string;
	message: string;
	read: boolean;
	created_at: string;
};

export type NotificationListResponse = {
	notifications: NotificationResponse[];
	unread_count: number;
};

export type FactureListItem = {
	id: string;
	reference_id: string;
	commande_id: string;
	commande_reference: string;
	pharmacien_nom: string;
	date_emission: string;
	montant_ht: number;
	montant_ttc: number;
};

export type BonLivraisonListItem = {
	id: string;
	code_barre: string;
	commande_id: string;
	commande_reference: string;
	date_emission: string;
};

export type ReclamationResponse = {
	id: string;
	pharmacien_nom: string;
	commande_id: string;
	commande_reference: string;
	motif: string;
	description: string;
	statut: string;
	resolution: string | null;
	created_at: string;
};

export type CreateReclamationRequest = {
	commande_id: string;
	motif: string;
	description: string;
};

export type ReportStats = {
	total_revenue: number;
	order_count: number;
	avg_order_value: number;
	delivery_rate: number;
	status_breakdown: Record<string, number>;
	top_products: { designation: string; total_qty: number; total_amount: number }[];
	previous_period: {
		total_revenue: number;
		order_count: number;
	};
	evolution: {
		revenue_pct: number | null;
		orders_pct: number | null;
	};
};

export type ArrivageResponse = {
	id: string;
	medicament_id: string;
	designation: string;
	quantite: number;
	n_lot: string | null;
	date_arrivage: string;
	date_peremption: string | null;
	fournisseur: string | null;
	created_at: string;
};

export type AuditLogEntry = {
	id: string;
	entity_type: string;
	entity_id: string;
	action: string;
	actor_id: string | null;
	actor_nom: string | null;
	timestamp: string;
	old_value: Record<string, unknown> | null;
	new_value: Record<string, unknown> | null;
};

export type CreanceResponse = {
	id: string;
	pharmacien_nom: string;
	facture_reference: string;
	montant_total: number;
	montant_paye: number;
	reste_a_payer: number;
	statut: string;
	echeance: string;
	created_at: string;
};

export type FeuilleDeRouteResponse = {
	id: string;
	camion_id: string;
	camion_nom: string;
	camion_plaque: string;
	date: string;
	ligne: string | null;
	compteurs: {
		colis_std: number;
		sachets_std: number;
		colis_frg: number;
		sachets_frg: number;
	};
	commandes: {
		id: string;
		reference_id: string;
		montant_total: number;
		pharmacien_id: string;
		statut: string;
	}[];
};

export type VignetteResponse = {
	id: string;
	filename: string;
	file_url: string;
	extracted_lot: string | null;
	extracted_fab: string | null;
	extracted_exp: string | null;
	extracted_ppa: string | null;
	extracted_designation: string | null;
};

export type LignePreparationResponse = {
	id: string;
	medicament_id: string;
	designation: string;
	qte_demandee: number;
	qte_prelevee: number | null;
	prix_unitaire: number;
	remise_pct: number;
	n_lot: string | null;
	fab: string | null;
	exp: string | null;
	ppa: string | null;
	medicament_ppa: string | null;
	verifie: boolean;
	vignette: VignetteResponse | null;
};

export type VignetteWarning =
	| "ppa_divergent"
	| "missing_lot"
	| "missing_fab"
	| "missing_exp"
	| "missing_ppa";

export type LigneOcrResponse = {
	ligne: LignePreparationResponse;
	vignette: VignetteResponse;
	warnings: VignetteWarning[];
};

export type PreparationDetailResponse = {
	lignes: LignePreparationResponse[];
	nb_colis: number | null;
	visa_preparateur: string | null;
	visa_controleur: string | null;
};

export type RouteSheetTodayCommande = {
	id: string;
	reference_id: string;
	montant_total: number;
	pharmacien_id: string;
	pharmacien_nom: string;
	pharmacien_adresse: string | null;
	pharmacien_secteur: string | null;
	statut: string;
	signature_pharmacien: boolean;
};

export type RouteSheetToday = {
	id: string;
	camion_id: string;
	camion_nom: string;
	camion_plaque: string;
	date: string;
	ligne: string | null;
	compteurs: {
		colis_std: number;
		sachets_std: number;
		colis_frg: number;
		sachets_frg: number;
	};
	chargement_valide: boolean;
	signature_expedition: boolean;
	signature_chauffeur: boolean;
	commandes: RouteSheetTodayCommande[];
};
