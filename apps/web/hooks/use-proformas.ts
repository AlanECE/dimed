"use client";

import { fetchApi } from "@/lib/api";
import type { ProformaListItem } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

type UseProformasParams = {
	dateFrom?: string;
	dateTo?: string;
	limit?: number;
	offset?: number;
};

export function useProformas(params: UseProformasParams = {}) {
	const [proformas, setProformas] = useState<ProformaListItem[]>([]);
	const [total, setTotal] = useState(0);
	const [loading, setLoading] = useState(true);

	const fetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ items: ProformaListItem[]; total: number }>(
				"/documents/proformas",
				{
					params: {
						date_from: params.dateFrom,
						date_to: params.dateTo,
						limit: params.limit,
						offset: params.offset,
					},
				},
			);
			setProformas(data.items);
			setTotal(data.total);
		} catch {
			setProformas([]);
			setTotal(0);
		} finally {
			setLoading(false);
		}
	}, [params.dateFrom, params.dateTo, params.limit, params.offset]);

	useEffect(() => {
		fetch();
	}, [fetch]);

	return { proformas, total, loading, refetch: fetch };
}
