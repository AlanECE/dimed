"use client";

import { StatusBadge } from "@/components/status-badge";
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
import { useReports } from "@/hooks/use-reports";
import { BarChart3, DollarSign, Package, Percent, ShoppingCart } from "lucide-react";
import { useState } from "react";

const PERIODS = [
	{ value: "week", label: "Cette semaine" },
	{ value: "month", label: "Ce mois" },
	{ value: "quarter", label: "Ce trimestre" },
	{ value: "year", label: "Cette année" },
];

const STATUS_LABELS: Record<string, string> = {
	creee: "Créée",
	acceptee: "Acceptée",
	en_preparation: "En préparation",
	en_verification: "En vérification",
	prete: "Prête",
	en_route: "En route",
	livree: "Livrée",
	annulee: "Annulée",
	refusee: "Refusée",
};

export default function RapportsPage() {
	const [period, setPeriod] = useState("month");
	const { stats, loading } = useReports(period);

	const kpis = [
		{
			label: "Chiffre d'affaires",
			value: stats ? `${stats.total_revenue.toLocaleString("fr-FR")} DA` : "—",
			icon: DollarSign,
			iconBg: "bg-emerald-50 text-emerald-600",
			gradient: "from-emerald-500 to-teal-500",
		},
		{
			label: "Commandes",
			value: stats?.order_count.toLocaleString("fr-FR") ?? "—",
			icon: ShoppingCart,
			iconBg: "bg-blue-50 text-blue-600",
			gradient: "from-blue-500 to-indigo-500",
		},
		{
			label: "Panier moyen",
			value: stats ? `${stats.avg_order_value.toLocaleString("fr-FR")} DA` : "—",
			icon: Package,
			iconBg: "bg-violet-50 text-violet-600",
			gradient: "from-violet-500 to-purple-500",
		},
		{
			label: "Taux de livraison",
			value: stats ? `${stats.delivery_rate}%` : "—",
			icon: Percent,
			iconBg: "bg-amber-50 text-amber-600",
			gradient: "from-amber-500 to-orange-500",
		},
		{
			label: "Remises accordées",
			value: stats ? `${(stats.total_remises ?? 0).toLocaleString("fr-FR")} DA` : "—",
			icon: Percent,
			iconBg: "bg-rose-50 text-rose-600",
			gradient: "from-rose-500 to-pink-500",
		},
	];

	const maxStatusCount = stats ? Math.max(...Object.values(stats.status_breakdown), 1) : 1;

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center justify-between">
				<div className="flex items-center gap-3">
					<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10">
						<BarChart3 className="h-5 w-5 text-primary" />
					</div>
					<div>
						<h2 className="font-heading text-xl font-bold">Rapports</h2>
						<p className="text-[13px] text-muted-foreground">
							Analyses et indicateurs de performance
						</p>
					</div>
				</div>
				<Select value={period} onValueChange={(v) => setPeriod(v ?? "month")}>
					<SelectTrigger className="w-44 rounded-lg border-border/60 bg-card text-[13px]">
						<SelectValue />
					</SelectTrigger>
					<SelectContent>
						{PERIODS.map((p) => (
							<SelectItem key={p.value} value={p.value}>
								{p.label}
							</SelectItem>
						))}
					</SelectContent>
				</Select>
			</div>

			{/* KPI Row */}
			<div className="grid grid-cols-2 gap-5 xl:grid-cols-5">
				{kpis.map((kpi, i) => (
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
									<Skeleton className="mb-2 h-8 w-24" />
								) : (
									<p className="font-heading text-2xl font-extrabold tabular-nums">{kpi.value}</p>
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

			{/* Two columns: Status breakdown + Top products */}
			<div className="grid gap-6 lg:grid-cols-2">
				{/* Status breakdown */}
				<div className="animate-fade-in-up delay-200 rounded-xl border border-border/60 bg-card p-5 shadow-sm">
					<h3 className="mb-4 font-heading text-[15px] font-bold">Répartition par statut</h3>
					{loading ? (
						<div className="space-y-3">
							{Array.from({ length: 5 }).map((_, i) => (
								<Skeleton key={`sk-${i}`} className="h-6 w-full" />
							))}
						</div>
					) : stats && Object.keys(stats.status_breakdown).length > 0 ? (
						<div className="space-y-3">
							{Object.entries(stats.status_breakdown)
								.sort(([, a], [, b]) => b - a)
								.map(([status, count]) => (
									<div key={status} className="flex items-center gap-3">
										<div className="w-28 shrink-0">
											<StatusBadge status={status} />
										</div>
										<div className="flex-1">
											<div className="h-6 overflow-hidden rounded-full bg-muted/50">
												<div
													className="h-full rounded-full bg-primary transition-all"
													style={{
														width: `${(count / maxStatusCount) * 100}%`,
													}}
												/>
											</div>
										</div>
										<span className="w-10 text-right text-[13px] font-semibold tabular-nums">
											{count}
										</span>
									</div>
								))}
						</div>
					) : (
						<p className="py-8 text-center text-[13px] text-muted-foreground">Aucune donnée</p>
					)}
				</div>

				{/* Top products */}
				<div className="animate-fade-in-up delay-300 rounded-xl border border-border/60 bg-card shadow-sm">
					<h3 className="p-5 pb-0 font-heading text-[15px] font-bold">Top 10 produits</h3>
					<Table>
						<TableHeader>
							<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Désignation
								</TableHead>
								<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Quantité
								</TableHead>
								<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Montant
								</TableHead>
							</TableRow>
						</TableHeader>
						<TableBody>
							{loading ? (
								Array.from({ length: 5 }).map((_, i) => (
									<TableRow key={`sk-${i}`} className="border-border/30">
										{Array.from({ length: 3 }).map((_, j) => (
											<TableCell key={`sk-${i}-${j}`}>
												<Skeleton className="h-4 w-full" />
											</TableCell>
										))}
									</TableRow>
								))
							) : stats && stats.top_products.length > 0 ? (
								stats.top_products.map((p, i) => (
									<TableRow key={p.designation} className="border-border/30 hover:bg-muted/40">
										<TableCell className="text-[13px]">
											<span className="mr-2 inline-flex h-5 w-5 items-center justify-center rounded-full bg-muted text-[10px] font-bold text-muted-foreground">
												{i + 1}
											</span>
											{p.designation}
										</TableCell>
										<TableCell className="text-right text-[13px] tabular-nums">
											{p.total_qty.toLocaleString("fr-FR")}
										</TableCell>
										<TableCell className="text-right text-[13px] font-semibold tabular-nums">
											{p.total_amount.toLocaleString("fr-FR")} DA
										</TableCell>
									</TableRow>
								))
							) : (
								<TableRow>
									<TableCell
										colSpan={3}
										className="py-8 text-center text-[13px] text-muted-foreground"
									>
										Aucune donnée
									</TableCell>
								</TableRow>
							)}
						</TableBody>
					</Table>
				</div>
			</div>
		</div>
	);
}
