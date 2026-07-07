"use client";

import { StatusBadge } from "@/components/status-badge";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogFooter,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
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
import { Textarea } from "@/components/ui/textarea";
import { useReclamations } from "@/hooks/use-reclamations";
import { useAuth } from "@/lib/auth";
import type { ReclamationResponse } from "@/lib/types";
import {
	Check,
	ChevronLeft,
	ChevronRight,
	Loader2,
	MessageSquareWarning,
	Reply,
	X,
} from "lucide-react";
import Link from "next/link";
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

const MOTIF_LABELS: Record<string, string> = {
	produit_endommage: "Produit endommagé",
	produit_manquant: "Produit manquant",
	erreur_facturation: "Erreur de facturation",
	erreur_produit: "Erreur de produit",
	autre: "Autre",
};

// Actions opératrice : accepter (résolue), contre-proposition (en cours), refuser (rejetée).
type ActionMode = "accepter" | "contre_proposition" | "refuser";

const ACTION_CONFIG: Record<
	ActionMode,
	{ title: string; statut: string; requireText: boolean; placeholder: string; confirm: string }
> = {
	accepter: {
		title: "Accepter la réclamation",
		statut: "resolue",
		requireText: false,
		placeholder: "Résolution appliquée (optionnel) — ex. avoir émis, produit remplacé…",
		confirm: "Accepter",
	},
	contre_proposition: {
		title: "Faire une contre-proposition",
		statut: "en_cours",
		requireText: true,
		placeholder: "Votre contre-proposition — ex. remise de 10% au lieu d'un remplacement…",
		confirm: "Envoyer la contre-proposition",
	},
	refuser: {
		title: "Refuser la réclamation",
		statut: "rejetee",
		requireText: false,
		placeholder: "Motif du refus (optionnel)",
		confirm: "Refuser",
	},
};

export default function ReclamationsPage() {
	const { user } = useAuth();
	const [statut, setStatut] = useState("all");
	const [page, setPage] = useState(0);
	const isPharmacien = user?.role === "pharmacien";
	const canAct = user?.role === "operatrice" || user?.role === "admin";

	const { reclamations, total, loading, updateReclamation } = useReclamations({
		statut,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});

	const [action, setAction] = useState<{
		reclamation: ReclamationResponse;
		mode: ActionMode;
	} | null>(null);

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
	const colCount = (isPharmacien ? 5 : 6) + (canAct ? 1 : 0);

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
							{canAct && (
								<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Actions
								</TableHead>
							)}
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 5 }).map((_, i) => (
								<TableRow key={`sk-${i}`} className="border-border/30">
									{Array.from({ length: colCount }).map((_, j) => (
										<TableCell key={`sk-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : reclamations.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={colCount}
									className="py-16 text-center text-[13px] text-muted-foreground"
								>
									Aucune réclamation
								</TableCell>
							</TableRow>
						) : (
							reclamations.map((r) => {
								const actionable = canAct && (r.statut === "ouverte" || r.statut === "en_cours");
								return (
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
										<TableCell className="max-w-[240px] text-[13px] text-muted-foreground">
											<span className="block truncate" title={r.description}>
												{r.description}
											</span>
											{r.resolution && (
												<span
													className="mt-0.5 block truncate text-[12px] text-teal-700"
													title={r.resolution}
												>
													↳ {r.resolution}
												</span>
											)}
										</TableCell>
										<TableCell className="text-[13px] text-muted-foreground">
											{new Date(r.created_at).toLocaleDateString("fr-FR")}
										</TableCell>
										<TableCell>
											<StatusBadge status={r.statut} />
										</TableCell>
										{canAct && (
											<TableCell>
												{actionable ? (
													<div className="flex items-center justify-end gap-1">
														<Button
															variant="ghost"
															size="icon"
															onClick={() => setAction({ reclamation: r, mode: "accepter" })}
															className="h-8 w-8 rounded-lg text-emerald-600 hover:bg-emerald-50 hover:text-emerald-700"
															title="Accepter"
															aria-label="Accepter la réclamation"
														>
															<Check className="h-4 w-4" />
														</Button>
														<Button
															variant="ghost"
															size="icon"
															onClick={() =>
																setAction({ reclamation: r, mode: "contre_proposition" })
															}
															className="h-8 w-8 rounded-lg text-sky-600 hover:bg-sky-50 hover:text-sky-700"
															title="Contre-proposition"
															aria-label="Faire une contre-proposition"
														>
															<Reply className="h-4 w-4" />
														</Button>
														<Button
															variant="ghost"
															size="icon"
															onClick={() => setAction({ reclamation: r, mode: "refuser" })}
															className="h-8 w-8 rounded-lg text-red-600 hover:bg-red-50 hover:text-red-700"
															title="Refuser"
															aria-label="Refuser la réclamation"
														>
															<X className="h-4 w-4" />
														</Button>
													</div>
												) : (
													<span className="block text-right text-[11px] text-muted-foreground/40">
														—
													</span>
												)}
											</TableCell>
										)}
									</TableRow>
								);
							})
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

			<ReclamationActionDialog
				action={action}
				onClose={() => setAction(null)}
				onConfirm={async (mode, reclamation, text) => {
					const config = ACTION_CONFIG[mode];
					await updateReclamation(reclamation.id, {
						statut: config.statut,
						resolution: text || undefined,
					});
				}}
			/>
		</div>
	);
}

function ReclamationActionDialog({
	action,
	onClose,
	onConfirm,
}: {
	action: { reclamation: ReclamationResponse; mode: ActionMode } | null;
	onClose: () => void;
	onConfirm: (mode: ActionMode, reclamation: ReclamationResponse, text: string) => Promise<void>;
}) {
	const [text, setText] = useState("");
	const [saving, setSaving] = useState(false);

	const config = action ? ACTION_CONFIG[action.mode] : null;
	const canConfirm = !config?.requireText || text.trim().length > 0;

	async function handleConfirm() {
		if (!action || !config) return;
		setSaving(true);
		try {
			await onConfirm(action.mode, action.reclamation, text.trim());
			toast.success("Réclamation mise à jour");
			setText("");
			onClose();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		} finally {
			setSaving(false);
		}
	}

	return (
		<Dialog
			open={!!action}
			onOpenChange={(open) => {
				if (!open) {
					setText("");
					onClose();
				}
			}}
		>
			<DialogContent className="max-w-md">
				<DialogHeader>
					<DialogTitle>{config?.title}</DialogTitle>
					<DialogDescription>
						Commande {action?.reclamation.commande_reference} —{" "}
						{action ? (MOTIF_LABELS[action.reclamation.motif] ?? action.reclamation.motif) : ""}
					</DialogDescription>
				</DialogHeader>

				{action && (
					<p className="rounded-lg bg-muted/40 px-3 py-2 text-[13px] text-muted-foreground">
						{action.reclamation.description}
					</p>
				)}

				<Textarea
					value={text}
					onChange={(e) => setText(e.target.value)}
					placeholder={config?.placeholder}
					rows={3}
					className="text-[13px]"
				/>

				<DialogFooter>
					<Button variant="outline" onClick={onClose} disabled={saving}>
						Annuler
					</Button>
					<Button onClick={handleConfirm} disabled={saving || !canConfirm} className="gap-1.5">
						{saving && <Loader2 className="h-4 w-4 animate-spin" />}
						{config?.confirm}
					</Button>
				</DialogFooter>
			</DialogContent>
		</Dialog>
	);
}
