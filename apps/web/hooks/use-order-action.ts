"use client";

import { fetchApi } from "@/lib/api";
import { useCallback, useState } from "react";

type UseOrderActionResult = {
	execute: (orderId: string) => Promise<void>;
	loading: boolean;
	error: string | null;
};

export function useOrderAction(action: string, onSuccess?: () => void): UseOrderActionResult {
	const [loading, setLoading] = useState(false);
	const [error, setError] = useState<string | null>(null);

	const execute = useCallback(
		async (orderId: string) => {
			setLoading(true);
			setError(null);
			try {
				await fetchApi(`/commandes/${orderId}/${action}`, { method: "PATCH" });
				onSuccess?.();
			} catch (err) {
				setError(err instanceof Error ? err.message : "Erreur");
			} finally {
				setLoading(false);
			}
		},
		[action, onSuccess],
	);

	return { execute, loading, error };
}
