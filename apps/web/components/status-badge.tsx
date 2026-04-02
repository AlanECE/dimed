"use client";

import { Badge } from "@/components/ui/badge";

const STATUS_CONFIG: Record<string, { label: string; className: string; dotColor: string }> = {
	creee: {
		label: "Créée",
		className: "bg-amber-50 text-amber-700 border-amber-200/80",
		dotColor: "#D97706",
	},
	acceptee: {
		label: "Acceptée",
		className: "bg-emerald-50 text-emerald-700 border-emerald-200/80",
		dotColor: "#059669",
	},
	en_preparation: {
		label: "En préparation",
		className: "bg-blue-50 text-blue-700 border-blue-200/80",
		dotColor: "#2563EB",
	},
	prelevee_partiellement: {
		label: "Prélèvement partiel",
		className: "bg-yellow-50 text-yellow-700 border-yellow-200/80",
		dotColor: "#CA8A04",
	},
	en_verification: {
		label: "En vérification",
		className: "bg-indigo-50 text-indigo-700 border-indigo-200/80",
		dotColor: "#4F46E5",
	},
	prete: {
		label: "Prête",
		className: "bg-violet-50 text-violet-700 border-violet-200/80",
		dotColor: "#7C3AED",
	},
	en_route: {
		label: "En route",
		className: "bg-orange-50 text-orange-700 border-orange-200/80",
		dotColor: "#EA580C",
	},
	livree: {
		label: "Livrée",
		className: "bg-teal-50 text-teal-700 border-teal-200/80",
		dotColor: "#0D9488",
	},
	livree_partiellement: {
		label: "Livrée partiellement",
		className: "bg-lime-50 text-lime-700 border-lime-200/80",
		dotColor: "#65A30D",
	},
	refusee: {
		label: "Refusée",
		className: "bg-red-50 text-red-700 border-red-200/80",
		dotColor: "#DC2626",
	},
	retournee: {
		label: "Retournée",
		className: "bg-orange-50 text-orange-800 border-orange-200/80",
		dotColor: "#C2410C",
	},
	annulee: {
		label: "Annulée",
		className: "bg-gray-50 text-gray-600 border-gray-200/80",
		dotColor: "#6B7280",
	},
	en_attente: {
		label: "En attente",
		className: "bg-amber-50 text-amber-700 border-amber-200/80",
		dotColor: "#D97706",
	},
	partiel: {
		label: "Partiel",
		className: "bg-blue-50 text-blue-700 border-blue-200/80",
		dotColor: "#2563EB",
	},
	soldee: {
		label: "Soldée",
		className: "bg-teal-50 text-teal-700 border-teal-200/80",
		dotColor: "#0D9488",
	},
	en_retard: {
		label: "En retard",
		className: "bg-red-50 text-red-700 border-red-200/80",
		dotColor: "#DC2626",
	},
	ouverte: {
		label: "Ouverte",
		className: "bg-amber-50 text-amber-700 border-amber-200/80",
		dotColor: "#D97706",
	},
	en_cours: {
		label: "En cours",
		className: "bg-blue-50 text-blue-700 border-blue-200/80",
		dotColor: "#2563EB",
	},
	resolue: {
		label: "Résolue",
		className: "bg-teal-50 text-teal-700 border-teal-200/80",
		dotColor: "#0D9488",
	},
	rejetee: {
		label: "Rejetée",
		className: "bg-red-50 text-red-700 border-red-200/80",
		dotColor: "#DC2626",
	},
};

export function StatusBadge({ status }: { status: string }) {
	const config = STATUS_CONFIG[status];

	if (!config) {
		return <Badge variant="outline">{status}</Badge>;
	}

	return (
		<Badge
			variant="outline"
			className={`gap-1.5 rounded-full px-2.5 py-0.5 text-[11px] font-semibold ${config.className}`}
		>
			<span
				className="inline-block h-1.5 w-1.5 rounded-full"
				style={{ backgroundColor: config.dotColor }}
			/>
			{config.label}
		</Badge>
	);
}
