"use client";

import { fetchApi } from "@/lib/api";
import type { CreanceResponse } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

type UseCreancesParams = {
	statut?: string;
	limit?: number;
	offset?: number;
};

type CreancesSummary = {
	total_montant: number;
	total_paye: number;
	total_en_retard: number;
};

export function useCreances(params: UseCreancesParams = {}) {
	const [creances, setCreances] = useState<CreanceResponse[]>([]);
	const [total, setTotal] = useState(0);
	const [summary, setSummary] = useState<CreancesSummary>({ total_montant: 0, total_paye: 0, total_en_retard: 0 });
	const [loading, setLoading] = useState(true);

	const fetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ items: CreanceResponse[]; total: number; summary: CreancesSummary }>("/creances", {
				params: {
					statut: params.statut === "all" ? undefined : params.statut,
					limit: params.limit,
					offset: params.offset,
				},
			});
			setCreances(data.items);
			setTotal(data.total);
			setSummary(data.summary ?? { total_montant: 0, total_paye: 0, total_en_retard: 0 });
		} catch {
			setCreances([]);
			setTotal(0);
			setSummary({ total_montant: 0, total_paye: 0, total_en_retard: 0 });
		} finally {
			setLoading(false);
		}
	}, [params.statut, params.limit, params.offset]);

	useEffect(() => {
		fetch();
	}, [fetch]);

	return { creances, total, summary, loading, refetch: fetch };
}
