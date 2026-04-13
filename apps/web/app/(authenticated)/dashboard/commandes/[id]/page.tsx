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
import { useOperatorEdit } from "@/hooks/use-operator-edit";
import { fetchApi } from "@/lib/api";
import type { MedicamentResponse, OrderDetailResponse } from "@/lib/types";
import { ArrowLeft, Check, Loader2, Plus, Save, Search, Trash2, XCircle } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

type CamionOption = { id: string; nom: string; plaque: string };

export default function OperatorOrderDetailPage() {
	const { id } = useParams<{ id: string }>();
	const [order, setOrder] = useState<OrderDetailResponse | null>(null);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);
	const [accepting, setAccepting] = useState(false);
	const [rejecting, setRejecting] = useState(false);
	const [camions, setCamions] = useState<CamionOption[]>([]);
	const [assigning, setAssigning] = useState(false);
	const { updateComment, editLine, addLine, removeLine, loading: editLoading } = useOperatorEdit();
	const [qteDrafts, setQteDrafts] = useState<Record<string, number>>({});
	const [commentDraft, setCommentDraft] = useState("");
	const [addMedSearch, setAddMedSearch] = useState("");
	const [addMedResults, setAddMedResults] = useState<MedicamentResponse[]>([]);
	const [addMedSelected, setAddMedSelected] = useState<MedicamentResponse | null>(null);
	const [addMedQte, setAddMedQte] = useState(1);

	const hydrateDrafts = useCallback((data: OrderDetailResponse) => {
		setQteDrafts(Object.fromEntries(data.lignes.map((l) => [l.id, l.qte_demandee])));
		setCommentDraft(data.operatrice_comment ?? "");
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

	// Load camions for assignment dropdown
	useEffect(() => {
		fetchApi<{ camions: CamionOption[] }>("/camions")
			.then((data) => setCamions(data.camions))
			.catch(() => {});
	}, []);

	async function handleAccept() {
		setAccepting(true);
		try {
			await fetchApi(`/commandes/${id}/accept`, { method: "PATCH" });
			toast.success("Commande acceptée");
			fetchOrder();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		} finally {
			setAccepting(false);
		}
	}

	async function handleReject() {
		setRejecting(true);
		try {
			await fetchApi(`/commandes/${id}/reject`, { method: "PATCH" });
			toast.success("Commande rejetée");
			fetchOrder();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		} finally {
			setRejecting(false);
		}
	}

	async function handleSaveComment() {
		if (!order) return;
		const next = commentDraft.trim() || null;
		if (next === (order.operatrice_comment ?? null)) return;
		try {
			const updated = await updateComment(order.id, next);
			setOrder(updated);
			hydrateDrafts(updated);
			toast.success("Commentaire enregistre");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur commentaire");
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
			toast.success("Ligne mise a jour");
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
			toast.success("Ligne supprimee");
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
			toast.success(`${addMedSelected.designation} ajoute`);
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

	async function handleAssignCamion(camionId: string | null) {
		if (!camionId) return;
		setAssigning(true);
		try {
			await fetchApi(`/commandes/${id}/assign-camion`, {
				method: "PATCH",
				body: JSON.stringify({ camion_id: camionId }),
			});
			const camion = camions.find((c) => c.id === camionId);
			toast.success(`Commande assignée au camion ${camion?.nom ?? camionId}`);
			fetchOrder();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur d'assignation");
		} finally {
			setAssigning(false);
		}
	}

	if (loading) {
		return (
			<div className="flex flex-col gap-4">
				<Skeleton className="h-6 w-32" />
				<Skeleton className="h-8 w-64" />
				<Skeleton className="h-48 w-full" />
			</div>
		);
	}

	if (error || !order) {
		return (
			<div className="flex flex-col items-center gap-4 py-12">
				<p className="text-muted-foreground">{error ?? "Commande introuvable"}</p>
				<Link href="/dashboard">
					<Button variant="outline">
						<ArrowLeft className="mr-2 h-4 w-4" />
						Retour au dashboard
					</Button>
				</Link>
			</div>
		);
	}

	return (
		<div className="flex flex-col gap-6">
			<Link
				href="/dashboard"
				className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
			>
				<ArrowLeft className="h-4 w-4" />
				Retour
			</Link>

			{/* Header */}
			<div className="flex items-center justify-between">
				<div>
					<h2 className="font-heading text-2xl font-semibold">Commande {order.reference_id}</h2>
					<p className="text-sm text-muted-foreground">
						Passée le {new Date(order.created_at).toLocaleDateString("fr-FR")}
					</p>
					{order.pharmacien_nom && (
						<p className="text-sm text-muted-foreground">
							Pharmacien : {order.pharmacien_nom}
							{order.pharmacien_email && ` (${order.pharmacien_email})`}
						</p>
					)}
				</div>
				<StatusBadge status={order.statut} />
			</div>

			{/* Articles table */}
			{(() => {
				const canEdit = order.statut === "creee" || order.statut === "acceptee";
				return (
					<>
						{canEdit && order.statut === "acceptee" && (
							<div className="rounded-lg border border-amber-200/80 bg-amber-50/60 px-4 py-2.5 text-[12px] text-amber-800">
								Commande deja acceptee : les modifications ajusteront le stock et regenereront la
								facture PDF.
							</div>
						)}
						<div className="overflow-x-auto rounded-md border">
							<Table>
								<TableHeader>
									<TableRow>
										<TableHead>Désignation</TableHead>
										<TableHead className="w-32 text-center">Quantité</TableHead>
										<TableHead className="tabular-nums text-right">Prix unitaire</TableHead>
										<TableHead className="tabular-nums text-right">Total</TableHead>
										{canEdit && <TableHead className="w-20" />}
									</TableRow>
								</TableHeader>
								<TableBody>
									{order.lignes.map((ligne) => {
										const draft = qteDrafts[ligne.id] ?? ligne.qte_demandee;
										const dirty = draft !== ligne.qte_demandee;
										return (
											<TableRow key={ligne.id}>
												<TableCell>{ligne.designation}</TableCell>
												<TableCell className="text-center tabular-nums">
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
												<TableCell className="tabular-nums text-right">
													{ligne.prix_unitaire.toLocaleString("fr-FR")} DA
												</TableCell>
												<TableCell className="tabular-nums text-right">
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
																	? "Derniere ligne : utiliser Rejeter"
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

						{canEdit && (
							<div className="rounded-lg border border-border/60 bg-muted/20 p-4">
								<div className="mb-3 flex items-center gap-2 text-[13px] font-semibold">
									<Plus className="h-4 w-4 text-primary" />
									Ajouter un medicament
								</div>
								<div className="flex flex-wrap items-start gap-2">
									<div className="relative flex-1 min-w-[240px]">
										<Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
										<Input
											placeholder="Rechercher par designation..."
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
										placeholder="Qte"
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

						{canEdit && (
							<div className="flex flex-col gap-2">
								<label
									htmlFor="operatrice-comment"
									className="text-[13px] font-semibold text-muted-foreground"
								>
									Commentaire operatrice
								</label>
								<textarea
									id="operatrice-comment"
									value={commentDraft}
									onChange={(e) => setCommentDraft(e.target.value)}
									onBlur={handleSaveComment}
									placeholder="Note interne (500 caracteres max)"
									maxLength={500}
									rows={3}
									className="min-h-[80px] w-full rounded-md border border-border/60 bg-card px-3 py-2 text-[13px] shadow-sm transition-colors placeholder:text-muted-foreground/60 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
								/>
							</div>
						)}

						{!canEdit && order.operatrice_comment && (
							<div className="rounded-lg border border-border/60 bg-muted/20 px-4 py-3">
								<p className="text-[12px] font-semibold text-muted-foreground">
									Commentaire operatrice
								</p>
								<p className="mt-1 whitespace-pre-wrap text-[13px]">{order.operatrice_comment}</p>
							</div>
						)}
					</>
				);
			})()}

			<div className="flex justify-end">
				<p className="text-lg font-semibold tabular-nums">
					Montant total : {order.montant_total.toLocaleString("fr-FR")} DA
				</p>
			</div>

			{/* Accept/Reject — only for Créée */}
			{order.statut === "creee" && (
				<div className="flex items-center gap-3">
					<AlertDialog>
						<AlertDialogTrigger className="inline-flex items-center gap-2 rounded-md border border-destructive px-4 py-2 text-sm font-medium text-destructive hover:bg-destructive/10">
							<XCircle className="h-4 w-4" />
							Rejeter
						</AlertDialogTrigger>
						<AlertDialogContent>
							<AlertDialogHeader>
								<AlertDialogTitle>Rejeter la commande</AlertDialogTitle>
								<AlertDialogDescription>
									Cette commande sera annulée. Voulez-vous continuer ?
								</AlertDialogDescription>
							</AlertDialogHeader>
							<AlertDialogFooter>
								<AlertDialogCancel disabled={rejecting}>Non, garder</AlertDialogCancel>
								<AlertDialogAction
									onClick={handleReject}
									disabled={rejecting}
									className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
								>
									{rejecting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
									Oui, rejeter
								</AlertDialogAction>
							</AlertDialogFooter>
						</AlertDialogContent>
					</AlertDialog>

					<Button
						onClick={handleAccept}
						disabled={accepting}
						className="bg-emerald-600 text-white hover:bg-emerald-700"
					>
						{accepting ? (
							<Loader2 className="mr-2 h-4 w-4 animate-spin" />
						) : (
							<Check className="mr-2 h-4 w-4" />
						)}
						Accepter
					</Button>
				</div>
			)}

			{/* Ligne de route — read only, assigned by controller */}
			{order.camion_nom && (
				<div className="flex items-center gap-2 rounded-lg border border-border/60 bg-muted/30 px-4 py-2.5">
					<span className="text-[13px] font-medium text-muted-foreground">Ligne de route :</span>
					<span className="text-[13px] font-semibold">{order.camion_nom}</span>
				</div>
			)}
		</div>
	);
}
