"use client";

import { fetchApi } from "@/lib/api";
import type { CreateReclamationRequest, ReclamationResponse } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

type UseReclamationsParams = {
	statut?: string;
	limit?: number;
	offset?: number;
};

export function useReclamations(params: UseReclamationsParams = {}) {
	const [reclamations, setReclamations] = useState<ReclamationResponse[]>([]);
	const [total, setTotal] = useState(0);
	const [loading, setLoading] = useState(true);

	const fetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ items: ReclamationResponse[]; total: number }>(
				"/reclamations",
				{
					params: {
						statut: params.statut === "all" ? undefined : params.statut,
						limit: params.limit,
						offset: params.offset,
					},
				},
			);
			setReclamations(data.items);
			setTotal(data.total);
		} catch {
			setReclamations([]);
			setTotal(0);
		} finally {
			setLoading(false);
		}
	}, [params.statut, params.limit, params.offset]);

	useEffect(() => {
		fetch();
	}, [fetch]);

	async function createReclamation(data: CreateReclamationRequest) {
		await fetchApi("/reclamations", {
			method: "POST",
			body: JSON.stringify(data),
		});
		fetch();
	}

	return { reclamations, total, loading, refetch: fetch, createReclamation };
}
