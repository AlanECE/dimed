"use client";

import { OrderTable } from "@/components/order-table";
import { ClipboardList } from "lucide-react";
import { Suspense } from "react";

export default function CommandesPage() {
	return (
		<div className="flex flex-col gap-4">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10">
					<ClipboardList className="h-5 w-5 text-primary" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Mes Commandes</h2>
					<p className="text-[13px] text-muted-foreground">Historique et suivi de vos commandes</p>
				</div>
			</div>
			<Suspense>
				<OrderTable />
			</Suspense>
		</div>
	);
}
