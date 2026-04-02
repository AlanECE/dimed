"use client";

import { fetchApi } from "@/lib/api";
import type { ArrivageResponse } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

export function useArrivages(dateFilter?: string) {
	const [items, setItems] = useState<ArrivageResponse[]>([]);
	const [total, setTotal] = useState(0);
	const [loading, setLoading] = useState(true);

	const fetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ items: ArrivageResponse[]; total: number; date: string }>(
				"/arrivages",
				{ params: { date_filter: dateFilter } },
			);
			setItems(data.items);
			setTotal(data.total);
		} catch {
			setItems([]);
			setTotal(0);
		} finally {
			setLoading(false);
		}
	}, [dateFilter]);

	useEffect(() => {
		fetch();
	}, [fetch]);

	return { items, total, loading, refetch: fetch };
}
