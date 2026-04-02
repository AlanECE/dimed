"use client";

import { fetchApi } from "@/lib/api";
import type { ReportStats } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

export function useReports(period = "month") {
	const [stats, setStats] = useState<ReportStats | null>(null);
	const [loading, setLoading] = useState(true);

	const fetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<ReportStats>(`/commandes/stats?period=${period}`);
			setStats(data);
		} catch {
			setStats(null);
		} finally {
			setLoading(false);
		}
	}, [period]);

	useEffect(() => {
		fetch();
	}, [fetch]);

	return { stats, loading, refetch: fetch };
}
