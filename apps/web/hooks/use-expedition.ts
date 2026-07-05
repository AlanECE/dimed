"use client";

import { API_BASE, fetchApi } from "@/lib/api";
import type {
	ChargementState,
	ColisDetail,
	PadOccupation,
	ScanChargementResult,
	ScanLivraisonResult,
	ValidateLoadingResult,
	ZoneExpeditionCommande,
} from "@/lib/types";
import { useCallback } from "react";

export function useExpedition() {
	const lookupColis = useCallback(async (numero: string) => {
		return fetchApi<ColisDetail>(`/expedition/colis/${encodeURIComponent(numero)}`);
	}, []);

	const deposePad = useCallback(async (numero: string, padTirId: string) => {
		return fetchApi<{ status: string; numero: string; pad: { id: string; code: string } }>(
			`/expedition/colis/${encodeURIComponent(numero)}/depose-pad`,
			{
				method: "POST",
				body: JSON.stringify({ pad_tir_id: padTirId }),
			},
		);
	}, []);

	const deposePadCommande = useCallback(async (commandeId: string, padTirId: string) => {
		return fetchApi<{
			status: string;
			commande_ref: string | null;
			pad: { id: string; code: string; nom: string };
			nb_colis: number;
			deposes: string[];
			ignores: string[];
		}>(`/expedition/commandes/${encodeURIComponent(commandeId)}/depose-pad`, {
			method: "POST",
			body: JSON.stringify({ pad_tir_id: padTirId }),
		});
	}, []);

	const fetchPads = useCallback(async () => {
		const data = await fetchApi<{ pads: PadOccupation[]; total: number }>("/expedition/pads");
		return data.pads;
	}, []);

	// Le magasinier dépose une commande entière en zone d'expédition (sans pad).
	const deposeZoneExpedition = useCallback(async (commandeId: string) => {
		return fetchApi<{
			status: string;
			commande_ref: string | null;
			nb_colis: number;
			deposes: string[];
		}>(`/expedition/commandes/${encodeURIComponent(commandeId)}/zone-expedition`, {
			method: "POST",
		});
	}, []);

	const fetchZoneExpedition = useCallback(async () => {
		const data = await fetchApi<{ commandes: ZoneExpeditionCommande[]; total: number }>(
			"/expedition/zone-expedition",
		);
		return data.commandes;
	}, []);

	const scanChargement = useCallback(async (numero: string) => {
		return fetchApi<ScanChargementResult>(
			`/expedition/colis/${encodeURIComponent(numero)}/scan-chargement`,
			{ method: "POST" },
		);
	}, []);

	const scanLivraison = useCallback(async (numero: string) => {
		return fetchApi<ScanLivraisonResult>(
			`/expedition/colis/${encodeURIComponent(numero)}/scan-livraison`,
			{ method: "POST" },
		);
	}, []);

	const fetchChargement = useCallback(async (feuilleId: string) => {
		return fetchApi<ChargementState>(`/expedition/feuilles-route/${feuilleId}/chargement`);
	}, []);

	const validateChargement = useCallback(async (feuilleId: string) => {
		return fetchApi<ValidateLoadingResult>(
			`/documents/feuilles-route/${feuilleId}/validate-loading`,
			{
				method: "PATCH",
				body: JSON.stringify({}),
			},
		);
	}, []);

	const downloadEtiquettes = useCallback(async (commandeId: string, commandeRef?: string) => {
		const res = await fetch(`${API_BASE}/expedition/commandes/${commandeId}/etiquettes`, {
			credentials: "include",
		});
		if (!res.ok) throw new Error("Erreur téléchargement étiquettes");
		const blob = await res.blob();
		const url = URL.createObjectURL(blob);
		const a = document.createElement("a");
		a.href = url;
		a.download = `etiquettes_${commandeRef ?? commandeId}.pdf`;
		a.click();
		URL.revokeObjectURL(url);
	}, []);

	return {
		lookupColis,
		deposePad,
		deposePadCommande,
		deposeZoneExpedition,
		fetchZoneExpedition,
		fetchPads,
		scanChargement,
		scanLivraison,
		fetchChargement,
		validateChargement,
		downloadEtiquettes,
	};
}
