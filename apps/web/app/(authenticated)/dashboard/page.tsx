"use client";

import { DashboardKPI } from "@/components/dashboard-kpi";
import { OperatorOrderTable } from "@/components/operator-order-table";
import { LayoutDashboard } from "lucide-react";
import { Suspense, useState } from "react";

export default function DashboardPage() {
	const [statusFilter, setStatusFilter] = useState("creee");

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
			<DashboardKPI onFilterChange={setStatusFilter} />
			<Suspense>
				<OperatorOrderTable defaultStatus={statusFilter} />
			</Suspense>
		</div>
	);
}
