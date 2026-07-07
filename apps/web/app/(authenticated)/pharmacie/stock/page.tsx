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
import { fetchApi } from "@/lib/api";
import { Boxes, ChevronLeft, ChevronRight, Search } from "lucide-react";
import { useEffect, useState } from "react";

const PAGE_SIZE = 50;

type StockItem = {
	id: string;
	designation: string;
	quantite: number;
	ppa: number | null;
	updated_at: string;
};

export default function StockPharmaciePage() {
	const [search, setSearch] = useState("");
	const [debouncedSearch, setDebouncedSearch] = useState("");
	const [page, setPage] = useState(0);
	const [items, setItems] = useState<StockItem[]>([]);
	const [total, setTotal] = useState(0);
	const [loading, setLoading] = useState(true);

	// Debounce de la recherche (300 ms)
	useEffect(() => {
		const id = setTimeout(() => {
			setDebouncedSearch(search.trim());
			setPage(0);
		}, 300);
		return () => clearTimeout(id);
	}, [search]);

	useEffect(() => {
		let aborted = false;
		setLoading(true);
		fetchApi<{ items: StockItem[]; total: number }>("/pharmacie/stock", {
			params: {
				search: debouncedSearch || undefined,
				limit: PAGE_SIZE,
				offset: page * PAGE_SIZE,
			},
		})
			.then((data) => {
				if (aborted) return;
				setItems(data.items);
				setTotal(data.total);
			})
			.catch(() => {
				if (aborted) return;
				setItems([]);
				setTotal(0);
			})
			.finally(() => {
				if (!aborted) setLoading(false);
			});
		return () => {
			aborted = true;
		};
	}, [debouncedSearch, page]);

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
	const totalUnites = items.reduce((sum, s) => sum + s.quantite, 0);

	return (
		<div className="flex flex-col gap-6">
			{/* Header */}
			<div className="flex items-center justify-between">
				<div className="flex items-center gap-3">
					<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-teal-50">
						<Boxes className="h-5 w-5 text-teal-600" />
					</div>
					<div>
						<h2 className="font-heading text-xl font-bold">Stock</h2>
						<p className="text-[13px] text-muted-foreground">
							Votre stock officine, mis à jour à chaque arrivage
						</p>
					</div>
				</div>
				<div className="rounded-xl border border-border/60 bg-card px-4 py-2 text-right shadow-sm">
					<p className="text-[20px] font-bold tabular-nums leading-tight">{total}</p>
					<p className="text-[11px] text-muted-foreground">référence{total > 1 ? "s" : ""}</p>
				</div>
			</div>

			{/* Search */}
			<div className="relative w-72">
				<Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
				<Input
					value={search}
					onChange={(e) => setSearch(e.target.value)}
					placeholder="Rechercher un produit..."
					className="pl-9 text-[13px]"
				/>
			</div>

			{/* Table */}
			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Désignation
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Quantité
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								PPA
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Dernière mise à jour
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							["s1", "s2", "s3", "s4", "s5"].map((k) => (
								<TableRow key={k} className="border-border/30">
									{["c1", "c2", "c3", "c4"].map((c) => (
										<TableCell key={`${k}-${c}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : items.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={4}
									className="py-16 text-center text-[13px] text-muted-foreground"
								>
									{debouncedSearch
										? "Aucun produit ne correspond à la recherche"
										: "Stock vide — enregistrez un arrivage pour commencer"}
								</TableCell>
							</TableRow>
						) : (
							items.map((s) => (
								<TableRow key={s.id} className="border-border/30 hover:bg-muted/40">
									<TableCell className="text-[13px] font-medium">{s.designation}</TableCell>
									<TableCell className="text-center">
										<span
											className={`inline-flex min-w-10 items-center justify-center rounded-md px-2 py-0.5 text-[13px] font-bold tabular-nums ${
												s.quantite === 0
													? "bg-red-100 text-red-700"
													: s.quantite < 10
														? "bg-amber-100 text-amber-700"
														: "bg-emerald-100 text-emerald-700"
											}`}
										>
											{s.quantite}
										</span>
									</TableCell>
									<TableCell className="text-right font-mono text-[13px] tabular-nums">
										{s.ppa !== null ? `${s.ppa.toLocaleString("fr-FR")} DA` : "—"}
									</TableCell>
									<TableCell className="text-right text-[13px] text-muted-foreground">
										{new Date(s.updated_at).toLocaleString("fr-FR", {
											day: "2-digit",
											month: "2-digit",
											year: "numeric",
											hour: "2-digit",
											minute: "2-digit",
										})}
									</TableCell>
								</TableRow>
							))
						)}
					</TableBody>
				</Table>
			</div>

			{/* Footer : pagination + total page */}
			<div className="flex items-center justify-between">
				<span className="text-[13px] text-muted-foreground">
					Page {page + 1} sur {totalPages}
					{items.length > 0 && ` — ${totalUnites.toLocaleString("fr-FR")} unités sur cette page`}
				</span>
				<div className="flex gap-1.5">
					<Button
						variant="outline"
						size="sm"
						disabled={page === 0}
						onClick={() => setPage((p) => p - 1)}
						className="h-8 rounded-lg border-border/60 px-3 text-[12px]"
					>
						<ChevronLeft className="mr-1 h-3.5 w-3.5" />
						Précédent
					</Button>
					<Button
						variant="outline"
						size="sm"
						disabled={page >= totalPages - 1}
						onClick={() => setPage((p) => p + 1)}
						className="h-8 rounded-lg border-border/60 px-3 text-[12px]"
					>
						Suivant
						<ChevronRight className="ml-1 h-3.5 w-3.5" />
					</Button>
				</div>
			</div>
		</div>
	);
}
