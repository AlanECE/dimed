export type UserResponse = {
	id: string;
	email: string;
	nom: string;
	prenom: string;
	role: string;
	is_active: boolean;
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
};

export type LigneResponse = {
	id: string;
	medicament_id: string;
	designation: string;
	qte_demandee: number;
	prix_unitaire: number;
	n_lot: string | null;
};

export type OrderResponse = {
	id: string;
	reference_id: string;
	statut: string;
	montant_total: number;
	pharmacien_id: string;
	operatrice_id: string | null;
	commercial: string | null;
	created_at: string;
	date_validation: string | null;
	camion_id: string | null;
	camion_nom: string | null;
	pharmacien_nom: string | null;
	pharmacien_email: string | null;
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
