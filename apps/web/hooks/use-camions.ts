"use client";

import { fetchApi } from "@/lib/api";
import type { CamionResponse } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

export function useCamions() {
	const [camions, setCamions] = useState<CamionResponse[]>([]);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	const fetchCamions = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ camions: CamionResponse[]; total: number }>("/camions");
			setCamions(data.camions);
			setError(null);
		} catch (err) {
			setError(err instanceof Error ? err.message : "Erreur de chargement");
		} finally {
			setLoading(false);
		}
	}, []);

	useEffect(() => {
		fetchCamions();
	}, [fetchCamions]);

	return { camions, loading, error, refetch: fetchCamions };
}

export async function createCamion(nom: string, plaque: string) {
	return fetchApi<CamionResponse>("/camions", {
		method: "POST",
		body: JSON.stringify({ nom, plaque }),
	});
}

export async function updateCamion(id: string, data: { nom?: string; plaque?: string }) {
	return fetchApi<CamionResponse>(`/camions/${id}`, {
		method: "PATCH",
		body: JSON.stringify(data),
	});
}

export async function deleteCamion(id: string) {
	return fetchApi(`/camions/${id}`, { method: "DELETE" });
}
