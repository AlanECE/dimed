"use client";

import { NotificationBell } from "@/components/notification-bell";
import { Sidebar } from "@/components/sidebar";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/lib/auth";
import { CartProvider } from "@/lib/cart";
import { Pill } from "lucide-react";

export default function AuthenticatedLayout({
	children,
}: {
	children: React.ReactNode;
}) {
	const { user, loading } = useAuth();

	if (loading) {
		return (
			<div className="flex h-screen flex-col items-center justify-center gap-4 bg-background">
				<div className="flex h-12 w-12 animate-pulse items-center justify-center rounded-2xl bg-gradient-to-br from-[#0F766E] to-[#0D9488]">
					<Pill className="h-6 w-6 text-white" />
				</div>
				<Skeleton className="h-4 w-32" />
			</div>
		);
	}

	return (
		<CartProvider>
			<div className="flex h-screen">
				<Sidebar />
				<div className="flex flex-1 flex-col overflow-hidden">
					<header className="flex h-14 shrink-0 items-center justify-end gap-3 border-b border-border/60 bg-card/50 px-6 backdrop-blur-sm">
						<NotificationBell />
						<div className="h-5 w-px bg-border" />
						<span className="text-[13px] font-medium text-muted-foreground">
							{user?.nom || user?.email}
						</span>
					</header>
					<main className="flex-1 overflow-y-auto p-6">
						<div className="mx-auto max-w-7xl animate-fade-in-up">{children}</div>
					</main>
				</div>
			</div>
		</CartProvider>
	);
}
