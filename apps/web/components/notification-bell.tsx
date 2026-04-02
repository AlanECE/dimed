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
			className={`flex w-full items-start gap-3 px-4 py-3 text-left transition-colors duration-150 hover:bg-muted/70 ${
				notification.read ? "bg-transparent" : "bg-primary/[0.03]"
			}`}
			onClick={() => onClick(notification)}
		>
			<span
				className={`mt-1.5 h-2 w-2 shrink-0 rounded-full transition-colors ${
					notification.read ? "bg-transparent" : "bg-primary"
				}`}
			/>
			<div className="min-w-0 flex-1">
				<p className="text-[13px] text-foreground">{notification.message}</p>
				<p className="mt-0.5 text-[11px] text-muted-foreground">
					{relativeTime(notification.created_at)}
				</p>
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
			<PopoverTrigger
				render={
					<Button
						variant="ghost"
						size="icon"
						className="h-9 w-9 rounded-lg text-muted-foreground hover:text-foreground"
						aria-label="Notifications"
					/>
				}
			>
				<span className="relative">
					<Bell className="h-[18px] w-[18px]" />
					{unreadCount > 0 && (
						<span
							className="absolute -top-1.5 -right-1.5 flex h-[16px] min-w-[16px] items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white shadow-sm"
							aria-live="polite"
						>
							{unreadCount > 99 ? "99+" : unreadCount}
						</span>
					)}
				</span>
			</PopoverTrigger>
			<PopoverContent
				align="end"
				sideOffset={8}
				className="w-80 gap-0 overflow-hidden rounded-xl border-border/60 p-0 shadow-lg"
			>
				<div className="flex items-center justify-between border-b border-border/60 px-4 py-3">
					<span className="text-[13px] font-semibold text-foreground">Notifications</span>
					{unreadCount > 0 && (
						<button
							type="button"
							className="text-[11px] font-semibold text-primary hover:text-primary/80 transition-colors"
							onClick={markAllRead}
						>
							Tout marquer comme lu
						</button>
					)}
				</div>
				<ScrollArea className="max-h-[400px]">
					{notifications.length === 0 ? (
						<div className="py-10 text-center">
							<Bell className="mx-auto mb-2 h-8 w-8 text-muted-foreground/30" />
							<p className="text-[13px] text-muted-foreground">Aucune notification</p>
						</div>
					) : (
						<div className="divide-y divide-border/40">
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
