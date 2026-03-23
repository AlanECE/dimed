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
