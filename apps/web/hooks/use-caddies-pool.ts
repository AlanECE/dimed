"use client";

import { fetchApi } from "@/lib/api";
import type { CaddiePoolResponse } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

type PoolResponse = { items: CaddiePoolResponse[] };

export function useCaddiesPool(autoLoad = true) {
	const [pool, setPool] = useState<CaddiePoolResponse[]>([]);
	const [loading, setLoading] = useState(false);

	const refetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<PoolResponse>("/commandes/caddies/pool");
			setPool(data.items);
		} catch {
			setPool([]);
		} finally {
			setLoading(false);
		}
	}, []);

	useEffect(() => {
		if (autoLoad) refetch();
	}, [autoLoad, refetch]);

	const available = pool.filter((c) => c.is_available);

	return { pool, available, loading, refetch };
}
