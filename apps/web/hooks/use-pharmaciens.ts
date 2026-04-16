"use client";

import { fetchApi } from "@/lib/api";
import type { UserResponse } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

type UsePharmacienResult = {
	pharmaciens: UserResponse[];
	loading: boolean;
	error: string | null;
};

export function usePharmaciens(): UsePharmacienResult {
	const [pharmaciens, setPharmaciens] = useState<UserResponse[]>([]);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	const doFetch = useCallback(async () => {
		setLoading(true);
		setError(null);
		try {
			const data = await fetchApi<{ pharmaciens: UserResponse[] }>(
				"/commandes/pharmaciens",
			);
			setPharmaciens(data.pharmaciens);
		} catch (err) {
			setError(err instanceof Error ? err.message : "Erreur de chargement");
		} finally {
			setLoading(false);
		}
	}, []);

	useEffect(() => {
		doFetch();
	}, [doFetch]);

	return { pharmaciens, loading, error };
}
