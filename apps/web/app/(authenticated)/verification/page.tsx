"use client";

import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogFooter,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
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
import { useCamions } from "@/hooks/use-camions";
import { useExpedition } from "@/hooks/use-expedition";
import { useOrders } from "@/hooks/use-orders";
import { usePreparation } from "@/hooks/use-preparation";
import { fetchApi } from "@/lib/api";
import type { LignePreparationResponse, OrderResponse } from "@/lib/types";
import {
	ArrowLeft,
	CheckCircle,
	FileDown,
	Loader2,
	Package,
	QrCode,
	Route,
	ShieldCheck,
	XCircle,
} from "lucide-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

export default function VerificationPage() {
	const [selectedOrder, setSelectedOrder] = useState<OrderResponse | null>(null);

	if (selectedOrder) {
		return <VerificationDetail order={selectedOrder} onBack={() => setSelectedOrder(null)} />;
	}

	return <VerificationList onSelect={setSelectedOrder} />;
}

// ---------------------------------------------------------------------------
// List view
// ---------------------------------------------------------------------------

function VerificationList({ onSelect }: { onSelect: (o: OrderResponse) => void }) {
	const { orders: enVerif, loading: loadingVerif } = useOrders({ statut: "en_verification" });
	const { orders: pretes, loading: loadingPretes } = useOrders({ statut: "prete" });
	const { downloadEtiquettes } = useExpedition();
	const [contenuOrder, setContenuOrder] = useState<OrderResponse | null>(null);

	const handleEtiquettes = useCallback(
		async (order: OrderResponse) => {
			try {
				await downloadEtiquettes(order.id, order.reference_id);
			} catch (err) {
				toast.error(err instanceof Error ? err.message : "Erreur téléchargement étiquettes");
			}
		},
		[downloadEtiquettes],
	);

	return (
		<div className="flex flex-col gap-8">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50">
					<ShieldCheck className="h-5 w-5 text-indigo-600" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Vérification des commandes</h2>
					<p className="text-[13px] text-muted-foreground">Comptez les articles et validez</p>
				</div>
			</div>

			{/* À vérifier */}
			<section className="animate-fade-in-up flex flex-col gap-3">
				<div className="flex items-center gap-2.5">
					<h3 className="text-[15px] font-semibold">À vérifier</h3>
					<span className="flex h-6 min-w-6 items-center justify-center rounded-full bg-indigo-100 px-2 text-[11px] font-bold text-indigo-700">
						{enVerif.length}
					</span>
				</div>
				<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
					<Table>
						<TableHeader>
							<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Référence
								</TableHead>
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Pharmacien
								</TableHead>
								<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Montant
								</TableHead>
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Statut
								</TableHead>
								<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Action
								</TableHead>
							</TableRow>
						</TableHeader>
						<TableBody>
							{loadingVerif ? (
								Array.from({ length: 3 }).map((_, i) => (
									<TableRow key={`sk-${i}`} className="border-border/30">
										{Array.from({ length: 5 }).map((_, j) => (
											<TableCell key={`sk-${i}-${j}`}>
												<Skeleton className="h-4 w-full" />
											</TableCell>
										))}
									</TableRow>
								))
							) : enVerif.length === 0 ? (
								<TableRow>
									<TableCell
										colSpan={5}
										className="py-12 text-center text-[13px] text-muted-foreground"
									>
										Aucune commande en attente de vérification
									</TableCell>
								</TableRow>
							) : (
								enVerif.map((order) => (
									<TableRow key={order.id} className="border-border/30 hover:bg-muted/40">
										<TableCell className="font-mono text-[13px]">{order.reference_id}</TableCell>
										<TableCell className="text-[13px]">{order.pharmacien_nom ?? "—"}</TableCell>
										<TableCell className="text-right text-[13px] font-semibold tabular-nums">
											{order.montant_total.toLocaleString("fr-FR")} DA
										</TableCell>
										<TableCell>
											<StatusBadge status={order.statut} />
										</TableCell>
										<TableCell className="text-right">
											<Button
												size="sm"
												onClick={() => onSelect(order)}
												className="h-8 gap-1.5 rounded-lg bg-primary text-[12px] font-semibold shadow-sm hover:brightness-110"
											>
												<ShieldCheck className="h-3.5 w-3.5" />
												Contrôler
											</Button>
										</TableCell>
									</TableRow>
								))
							)}
						</TableBody>
					</Table>
				</div>
			</section>

			{/* Prêtes */}
			<section className="animate-fade-in-up delay-150 flex flex-col gap-3">
				<div className="flex items-center gap-2.5">
					<h3 className="text-[15px] font-semibold">Prêtes à livrer</h3>
					<span className="flex h-6 min-w-6 items-center justify-center rounded-full bg-violet-100 px-2 text-[11px] font-bold text-violet-700">
						{pretes.length}
					</span>
				</div>
				<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
					<Table>
						<TableHeader>
							<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Référence
								</TableHead>
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Pharmacien
								</TableHead>
								<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Montant
								</TableHead>
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Statut
								</TableHead>
								<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Étiquettes
								</TableHead>
							</TableRow>
						</TableHeader>
						<TableBody>
							{loadingPretes ? (
								Array.from({ length: 2 }).map((_, i) => (
									<TableRow key={`skp-${i}`} className="border-border/30">
										{Array.from({ length: 5 }).map((_, j) => (
											<TableCell key={`skp-${i}-${j}`}>
												<Skeleton className="h-4 w-full" />
											</TableCell>
										))}
									</TableRow>
								))
							) : pretes.length === 0 ? (
								<TableRow>
									<TableCell
										colSpan={5}
										className="py-8 text-center text-[13px] text-muted-foreground"
									>
										Aucune commande prête
									</TableCell>
								</TableRow>
							) : (
								pretes.map((order) => (
									<TableRow
										key={order.id}
										className="border-border/30 opacity-60 hover:bg-muted/40 hover:opacity-100"
									>
										<TableCell className="font-mono text-[13px]">{order.reference_id}</TableCell>
										<TableCell className="text-[13px]">{order.pharmacien_nom ?? "—"}</TableCell>
										<TableCell className="text-right text-[13px] font-semibold tabular-nums">
											{order.montant_total.toLocaleString("fr-FR")} DA
										</TableCell>
										<TableCell>
											<StatusBadge status={order.statut} />
										</TableCell>
										<TableCell className="text-right">
											<div className="flex items-center justify-end gap-1.5">
												<Button
													variant="outline"
													size="sm"
													onClick={() => setContenuOrder(order)}
													className="h-8 gap-1.5 rounded-lg text-[12px]"
												>
													<Package className="h-3.5 w-3.5" />
													Contenu
												</Button>
												<Button
													variant="outline"
													size="sm"
													onClick={() => handleEtiquettes(order)}
													className="h-8 gap-1.5 rounded-lg text-[12px]"
												>
													<QrCode className="h-3.5 w-3.5" />
													Étiquettes PDF
												</Button>
											</div>
										</TableCell>
									</TableRow>
								))
							)}
						</TableBody>
					</Table>
				</div>
			</section>

			<ColisContenuDialog order={contenuOrder} onClose={() => setContenuOrder(null)} />
		</div>
	);
}

