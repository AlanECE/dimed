"use client";

import { StatusBadge } from "@/components/status-badge";
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
import { useOrders } from "@/hooks/use-orders";
import type { OrderResponse } from "@/lib/types";
import { cn } from "@/lib/utils";
import { ArrowDown, ArrowUp, ArrowUpDown, ChevronLeft, ChevronRight } from "lucide-react";
import { useRouter, useSearchParams } from "next/navigation";
import { useCallback, useMemo, useState } from "react";

const PAGE_SIZE = 20;

// Les valeurs correspondent exactement à l'enum OrderStatus du backend.
const STATUS_OPTIONS = [
	{ value: "all", label: "Toutes" },
	{ value: "creee", label: "Créée" },
	{ value: "acceptee", label: "Acceptée" },
	{ value: "en_preparation", label: "En préparation" },
	{ value: "prelevee_partiellement", label: "Prélevée partiellement" },
	{ value: "en_verification", label: "En vérification" },
	{ value: "prete", label: "Prête à livrer" },
	{ value: "en_route", label: "En livraison" },
	{ value: "livree", label: "Livrée" },
	{ value: "livree_partiellement", label: "Livrée partiellement" },
	{ value: "refusee", label: "Refusée" },
	{ value: "retournee", label: "Retournée" },
	{ value: "annulee", label: "Annulée" },
];

type SortKey = "reference_id" | "pharmacien_nom" | "created_at" | "montant_total" | "statut";
type SortDir = "asc" | "desc";

type OperatorOrderTableProps = {
	defaultStatus?: string;
};

export function OperatorOrderTable({ defaultStatus }: OperatorOrderTableProps) {
	const router = useRouter();
	const searchParams = useSearchParams();

	// L'URL prime : le Select et les cartes KPI écrivent tous deux ?statut=.
	const statut = searchParams.get("statut") ?? defaultStatus ?? "all";
	const dateFrom = searchParams.get("date_from") ?? "";
	const dateTo = searchParams.get("date_to") ?? "";
	const page = Number(searchParams.get("page") ?? "0");

	const [sortKey, setSortKey] = useState<SortKey>("created_at");
	const [sortDir, setSortDir] = useState<SortDir>("desc");

	const { orders, total, loading } = useOrders({
		statut,
		dateFrom: dateFrom || undefined,
		dateTo: dateTo || undefined,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

	const sorted = useMemo(() => {
		return [...orders].sort((a, b) => {
			const valA = a[sortKey] ?? "";
			const valB = b[sortKey] ?? "";
			const cmp =
				typeof valA === "number"
					? valA - (valB as number)
					: String(valA).localeCompare(String(valB));
			return sortDir === "asc" ? cmp : -cmp;
		});
	}, [orders, sortKey, sortDir]);

	const toggleSort = useCallback(
		(key: SortKey) => {
			if (sortKey === key) {
				setSortDir((d) => (d === "asc" ? "desc" : "asc"));
			} else {
				setSortKey(key);
				setSortDir("asc");
			}
		},
		[sortKey],
	);

	const updateParam = useCallback(
		(key: string, value: string) => {
			const params = new URLSearchParams(searchParams.toString());
			if (value && value !== "all" && value !== "0") {
				params.set(key, value);
			} else {
				params.delete(key);
			}
			if (key !== "page") params.delete("page");
			router.push(`/dashboard?${params.toString()}`);
		},
		[searchParams, router],
	);

	function SortIcon({ col }: { col: SortKey }) {
		if (sortKey !== col)
			return <ArrowUpDown className="ml-1 h-3 w-3 opacity-0 group-hover:opacity-50" />;
		return sortDir === "asc" ? (
			<ArrowUp className="ml-1 h-3 w-3" />
		) : (
			<ArrowDown className="ml-1 h-3 w-3" />
		);
	}

	return (
		<div className="flex flex-col gap-4">
			{/* Filters */}
			<div className="flex gap-3">
				<Select value={statut} onValueChange={(v) => updateParam("statut", v ?? "all")}>
					<SelectTrigger className="w-48 rounded-lg border-border/60 bg-card text-[13px]">
						<SelectValue placeholder="Statut" />
					</SelectTrigger>
					<SelectContent>
						{STATUS_OPTIONS.map((opt) => (
							<SelectItem key={opt.value} value={opt.value}>
								{opt.label}
							</SelectItem>
						))}
					</SelectContent>
				</Select>
				<Input
					type="date"
					value={dateFrom}
					onChange={(e) => updateParam("date_from", e.target.value)}
					className="w-40 rounded-lg border-border/60 bg-card text-[13px]"
				/>
				<Input
					type="date"
					value={dateTo}
					onChange={(e) => updateParam("date_to", e.target.value)}
					className="w-40 rounded-lg border-border/60 bg-card text-[13px]"
				/>
			</div>

			{/* Table */}
			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							{(
								[
									["reference_id", "Référence"],
									["pharmacien_nom", "Pharmacien"],
									["created_at", "Date & heure"],
									["montant_total", "Montant"],
									["statut", "Statut"],
								] as [SortKey, string][]
							).map(([key, label]) => (
								<TableHead
									key={key}
									className={cn(
										"group cursor-pointer select-none text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70",
										key === "montant_total" && "text-right tabular-nums",
									)}
									onClick={() => toggleSort(key)}
									aria-label={`Trier par ${label}`}
								>
									<span className="inline-flex items-center">
										{label}
										<SortIcon col={key} />
									</span>
								</TableHead>
							))}
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 6 }).map((_, i) => (
								<TableRow key={i} className="border-border/30">
									{Array.from({ length: 5 }).map((_, j) => (
										<TableCell key={j}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : sorted.length === 0 ? (
							<TableRow>
								<TableCell colSpan={5} className="py-16 text-center">
									<p className="text-[13px] font-medium text-muted-foreground">
										Aucune commande en attente
									</p>
								</TableCell>
							</TableRow>
						) : (
							sorted.map((order) => (
								<TableRow
									key={order.id}
									className="cursor-pointer border-border/30 transition-colors hover:bg-muted/40"
									onClick={() => router.push(`/dashboard/commandes/${order.id}`)}
								>
									<TableCell className="font-mono text-[13px]">{order.reference_id}</TableCell>
									<TableCell className="text-[13px]">{order.pharmacien_nom ?? "—"}</TableCell>
									<TableCell className="text-[13px] text-muted-foreground tabular-nums">
										{new Date(order.created_at).toLocaleString("fr-FR", {
											day: "2-digit",
											month: "2-digit",
											year: "numeric",
											hour: "2-digit",
											minute: "2-digit",
										})}
									</TableCell>
									<TableCell className="text-right text-[13px] font-semibold tabular-nums">
										{order.montant_total.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell>
										<StatusBadge status={order.statut} />
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
						onClick={() => updateParam("page", String(page - 1))}
						className="h-8 rounded-lg border-border/60 px-3 text-[12px]"
					>
						<ChevronLeft className="mr-1 h-3.5 w-3.5" />
						Précédent
					</Button>
					<Button
						variant="outline"
						size="sm"
						disabled={page >= totalPages - 1}
						onClick={() => updateParam("page", String(page + 1))}
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
