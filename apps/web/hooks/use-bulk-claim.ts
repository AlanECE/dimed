"use client";

import { fetchApi } from "@/lib/api";
import type { BulkClaimPayload, OrderResponse } from "@/lib/types";
import { useCallback, useState } from "react";

export function useBulkClaim() {
	const [submitting, setSubmitting] = useState(false);

	const bulkClaim = useCallback(async (payload: BulkClaimPayload) => {
		setSubmitting(true);
		try {
			const data = await fetchApi<{ items: OrderResponse[] }>("/commandes/bulk-claim", {
				method: "POST",
				body: JSON.stringify(payload),
			});
			return data.items;
		} finally {
			setSubmitting(false);
		}
	}, []);

	return { bulkClaim, submitting };
}
