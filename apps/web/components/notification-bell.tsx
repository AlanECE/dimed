"use client";

import { useNotifications } from "@/hooks/use-notifications";
import { relativeTime } from "@/lib/relative-time";
import type { NotificationResponse } from "@/lib/types";
import { Bell } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { Button } from "./ui/button";
import { Popover, PopoverContent, PopoverTrigger } from "./ui/popover";
import { ScrollArea } from "./ui/scroll-area";

function NotificationItem({
	notification,
	onClick,
}: {
	notification: NotificationResponse;
	onClick: (n: NotificationResponse) => void;
}) {
	return (
		<button
			type="button"
			className={`flex w-full items-start gap-3 px-4 py-3 text-left transition-colors duration-150 hover:bg-sky-100 ${
				notification.read ? "bg-white" : "bg-sky-50"
			}`}
			onClick={() => onClick(notification)}
		>
			<span
				className={`mt-1.5 h-2 w-2 shrink-0 rounded-full ${
					notification.read ? "bg-transparent" : "bg-sky-600"
				}`}
			/>
			<div className="min-w-0 flex-1">
				<p className="text-sm text-slate-900">{notification.message}</p>
				<p className="text-xs text-slate-500">{relativeTime(notification.created_at)}</p>
			</div>
		</button>
	);
}

export function NotificationBell() {
	const { notifications, unreadCount, markRead, markAllRead, refetch } = useNotifications();
	const router = useRouter();
	const [open, setOpen] = useState(false);

	const handleNotificationClick = async (n: NotificationResponse) => {
		if (!n.read) {
			await markRead(n.id);
		}
		setOpen(false);
		router.push(`/commandes/${n.commande_id}`);
	};

	const handleOpenChange = (isOpen: boolean) => {
		setOpen(isOpen);
		if (isOpen) {
			refetch();
		}
	};

	return (
		<Popover open={open} onOpenChange={handleOpenChange}>
			<PopoverTrigger render={<Button variant="ghost" size="icon" aria-label="Notifications" />}>
				<span className="relative">
					<Bell className="h-5 w-5" />
					{unreadCount > 0 && (
						<span
							className="absolute -top-2 -right-2 flex h-[18px] min-w-[18px] items-center justify-center rounded-full bg-red-500 px-1 text-[11px] font-semibold text-white"
							aria-live="polite"
						>
							{unreadCount > 99 ? "99+" : unreadCount}
						</span>
					)}
				</span>
			</PopoverTrigger>
			<PopoverContent align="end" sideOffset={8} className="w-80 gap-0 p-0">
				<div className="flex items-center justify-between border-b px-4 py-3">
					<span className="text-sm font-semibold text-slate-900">Notifications</span>
					{unreadCount > 0 && (
						<button
							type="button"
							className="text-xs font-medium text-sky-600 hover:text-sky-700"
							onClick={markAllRead}
						>
							Tout marquer comme lu
						</button>
					)}
				</div>
				<ScrollArea className="max-h-[400px]">
					{notifications.length === 0 ? (
						<div className="py-8 text-center text-sm text-slate-500">Aucune notification</div>
					) : (
						<div className="divide-y">
							{notifications.map((n) => (
								<NotificationItem key={n.id} notification={n} onClick={handleNotificationClick} />
							))}
						</div>
					)}
				</ScrollArea>
			</PopoverContent>
		</Popover>
	);
}
