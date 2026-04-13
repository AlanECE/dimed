"use client";

import { fetchApi } from "@/lib/api";
import type { FactureListItem, UpdateRemisesRequest } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

type UseFacturesParams = {
	dateFrom?: string;
	dateTo?: string;
	limit?: number;
	offset?: number;
};

export function useFactures(params: UseFacturesParams = {}) {
	const [factures, setFactures] = useState<FactureListItem[]>([]);
	const [total, setTotal] = useState(0);
	const [loading, setLoading] = useState(true);

	const fetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ items: FactureListItem[]; total: number }>(
				"/documents/factures",
				{
					params: {
						date_from: params.dateFrom,
						date_to: params.dateTo,
						limit: params.limit,
						offset: params.offset,
					},
				},
			);
			setFactures(data.items);
			setTotal(data.total);
		} catch {
			setFactures([]);
			setTotal(0);
		} finally {
			setLoading(false);
		}
	}, [params.dateFrom, params.dateTo, params.limit, params.offset]);

	useEffect(() => {
		fetch();
	}, [fetch]);

	const updateRemises = useCallback(
		async (commande_id: string, payload: UpdateRemisesRequest) => {
			await fetchApi(`/documents/facture/${commande_id}/remises`, {
				method: "PATCH",
				body: JSON.stringify(payload),
			});
			await fetch();
		},
		[fetch],
	);

	return { factures, total, loading, refetch: fetch, updateRemises };
}
