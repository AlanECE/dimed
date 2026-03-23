"use client";

import { fetchApi } from "@/lib/api";
import type { MedicamentResponse } from "@/lib/types";
import { useCallback, useEffect, useRef, useState } from "react";

type UseMedicationsParams = {
	search?: string;
	limit?: number;
	offset?: number;
};

type UseMedicationsResult = {
	medications: MedicamentResponse[];
	total: number;
	loading: boolean;
	error: string | null;
	refetch: () => void;
};

export function useMedications({
	search,
	limit = 20,
	offset = 0,
}: UseMedicationsParams = {}): UseMedicationsResult {
	const [medications, setMedications] = useState<MedicamentResponse[]>([]);
	const [total, setTotal] = useState(0);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);
	const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
	const [debouncedSearch, setDebouncedSearch] = useState(search);

	// Debounce search input by 300ms
	useEffect(() => {
		if (debounceRef.current) clearTimeout(debounceRef.current);
		debounceRef.current = setTimeout(() => {
			setDebouncedSearch(search);
		}, 300);
		return () => {
			if (debounceRef.current) clearTimeout(debounceRef.current);
		};
	}, [search]);

	const doFetch = useCallback(async () => {
		setLoading(true);
		setError(null);
		try {
			const data = await fetchApi<{
				medicaments: MedicamentResponse[];
				total: number;
			}>("/medicaments", {
				params: {
					search: debouncedSearch,
					limit,
					offset,
				},
			});
			setMedications(data.medicaments);
			setTotal(data.total);
		} catch (err) {
			setError(err instanceof Error ? err.message : "Erreur de chargement");
			setMedications([]);
			setTotal(0);
		} finally {
			setLoading(false);
		}
	}, [debouncedSearch, limit, offset]);

	useEffect(() => {
		doFetch();
	}, [doFetch]);

	return { medications, total, loading, error, refetch: doFetch };
}