// ---------------------------------------------------------------------------
// Contenu des colis — le contrôleur répartit les lignes dans les cartons ;
// le contenu devient consultable au scan du QR (tablette magasinier/livreur).
// ---------------------------------------------------------------------------

type ColisSummary = { id: string; numero: string; index_colis: number };

function ColisContenuDialog({
	order,
	onClose,
}: {
	order: OrderResponse | null;
	onClose: () => void;
}) {
	const [lignes, setLignes] = useState<LignePreparationResponse[]>([]);
	const [colis, setColis] = useState<ColisSummary[]>([]);
	const [qty, setQty] = useState<Record<string, Record<string, string>>>({});
	const [loading, setLoading] = useState(false);
	const [saving, setSaving] = useState(false);

	useEffect(() => {
		if (!order) return;
		setLoading(true);
		setQty({});
		Promise.all([
			fetchApi<{ lignes: LignePreparationResponse[] }>(`/commandes/${order.id}/lignes`),
			fetchApi<{ colis: ColisSummary[] }>(`/expedition/commandes/${order.id}/colis`),
		])
			.then(([lignesRes, colisRes]) => {
				setLignes(lignesRes.lignes);
				setColis(colisRes.colis);
			})
			.catch((err) => {
				toast.error(err instanceof Error ? err.message : "Erreur de chargement");
				onClose();
			})
			.finally(() => setLoading(false));
	}, [order, onClose]);

	const handleSave = useCallback(async () => {
		if (!order) return;
		const repartition = colis
			.map((k) => ({
				colis_id: k.id,
				lignes: lignes
					.map((l) => ({
						ligne_id: l.id,
						quantite: Number.parseInt(qty[k.id]?.[l.id] ?? "", 10) || 0,
					}))
					.filter((entry) => entry.quantite >= 1),
			}))
			.filter((item) => item.lignes.length > 0);

		setSaving(true);
		try {
			await fetchApi(`/expedition/commandes/${order.id}/repartition`, {
				method: "PUT",
				body: JSON.stringify({ repartition }),
			});
			toast.success(`Contenu des colis enregistré (${order.reference_id})`);
			onClose();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur d'enregistrement");
		} finally {
			setSaving(false);
		}
	}, [order, colis, lignes, qty, onClose]);

	return (
		<Dialog open={!!order} onOpenChange={(open) => !open && onClose()}>
			<DialogContent className="max-h-[85vh] max-w-2xl overflow-y-auto">
				<DialogHeader>
					<DialogTitle>Contenu des colis — {order?.reference_id}</DialogTitle>
					<DialogDescription>
						Indiquez la quantité de chaque article placée dans chaque carton. Le contenu sera
						visible à la lecture du QR code du colis.
					</DialogDescription>
				</DialogHeader>

				{loading ? (
					<div className="flex flex-col gap-3">
						{Array.from({ length: 3 }).map((_, i) => (
							<Skeleton key={`ct-sk-${i}`} className="h-16 rounded-xl" />
						))}
					</div>
				) : (
					<div className="flex flex-col gap-4">
						{colis.map((k) => (
							<div key={k.id} className="rounded-xl border border-border/60 bg-muted/20 p-3">
								<p className="mb-2 flex items-center gap-2 font-mono text-[13px] font-bold">
									<Package className="h-4 w-4 text-violet-600" />
									{k.numero}
									<span className="font-sans text-[11px] font-medium text-muted-foreground">
										Carton {k.index_colis} / {colis.length}
									</span>
								</p>
								<div className="flex flex-col gap-1.5">
									{lignes.map((l) => (
										<div
											key={`${k.id}-${l.id}`}
											className="flex items-center justify-between gap-3"
										>
											<span className="truncate text-[13px]">{l.designation}</span>
											<Input
												type="number"
												min={0}
												placeholder="0"
												value={qty[k.id]?.[l.id] ?? ""}
												onChange={(e) =>
													setQty((prev) => ({
														...prev,
														[k.id]: { ...prev[k.id], [l.id]: e.target.value },
													}))
												}
												className="h-8 w-20 text-right text-[13px]"
											/>
										</div>
									))}
								</div>
							</div>
						))}
					</div>
				)}

				<DialogFooter>
					<Button variant="outline" onClick={onClose}>
						Annuler
					</Button>
					<Button onClick={handleSave} disabled={saving || loading} className="gap-1.5">
						{saving && <Loader2 className="h-4 w-4 animate-spin" />}
						Enregistrer le contenu
					</Button>
				</DialogFooter>
			</DialogContent>
		</Dialog>
	);
}

