"use client";

import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
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
import { useCreances } from "@/hooks/use-creances";
import { useAuth } from "@/lib/auth";
import { AlertTriangle, ChevronLeft, ChevronRight, TrendingDown, Wallet } from "lucide-react";
import { useState } from "react";

const PAGE_SIZE = 20;

const STATUT_OPTIONS = [
	{ value: "all", label: "Toutes" },
	{ value: "en_attente", label: "En attente" },
	{ value: "partiel", label: "Partiel" },
	{ value: "en_retard", label: "En retard" },
	{ value: "soldee", label: "Soldée" },
];

export default function CreancesPage() {
	const { user } = useAuth();
	const [statut, setStatut] = useState("all");
	const [page, setPage] = useState(0);
	const isPharmacien = user?.role === "pharmacien";

	const { creances, total, summary, loading } = useCreances({
		statut,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

	const totalCreances = summary.total_montant;
	const totalEnRetard = summary.total_en_retard;
	const totalPaye = summary.total_paye;

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-violet-50">
					<Wallet className="h-5 w-5 text-violet-600" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Créances & Paiements</h2>
					<p className="text-[13px] text-muted-foreground">Suivi des paiements et échéanciers</p>
				</div>
			</div>

			{/* KPI Cards */}
			<div className="grid grid-cols-3 gap-5">
				{[
					{
						label: "Total créances",
						value: totalCreances,
						icon: Wallet,
						iconBg: "bg-violet-50 text-violet-600",
						gradient: "from-violet-500 to-purple-500",
					},
					{
						label: "En retard",
						value: totalEnRetard,
						icon: AlertTriangle,
						iconBg: "bg-red-50 text-red-600",
						gradient: "from-red-500 to-orange-500",
					},
					{
						label: "Encaissé",
						value: totalPaye,
						icon: TrendingDown,
						iconBg: "bg-emerald-50 text-emerald-600",
						gradient: "from-emerald-500 to-teal-500",
					},
				].map((kpi, i) => (
					<div
						key={kpi.label}
						className="animate-fade-in-up relative overflow-hidden rounded-xl border border-border/60 bg-card p-5 shadow-sm"
						style={{ animationDelay: `${i * 100}ms` }}
					>
						<div
							className={`absolute left-0 top-0 h-full w-1 rounded-l-xl bg-gradient-to-b ${kpi.gradient}`}
						/>
						<div className="flex items-start justify-between pl-2">
							<div>
								{loading ? (
									<Skeleton className="mb-2 h-9 w-20" />
								) : (
									<p className="font-heading text-2xl font-extrabold tabular-nums">
										{kpi.value.toLocaleString("fr-FR")} DA
									</p>
								)}
								<p className="mt-1 text-[13px] font-medium text-muted-foreground">{kpi.label}</p>
							</div>
							<div
								className={`flex h-10 w-10 items-center justify-center rounded-xl ${kpi.iconBg}`}
							>
								<kpi.icon className="h-5 w-5" />
							</div>
						</div>
					</div>
				))}
			</div>

			{/* Filter */}
			<div className="flex gap-3">
				<Select
					value={statut}
					onValueChange={(v) => {
						setStatut(v ?? "all");
						setPage(0);
					}}
				>
					<SelectTrigger className="w-48 rounded-lg border-border/60 bg-card text-[13px]">
						<SelectValue placeholder="Statut" />
					</SelectTrigger>
					<SelectContent>
						{STATUT_OPTIONS.map((opt) => (
							<SelectItem key={opt.value} value={opt.value}>
								{opt.label}
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
								Facture
							</TableHead>
							{!isPharmacien && (
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Pharmacien
								</TableHead>
							)}
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Montant
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Payé
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Reste
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Échéance
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Statut
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 5 }).map((_, i) => (
								<TableRow key={`sk-${i}`} className="border-border/30">
									{Array.from({ length: isPharmacien ? 6 : 7 }).map((_, j) => (
										<TableCell key={`sk-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : creances.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={isPharmacien ? 6 : 7}
									className="py-16 text-center text-[13px] text-muted-foreground"
								>
									Aucune créance
								</TableCell>
							</TableRow>
						) : (
							creances.map((c) => (
								<TableRow
									key={c.id}
									className="border-border/30 transition-colors hover:bg-muted/40"
								>
									<TableCell className="font-mono text-[13px]">{c.facture_reference}</TableCell>
									{!isPharmacien && (
										<TableCell className="text-[13px]">{c.pharmacien_nom}</TableCell>
									)}
									<TableCell className="text-right text-[13px] tabular-nums">
										{c.montant_total.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell className="text-right text-[13px] tabular-nums text-emerald-600">
										{c.montant_paye.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell className="text-right text-[13px] font-semibold tabular-nums">
										{c.reste_a_payer.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell className="text-[13px] text-muted-foreground">
										{new Date(c.echeance).toLocaleDateString("fr-FR")}
									</TableCell>
									<TableCell>
										<StatusBadge status={c.statut} />
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
