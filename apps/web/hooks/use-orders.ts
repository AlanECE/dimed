"use client";

import { fetchApi } from "@/lib/api";
import type { OrderResponse } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

type UseOrdersParams = {
	statut?: string;
	dateFrom?: string;
	dateTo?: string;
	limit?: number;
	offset?: number;
};

type UseOrdersResult = {
	orders: OrderResponse[];
	total: number;
	loading: boolean;
	error: string | null;
	refetch: () => void;
};

export function useOrders({
	statut,
	dateFrom,
	dateTo,
	limit = 20,
	offset = 0,
}: UseOrdersParams = {}): UseOrdersResult {
	const [orders, setOrders] = useState<OrderResponse[]>([]);
	const [total, setTotal] = useState(0);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	const doFetch = useCallback(async () => {
		setLoading(true);
		setError(null);
		try {
			const data = await fetchApi<{
				commandes: OrderResponse[];
				total: number;
			}>("/commandes", {
				params: {
					statut: statut && statut !== "all" ? statut : undefined,
					date_from: dateFrom,
					date_to: dateTo,
					limit,
					offset,
				},
			});
			setOrders(data.commandes);
			setTotal(data.total);
		} catch (err) {
			setError(err instanceof Error ? err.message : "Erreur de chargement");
			setOrders([]);
			setTotal(0);
		} finally {
			setLoading(false);
		}
	}, [statut, dateFrom, dateTo, limit, offset]);

	useEffect(() => {
		doFetch();
	}, [doFetch]);

	return { orders, total, loading, error, refetch: doFetch };
}
