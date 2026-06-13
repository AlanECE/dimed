"use client";

import { API_BASE, fetchApi } from "@/lib/api";
import type { LigneOcrResponse, PreparationDetailResponse } from "@/lib/types";
import { useCallback, useState } from "react";

export type UpdateLignePatch = {
	qte_prelevee?: number | null;
	verifie?: boolean | null;
	n_lot?: string | null;
	fab?: string | null;
	exp?: string | null;
	ppa?: string | null;
};

export function usePreparation() {
	const [detail, setDetail] = useState<PreparationDetailResponse | null>(null);
	const [loading, setLoading] = useState(false);

	const fetchLignes = useCallback(async (commandeId: string) => {
		setLoading(true);
		try {
			const data = await fetchApi<PreparationDetailResponse>(`/commandes/${commandeId}/lignes`);
			setDetail(data);
		} catch {
			setDetail(null);
		} finally {
			setLoading(false);
		}
	}, []);

	const updateLigne = useCallback(
		async (commandeId: string, ligneId: string, patch: UpdateLignePatch) => {
			const body: Record<string, unknown> = {};
			for (const [k, v] of Object.entries(patch)) {
				if (v !== undefined) body[k] = v;
			}
			await fetchApi(`/commandes/${commandeId}/update-ligne/${ligneId}`, {
				method: "PATCH",
				body: JSON.stringify(body),
			});
		},
		[],
	);

	const startPreparation = useCallback(async (commandeId: string, caddiePoolId: string) => {
		await fetchApi(`/commandes/${commandeId}/start-preparation`, {
			method: "PATCH",
			body: JSON.stringify({ caddie_pool_id: caddiePoolId }),
		});
	}, []);

	const finalizePreparation = useCallback(async (commandeId: string) => {
		await fetchApi(`/commandes/${commandeId}/finalize-preparation`, {
			method: "PATCH",
		});
	}, []);

	const validateControl = useCallback(async (commandeId: string, nbColis: number) => {
		await fetchApi(`/commandes/${commandeId}/validate-control`, {
			method: "PATCH",
			body: JSON.stringify({ nb_colis: nbColis }),
		});
	}, []);

	const scanLigneVignette = useCallback(
		async (commandeId: string, ligneId: string, file: File): Promise<LigneOcrResponse> => {
			const form = new FormData();
			form.append("file", file);
			const res = await fetch(`${API_BASE}/commandes/${commandeId}/lignes/${ligneId}/vignette`, {
				method: "POST",
				body: form,
				credentials: "include",
			});
			if (!res.ok) {
				const body = await res.json().catch(() => ({ detail: "Erreur OCR" }));
				throw new Error(body.detail ?? `Vignette ${res.status}`);
			}
			return res.json();
		},
		[],
	);

	const clearLigneVignette = useCallback(
		async (commandeId: string, ligneId: string): Promise<void> => {
			await fetchApi(`/commandes/${commandeId}/lignes/${ligneId}/vignette`, {
				method: "DELETE",
			});
		},
		[],
	);

	const downloadListePrelevement = useCallback(async (commandeId: string) => {
		const res = await fetch(`${API_BASE}/commandes/${commandeId}/liste-prelevement`, {
			credentials: "include",
		});
		if (!res.ok) throw new Error("Erreur téléchargement");
		const blob = await res.blob();
		const url = URL.createObjectURL(blob);
		const a = document.createElement("a");
		a.href = url;
		a.download = `prelevement_${commandeId}.pdf`;
		a.click();
		URL.revokeObjectURL(url);
	}, []);

	return {
		detail,
		loading,
		fetchLignes,
		updateLigne,
		startPreparation,
		finalizePreparation,
		validateControl,
		downloadListePrelevement,
		scanLigneVignette,
		clearLigneVignette,
	};
}
