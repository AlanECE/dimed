"use client";

import { fetchApi } from "@/lib/api";
import type { CreanceResponse } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

type UseCreancesParams = {
	statut?: string;
	limit?: number;
	offset?: number;
};

export function useCreances(params: UseCreancesParams = {}) {
	const [creances, setCreances] = useState<CreanceResponse[]>([]);
	const [total, setTotal] = useState(0);
	const [loading, setLoading] = useState(true);

	const fetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ items: CreanceResponse[]; total: number }>("/creances", {
				params: {
					statut: params.statut === "all" ? undefined : params.statut,
					limit: params.limit,
					offset: params.offset,
				},
			});
			setCreances(data.items);
			setTotal(data.total);
		} catch {
			setCreances([]);
			setTotal(0);
		} finally {
			setLoading(false);
		}
	}, [params.statut, params.limit, params.offset]);

	useEffect(() => {
		fetch();
	}, [fetch]);

	return { creances, total, loading, refetch: fetch };
}
