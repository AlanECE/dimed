"use client";

import { FactureTable } from "@/components/facture-table";
import { Receipt } from "lucide-react";

export default function FacturationPage() {
	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50">
					<Receipt className="h-5 w-5 text-emerald-600" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Facturation</h2>
					<p className="text-[13px] text-muted-foreground">Historique des factures</p>
				</div>
			</div>
			<FactureTable />
		</div>
	);
}
