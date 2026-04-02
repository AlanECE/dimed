"use client";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
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
import { useAuditLog } from "@/hooks/use-audit-log";
import { ChevronLeft, ChevronRight, ScrollText } from "lucide-react";
import { useState } from "react";

const PAGE_SIZE = 30;

const ENTITY_TYPES = [
	{ value: "", label: "Toutes les entités" },
	{ value: "Commande", label: "Commande" },
	{ value: "User", label: "Utilisateur" },
	{ value: "Facture", label: "Facture" },
	{ value: "Camion", label: "Camion" },
	{ value: "FeuilleDeRoute", label: "Feuille de route" },
];

const ACTION_COLORS: Record<string, string> = {
	INSERT: "bg-emerald-50 text-emerald-700 border-emerald-200/80",
	UPDATE: "bg-blue-50 text-blue-700 border-blue-200/80",
	DELETE: "bg-red-50 text-red-700 border-red-200/80",
};

export default function JournalPage() {
	const [entityType, setEntityType] = useState("");
	const [page, setPage] = useState(0);
	const [expandedId, setExpandedId] = useState<string | null>(null);

	const { entries, total, loading } = useAuditLog({
		entityType: entityType || undefined,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gray-100">
					<ScrollText className="h-5 w-5 text-gray-600" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Journal d'activité</h2>
					<p className="text-[13px] text-muted-foreground">Historique des modifications système</p>
				</div>
			</div>

			{/* Filters */}
			<div className="flex gap-3">
				<Select
					value={entityType}
					onValueChange={(v) => {
						setEntityType(v ?? "");
						setPage(0);
					}}
				>
					<SelectTrigger className="w-48 rounded-lg border-border/60 bg-card text-[13px]">
						<SelectValue placeholder="Entité" />
					</SelectTrigger>
					<SelectContent>
						{ENTITY_TYPES.map((et) => (
							<SelectItem key={et.value} value={et.value}>
								{et.label}
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
								Date / Heure
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Utilisateur
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Action
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Entité
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Détails
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 8 }).map((_, i) => (
								<TableRow key={`sk-${i}`} className="border-border/30">
									{Array.from({ length: 5 }).map((_, j) => (
										<TableCell key={`sk-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : entries.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={5}
									className="py-16 text-center text-[13px] text-muted-foreground"
								>
									Aucune entrée
								</TableCell>
							</TableRow>
						) : (
							entries.map((entry) => (
								<TableRow
									key={entry.id}
									className="cursor-pointer border-border/30 transition-colors hover:bg-muted/40"
									onClick={() => setExpandedId(expandedId === entry.id ? null : entry.id)}
								>
									<TableCell className="text-[13px] text-muted-foreground">
										{new Date(entry.timestamp).toLocaleString("fr-FR")}
									</TableCell>
									<TableCell className="text-[13px]">{entry.actor_nom ?? "Système"}</TableCell>
									<TableCell>
										<Badge
											variant="outline"
											className={`rounded-full text-[11px] font-semibold ${ACTION_COLORS[entry.action] ?? ""}`}
										>
											{entry.action}
										</Badge>
									</TableCell>
									<TableCell className="text-[13px]">{entry.entity_type}</TableCell>
									<TableCell className="max-w-[300px] text-[12px] text-muted-foreground">
										{expandedId === entry.id ? (
											<pre className="mt-1 overflow-x-auto whitespace-pre-wrap rounded-lg bg-muted/50 p-2 text-[11px]">
												{JSON.stringify({ old: entry.old_value, new: entry.new_value }, null, 2)}
											</pre>
										) : (
											<span className="truncate">Cliquer pour voir les détails</span>
										)}
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
