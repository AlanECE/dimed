"use client";

import { StatusBadge } from "@/components/status-badge";
import {
	AlertDialog,
	AlertDialogAction,
	AlertDialogCancel,
	AlertDialogContent,
	AlertDialogDescription,
	AlertDialogFooter,
	AlertDialogHeader,
	AlertDialogTitle,
	AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from "@/components/ui/table";
// Pharmacien et opératrice éditent les mêmes lignes via les mêmes endpoints.
import { useOperatorEdit } from "@/hooks/use-operator-edit";
import { fetchApi } from "@/lib/api";
import type { MedicamentResponse, OrderDetailResponse } from "@/lib/types";
import { ArrowLeft, Loader2, Plus, Save, Search, Trash2, XCircle } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

export default function CommandeDetailPage() {
	const { id } = useParams<{ id: string }>();
	const [order, setOrder] = useState<OrderDetailResponse | null>(null);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);
	const [cancelling, setCancelling] = useState(false);
	const { editLine, addLine, removeLine, loading: editLoading } = useOperatorEdit();
	const [qteDrafts, setQteDrafts] = useState<Record<string, number>>({});
	const [addMedSearch, setAddMedSearch] = useState("");
	const [addMedResults, setAddMedResults] = useState<MedicamentResponse[]>([]);
	const [addMedSelected, setAddMedSelected] = useState<MedicamentResponse | null>(null);
	const [addMedQte, setAddMedQte] = useState(1);

	const hydrateDrafts = useCallback((data: OrderDetailResponse) => {
		setQteDrafts(Object.fromEntries(data.lignes.map((l) => [l.id, l.qte_demandee])));
	}, []);

	const fetchOrder = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<OrderDetailResponse>(`/commandes/${id}`);
			setOrder(data);
			hydrateDrafts(data);
			setError(null);
		} catch (err) {
			setError(err instanceof Error ? err.message : "Commande introuvable");
		} finally {
			setLoading(false);
		}
	}, [id, hydrateDrafts]);

	useEffect(() => {
		fetchOrder();
	}, [fetchOrder]);

	async function handleCancel() {
		setCancelling(true);
		try {
			await fetchApi(`/commandes/${id}/cancel`, { method: "PATCH" });
			toast.success("Commande annulée");
			fetchOrder();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors de l'annulation");
		} finally {
			setCancelling(false);
		}
	}

	async function handleSaveQte(ligneId: string) {
		if (!order) return;
		const draft = qteDrafts[ligneId];
		const current = order.lignes.find((l) => l.id === ligneId);
		if (!current || !draft || draft === current.qte_demandee) return;
		try {
			const updated = await editLine(order.id, ligneId, draft);
			setOrder(updated);
			hydrateDrafts(updated);
			toast.success("Ligne mise à jour");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur ligne");
		}
	}

	async function handleRemoveLine(ligneId: string) {
		if (!order) return;
		try {
			const updated = await removeLine(order.id, ligneId);
			setOrder(updated);
			hydrateDrafts(updated);
			toast.success("Ligne supprimée");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur suppression");
		}
	}

	async function handleAddLine() {
		if (!order || !addMedSelected || addMedQte < 1) return;
		try {
			const updated = await addLine(order.id, addMedSelected.id, addMedQte);
			setOrder(updated);
			hydrateDrafts(updated);
			setAddMedSelected(null);
			setAddMedSearch("");
			setAddMedResults([]);
			setAddMedQte(1);
			toast.success(`${addMedSelected.designation} ajouté`);
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur ajout");
		}
	}

	useEffect(() => {
		const q = addMedSearch.trim();
		if (q.length < 2) {
			setAddMedResults([]);
			return;
		}
		let aborted = false;
		fetchApi<{ medicaments: MedicamentResponse[] }>("/medicaments", {
			params: { search: q, limit: 8 },
		})
			.then((data) => {
				if (!aborted) setAddMedResults(data.medicaments);
			})
			.catch(() => {});
		return () => {
			aborted = true;
		};
	}, [addMedSearch]);

	if (loading) {
		return (
			<div className="flex flex-col gap-4">
				<Skeleton className="h-5 w-24" />
				<Skeleton className="h-8 w-64" />
				<Skeleton className="h-48 w-full rounded-xl" />
			</div>
		);
	}

	if (error || !order) {
		return (
			<div className="flex flex-col items-center gap-4 py-16">
				<p className="text-[13px] text-muted-foreground">{error ?? "Commande introuvable"}</p>
				<Link href="/commandes">
					<Button variant="outline" className="rounded-lg">
						<ArrowLeft className="mr-2 h-4 w-4" />
						Retour aux commandes
					</Button>
				</Link>
			</div>
		);
	}

	// Le pharmacien ne peut modifier sa commande que tant qu'elle est en saisie
	// (créée). Une fois validée par l'opératrice, l'écran passe en lecture seule.
	const canEdit = order.statut === "creee";

	return (
		<div className="animate-fade-in-up flex flex-col gap-6">
			{/* Back link */}
			<Link
				href="/commandes"
				className="inline-flex items-center gap-1.5 text-[13px] font-medium text-muted-foreground transition-colors hover:text-foreground"
			>
				<ArrowLeft className="h-3.5 w-3.5" />
				Retour
			</Link>

			{/* Header */}
			<div className="flex items-center justify-between">
				<div>
					<h2 className="font-heading text-xl font-bold">Commande {order.reference_id}</h2>
					<p className="mt-0.5 text-[13px] text-muted-foreground">
						Passée le {new Date(order.created_at).toLocaleDateString("fr-FR")}
					</p>
				</div>
				<StatusBadge status={order.statut} />
			</div>

			{/* Message de l'opératrice (motif de refus / note) */}
			{order.operatrice_comment && (
				<div className="rounded-xl border border-amber-200/80 bg-amber-50/60 px-4 py-3">
					<p className="text-[12px] font-semibold text-amber-800">Message de l'opératrice</p>
					<p className="mt-1 whitespace-pre-wrap text-[13px] text-amber-900">
						{order.operatrice_comment}
					</p>
					{canEdit && (
						<p className="mt-1.5 text-[12px] text-amber-700/80">
							Corrigez votre commande ci-dessous, elle sera de nouveau soumise à validation.
						</p>
					)}
				</div>
			)}

			{/* Articles table */}
			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Désignation
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Quantité
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70 tabular-nums">
								Prix unitaire
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70 tabular-nums">
								Total
							</TableHead>
							{canEdit && <TableHead className="w-12" />}
						</TableRow>
					</TableHeader>
					<TableBody>
						{order.lignes.map((ligne) => {
							const draft = qteDrafts[ligne.id] ?? ligne.qte_demandee;
							const dirty = draft !== ligne.qte_demandee;
							return (
								<TableRow key={ligne.id} className="border-border/30">
									<TableCell className="text-[13px] font-medium">{ligne.designation}</TableCell>
									<TableCell className="text-center text-[13px] tabular-nums">
										{canEdit ? (
											<div className="flex items-center justify-center gap-1">
												<Input
													type="number"
													min={1}
													value={draft}
													onChange={(e) =>
														setQteDrafts((prev) => ({
															...prev,
															[ligne.id]: Number.parseInt(e.target.value, 10) || 1,
														}))
													}
													className="h-8 w-20 text-center"
												/>
												<Button
													size="icon"
													variant="ghost"
													className="h-8 w-8"
													disabled={!dirty || editLoading}
													onClick={() => handleSaveQte(ligne.id)}
													title="Enregistrer"
												>
													<Save className="h-4 w-4" />
												</Button>
											</div>
										) : (
											ligne.qte_demandee
										)}
									</TableCell>
									<TableCell className="text-right text-[13px] tabular-nums">
										{ligne.prix_unitaire.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell className="text-right text-[13px] font-semibold tabular-nums">
										{(draft * ligne.prix_unitaire).toLocaleString("fr-FR")} DA
									</TableCell>
									{canEdit && (
										<TableCell className="text-right">
											<Button
												size="icon"
												variant="ghost"
												className="h-8 w-8 text-muted-foreground hover:text-destructive"
												disabled={editLoading || order.lignes.length <= 1}
												onClick={() => handleRemoveLine(ligne.id)}
												title={
													order.lignes.length <= 1
														? "Dernière ligne : annulez la commande"
														: "Supprimer la ligne"
												}
											>
												<Trash2 className="h-4 w-4" />
											</Button>
										</TableCell>
									)}
								</TableRow>
							);
						})}
					</TableBody>
				</Table>
			</div>

			{/* Ajout de médicament */}
			{canEdit && (
				<div className="rounded-xl border border-border/60 bg-muted/20 p-4">
					<div className="mb-3 flex items-center gap-2 text-[13px] font-semibold">
						<Plus className="h-4 w-4 text-primary" />
						Ajouter un médicament
					</div>
					<div className="flex flex-wrap items-start gap-2">
						<div className="relative min-w-[240px] flex-1">
							<Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
							<Input
								placeholder="Rechercher par désignation..."
								value={addMedSelected ? addMedSelected.designation : addMedSearch}
								onChange={(e) => {
									setAddMedSelected(null);
									setAddMedSearch(e.target.value);
								}}
								className="pl-9"
							/>
							{addMedSearch.length >= 2 && !addMedSelected && addMedResults.length > 0 && (
								<div className="absolute z-20 mt-1 max-h-60 w-full overflow-y-auto rounded-md border border-border/60 bg-card shadow-md">
									{addMedResults.map((med) => (
										<button
											type="button"
											key={med.id}
											disabled={med.stock_quantity === 0}
											onClick={() => {
												setAddMedSelected(med);
												setAddMedResults([]);
												setAddMedSearch("");
											}}
											className="flex w-full items-center justify-between gap-2 border-b border-border/40 px-3 py-2 text-left text-[13px] last:border-0 hover:bg-muted/50 disabled:cursor-not-allowed disabled:opacity-50"
										>
											<span className="font-medium">{med.designation}</span>
											<span
												className={`text-[11px] tabular-nums ${
													med.stock_quantity === 0 ? "text-red-500" : "text-muted-foreground"
												}`}
											>
												Stock : {med.stock_quantity}
											</span>
										</button>
									))}
								</div>
							)}
						</div>
						<Input
							type="number"
							min={1}
							value={addMedQte}
							onChange={(e) => setAddMedQte(Number.parseInt(e.target.value, 10) || 1)}
							className="w-24"
							placeholder="Qté"
						/>
						<Button
							onClick={handleAddLine}
							disabled={!addMedSelected || addMedQte < 1 || editLoading}
						>
							{editLoading ? (
								<Loader2 className="mr-2 h-4 w-4 animate-spin" />
							) : (
								<Plus className="mr-2 h-4 w-4" />
							)}
							Ajouter
						</Button>
					</div>
				</div>
			)}

			{/* Total */}
			<div className="flex justify-end">
				<div className="rounded-xl border border-border/60 bg-muted/30 px-5 py-3">
					<span className="text-[13px] text-muted-foreground">Montant total : </span>
					<span className="font-heading text-lg font-bold tabular-nums">
						{order.montant_total.toLocaleString("fr-FR")} DA
					</span>
				</div>
			</div>

			{/* Cancel button */}
			{canEdit && (
				<AlertDialog>
					<AlertDialogTrigger className="inline-flex w-fit items-center gap-2 rounded-lg border border-destructive/30 px-4 py-2.5 text-[13px] font-semibold text-destructive transition-colors hover:bg-destructive/5">
						<XCircle className="h-4 w-4" />
						Annuler la commande
					</AlertDialogTrigger>
					<AlertDialogContent className="rounded-xl">
						<AlertDialogHeader>
							<AlertDialogTitle>Annuler la commande</AlertDialogTitle>
							<AlertDialogDescription>
								Cette action est irréversible. Voulez-vous continuer ?
							</AlertDialogDescription>
						</AlertDialogHeader>
						<AlertDialogFooter>
							<AlertDialogCancel disabled={cancelling} className="rounded-lg">
								Non, garder
							</AlertDialogCancel>
							<AlertDialogAction
								onClick={handleCancel}
								disabled={cancelling}
								className="rounded-lg bg-destructive text-destructive-foreground hover:bg-destructive/90"
							>
								{cancelling && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
								Oui, annuler
							</AlertDialogAction>
						</AlertDialogFooter>
					</AlertDialogContent>
				</AlertDialog>
			)}
		</div>
	);
}
