"use client";

import { DashboardKPI } from "@/components/dashboard-kpi";
import { OperatorOrderTable } from "@/components/operator-order-table";
import { LayoutDashboard } from "lucide-react";
import { useRouter } from "next/navigation";
import { Suspense } from "react";

export default function DashboardPage() {
	const router = useRouter();

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10">
					<LayoutDashboard className="h-5 w-5 text-primary" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Dashboard</h2>
					<p className="text-[13px] text-muted-foreground">Vue d'ensemble des opérations</p>
				</div>
			</div>
			{/* Le filtre est piloté par l'URL : les KPI et le Select modifient le même paramètre. */}
			<DashboardKPI
				onFilterChange={(status) =>
					router.push(status === "all" ? "/dashboard" : `/dashboard?statut=${status}`)
				}
			/>
			<Suspense>
				<OperatorOrderTable />
			</Suspense>
		</div>
	);
}
