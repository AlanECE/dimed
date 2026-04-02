"use client";

import { fetchApi } from "@/lib/api";
import type { AuditLogEntry } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

type UseAuditLogParams = {
	entityType?: string;
	action?: string;
	limit?: number;
	offset?: number;
};

export function useAuditLog(params: UseAuditLogParams = {}) {
	const [entries, setEntries] = useState<AuditLogEntry[]>([]);
	const [total, setTotal] = useState(0);
	const [loading, setLoading] = useState(true);

	const fetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ items: AuditLogEntry[]; total: number }>("/admin/audit-log", {
				params: {
					entity_type: params.entityType,
					action: params.action,
					limit: params.limit,
					offset: params.offset,
				},
			});
			setEntries(data.items);
			setTotal(data.total);
		} catch {
			setEntries([]);
			setTotal(0);
		} finally {
			setLoading(false);
		}
	}, [params.entityType, params.action, params.limit, params.offset]);

	useEffect(() => {
		fetch();
	}, [fetch]);

	return { entries, total, loading, refetch: fetch };
}
