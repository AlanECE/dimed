"use client";

import { StatusBadge } from "@/components/status-badge";
import {
	AlertDialog,
	AlertDialogAction,
	AlertDialogCancel,
	AlertDialogContent,
	AlertDialogFooter,
	AlertDialogHeader,
	AlertDialogTitle,
} from "@/components/ui/alert-dialog";
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
import { useReclamations } from "@/hooks/use-reclamations";
import { useAuth } from "@/lib/auth";
import { ChevronLeft, ChevronRight, Loader2, MessageSquareWarning, Plus } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

const PAGE_SIZE = 20;

const STATUT_OPTIONS = [
	{ value: "all", label: "Toutes" },
	{ value: "ouverte", label: "Ouverte" },
	{ value: "en_cours", label: "En cours" },
	{ value: "resolue", label: "Résolue" },
	{ value: "rejetee", label: "Rejetée" },
];

const MOTIF_OPTIONS = [
	{ value: "produit_endommage", label: "Produit endommagé" },
	{ value: "produit_manquant", label: "Produit manquant" },
	{ value: "erreur_facturation", label: "Erreur de facturation" },
	{ value: "erreur_produit", label: "Erreur de produit" },
	{ value: "autre", label: "Autre" },
];

const MOTIF_LABELS: Record<string, string> = Object.fromEntries(
	MOTIF_OPTIONS.map((o) => [o.value, o.label]),
);

export default function ReclamationsPage() {
	const { user } = useAuth();
	const [statut, setStatut] = useState("all");
	const [page, setPage] = useState(0);
	const [dialogOpen, setDialogOpen] = useState(false);
	const [commandeId, setCommandeId] = useState("");
	const [motif, setMotif] = useState("produit_endommage");
	const [description, setDescription] = useState("");
	const [submitting, setSubmitting] = useState(false);
	const isPharmacien = user?.role === "pharmacien";

	const { reclamations, total, loading, createReclamation } = useReclamations({
		statut,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

	async function handleCreate() {
		if (!commandeId.trim()) {
			toast.error("Veuillez entrer l'ID de commande");
			return;
		}
		setSubmitting(true);
		try {
			await createReclamation({ commande_id: commandeId, motif, description });
			toast.success("Réclamation créée");
			setDialogOpen(false);
			setCommandeId("");
			setDescription("");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		} finally {
			setSubmitting(false);
		}
	}

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
							Déclaration et suivi des réclamations
						</p>
					</div>
				</div>
				{(isPharmacien || user?.role === "admin") && (
					<Button
						onClick={() => setDialogOpen(true)}
						className="h-9 gap-1.5 rounded-lg bg-primary text-[13px] font-semibold shadow-sm hover:brightness-110"
					>
						<Plus className="h-4 w-4" />
						Nouvelle réclamation
					</Button>
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

			{/* Create dialog */}
			<AlertDialog open={dialogOpen} onOpenChange={setDialogOpen}>
				<AlertDialogContent className="rounded-xl">
					<AlertDialogHeader>
						<AlertDialogTitle className="font-heading font-bold">
							Nouvelle réclamation
						</AlertDialogTitle>
					</AlertDialogHeader>
					<div className="space-y-4">
						<div className="space-y-1.5">
							<label className="text-[13px] font-semibold text-foreground/80">ID Commande</label>
							<Input
								value={commandeId}
								onChange={(e) => setCommandeId(e.target.value)}
								placeholder="UUID de la commande"
								className="h-10 rounded-lg border-border/60 text-[13px]"
							/>
						</div>
						<div className="space-y-1.5">
							<label className="text-[13px] font-semibold text-foreground/80">Motif</label>
							<Select value={motif} onValueChange={(v) => setMotif(v ?? "autre")}>
								<SelectTrigger className="rounded-lg border-border/60 text-[13px]">
									<SelectValue />
								</SelectTrigger>
								<SelectContent>
									{MOTIF_OPTIONS.map((o) => (
										<SelectItem key={o.value} value={o.value}>
											{o.label}
										</SelectItem>
									))}
								</SelectContent>
							</Select>
						</div>
						<div className="space-y-1.5">
							<label className="text-[13px] font-semibold text-foreground/80">Description</label>
							<textarea
								value={description}
								onChange={(e) => setDescription(e.target.value)}
								placeholder="Décrivez le problème..."
								rows={3}
								className="w-full rounded-lg border border-border/60 bg-card px-3 py-2 text-[13px] outline-none focus:border-primary/30 focus:ring-2 focus:ring-primary/10"
							/>
						</div>
					</div>
					<AlertDialogFooter>
						<AlertDialogCancel className="rounded-lg" disabled={submitting}>
							Annuler
						</AlertDialogCancel>
						<AlertDialogAction
							onClick={handleCreate}
							disabled={submitting}
							className="rounded-lg bg-primary font-semibold shadow-sm hover:brightness-110"
						>
							{submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
							Créer
						</AlertDialogAction>
					</AlertDialogFooter>
				</AlertDialogContent>
			</AlertDialog>
		</div>
	);
}
