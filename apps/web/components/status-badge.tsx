"use client";

import { Badge } from "@/components/ui/badge";

const STATUS_CONFIG: Record<string, { label: string; className: string }> = {
	creee: { label: "Créée", className: "bg-[#FEF3C7] text-[#92400E] border-[#FDE68A]" },
	acceptee: { label: "Acceptée", className: "bg-[#D1FAE5] text-[#065F46] border-[#A7F3D0]" },
	en_preparation: {
		label: "En préparation",
		className: "bg-[#DBEAFE] text-[#1E40AF] border-[#BFDBFE]",
	},
	prete_a_livrer: {
		label: "Prête à livrer",
		className: "bg-[#E0E7FF] text-[#3730A3] border-[#C7D2FE]",
	},
	en_livraison: {
		label: "En livraison",
		className: "bg-[#FED7AA] text-[#9A3412] border-[#FDBA74]",
	},
	livree: { label: "Livrée", className: "bg-[#BBF7D0] text-[#14532D] border-[#86EFAC]" },
	annulee: { label: "Annulée", className: "bg-[#FEE2E2] text-[#991B1B] border-[#FECACA]" },
};

export function StatusBadge({ status }: { status: string }) {
	const config = STATUS_CONFIG[status];

	if (!config) {
		return <Badge variant="outline">{status}</Badge>;
	}

	return (
		<Badge variant="outline" className={config.className}>
			<span
				className="mr-1.5 inline-block h-2 w-2 rounded-full"
				style={{ backgroundColor: "currentColor" }}
			/>
			{config.label}
		</Badge>
	);
}
