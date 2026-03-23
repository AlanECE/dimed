"use client";

import { fetchApi } from "@/lib/api";
import { useCallback, useEffect, useState } from "react";

type DashboardStats = {
	pending: number;
	acceptedToday: number;
	totalToday: number;
	loading: boolean;
};

export function useDashboardStats(): DashboardStats {
	const [pending, setPending] = useState(0);
	const [acceptedToday, setAcceptedToday] = useState(0);
	const [totalToday, setTotalToday] = useState(0);
	const [loading, setLoading] = useState(true);

	const fetchStats = useCallback(async () => {
		setLoading(true);
		const today = new Date().toISOString().split("T")[0];
		try {
			const [pendingRes, acceptedRes, totalRes] = await Promise.all([
				fetchApi<{ total: number }>("/commandes", {
					params: { statut: "creee", limit: 1 },
				}),
				fetchApi<{ total: number }>("/commandes", {
					params: { statut: "acceptee", date_from: today, limit: 1 },
				}),
				fetchApi<{ total: number }>("/commandes", {
					params: { date_from: today, limit: 1 },
				}),
			]);
			setPending(pendingRes.total);
			setAcceptedToday(acceptedRes.total);
			setTotalToday(totalRes.total);
		} catch {
			// silently fail — stats are non-critical
		} finally {
			setLoading(false);
		}
	}, []);

	useEffect(() => {
		fetchStats();
	}, [fetchStats]);

	return { pending, acceptedToday, totalToday, loading };
}