// ---------------------------------------------------------------------------
// Detail view — controller counts items blindly, then reveals comparison
// ---------------------------------------------------------------------------

function VerificationDetail({ order, onBack }: { order: OrderResponse; onBack: () => void }) {
	const { detail, loading, fetchLignes, updateLigne, validateControl, downloadListePrelevement } =
		usePreparation();
	const { camions } = useCamions();
	const [saving, setSaving] = useState(false);
	const [selectedLigne, setSelectedLigne] = useState(order.camion_id ?? "");
	const [nbColis, setNbColis] = useState<number | null>(null);

	// Controller's blind counts + per-line check status
	const [controlCounts, setControlCounts] = useState<Record<string, number | null>>({});
	const [lineStatus, setLineStatus] = useState<Record<string, boolean | null>>({});

	useEffect(() => {
		fetchLignes(order.id);
	}, [order.id, fetchLignes]);

	useEffect(() => {
		setSelectedLigne(order.camion_id ?? "");
	}, [order.camion_id]);

	useEffect(() => {
		if (detail?.lignes) {
			const counts: Record<string, number | null> = {};
			const statuses: Record<string, boolean | null> = {};
			for (const l of detail.lignes) {
				counts[l.id] = null;
				statuses[l.id] = null;
			}
			setControlCounts(counts);
			setLineStatus(statuses);
		}
	}, [detail]);

	const handleCountChange = useCallback((ligneId: string, val: number) => {
		setControlCounts((prev) => ({ ...prev, [ligneId]: val }));
		// Reset status when editing
		setLineStatus((prev) => ({ ...prev, [ligneId]: null }));
	}, []);

	// Vérification explicite : aucun feedback pendant la saisie. Les lignes
	// correctes sont validées ; les lignes fausses sont signalées SANS révéler
	// la quantité attendue, et leur saisie est effacée pour forcer un recomptage.
	const handleCheckCounts = useCallback(() => {
		if (!detail) return;
		let wrong = 0;
		const nextStatus: Record<string, boolean | null> = {};
		const nextCounts: Record<string, number | null> = { ...controlCounts };
		for (const l of detail.lignes) {
			// Les lignes déjà validées restent validées.
			if (lineStatus[l.id] === true) {
				nextStatus[l.id] = true;
				continue;
			}
			const counted = controlCounts[l.id];
			if (counted === null || counted === undefined) {
				nextStatus[l.id] = null;
				continue;
			}
			const correct = counted === l.qte_demandee;
			nextStatus[l.id] = correct;
			if (!correct) {
				wrong += 1;
				nextCounts[l.id] = null;
			}
		}
		setLineStatus(nextStatus);
		setControlCounts(nextCounts);
		if (wrong > 0) {
			toast.warning(
				`${wrong} article${wrong > 1 ? "s" : ""} mal compté${wrong > 1 ? "s" : ""} — recomptez-le${wrong > 1 ? "s" : ""}`,
			);
		} else {
			toast.success("Comptage correct");
		}
	}, [detail, controlCounts, lineStatus]);

	const allEntered = useMemo(() => {
		if (!detail?.lignes.length) return false;
		return detail.lignes.every(
			(l) =>
				lineStatus[l.id] === true ||
				(controlCounts[l.id] !== null && controlCounts[l.id] !== undefined),
		);
	}, [detail, lineStatus, controlCounts]);

	const allCorrect = useMemo(() => {
		if (!detail?.lignes.length) return false;
		return detail.lignes.every((l) => lineStatus[l.id] === true);
	}, [detail, lineStatus]);

	const errorCount = useMemo(() => {
		return Object.values(lineStatus).filter((v) => v === false).length;
	}, [lineStatus]);

	const handleValidate = useCallback(async () => {
		if (!detail || !selectedLigne.length || !nbColis || nbColis < 1) return;
		setSaving(true);
		try {
			for (const l of detail.lignes) {
				const counted = controlCounts[l.id] ?? 0;
				await updateLigne(order.id, l.id, { qte_prelevee: counted, verifie: true });
			}
			// Assign route line (camion)
			await fetchApi(`/commandes/${order.id}/assign-camion`, {
				method: "PATCH",
				body: JSON.stringify({ camion_id: selectedLigne }),
			});
			await validateControl(order.id, nbColis);
			toast.success(
				`Commande validée → Prête — ${nbColis} colis créé${nbColis > 1 ? "s" : ""} (étiquettes disponibles)`,
			);
			onBack();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		} finally {
			setSaving(false);
		}
	}, [
		order.id,
		detail,
		controlCounts,
		selectedLigne,
		nbColis,
		updateLigne,
		validateControl,
		onBack,
	]);

	if (loading || !detail) {
		return (
			<div className="flex flex-col gap-4">
				<Skeleton className="h-10 w-64" />
				<Skeleton className="h-80 rounded-xl" />
			</div>
		);
	}

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center gap-3">
				<Button variant="ghost" size="sm" onClick={onBack} className="gap-1.5">
					<ArrowLeft className="h-4 w-4" />
					Retour
				</Button>
				<div className="flex-1">
					<h2 className="font-heading text-xl font-bold">Contrôle {order.reference_id}</h2>
					<p className="text-[13px] text-muted-foreground">
						{order.pharmacien_nom} — Préparé par : {detail.visa_preparateur ?? "—"}
						{detail.nb_colis ? ` — ${detail.nb_colis} colis` : ""}
					</p>
				</div>
				<Button
					variant="outline"
					size="sm"
					onClick={() => downloadListePrelevement(order.id)}
					className="gap-1.5 text-[12px]"
				>
					<FileDown className="h-3.5 w-3.5" />
					Liste PDF
				</Button>
			</div>

			<div className="flex items-center gap-2 rounded-xl border border-indigo-200 bg-indigo-50 px-4 py-3">
				<ShieldCheck className="h-4 w-4 text-indigo-600" />
				<p className="text-[13px] text-indigo-800">
					Comptez chaque article, saisissez les quantités puis cliquez sur « Vérifier le comptage ».
					Les articles corrects sont validés.
				</p>
			</div>

			{errorCount > 0 && (
				<div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3">
					<XCircle className="h-4 w-4 text-red-600" />
					<p className="text-[13px] text-red-800">
						{errorCount} article{errorCount > 1 ? "s" : ""} mal compté
						{errorCount > 1 ? "s" : ""} — recomptez{" "}
						{errorCount > 1 ? "les articles signalés" : "l'article signalé"} puis vérifiez à
						nouveau.
					</p>
				</div>
			)}

			{allCorrect && (
				<div className="flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3">
					<CheckCircle className="h-4 w-4 text-emerald-600" />
					<p className="text-[13px] text-emerald-800">Tout est correct — vous pouvez valider.</p>
				</div>
			)}

			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Désignation
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Lot
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								PU (DA)
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Votre comptage
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Résultat
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{detail.lignes.map((ligne) => {
							const counted = controlCounts[ligne.id];
							const status = lineStatus[ligne.id];
							return (
								<TableRow
									key={ligne.id}
									className={`border-border/30 hover:bg-muted/40 ${
										status === false ? "bg-red-50/50" : status === true ? "bg-emerald-50/30" : ""
									}`}
								>
									<TableCell className="text-[13px] font-medium">{ligne.designation}</TableCell>
									<TableCell className="font-mono text-[12px] text-muted-foreground">
										{ligne.n_lot || "—"}
									</TableCell>
									<TableCell className="text-right text-[13px] tabular-nums">
										{ligne.prix_unitaire.toLocaleString("fr-FR")}
									</TableCell>
									<TableCell className="text-center">
										<Input
											type="number"
											min={0}
											value={counted ?? ""}
											disabled={status === true}
											onChange={(e) =>
												handleCountChange(ligne.id, Number.parseInt(e.target.value) || 0)
											}
											placeholder="—"
											className={`mx-auto h-8 w-20 text-center text-[13px] tabular-nums ${
												status === false
													? "border-red-400 bg-red-50 text-red-700"
													: status === true
														? "border-emerald-400 bg-emerald-50 text-emerald-700"
														: ""
											}`}
										/>
									</TableCell>
									<TableCell className="text-center">
										{status === null ? (
											<span className="text-[11px] text-muted-foreground/40">—</span>
										) : status ? (
											<span className="inline-flex items-center gap-1 text-[12px] font-semibold text-emerald-600">
												<CheckCircle className="h-4 w-4" />
												Validé
											</span>
										) : (
											// Ne jamais révéler la quantité attendue ni l'écart.
											<span className="text-[12px] font-bold text-red-600">À recompter</span>
										)}
									</TableCell>
								</TableRow>
							);
						})}
					</TableBody>
				</Table>
			</div>

			<div className="flex items-center justify-between rounded-xl border border-border/60 bg-card px-5 py-4 shadow-sm">
				<div className="flex flex-wrap items-center gap-3">
					<Route className="h-4 w-4 text-muted-foreground" />
					<span className="text-[13px] font-medium">Ligne de route</span>
					<Select value={selectedLigne} onValueChange={(value) => setSelectedLigne(value ?? "")}>
						<SelectTrigger className="w-64 rounded-lg border-border/60 bg-background text-[13px]">
							<SelectValue placeholder="Choisir une ligne..." />
						</SelectTrigger>
						<SelectContent>
							{camions.map((c) => (
								<SelectItem key={c.id} value={c.id}>
									{c.nom}
								</SelectItem>
							))}
						</SelectContent>
					</Select>
					<Package className="ml-2 h-4 w-4 text-muted-foreground" />
					<label htmlFor="nb-colis" className="text-[13px] font-medium">
						Nombre de colis
					</label>
					<Input
						id="nb-colis"
						type="number"
						min={1}
						max={500}
						value={nbColis ?? ""}
						onChange={(e) => {
							const v = Number.parseInt(e.target.value, 10);
							setNbColis(Number.isNaN(v) ? null : v);
						}}
						placeholder="—"
						className="h-9 w-20 text-center text-[13px] tabular-nums"
					/>
				</div>
				<div className="flex items-center gap-2">
					<Button
						variant="outline"
						onClick={handleCheckCounts}
						disabled={saving || !allEntered || allCorrect}
						className="gap-1.5 rounded-lg text-[13px] font-semibold"
					>
						<ShieldCheck className="h-4 w-4" />
						Vérifier le comptage
					</Button>
					<Button
						onClick={handleValidate}
						disabled={saving || !allCorrect || !selectedLigne.length || !nbColis || nbColis < 1}
						className="gap-1.5 rounded-lg bg-gradient-to-r from-[#0F766E] to-[#0D9488] text-[13px] font-semibold text-white shadow-sm hover:brightness-110"
					>
						{saving ? (
							<Loader2 className="h-4 w-4 animate-spin" />
						) : (
							<CheckCircle className="h-4 w-4" />
						)}
						Valider → Prête
					</Button>
				</div>
			</div>
		</div>
	);
}
