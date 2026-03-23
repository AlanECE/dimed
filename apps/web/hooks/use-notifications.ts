"use client";

import { fetchApi } from "@/lib/api";
import type { NotificationListResponse, NotificationResponse } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

type UseNotificationsResult = {
	notifications: NotificationResponse[];
	unreadCount: number;
	loading: boolean;
	markRead: (id: string) => Promise<void>;
	markAllRead: () => Promise<void>;
	refetch: () => void;
};

export function useNotifications(): UseNotificationsResult {
	const [notifications, setNotifications] = useState<NotificationResponse[]>([]);
	const [unreadCount, setUnreadCount] = useState(0);
	const [loading, setLoading] = useState(true);

	const doFetch = useCallback(async () => {
		try {
			const data = await fetchApi<NotificationListResponse>("/notifications");
			setNotifications(data.notifications);
			setUnreadCount(data.unread_count);
		} catch {
			setNotifications([]);
			setUnreadCount(0);
		} finally {
			setLoading(false);
		}
	}, []);

	useEffect(() => {
		doFetch();
	}, [doFetch]);

	const markRead = useCallback(
		async (id: string) => {
			// Optimistic update
			setNotifications((prev) => prev.map((n) => (n.id === id ? { ...n, read: true } : n)));
			setUnreadCount((prev) => Math.max(0, prev - 1));

			try {
				await fetchApi(`/notifications/${id}/read`, { method: "PATCH" });
			} catch {
				doFetch();
			}
		},
		[doFetch],
	);

	const markAllRead = useCallback(async () => {
		// Optimistic update
		setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
		setUnreadCount(0);

		try {
			await fetchApi("/notifications/read-all", { method: "PATCH" });
		} catch {
			doFetch();
		}
	}, [doFetch]);

	return { notifications, unreadCount, loading, markRead, markAllRead, refetch: doFetch };
}
