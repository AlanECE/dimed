"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from "@/components/ui/table";
import { useMedications } from "@/hooks/use-medications";
import { fetchApi } from "@/lib/api";
import { Loader2, Search, Settings2, Star, StarOff } from "lucide-react";
import { useCallback, useState } from "react";
import { toast } from "sonner";

export default function AdminCataloguePage() {
	const [search, setSearch] = useState("");
	const { medications, loading, refetch } = useMedications({
		search: search || undefined,
		limit: 50,
	});
	const [toggling, setToggling] = useState<string | null>(null);

	const toggleFeatured = useCallback(
		async (id: string) => {
			setToggling(id);
			try {
				const res = await fetchApi<{ featured: boolean }>(`/medicaments/${id}/toggle-featured`, {
					method: "PATCH",
				});
				toast.success(res.featured ? "Produit mis en avant" : "Produit retiré");
				refetch();
			} catch (err) {
				toast.error(err instanceof Error ? err.message : "Erreur");
			} finally {
				setToggling(null);
			}
		},
		[refetch],
	);

	const featured = medications.filter((m) => m.featured);

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-50">
					<Settings2 className="h-5 w-5 text-amber-600" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Produits mis en avant</h2>
					<p className="text-[13px] text-muted-foreground">
						Gérez les produits affichés en haut du catalogue ({featured.length} actifs)
					</p>
				</div>
			</div>

			<div className="relative">
				<Search className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground/60" />
				<Input
					placeholder="Rechercher un médicament..."
					value={search}
					onChange={(e) => setSearch(e.target.value)}
					className="h-10 rounded-xl border-border/60 bg-card pl-10 text-sm shadow-sm"
				/>
			</div>

			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="w-16 text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Vedette
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Désignation
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Fabricant
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Stock
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								PPA
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 8 }).map((_, i) => (
								<TableRow key={`sk-${i}`} className="border-border/30">
									{Array.from({ length: 5 }).map((_, j) => (
										<TableCell key={`sk-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : medications.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={5}
									className="py-12 text-center text-[13px] text-muted-foreground"
								>
									Aucun médicament trouvé
								</TableCell>
							</TableRow>
						) : (
							medications.map((med) => (
								<TableRow
									key={med.id}
									className={`border-border/30 hover:bg-muted/40 ${med.featured ? "bg-amber-50/30" : ""}`}
								>
									<TableCell className="text-center">
										<Button
											variant="ghost"
											size="icon"
											className="h-8 w-8"
											disabled={toggling === med.id}
											onClick={() => toggleFeatured(med.id)}
										>
											{toggling === med.id ? (
												<Loader2 className="h-4 w-4 animate-spin" />
											) : med.featured ? (
												<Star className="h-4 w-4 fill-amber-400 text-amber-400" />
											) : (
												<StarOff className="h-4 w-4 text-muted-foreground/40" />
											)}
										</Button>
									</TableCell>
									<TableCell className="text-[13px] font-medium">{med.designation}</TableCell>
									<TableCell className="text-[13px] text-muted-foreground">
										{med.fabricant ?? "—"}
									</TableCell>
									<TableCell
										className={`text-center text-[13px] font-semibold tabular-nums ${
											med.stock_quantity === 0
												? "text-red-500"
												: med.stock_quantity < 10
													? "text-amber-600"
													: "text-emerald-600"
										}`}
									>
										{med.stock_quantity}
									</TableCell>
									<TableCell className="text-right text-[13px] tabular-nums">
										{med.ppa.toLocaleString("fr-FR")} DA
									</TableCell>
								</TableRow>
							))
						)}
					</TableBody>
				</Table>
			</div>
		</div>
	);
}
