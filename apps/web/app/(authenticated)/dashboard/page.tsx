"use client";

import { DashboardKPI } from "@/components/dashboard-kpi";
import { OperatorOrderTable } from "@/components/operator-order-table";
import { Suspense, useState } from "react";

export default function DashboardPage() {
	const [statusFilter, setStatusFilter] = useState("creee");

	return (
		<div className="flex flex-col gap-6">
			<h2 className="font-heading text-2xl font-semibold">Dashboard</h2>
			<DashboardKPI onFilterChange={setStatusFilter} />
			<Suspense>
				<OperatorOrderTable defaultStatus={statusFilter} />
			</Suspense>
		</div>
	);
}
