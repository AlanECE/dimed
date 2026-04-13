"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";
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
import { useCart } from "@/lib/cart";
import { ChevronLeft, ChevronRight, Plus, Search } from "lucide-react";
import { useMemo, useState } from "react";

const PAGE_SIZE = 20;

export function MedicationTable() {
	const [searchTerm, setSearchTerm] = useState("");
	const [formeFilter, setFormeFilter] = useState<string>("all");
	const [fabricantFilter, setFabricantFilter] = useState<string>("all");
	const [page, setPage] = useState(0);

	const { medications, total, loading } = useMedications({
		search: searchTerm || undefined,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});

	const { addItem } = useCart();

	const formes = useMemo(() => {
		const set = new Set(medications.map((m) => m.forme).filter(Boolean));
		return Array.from(set).sort() as string[];
	}, [medications]);

	const fabricants = useMemo(() => {
		const set = new Set(medications.map((m) => m.fabricant).filter(Boolean));
		return Array.from(set).sort() as string[];
	}, [medications]);

	const filtered = useMemo(() => {
		return medications.filter((m) => {
			if (formeFilter !== "all" && m.forme !== formeFilter) return false;
			if (fabricantFilter !== "all" && m.fabricant !== fabricantFilter) return false;
			return true;
		});
	}, [medications, formeFilter, fabricantFilter]);

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

	return (
		<div className="flex flex-1 flex-col gap-4">
			{/* Search */}
			<div className="relative">
				<Search className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground/60" />
				<Input
					placeholder="Rechercher un médicament..."
					value={searchTerm}
					onChange={(e) => {
						setSearchTerm(e.target.value);
						setPage(0);
					}}
					className="h-11 rounded-xl border-border/60 bg-card pl-10 text-sm shadow-sm transition-all focus:border-primary/30 focus:shadow-md focus:shadow-primary/5"
				/>
			</div>

			{/* Filters */}
			<div className="flex gap-3">
				<Select value={formeFilter} onValueChange={(v) => setFormeFilter(v ?? "all")}>
					<SelectTrigger className="w-48 rounded-lg border-border/60 bg-card text-[13px]">
						<SelectValue placeholder="Forme" />
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="all">Toutes les formes</SelectItem>
						{formes.map((f) => (
							<SelectItem key={f} value={f}>
								{f}
							</SelectItem>
						))}
					</SelectContent>
				</Select>

				<Select value={fabricantFilter} onValueChange={(v) => setFabricantFilter(v ?? "all")}>
					<SelectTrigger className="w-48 rounded-lg border-border/60 bg-card text-[13px]">
						<SelectValue placeholder="Fabricant" />
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="all">Tous les fabricants</SelectItem>
						{fabricants.map((f) => (
							<SelectItem key={f} value={f}>
								{f}
							</SelectItem>
						))}
					</SelectContent>
				</Select>
			</div>

			{/* Table */}
			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Désignation
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								DCI
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Dosage
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Forme
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70 tabular-nums">
								PPA
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Fabricant
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Stock
							</TableHead>
							<TableHead className="w-14" />
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 6 }).map((_, i) => (
								<TableRow key={`skeleton-${i}`} className="border-border/30">
									{Array.from({ length: 8 }).map((_, j) => (
										<TableCell key={`cell-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : filtered.length === 0 ? (
							<TableRow>
								<TableCell colSpan={8} className="py-12 text-center">
									<p className="text-[13px] font-medium text-muted-foreground">
										Aucun médicament trouvé
									</p>
								</TableCell>
							</TableRow>
						) : (
							filtered.map((med, i) => (
								<TableRow
									key={med.id}
									className="animate-fade-in border-border/30 transition-colors hover:bg-muted/40"
									style={{ animationDelay: `${i * 20}ms` }}
								>
									<TableCell className="text-[13px] font-semibold">{med.designation}</TableCell>
									<TableCell className="text-[13px] text-muted-foreground">
										{med.dci ?? "—"}
									</TableCell>
									<TableCell className="text-[13px] text-muted-foreground">
										{med.dosage ?? "—"}
									</TableCell>
									<TableCell className="text-[13px] text-muted-foreground">
										{med.forme ?? "—"}
									</TableCell>
									<TableCell className="text-right text-[13px] font-semibold tabular-nums">
										{med.ppa.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell className="text-[13px] text-muted-foreground">
										{med.fabricant ?? "—"}
									</TableCell>
									<TableCell
										className={`text-center text-[13px] font-semibold tabular-nums ${med.stock_quantity === 0 ? "text-red-500" : med.stock_quantity < 10 ? "text-amber-600" : "text-emerald-600"}`}
									>
										{med.stock_quantity}
									</TableCell>
									<TableCell>
										<Button
											variant="ghost"
											size="icon"
											className="h-8 w-8 rounded-lg text-primary/70 hover:bg-primary/10 hover:text-primary"
											onClick={() => addItem(med)}
											disabled={med.stock_quantity === 0}
											title={
												med.stock_quantity === 0
													? "Produit en rupture de stock"
													: `Ajouter ${med.designation}`
											}
											aria-label={`Ajouter ${med.designation}`}
										>
											<Plus className="h-4 w-4" />
										</Button>
									</TableCell>
								</TableRow>
							))
						)}
					</TableBody>
				</Table>
			</div>

			{/* Pagination */}
			<div className="flex items-center justify-between">
				<span className="text-[13px] text-muted-foreground">
					Page {page + 1} sur {totalPages}
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
