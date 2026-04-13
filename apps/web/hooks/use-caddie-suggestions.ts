"use client";

import { fetchApi } from "@/lib/api";
import { useCallback, useEffect, useState } from "react";

export function useCaddieSuggestions() {
	const [suggestions, setSuggestions] = useState<string[]>([]);
	const [loading, setLoading] = useState(true);

	const refetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ suggestions: string[] }>("/commandes/caddies/suggestions");
			setSuggestions(data.suggestions ?? []);
		} catch {
			setSuggestions([]);
		} finally {
			setLoading(false);
		}
	}, []);

	useEffect(() => {
		refetch();
	}, [refetch]);

	return { suggestions, loading, refetch };
}
