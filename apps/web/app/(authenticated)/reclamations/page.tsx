"use client";

import { StatusBadge } from "@/components/status-badge";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
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
import { useReclamations } from "@/hooks/use-reclamations";
import { useAuth } from "@/lib/auth";
import { ChevronLeft, ChevronRight, MessageSquareWarning } from "lucide-react";
import Link from "next/link";
import { useState } from "react";

const PAGE_SIZE = 20;

const STATUT_OPTIONS = [
	{ value: "all", label: "Toutes" },
	{ value: "ouverte", label: "Ouverte" },
	{ value: "en_cours", label: "En cours" },
	{ value: "resolue", label: "Résolue" },
	{ value: "rejetee", label: "Rejetée" },
];

const MOTIF_LABELS: Record<string, string> = {
	produit_endommage: "Produit endommagé",
	produit_manquant: "Produit manquant",
	erreur_facturation: "Erreur de facturation",
	erreur_produit: "Erreur de produit",
	autre: "Autre",
};

export default function ReclamationsPage() {
	const { user } = useAuth();
	const [statut, setStatut] = useState("all");
	const [page, setPage] = useState(0);
	const isPharmacien = user?.role === "pharmacien";

	const { reclamations, total, loading } = useReclamations({
		statut,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center justify-between">
				<div className="flex items-center gap-3">
					<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-orange-50">
						<MessageSquareWarning className="h-5 w-5 text-orange-600" />
					</div>
					<div>
						<h2 className="font-heading text-xl font-bold">Réclamations</h2>
						<p className="text-[13px] text-muted-foreground">
							{isPharmacien
								? "Pour réclamation, cliquez sur ⚠ depuis vos commandes"
								: "Suivi et traitement des réclamations"}
						</p>
					</div>
				</div>
				{isPharmacien && (
					<Link href="/commandes">
						<Button
							variant="outline"
							className="h-9 gap-1.5 rounded-lg text-[13px] font-semibold border-orange-200 text-orange-600 hover:bg-orange-50"
						>
							<MessageSquareWarning className="h-4 w-4" />
							Aller à mes commandes
						</Button>
					</Link>
				)}
			</div>

			{/* Filter */}
			<div className="flex gap-3">
				<Select
					value={statut}
					onValueChange={(v) => {
						setStatut(v ?? "all");
						setPage(0);
					}}
				>
					<SelectTrigger className="w-48 rounded-lg border-border/60 bg-card text-[13px]">
						<SelectValue placeholder="Statut" />
					</SelectTrigger>
					<SelectContent>
						{STATUT_OPTIONS.map((opt) => (
							<SelectItem key={opt.value} value={opt.value}>
								{opt.label}
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
								Commande
							</TableHead>
							{!isPharmacien && (
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Pharmacien
								</TableHead>
							)}
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Motif
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Description
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Date
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Statut
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 5 }).map((_, i) => (
								<TableRow key={`sk-${i}`} className="border-border/30">
									{Array.from({ length: isPharmacien ? 5 : 6 }).map((_, j) => (
										<TableCell key={`sk-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : reclamations.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={isPharmacien ? 5 : 6}
									className="py-16 text-center text-[13px] text-muted-foreground"
								>
									Aucune réclamation
								</TableCell>
							</TableRow>
						) : (
							reclamations.map((r) => (
								<TableRow
									key={r.id}
									className="border-border/30 transition-colors hover:bg-muted/40"
								>
									<TableCell className="font-mono text-[13px]">{r.commande_reference}</TableCell>
									{!isPharmacien && (
										<TableCell className="text-[13px]">{r.pharmacien_nom}</TableCell>
									)}
									<TableCell>
										<Badge variant="outline" className="rounded-full text-[11px]">
											{MOTIF_LABELS[r.motif] ?? r.motif}
										</Badge>
									</TableCell>
									<TableCell className="max-w-[200px] truncate text-[13px] text-muted-foreground">
										{r.description}
									</TableCell>
									<TableCell className="text-[13px] text-muted-foreground">
										{new Date(r.created_at).toLocaleDateString("fr-FR")}
									</TableCell>
									<TableCell>
										<StatusBadge status={r.statut} />
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
