"use client";

import { BulkClaimDialog } from "@/components/bulk-claim-dialog";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
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
import { useOrderAction } from "@/hooks/use-order-action";
import { useOrders } from "@/hooks/use-orders";
import { usePreparation } from "@/hooks/use-preparation";
import { useAuth } from "@/lib/auth";
import type { LignePreparationResponse, OrderResponse } from "@/lib/types";
import {
	ArrowLeft,
	CheckCircle2,
	ClipboardList,
	FileDown,
	Loader2,
	Package,
	Play,
	Truck,
} from "lucide-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

export default function PreparationPage() {
	const [selectedOrder, setSelectedOrder] = useState<OrderResponse | null>(null);

	if (selectedOrder) {
		return <PreparationDetail order={selectedOrder} onBack={() => setSelectedOrder(null)} />;
	}

	return <PreparationList onSelect={setSelectedOrder} />;
}

// ---------------------------------------------------------------------------
// List view
// ---------------------------------------------------------------------------

function PreparationList({ onSelect }: { onSelect: (o: OrderResponse) => void }) {
	const { user } = useAuth();
	const {
		orders: acceptees,
		loading: loadingAcceptees,
		refetch: refetchAcceptees,
	} = useOrders({ statut: "acceptee" });
	const {
		orders: enPrep,
		loading: loadingEnPrep,
		refetch: refetchEnPrep,
	} = useOrders({ statut: "en_preparation" });

	const refetchAll = useCallback(() => {
		refetchAcceptees();
		refetchEnPrep();
	}, [refetchAcceptees, refetchEnPrep]);

	const { execute: startPrep, loading: starting } = useOrderAction("start-preparation", refetchAll);

	const canBulkClaim =
		user?.role === "preparateur" || user?.role === "operatrice" || user?.role === "admin";
	const [selectionMode, setSelectionMode] = useState(false);
	const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
	const [dialogOpen, setDialogOpen] = useState(false);

	const selectedCommandes = useMemo(
		() => acceptees.filter((o) => selectedIds.has(o.id)),
		[acceptees, selectedIds],
	);

	const handleStart = useCallback(
		async (order: OrderResponse) => {
			await startPrep(order.id);
			onSelect({ ...order, statut: "en_preparation" });
		},
		[startPrep, onSelect],
	);

	function toggleSelect(id: string) {
		setSelectedIds((prev) => {
			const next = new Set(prev);
			if (next.has(id)) next.delete(id);
			else next.add(id);
			return next;
		});
	}

	function exitSelectionMode() {
		setSelectionMode(false);
		setSelectedIds(new Set());
	}

	return (
		<div className="flex flex-col gap-8">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10">
					<Package className="h-5 w-5 text-primary" />
				</div>
				<div className="flex-1">
					<h2 className="font-heading text-xl font-bold">Préparation des commandes</h2>
					<p className="text-[13px] text-muted-foreground">Prélèvement article par article</p>
				</div>
				{canBulkClaim && !selectionMode && (
					<Button
						variant="outline"
						size="sm"
						onClick={() => setSelectionMode(true)}
						className="gap-1.5 rounded-lg text-[12px] font-semibold"
					>
						<Truck className="h-3.5 w-3.5" />
						Mode wave-picking
					</Button>
				)}
				{selectionMode && (
					<div className="flex items-center gap-2">
						<Button variant="ghost" size="sm" onClick={exitSelectionMode} className="text-[12px]">
							Annuler
						</Button>
						<Button
							size="sm"
							disabled={selectedIds.size === 0}
							onClick={() => setDialogOpen(true)}
							className="gap-1.5 rounded-lg bg-primary text-[12px] font-semibold shadow-sm hover:brightness-110"
						>
							<Truck className="h-3.5 w-3.5" />
							Prendre en charge ({selectedIds.size})
						</Button>
					</div>
				)}
			</div>

			{/* À préparer */}
			<OrderSection
				title="À préparer"
				orders={acceptees}
				loading={loadingAcceptees}
				badgeClass="bg-amber-100 text-amber-700"
				selectionMode={selectionMode}
				selectedIds={selectedIds}
				onToggleSelect={toggleSelect}
				action={(order) =>
					selectionMode ? null : (
						<Button
							size="sm"
							onClick={() => handleStart(order)}
							disabled={starting}
							className="h-8 gap-1.5 rounded-lg bg-primary text-[12px] font-semibold shadow-sm hover:brightness-110"
						>
							{starting ? (
								<Loader2 className="h-3.5 w-3.5 animate-spin" />
							) : (
								<Play className="h-3.5 w-3.5" />
							)}
							Commencer
						</Button>
					)
				}
			/>

			{/* En cours */}
			<OrderSection
				title="En cours de préparation"
				orders={enPrep}
				loading={loadingEnPrep}
				badgeClass="bg-blue-100 text-blue-700"
				action={(order) => (
					<Button
						size="sm"
						variant="outline"
						onClick={() => onSelect(order)}
						className="h-8 gap-1.5 rounded-lg text-[12px] font-semibold"
					>
						<ClipboardList className="h-3.5 w-3.5" />
						Continuer
					</Button>
				)}
			/>

			<BulkClaimDialog
				open={dialogOpen}
				commandes={selectedCommandes}
				onOpenChange={setDialogOpen}
				onDone={() => {
					exitSelectionMode();
					refetchAll();
				}}
			/>
		</div>
	);
}

