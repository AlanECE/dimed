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
import { useFactures } from "@/hooks/use-factures";
import { API_BASE } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { ChevronLeft, ChevronRight, Download } from "lucide-react";
import { useState } from "react";
const PAGE_SIZE = 20;

export function FactureTable() {
	const { user } = useAuth();
	const [dateFrom, setDateFrom] = useState("");
	const [dateTo, setDateTo] = useState("");
	const [page, setPage] = useState(0);

	const { factures, total, loading } = useFactures({
		dateFrom: dateFrom || undefined,
		dateTo: dateTo || undefined,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
	const isPharmacien = user?.role === "pharmacien";

	return (
		<div className="flex flex-col gap-4">
			{/* Filters */}
			<div className="flex gap-3">
				<Input
					type="date"
					value={dateFrom}
					onChange={(e) => {
						setDateFrom(e.target.value);
						setPage(0);
					}}
					className="w-40 rounded-lg border-border/60 bg-card text-[13px]"
				/>
				<Input
					type="date"
					value={dateTo}
					onChange={(e) => {
						setDateTo(e.target.value);
						setPage(0);
					}}
					className="w-40 rounded-lg border-border/60 bg-card text-[13px]"
				/>
			</div>

			{/* Table */}
			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Référence
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Commande
							</TableHead>
							{!isPharmacien && (
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Pharmacien
								</TableHead>
							)}
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Date
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Montant HT
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Montant TTC
							</TableHead>
							<TableHead className="w-14" />
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 5 }).map((_, i) => (
								<TableRow key={`skel-${i}`} className="border-border/30">
									{Array.from({ length: isPharmacien ? 6 : 7 }).map((_, j) => (
										<TableCell key={`skel-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : factures.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={isPharmacien ? 6 : 7}
									className="py-16 text-center text-[13px] text-muted-foreground"
								>
									Aucune facture trouvée
								</TableCell>
							</TableRow>
						) : (
							factures.map((f) => (
								<TableRow
									key={f.id}
									className="border-border/30 transition-colors hover:bg-muted/40"
								>
									<TableCell className="font-mono text-[13px]">{f.reference_id}</TableCell>
									<TableCell className="font-mono text-[13px] text-muted-foreground">
										{f.commande_reference}
									</TableCell>
									{!isPharmacien && (
										<TableCell className="text-[13px]">{f.pharmacien_nom}</TableCell>
									)}
									<TableCell className="text-[13px] text-muted-foreground">
										{new Date(f.date_emission).toLocaleDateString("fr-FR")}
									</TableCell>
									<TableCell className="text-right text-[13px] tabular-nums">
										{f.montant_ht.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell className="text-right text-[13px] font-semibold tabular-nums">
										{f.montant_ttc.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell>
										<a
											href={`${API_BASE}/documents/facture/${f.commande_id}`}
											target="_blank"
											rel="noopener noreferrer"
										>
											<Button
												variant="ghost"
												size="icon"
												className="h-8 w-8 rounded-lg text-primary/70 hover:bg-primary/10 hover:text-primary"
												aria-label="Télécharger la facture"
											>
												<Download className="h-4 w-4" />
											</Button>
										</a>
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
