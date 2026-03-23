"use client";

import { fetchApi } from "@/lib/api";
import type { FeuilleDeRouteResponse } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

export function useRouteSheets() {
	const [sheets, setSheets] = useState<FeuilleDeRouteResponse[]>([]);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	const fetchSheets = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ feuilles: FeuilleDeRouteResponse[]; total: number }>(
				"/documents/feuilles-route",
			);
			setSheets(data.feuilles);
			setError(null);
		} catch (err) {
			setError(err instanceof Error ? err.message : "Erreur de chargement");
		} finally {
			setLoading(false);
		}
	}, []);

	useEffect(() => {
		fetchSheets();
	}, [fetchSheets]);

	return { sheets, loading, error, refetch: fetchSheets };
}
