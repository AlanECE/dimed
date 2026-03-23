"use client";

import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useDashboardStats } from "@/hooks/use-dashboard-stats";
import { cn } from "@/lib/utils";

type KPICardConfig = {
	key: "pending" | "acceptedToday" | "totalToday";
	label: string;
	accentColor: string;
	filterValue: string;
};

const KPI_CARDS: KPICardConfig[] = [
	{ key: "pending", label: "En attente", accentColor: "border-l-[#FEF3C7]", filterValue: "creee" },
	{
		key: "acceptedToday",
		label: "Acceptées aujourd'hui",
		accentColor: "border-l-[#D1FAE5]",
		filterValue: "acceptee",
	},
	{
		key: "totalToday",
		label: "Total du jour",
		accentColor: "border-l-[#DBEAFE]",
		filterValue: "all",
	},
];

type DashboardKPIProps = {
	onFilterChange?: (status: string) => void;
};

export function DashboardKPI({ onFilterChange }: DashboardKPIProps) {
	const stats = useDashboardStats();

	return (
		<div className="grid grid-cols-3 gap-4">
			{KPI_CARDS.map((card) => (
				<button
					key={card.key}
					type="button"
					className={cn(
						"cursor-pointer rounded-lg border border-l-4 bg-card p-4 text-left shadow-sm transition-shadow hover:shadow-md",
						card.accentColor,
					)}
					onClick={() => onFilterChange?.(card.filterValue)}
					aria-label={`Filtrer par ${card.label}`}
				>
					{stats.loading ? (
						<Skeleton className="mb-1 h-8 w-16" />
					) : (
						<p className="font-heading text-[28px] font-bold tabular-nums">{stats[card.key]}</p>
					)}
					<p className="text-[13px] font-medium text-muted-foreground">{card.label}</p>
				</button>
			))}
		</div>
	);
}
