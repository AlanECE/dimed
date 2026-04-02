"use client";

import { fetchApi } from "@/lib/api";
import type { BonLivraisonListItem } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

export function useBonsLivraison(limit = 50) {
	const [bls, setBls] = useState<BonLivraisonListItem[]>([]);
	const [total, setTotal] = useState(0);
	const [loading, setLoading] = useState(true);

	const fetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ items: BonLivraisonListItem[]; total: number }>(
				"/documents/bons-livraison",
				{ params: { limit } },
			);
			setBls(data.items);
			setTotal(data.total);
		} catch {
			setBls([]);
			setTotal(0);
		} finally {
			setLoading(false);
		}
	}, [limit]);

	useEffect(() => {
		fetch();
	}, [fetch]);

	return { bls, total, loading, refetch: fetch };
}
