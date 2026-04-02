"use client";

import { CartSidebar } from "@/components/cart-sidebar";
import { MedicationTable } from "@/components/medication-table";
import { Skeleton } from "@/components/ui/skeleton";
import { fetchApi } from "@/lib/api";
import { useCart } from "@/lib/cart";
import type { MedicamentResponse } from "@/lib/types";
import { AlertTriangle, Package, Plus } from "lucide-react";
import { useCallback, useEffect, useState } from "react";

type HighlightsData = {
	out_of_stock: MedicamentResponse[];
	featured: MedicamentResponse[];
};

function useHighlights() {
	const [data, setData] = useState<HighlightsData | null>(null);
	const [loading, setLoading] = useState(true);

	const fetch = useCallback(async () => {
		try {
			const res = await fetchApi<HighlightsData>("/medicaments/highlights");
			setData(res);
		} catch {
			setData(null);
		} finally {
			setLoading(false);
		}
	}, []);

	useEffect(() => {
		fetch();
	}, [fetch]);

	return { data, loading };
}

export default function CataloguePage() {
	const { data: highlights, loading: hlLoading } = useHighlights();
	const { addItem } = useCart();

	return (
		<div className="-m-6 flex h-[calc(100vh)]">
			<div className="flex flex-1 flex-col gap-6 overflow-y-auto p-6">
				{/* Header */}
				<div className="flex items-center gap-3">
					<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10">
						<Package className="h-5 w-5 text-primary" />
					</div>
					<div>
						<h2 className="font-heading text-xl font-bold">Catalogue</h2>
						<p className="text-[13px] text-muted-foreground">
							Parcourez et commandez vos médicaments
						</p>
					</div>
				</div>

				{/* Featured Products */}
				{hlLoading ? (
					<div className="grid grid-cols-3 gap-3">
						{Array.from({ length: 3 }).map((_, i) => (
							<Skeleton key={`feat-sk-${i}`} className="h-32 rounded-xl" />
						))}
					</div>
				) : (
					highlights &&
					highlights.featured.length > 0 && (
						<section className="animate-fade-in-up">
							<div className="mb-3 flex items-center gap-2">
								<span className="h-2 w-2 rounded-full bg-amber-500" />
								<h3 className="text-[14px] font-semibold">Produits mis en avant</h3>
							</div>
							<div className="grid grid-cols-2 gap-3 lg:grid-cols-3">
								{highlights.featured.map((med) => (
									<button
										type="button"
										key={med.id}
										onClick={() => addItem(med)}
										className="group relative overflow-hidden rounded-xl border border-border/50 bg-gradient-to-br from-card to-muted/30 p-4 text-left shadow-sm transition-all hover:border-primary/30 hover:shadow-md hover:shadow-primary/5"
									>
										<div className="absolute right-3 top-3 flex h-7 w-7 items-center justify-center rounded-full bg-primary/10 opacity-0 transition-opacity group-hover:opacity-100">
											<Plus className="h-3.5 w-3.5 text-primary" />
										</div>
										<p className="text-[13px] font-semibold leading-tight">{med.designation}</p>
										<p className="mt-1 text-[11px] text-muted-foreground">
											{med.forme ?? ""} {med.dosage ? `· ${med.dosage}` : ""}
										</p>
										<div className="mt-2.5 flex items-center justify-between">
											<span className="text-[14px] font-bold tabular-nums text-primary">
												{med.ppa.toLocaleString("fr-FR")} DA
											</span>
											<span className="text-[11px] font-medium text-emerald-600">
												{med.stock_quantity} en stock
											</span>
										</div>
										{med.fabricant && (
											<p className="mt-1.5 text-[10px] uppercase tracking-wider text-muted-foreground/60">
												{med.fabricant}
											</p>
										)}
									</button>
								))}
							</div>
						</section>
					)
				)}

				{/* Out of Stock */}
				{!hlLoading && highlights && highlights.out_of_stock.length > 0 && (
					<section className="animate-fade-in-up" style={{ animationDelay: "50ms" }}>
						<details className="group">
							<summary className="mb-2 flex cursor-pointer list-none items-center gap-2 [&::-webkit-details-marker]:hidden">
								<AlertTriangle className="h-4 w-4 text-red-500" />
								<h3 className="text-[14px] font-semibold">Produits en rupture</h3>
								<span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-red-100 px-1.5 text-[10px] font-bold text-red-700">
									{highlights.out_of_stock.length}
								</span>
								<span className="ml-1 text-[11px] text-muted-foreground group-open:hidden">
									Cliquez pour afficher
								</span>
							</summary>
							<div className="rounded-xl border border-red-200/60 bg-red-50/30 p-3">
								<div className="flex flex-wrap gap-2">
									{highlights.out_of_stock.map((med) => (
										<span
											key={med.id}
											className="inline-flex items-center gap-1.5 rounded-lg border border-red-200/80 bg-white px-2.5 py-1.5 text-[12px] font-medium text-red-800 shadow-sm"
										>
											<span className="h-1.5 w-1.5 rounded-full bg-red-400" />
											{med.designation}
										</span>
									))}
								</div>
							</div>
						</details>
					</section>
				)}

				{/* Main table */}
				<div className="animate-fade-in-up" style={{ animationDelay: "100ms" }}>
					<MedicationTable />
				</div>
			</div>
			<CartSidebar />
		</div>
	);
}
