"use client";

import { fetchApi } from "@/lib/api";
import type { OrderDetailResponse } from "@/lib/types";
import { useState } from "react";

export function useOperatorEdit() {
	const [loading, setLoading] = useState(false);

	async function updateComment(
		commandeId: string,
		comment: string | null,
	): Promise<OrderDetailResponse> {
		setLoading(true);
		try {
			return await fetchApi<OrderDetailResponse>(`/commandes/${commandeId}/comment`, {
				method: "PATCH",
				body: JSON.stringify({ comment }),
			});
		} finally {
			setLoading(false);
		}
	}

	async function editLine(
		commandeId: string,
		ligneId: string,
		qteDemandee: number,
	): Promise<OrderDetailResponse> {
		setLoading(true);
		try {
			return await fetchApi<OrderDetailResponse>(`/commandes/${commandeId}/lines/${ligneId}`, {
				method: "PATCH",
				body: JSON.stringify({ qte_demandee: qteDemandee }),
			});
		} finally {
			setLoading(false);
		}
	}

	async function addLine(
		commandeId: string,
		medicamentId: string,
		qteDemandee: number,
	): Promise<OrderDetailResponse> {
		setLoading(true);
		try {
			return await fetchApi<OrderDetailResponse>(`/commandes/${commandeId}/lines`, {
				method: "POST",
				body: JSON.stringify({
					medicament_id: medicamentId,
					qte_demandee: qteDemandee,
				}),
			});
		} finally {
			setLoading(false);
		}
	}

	async function removeLine(commandeId: string, ligneId: string): Promise<OrderDetailResponse> {
		setLoading(true);
		try {
			return await fetchApi<OrderDetailResponse>(`/commandes/${commandeId}/lines/${ligneId}`, {
				method: "DELETE",
			});
		} finally {
			setLoading(false);
		}
	}

	return { updateComment, editLine, addLine, removeLine, loading };
}
