"use client";

import { API_BASE, fetchApi } from "@/lib/api";
import type { PreparationDetailResponse } from "@/lib/types";
import { useCallback, useState } from "react";

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
		async (
			commandeId: string,
			ligneId: string,
			qtePrelevee: number | null,
			verifie: boolean | null,
			ocrVerifie?: boolean,
		) => {
			const body: Record<string, unknown> = {};
			if (qtePrelevee !== null) body.qte_prelevee = qtePrelevee;
			if (verifie !== null) body.verifie = verifie;
			if (ocrVerifie !== undefined) body.ocr_verifie = ocrVerifie;
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

	const validateControl = useCallback(async (commandeId: string) => {
		await fetchApi(`/commandes/${commandeId}/validate-control`, {
			method: "PATCH",
		});
	}, []);

	const scanPrelevement = useCallback(
		async (
			commandeId: string,
			file: File,
		): Promise<{ matched_count: number; total_lines: number; matched_ligne_ids: string[] }> => {
			const form = new FormData();
			form.append("file", file);
			const res = await fetch(`${API_BASE}/commandes/${commandeId}/ocr-scan`, {
				method: "POST",
				body: form,
				credentials: "include",
			});
			if (!res.ok) {
				const body = await res.json().catch(() => ({ detail: "Erreur OCR" }));
				throw new Error(body.detail ?? `OCR ${res.status}`);
			}
			return res.json();
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
		scanPrelevement,
	};
}
