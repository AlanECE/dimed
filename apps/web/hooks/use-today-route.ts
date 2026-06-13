"use client";

import { fetchApi } from "@/lib/api";
import type { RouteSheetToday, ValidateLoadingResult } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

export function useTodayRoute() {
	const [feuille, setFeuille] = useState<RouteSheetToday | null>(null);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	const fetch = useCallback(async () => {
		setLoading(true);
		setError(null);
		try {
			const data = await fetchApi<{ feuille: RouteSheetToday | null }>(
				"/documents/feuilles-route/today",
			);
			setFeuille(data.feuille);
		} catch (err) {
			setError(err instanceof Error ? err.message : "Erreur");
			setFeuille(null);
		} finally {
			setLoading(false);
		}
	}, []);

	useEffect(() => {
		fetch();
	}, [fetch]);

	const validateLoading = useCallback(
		async (feuilleId: string): Promise<ValidateLoadingResult> => {
			// La validation se fait désormais sur les scans par colis côté serveur :
			// ok=false renvoie la liste explicite des colis manquants.
			const result = await fetchApi<ValidateLoadingResult>(
				`/documents/feuilles-route/${feuilleId}/validate-loading`,
				{
					method: "PATCH",
					body: JSON.stringify({}),
				},
			);
			if (result.ok) await fetch();
			return result;
		},
		[fetch],
	);

	const signSheet = useCallback(
		async (feuilleId: string, type: "expedition" | "chauffeur", signature: string) => {
			await fetchApi(`/documents/feuilles-route/${feuilleId}/sign`, {
				method: "PATCH",
				body: JSON.stringify({ type, signature }),
			});
			await fetch();
		},
		[fetch],
	);

	const deliverWithSignature = useCallback(
		async (commandeId: string, signature: string) => {
			await fetchApi(`/commandes/${commandeId}/deliver-with-signature`, {
				method: "PATCH",
				body: JSON.stringify({ signature }),
			});
			await fetch();
		},
		[fetch],
	);

	const markFailed = useCallback(
		async (commandeId: string, action: "refuse" | "retourne", motif: string) => {
			await fetchApi(`/commandes/${commandeId}/mark-failed`, {
				method: "PATCH",
				body: JSON.stringify({ action, motif }),
			});
			await fetch();
		},
		[fetch],
	);

	const claimToday = useCallback(async () => {
		await fetchApi("/documents/feuilles-route/claim-today", {
			method: "POST",
		});
		await fetch();
	}, [fetch]);

	return {
		feuille,
		loading,
		error,
		refetch: fetch,
		validateLoading,
		signSheet,
		deliverWithSignature,
		markFailed,
		claimToday,
	};
}