function OrderSection({
	title,
	orders,
	loading,
	badgeClass,
	action,
	selectionMode = false,
	selectedIds,
	onToggleSelect,
}: {
	title: string;
	orders: OrderResponse[];
	loading: boolean;
	badgeClass: string;
	action: (order: OrderResponse) => React.ReactNode;
	selectionMode?: boolean;
	selectedIds?: Set<string>;
	onToggleSelect?: (id: string) => void;
}) {
	const cols = selectionMode ? 6 : 5;
	return (
		<section className="animate-fade-in-up flex flex-col gap-3">
			<div className="flex items-center gap-2.5">
				<h3 className="text-[15px] font-semibold">{title}</h3>
				<span
					className={`flex h-6 min-w-6 items-center justify-center rounded-full px-2 text-[11px] font-bold ${badgeClass}`}
				>
					{orders.length}
				</span>
			</div>
			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							{selectionMode && <TableHead className="w-10" />}
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
								{selectionMode ? "Caddies" : "Action"}
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 3 }).map((_, i) => (
								<TableRow key={`sk-${i}`} className="border-border/30">
									{Array.from({ length: cols }).map((_, j) => (
										<TableCell key={`sk-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : orders.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={cols}
									className="py-12 text-center text-[13px] text-muted-foreground"
								>
									Aucune commande
								</TableCell>
							</TableRow>
						) : (
							orders.map((order) => {
								const checked = selectedIds?.has(order.id) ?? false;
								return (
									<TableRow
										key={order.id}
										className={`border-border/30 hover:bg-muted/40 ${
											checked ? "bg-primary/5" : ""
										}`}
									>
										{selectionMode && (
											<TableCell>
												<Checkbox
													checked={checked}
													onCheckedChange={() => onToggleSelect?.(order.id)}
													aria-label={`Selectionner ${order.reference_id}`}
												/>
											</TableCell>
										)}
										<TableCell className="font-mono text-[13px]">{order.reference_id}</TableCell>
										<TableCell className="text-[13px]">{order.pharmacien_nom ?? "—"}</TableCell>
										<TableCell className="text-right text-[13px] font-semibold tabular-nums">
											{order.montant_total.toLocaleString("fr-FR")} DA
										</TableCell>
										<TableCell>
											<StatusBadge status={order.statut} />
										</TableCell>
										<TableCell className="text-right">
											{selectionMode ? (
												<span className="text-[12px] text-muted-foreground">
													{order.caddies?.length
														? order.caddies.map((c) => c.numero).join(", ")
														: "—"}
												</span>
											) : (
												action(order)
											)}
										</TableCell>
									</TableRow>
								);
							})
						)}
					</TableBody>
				</Table>
			</div>
		</section>
	);
}

// ---------------------------------------------------------------------------
// Detail view — article by article preparation
// ---------------------------------------------------------------------------

function PreparationDetail({ order, onBack }: { order: OrderResponse; onBack: () => void }) {
	const {
		detail,
		loading,
		fetchLignes,
		updateLigne,
		finalizePreparation,
		downloadListePrelevement,
	} = usePreparation();
	const [localLignes, setLocalLignes] = useState<LignePreparationResponse[]>([]);
	const [nbColis, setNbColis] = useState(1);
	const [saving, setSaving] = useState(false);

	useEffect(() => {
		fetchLignes(order.id);
	}, [order.id, fetchLignes]);

	useEffect(() => {
		if (detail?.lignes) {
			setLocalLignes(
				detail.lignes.map((l) => ({
					...l,
					qte_prelevee: l.qte_prelevee ?? l.qte_demandee,
				})),
			);
			if (detail.nb_colis) setNbColis(detail.nb_colis);
		}
	}, [detail]);

	const handleToggle = useCallback(
		async (ligne: LignePreparationResponse) => {
			const newVerifie = !ligne.verifie;
			const qte = ligne.qte_prelevee ?? ligne.qte_demandee;
			setLocalLignes((prev) =>
				prev.map((l) => (l.id === ligne.id ? { ...l, verifie: newVerifie } : l)),
			);
			try {
				await updateLigne(order.id, ligne.id, qte, newVerifie);
			} catch {
				toast.error("Erreur mise à jour");
				setLocalLignes((prev) =>
					prev.map((l) => (l.id === ligne.id ? { ...l, verifie: !newVerifie } : l)),
				);
			}
		},
		[order.id, updateLigne],
	);

	const handleOcrToggle = useCallback(
		async (ligne: LignePreparationResponse) => {
			const newOcr = !ligne.ocr_verifie;
			setLocalLignes((prev) =>
				prev.map((l) => (l.id === ligne.id ? { ...l, ocr_verifie: newOcr } : l)),
			);
			try {
				await updateLigne(order.id, ligne.id, null, null, newOcr);
			} catch {
				toast.error("Erreur mise à jour OCR");
				setLocalLignes((prev) =>
					prev.map((l) => (l.id === ligne.id ? { ...l, ocr_verifie: !newOcr } : l)),
				);
			}
		},
		[order.id, updateLigne],
	);

	const handleQteChange = useCallback((ligne: LignePreparationResponse, qte: number) => {
		setLocalLignes((prev) =>
			prev.map((l) => (l.id === ligne.id ? { ...l, qte_prelevee: qte } : l)),
		);
	}, []);

	const handleQteBlur = useCallback(
		async (ligne: LignePreparationResponse) => {
			const current = localLignes.find((l) => l.id === ligne.id);
			if (!current) return;
			try {
				await updateLigne(order.id, ligne.id, current.qte_prelevee ?? 0, current.verifie);
			} catch {
				toast.error("Erreur sauvegarde quantité");
			}
		},
		[order.id, localLignes, updateLigne],
	);

	const allVerified = localLignes.length > 0 && localLignes.every((l) => l.verifie);

	const handleFinalize = useCallback(async () => {
		setSaving(true);
		try {
			await finalizePreparation(order.id, nbColis);
			toast.success("Préparation finalisée → En vérification");
			onBack();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		} finally {
			setSaving(false);
		}
	}, [order.id, nbColis, finalizePreparation, onBack]);

	if (loading) {
		return (
			<div className="flex flex-col gap-4">
				<Skeleton className="h-10 w-64" />
				<Skeleton className="h-80 rounded-xl" />
			</div>
		);
	}

	return (
		<div className="flex flex-col gap-6">
			{/* Header */}
			<div className="flex items-center gap-3">
				<Button variant="ghost" size="sm" onClick={onBack} className="gap-1.5">
					<ArrowLeft className="h-4 w-4" />
					Retour
				</Button>
				<div className="flex-1">
					<h2 className="font-heading text-xl font-bold">Préparation {order.reference_id}</h2>
					<p className="text-[13px] text-muted-foreground">
						{order.pharmacien_nom} — {order.montant_total.toLocaleString("fr-FR")} DA
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

			{/* Caddies affectes */}
			{order.caddies && order.caddies.length > 0 && (
				<div className="flex items-center gap-2 rounded-lg border border-primary/30 bg-primary/5 px-4 py-2.5">
					<Truck className="h-4 w-4 text-primary" />
					<span className="text-[12px] font-semibold uppercase tracking-wider text-primary">
						Caddies affectes :
					</span>
					<div className="flex flex-wrap gap-1.5">
						{order.caddies.map((c) => (
							<span
								key={c.id}
								className="inline-flex items-center rounded-md bg-primary/15 px-2 py-0.5 text-[12px] font-semibold text-primary"
							>
								{c.numero}
							</span>
						))}
					</div>
				</div>
			)}

			{/* Article list */}
			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="w-12 text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Vérifié
							</TableHead>
							<TableHead className="w-12 text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								OCR
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Désignation
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Lot
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Qté dem.
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Qté prél.
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								PU (DA)
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{localLignes.map((ligne) => {
							const isPartial = (ligne.qte_prelevee ?? 0) < ligne.qte_demandee;
							const fullyValidated = ligne.verifie && ligne.ocr_verifie;
							return (
								<TableRow
									key={ligne.id}
									className={`border-border/30 transition-colors hover:bg-muted/40 ${
										fullyValidated
											? "bg-emerald-100/60"
											: ligne.verifie || ligne.ocr_verifie
												? "bg-emerald-50/30"
												: ""
									}`}
								>
									<TableCell className="text-center">
										<Checkbox
											checked={ligne.verifie}
											onCheckedChange={() => handleToggle(ligne)}
											aria-label="Verifie"
										/>
									</TableCell>
									<TableCell className="text-center">
										<Checkbox
											checked={ligne.ocr_verifie}
											onCheckedChange={() => handleOcrToggle(ligne)}
											aria-label="OCR"
										/>
									</TableCell>
									<TableCell className="text-[13px] font-medium">{ligne.designation}</TableCell>
									<TableCell className="font-mono text-[12px] text-muted-foreground">
										{ligne.n_lot || "—"}
									</TableCell>
									<TableCell className="text-center text-[13px] tabular-nums">
										{ligne.qte_demandee}
									</TableCell>
									<TableCell className="text-center">
										<Input
											type="number"
											min={0}
											max={ligne.qte_demandee}
											value={ligne.qte_prelevee ?? ""}
											onChange={(e) => handleQteChange(ligne, Number.parseInt(e.target.value) || 0)}
											onBlur={() => handleQteBlur(ligne)}
											className={`mx-auto h-8 w-20 text-center text-[13px] tabular-nums ${
												isPartial ? "border-red-300 text-red-700" : ""
											}`}
										/>
									</TableCell>
									<TableCell className="text-right text-[13px] tabular-nums">
										{ligne.prix_unitaire.toLocaleString("fr-FR")}
									</TableCell>
								</TableRow>
							);
						})}
					</TableBody>
				</Table>
			</div>

			{/* Footer: nb colis + finalize */}
			<div className="flex items-center justify-between rounded-xl border border-border/60 bg-card px-5 py-4 shadow-sm">
				<div className="flex items-center gap-3">
					<label htmlFor="nb-colis" className="text-[13px] font-medium">
						Nombre de colis
					</label>
					<Input
						id="nb-colis"
						type="number"
						min={1}
						value={nbColis}
						onChange={(e) => setNbColis(Number.parseInt(e.target.value) || 1)}
						className="h-8 w-20 text-center text-[13px]"
					/>
				</div>
				<Button
					onClick={handleFinalize}
					disabled={!allVerified || saving}
					className="gap-1.5 rounded-lg bg-gradient-to-r from-[#0F766E] to-[#0D9488] text-[12px] font-semibold text-white shadow-sm hover:brightness-110"
				>
					{saving ? (
						<Loader2 className="h-3.5 w-3.5 animate-spin" />
					) : (
						<CheckCircle2 className="h-3.5 w-3.5" />
					)}
					Finaliser la préparation ({localLignes.filter((l) => l.verifie).length}/
					{localLignes.length})
				</Button>
			</div>
		</div>
	);
}
