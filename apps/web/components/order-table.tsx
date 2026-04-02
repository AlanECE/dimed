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
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useRouter, useSearchParams } from "next/navigation";
import { useCallback } from "react";

const PAGE_SIZE = 20;

const STATUS_OPTIONS = [
	{ value: "all", label: "Toutes" },
	{ value: "creee", label: "Créée" },
	{ value: "acceptee", label: "Acceptée" },
	{ value: "en_preparation", label: "En préparation" },
	{ value: "prete_a_livrer", label: "Prête à livrer" },
	{ value: "en_livraison", label: "En livraison" },
	{ value: "livree", label: "Livrée" },
	{ value: "annulee", label: "Annulée" },
];

export function OrderTable() {
	const router = useRouter();
	const searchParams = useSearchParams();

	const statut = searchParams.get("statut") ?? "all";
	const dateFrom = searchParams.get("date_from") ?? "";
	const dateTo = searchParams.get("date_to") ?? "";
	const page = Number(searchParams.get("page") ?? "0");

	const { orders, total, loading } = useOrders({
		statut,
		dateFrom: dateFrom || undefined,
		dateTo: dateTo || undefined,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

	const updateParam = useCallback(
		(key: string, value: string) => {
			const params = new URLSearchParams(searchParams.toString());
			if (value && value !== "all" && value !== "0") {
				params.set(key, value);
			} else {
				params.delete(key);
			}
			if (key !== "page") params.delete("page");
			router.push(`/commandes?${params.toString()}`);
		},
		[searchParams, router],
	);

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
					placeholder="Du"
				/>
				<Input
					type="date"
					value={dateTo}
					onChange={(e) => updateParam("date_to", e.target.value)}
					className="w-40 rounded-lg border-border/60 bg-card text-[13px]"
					placeholder="Au"
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
								Date
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Articles
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70 tabular-nums">
								Montant
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Statut
							</TableHead>
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
						) : orders.length === 0 ? (
							<TableRow>
								<TableCell colSpan={5} className="py-16 text-center">
									<p className="text-[13px] font-medium text-muted-foreground">Aucune commande</p>
									<p className="mt-1 text-[12px] text-muted-foreground/70">
										Vos commandes apparaîtront ici une fois passées.
									</p>
								</TableCell>
							</TableRow>
						) : (
							orders.map((order) => (
								<TableRow
									key={order.id}
									className="cursor-pointer border-border/30 transition-colors hover:bg-muted/40"
									onClick={() => router.push(`/commandes/${order.id}`)}
								>
									<TableCell className="font-mono text-[13px]">{order.reference_id}</TableCell>
									<TableCell className="text-[13px] text-muted-foreground">
										{new Date(order.created_at).toLocaleDateString("fr-FR")}
									</TableCell>
									<TableCell className="text-center text-[13px] text-muted-foreground">—</TableCell>
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
