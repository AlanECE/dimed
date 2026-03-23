"use client";

import { NotificationBell } from "@/components/notification-bell";
import { Sidebar } from "@/components/sidebar";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/lib/auth";
import { CartProvider } from "@/lib/cart";

export default function AuthenticatedLayout({
	children,
}: {
	children: React.ReactNode;
}) {
	const { user, loading } = useAuth();

	if (loading) {
		return (
			<div className="flex h-screen items-center justify-center">
				<Skeleton className="h-8 w-48" />
			</div>
		);
	}

	return (
		<CartProvider>
			<div className="flex h-screen">
				<Sidebar />
				<div className="flex flex-1 flex-col">
					<header className="flex items-center justify-end gap-3 border-b px-6 py-2">
						<NotificationBell />
						<span className="text-sm text-slate-600">{user?.nom || user?.email}</span>
					</header>
					<main className="flex-1 overflow-y-auto bg-background p-6">
						<div className="mx-auto max-w-7xl">{children}</div>
					</main>
				</div>
			</div>
		</CartProvider>
	);
}
