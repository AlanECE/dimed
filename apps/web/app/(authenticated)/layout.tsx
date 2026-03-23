"use client";

import { Sidebar } from "@/components/sidebar";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/lib/auth";

export default function AuthenticatedLayout({
	children,
}: {
	children: React.ReactNode;
}) {
	const { loading } = useAuth();

	if (loading) {
		return (
			<div className="flex h-screen items-center justify-center">
				<Skeleton className="h-8 w-48" />
			</div>
		);
	}

	return (
		<div className="flex h-screen">
			<Sidebar />
			<main className="flex-1 overflow-y-auto bg-background p-6">
				<div className="mx-auto max-w-7xl">{children}</div>
			</main>
		</div>
	);
}
