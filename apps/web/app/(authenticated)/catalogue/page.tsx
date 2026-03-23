"use client";

import { CartSidebar } from "@/components/cart-sidebar";
import { MedicationTable } from "@/components/medication-table";

export default function CataloguePage() {
	return (
		<div className="-m-6 flex h-[calc(100vh)] ">
			<div className="flex flex-1 flex-col gap-4 overflow-y-auto p-6">
				<h2 className="font-heading text-2xl font-semibold">Catalogue</h2>
				<MedicationTable />
			</div>
			<CartSidebar />
		</div>
	);
}
