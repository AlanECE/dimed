"use client";

import { OrderTable } from "@/components/order-table";
import { Suspense } from "react";

export default function CommandesPage() {
	return (
		<div className="flex flex-col gap-4">
			<h2 className="font-heading text-2xl font-semibold">Mes Commandes</h2>
			<Suspense>
				<OrderTable />
			</Suspense>
		</div>
	);
}
