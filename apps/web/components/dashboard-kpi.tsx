"use client";

import { Skeleton } from "@/components/ui/skeleton";
import { useDashboardStats } from "@/hooks/use-dashboard-stats";
import { cn } from "@/lib/utils";
import { Clock, PackageCheck, TrendingUp } from "lucide-react";
import type { LucideIcon } from "lucide-react";

type KPICardConfig = {
	key: "pending" | "acceptedToday" | "totalToday";
	label: string;
	icon: LucideIcon;
	iconBg: string;
	filterValue: string;
};

const KPI_CARDS: KPICardConfig[] = [
	{
		key: "pending",
		label: "En attente",
		icon: Clock,
		iconBg: "bg-amber-50 text-amber-600",
		filterValue: "creee",
	},
	{
		key: "acceptedToday",
		label: "Acceptées aujourd'hui",
		icon: PackageCheck,
		iconBg: "bg-emerald-50 text-emerald-600",
		filterValue: "acceptee",
	},
	{
		key: "totalToday",
		label: "Total du jour",
		icon: TrendingUp,
		iconBg: "bg-teal-50 text-teal-600",
		filterValue: "all",
	},
];

type DashboardKPIProps = {
	onFilterChange?: (status: string) => void;
};

export function DashboardKPI({ onFilterChange }: DashboardKPIProps) {
	const stats = useDashboardStats();

	return (
		<div className="grid grid-cols-3 gap-5">
			{KPI_CARDS.map((card, i) => (
				<button
					key={card.key}
					type="button"
					className={cn(
						"animate-fade-in-up group relative overflow-hidden rounded-xl border-2 border-border/60 bg-transparent p-5 text-left transition-all duration-200 hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-md",
					)}
					style={{ animationDelay: `${i * 100}ms` }}
					onClick={() => onFilterChange?.(card.filterValue)}
					aria-label={`Filtrer par ${card.label}`}
				>
					<div className="flex items-start justify-between">
						<div>
							{stats.loading ? (
								<Skeleton className="mb-2 h-9 w-16" />
							) : (
								<p className="animate-count-up font-heading text-3xl font-extrabold tabular-nums text-foreground">
									{stats[card.key]}
								</p>
							)}
							<p className="mt-1 text-[13px] font-medium text-muted-foreground">{card.label}</p>
						</div>
						<div
							className={`flex h-10 w-10 items-center justify-center rounded-xl ${card.iconBg} transition-transform group-hover:scale-110`}
						>
							<card.icon className="h-5 w-5" />
						</div>
					</div>
				</button>
			))}
		</div>
	);
}
