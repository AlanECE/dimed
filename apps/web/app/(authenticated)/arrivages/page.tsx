"use client";

import { StatusBadge } from "@/components/status-badge";
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
import { useArrivages } from "@/hooks/use-arrivages";
import { PackagePlus } from "lucide-react";
import { useState } from "react";

export default function ArrivagesPage() {
	const today = new Date().toISOString().split("T")[0];
	const [dateFilter, setDateFilter] = useState(today);
	const { items, total, loading } = useArrivages(dateFilter);

	return (
		<div className="flex flex-col gap-8">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50">
					<PackagePlus className="h-5 w-5 text-emerald-600" />
				</div>
				<div className="flex-1">
					<h2 className="font-heading text-xl font-bold">Arrivages</h2>
					<p className="text-[13px] text-muted-foreground">Réceptions de marchandise du jour</p>
				</div>
				<Input
					type="date"
					value={dateFilter}
					onChange={(e) => setDateFilter(e.target.value)}
					className="h-9 w-44 text-[13px]"
				/>
			</div>

			<div className="animate-fade-in-up overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Désignation
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Quantité
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Lot
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Péremption
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Fournisseur
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Heure
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 5 }).map((_, i) => (
								<TableRow key={`sk-${i}`} className="border-border/30">
									{Array.from({ length: 6 }).map((_, j) => (
										<TableCell key={`sk-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : items.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={6}
									className="py-16 text-center text-[13px] text-muted-foreground"
								>
									Aucun arrivage pour cette date
								</TableCell>
							</TableRow>
						) : (
							items.map((arr) => (
								<TableRow key={arr.id} className="border-border/30 hover:bg-muted/40">
									<TableCell className="text-[13px] font-medium">{arr.designation}</TableCell>
									<TableCell className="text-center text-[13px] font-semibold tabular-nums text-emerald-700">
										+{arr.quantite}
									</TableCell>
									<TableCell className="font-mono text-[12px] text-muted-foreground">
										{arr.n_lot || "—"}
									</TableCell>
									<TableCell className="text-[13px] text-muted-foreground">
										{arr.date_peremption
											? new Date(arr.date_peremption).toLocaleDateString("fr-FR")
											: "—"}
									</TableCell>
									<TableCell className="text-[13px]">{arr.fournisseur || "—"}</TableCell>
									<TableCell className="text-[12px] text-muted-foreground">
										{new Date(arr.created_at).toLocaleTimeString("fr-FR", {
											hour: "2-digit",
											minute: "2-digit",
										})}
									</TableCell>
								</TableRow>
							))
						)}
					</TableBody>
				</Table>
				{total > 0 && (
					<div className="border-t border-border/40 bg-muted/20 px-5 py-2.5 text-[12px] text-muted-foreground">
						{total} arrivage{total > 1 ? "s" : ""}
					</div>
				)}
			</div>
		</div>
	);
}
