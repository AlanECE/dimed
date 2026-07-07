"use client";

import { CaddieSelectDialog } from "@/components/caddie-select-dialog";
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
import { VignetteCaptureDialog } from "@/components/vignette-capture-dialog";
import { VignettePreviewModal } from "@/components/vignette-preview-modal";
import { useOrders } from "@/hooks/use-orders";
import { type UpdateLignePatch, usePreparation } from "@/hooks/use-preparation";
import { API_BASE } from "@/lib/api";
import type {
	CaddiePoolResponse,
	LignePreparationResponse,
	OrderResponse,
	VignetteResponse,
	VignetteWarning,
} from "@/lib/types";
import {
	ArrowLeft,
	CheckCircle2,
	ClipboardList,
	FileDown,
	Loader2,
	Package,
	Play,
	ScanLine,
	ShoppingCart,
	X,
} from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
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

	const { startPreparation } = usePreparation();
	const [pendingOrder, setPendingOrder] = useState<OrderResponse | null>(null);

	const refetchAll = useCallback(() => {
		refetchAcceptees();
		refetchEnPrep();
	}, [refetchAcceptees, refetchEnPrep]);

	const handleStartClick = useCallback((order: OrderResponse) => {
		setPendingOrder(order);
	}, []);

	const handleCaddieConfirm = useCallback(
		async (caddie: CaddiePoolResponse) => {
			if (!pendingOrder) return;
			try {
				await startPreparation(pendingOrder.id, caddie.id);
				toast.success(`Préparation démarrée — Caddie ${caddie.numero}`);
				const started = { ...pendingOrder, statut: "en_preparation" };
				setPendingOrder(null);
				refetchAll();
				onSelect(started);
			} catch (err) {
				toast.error(err instanceof Error ? err.message : "Caddie indisponible");
			}
		},
		[pendingOrder, startPreparation, refetchAll, onSelect],
	);

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
			</div>

			<OrderSection
				title="À préparer"
				orders={acceptees}
				loading={loadingAcceptees}
				badgeClass="bg-amber-100 text-amber-700"
				action={(order) => (
					<Button
						size="sm"
						onClick={() => handleStartClick(order)}
						className="h-8 gap-1.5 rounded-lg bg-primary text-[12px] font-semibold shadow-sm hover:brightness-110"
					>
						<Play className="h-3.5 w-3.5" />
						Commencer
					</Button>
				)}
			/>

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

			<CaddieSelectDialog
				open={pendingOrder !== null}
				commandeRef={pendingOrder?.reference_id ?? ""}
				onOpenChange={(open) => {
					if (!open) setPendingOrder(null);
				}}
				onConfirm={handleCaddieConfirm}
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
}: {
	title: string;
	orders: OrderResponse[];
	loading: boolean;
	badgeClass: string;
	action: (order: OrderResponse) => React.ReactNode;
}) {
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
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Caddie
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Action
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 3 }).map((_, i) => (
								<TableRow key={`sk-${i}`} className="border-border/30">
									{Array.from({ length: 6 }).map((_, j) => (
										<TableCell key={`sk-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : orders.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={6}
									className="py-12 text-center text-[13px] text-muted-foreground"
								>
									Aucune commande
								</TableCell>
							</TableRow>
						) : (
							orders.map((order) => (
								<TableRow key={order.id} className="border-border/30 hover:bg-muted/40">
									<TableCell className="font-mono text-[13px]">{order.reference_id}</TableCell>
									<TableCell className="text-[13px]">{order.pharmacien_nom ?? "—"}</TableCell>
									<TableCell className="text-right text-[13px] font-semibold tabular-nums">
										{order.montant_total.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell>
										<StatusBadge status={order.statut} />
									</TableCell>
									<TableCell className="text-[12px] text-muted-foreground">
										{order.caddie_pool ? (
											<span className="inline-flex items-center gap-1 rounded-md bg-primary/10 px-2 py-0.5 font-semibold text-primary">
												<ShoppingCart className="h-3 w-3" />
												{order.caddie_pool.numero}
											</span>
										) : (
											"—"
										)}
									</TableCell>
									<TableCell className="text-right">{action(order)}</TableCell>
								</TableRow>
							))
						)}
					</TableBody>
				</Table>
			</div>
		</section>
	);
}

// ---------------------------------------------------------------------------
// Detail view — article by article preparation with per-line OCR scan
// ---------------------------------------------------------------------------

function PreparationDetail({ order, onBack }: { order: OrderResponse; onBack: () => void }) {
	const {
		detail,
		loading,
		fetchLignes,
		updateLigne,
		finalizePreparation,
		downloadListePrelevement,
		scanLigneVignette,
		clearLigneVignette,
	} = usePreparation();
	const [localLignes, setLocalLignes] = useState<LignePreparationResponse[]>([]);
	const [saving, setSaving] = useState(false);
	const [scanningId, setScanningId] = useState<string | null>(null);
	const [justScannedId, setJustScannedId] = useState<string | null>(null);
	const [pulseCheckId, setPulseCheckId] = useState<string | null>(null);
	const [previewVignette, setPreviewVignette] = useState<VignetteResponse | null>(null);
	const [captureForLineId, setCaptureForLineId] = useState<string | null>(null);

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
		}
	}, [detail]);

	const patchLigne = useCallback(
		async (
			ligneId: string,
			patch: UpdateLignePatch,
			optimistic?: Partial<LignePreparationResponse>,
		) => {
			if (optimistic) {
				setLocalLignes((prev) => prev.map((l) => (l.id === ligneId ? { ...l, ...optimistic } : l)));
			}
			try {
				await updateLigne(order.id, ligneId, patch);
			} catch {
				toast.error("Erreur mise à jour");
				fetchLignes(order.id);
			}
		},
		[order.id, updateLigne, fetchLignes],
	);

	const handleToggle = useCallback(
		(ligne: LignePreparationResponse) => {
			const newVerifie = !ligne.verifie;
			// En cochant "vérifié", on persiste aussi la quantité prélevée (sinon elle
			// reste NULL côté serveur si le préparateur n'a pas touché au champ).
			const patch: UpdateLignePatch = newVerifie
				? { verifie: true, qte_prelevee: ligne.qte_prelevee ?? ligne.qte_demandee }
				: { verifie: false };
			void patchLigne(ligne.id, patch, { verifie: newVerifie });
		},
		[patchLigne],
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
			void patchLigne(ligne.id, { qte_prelevee: current.qte_prelevee ?? 0 });
		},
		[localLignes, patchLigne],
	);

	// Manual edit on lot/fab/exp/ppa decoche verifie
	const handleFieldEdit = useCallback(
		(ligne: LignePreparationResponse, field: "n_lot" | "fab" | "exp" | "ppa", value: string) => {
			const cleaned = value.trim() === "" ? null : value;
			setLocalLignes((prev) =>
				prev.map((l) => (l.id === ligne.id ? { ...l, [field]: cleaned, verifie: false } : l)),
			);
			void patchLigne(ligne.id, { [field]: cleaned, verifie: false });
		},
		[patchLigne],
	);

	const handleScanClick = useCallback((ligneId: string) => {
		setCaptureForLineId(ligneId);
	}, []);

	const handleFileSelected = useCallback(
		async (ligne: LignePreparationResponse, file: File) => {
			setScanningId(ligne.id);
			try {
				const result = await scanLigneVignette(order.id, ligne.id, file);
				setLocalLignes((prev) => prev.map((l) => (l.id === ligne.id ? result.ligne : l)));
				setJustScannedId(ligne.id);
				if (result.warnings.length === 0) {
					setPulseCheckId(ligne.id);
					toast.success("Vignette scannée et validée");
				} else {
					toast.warning(formatWarnings(result.warnings));
				}
				setTimeout(() => setJustScannedId(null), 800);
				setTimeout(() => setPulseCheckId(null), 700);
			} catch (err) {
				toast.error(err instanceof Error ? err.message : "Erreur OCR");
			} finally {
				setScanningId(null);
			}
		},
		[order.id, scanLigneVignette],
	);

	const handleClearVignette = useCallback(
		async (ligne: LignePreparationResponse) => {
			try {
				await clearLigneVignette(order.id, ligne.id);
			} catch (err) {
				// Treat 404 as already-cleared (state was stale): no-op + silent.
				const is404 = err instanceof Error && /404|not found/i.test(err.message);
				if (!is404) {
					toast.error("Erreur suppression vignette");
					return;
				}
			}
			setLocalLignes((prev) =>
				prev.map((l) =>
					l.id === ligne.id
						? {
								...l,
								vignette: null,
								n_lot: null,
								fab: null,
								exp: null,
								ppa: null,
								verifie: false,
							}
						: l,
				),
			);
			setPreviewVignette(null);
			toast.success("Vignette retirée");
		},
		[order.id, clearLigneVignette],
	);

	const allVerified = localLignes.length > 0 && localLignes.every((l) => l.verifie);
	const missingExp = localLignes.filter((l) => !l.exp).length;

	const handleFinalize = useCallback(async () => {
		setSaving(true);
		try {
			if (missingExp > 0) {
				toast.warning(
					`Attention : ${missingExp} ligne${missingExp > 1 ? "s" : ""} sans date de péremption`,
				);
			}
			await finalizePreparation(order.id);
			toast.success("Préparation envoyée au contrôleur");
			onBack();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		} finally {
			setSaving(false);
		}
	}, [order.id, finalizePreparation, onBack, missingExp]);

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

			<VignettePreviewModal
				vignette={previewVignette}
				onClose={() => setPreviewVignette(null)}
				onRescan={() => {
					const ligne = localLignes.find((l) => l.vignette?.id === previewVignette?.id);
					if (ligne) {
						setPreviewVignette(null);
						setCaptureForLineId(ligne.id);
					}
				}}
				onDelete={() => {
					const ligne = localLignes.find((l) => l.vignette?.id === previewVignette?.id);
					if (ligne) void handleClearVignette(ligne);
				}}
			/>

			<VignetteCaptureDialog
				open={captureForLineId !== null}
				onOpenChange={(open) => {
					if (!open) setCaptureForLineId(null);
				}}
				onCapture={(file) => {
					const ligne = localLignes.find((l) => l.id === captureForLineId);
					if (ligne) void handleFileSelected(ligne, file);
				}}
			/>

			{order.caddie_pool && (
				<div className="flex items-center gap-2 rounded-lg border border-primary/30 bg-primary/5 px-4 py-2.5">
					<ShoppingCart className="h-4 w-4 text-primary" />
					<span className="text-[12px] font-semibold uppercase tracking-wider text-primary">
						Caddie affecté :
					</span>
					<span className="inline-flex items-center rounded-md bg-primary/15 px-2 py-0.5 text-[12px] font-semibold text-primary">
						{order.caddie_pool.numero}
					</span>
				</div>
			)}

			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="w-14 text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								OK
							</TableHead>
							<TableHead className="w-14 text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								&nbsp;
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Désignation
							</TableHead>
							<TableHead className="w-28 text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Lot
							</TableHead>
							<TableHead className="w-28 text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Fab
							</TableHead>
							<TableHead className="w-28 text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Exp
							</TableHead>
							<TableHead className="w-28 text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								PPA
							</TableHead>
							<TableHead className="w-20 text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Dem.
							</TableHead>
							<TableHead className="w-24 text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Prél.
							</TableHead>
							<TableHead className="w-36 text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								OCR
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{localLignes.map((ligne) => {
							const isPartial = (ligne.qte_prelevee ?? 0) < ligne.qte_demandee;
							const isScanning = scanningId === ligne.id;
							const justScanned = justScannedId === ligne.id;
							const shouldPulse = pulseCheckId === ligne.id;
							return (
								<TableRow
									key={ligne.id}
									className={`group border-border/30 transition-colors hover:bg-muted/40 ${
										isScanning ? "scan-row" : ""
									} ${ligne.verifie ? "bg-emerald-50/40" : ""}`}
								>
									<TableCell className="text-center">
										<span className={shouldPulse ? "pulse-check inline-block" : "inline-block"}>
											<Checkbox
												checked={ligne.verifie}
												onCheckedChange={() => handleToggle(ligne)}
												aria-label="Verifie"
											/>
										</span>
									</TableCell>
									<TableCell>
										<div className="relative">
											<button
												type="button"
												disabled={!ligne.vignette}
												onClick={() => ligne.vignette && setPreviewVignette(ligne.vignette)}
												className={`block h-9 w-9 overflow-hidden rounded-md border border-amber-300/60 bg-gradient-to-br from-amber-200 to-amber-400 transition ${
													ligne.vignette
														? "cursor-zoom-in hover:scale-105"
														: "cursor-default opacity-40"
												}`}
												aria-label="Aperçu vignette"
											>
												{ligne.vignette && (
													<img
														src={`${API_BASE}${ligne.vignette.file_url}`}
														alt=""
														className="h-full w-full object-cover"
													/>
												)}
											</button>
											{ligne.vignette && (
												<button
													type="button"
													onClick={() => handleClearVignette(ligne)}
													className="absolute -right-1 -top-1 hidden h-4 w-4 items-center justify-center rounded-full bg-red-500 text-white shadow group-hover:flex"
													aria-label="Retirer la vignette"
												>
													<X className="h-2.5 w-2.5" />
												</button>
											)}
										</div>
									</TableCell>
									<TableCell className="text-[13px] font-medium">{ligne.designation}</TableCell>
									<td colSpan={4} className="p-0">
										<div className={`grid grid-cols-4 ${justScanned ? "reveal-staggered" : ""}`}>
											<div className="px-2 py-1.5">
												<Input
													value={ligne.n_lot ?? ""}
													onChange={(e) => handleFieldEdit(ligne, "n_lot", e.target.value)}
													placeholder="—"
													className="h-7 font-mono text-[12px]"
												/>
											</div>
											<div className="px-2 py-1.5">
												<Input
													type="date"
													value={ligne.fab ?? ""}
													onChange={(e) => handleFieldEdit(ligne, "fab", e.target.value)}
													className="h-7 font-mono text-[12px]"
												/>
											</div>
											<div className="px-2 py-1.5">
												<Input
													type="date"
													value={ligne.exp ?? ""}
													onChange={(e) => handleFieldEdit(ligne, "exp", e.target.value)}
													className="h-7 font-mono text-[12px]"
												/>
											</div>
											<div className="px-2 py-1.5">
												{/* Le PPA de la vignette fait foi — aucune alerte de divergence
												    avec le prix catalogue. */}
												<Input
													type="number"
													step="0.01"
													value={ligne.ppa ?? ""}
													onChange={(e) => handleFieldEdit(ligne, "ppa", e.target.value)}
													placeholder="—"
													className="h-7 font-mono text-[12px] tabular-nums"
												/>
											</div>
										</div>
									</td>
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
											className={`mx-auto h-7 w-20 text-center text-[13px] tabular-nums ${
												isPartial ? "border-red-300 text-red-700" : ""
											}`}
										/>
									</TableCell>
									<TableCell className="text-center">
										<Button
											size="sm"
											variant={ligne.vignette ? "secondary" : "outline"}
											disabled={isScanning}
											onClick={() => handleScanClick(ligne.id)}
											className="h-7 gap-1 text-[11px]"
										>
											{isScanning ? (
												<>
													<Loader2 className="h-3 w-3 animate-spin" />
													Analyse…
												</>
											) : (
												<>
													<ScanLine className="h-3 w-3" />
													{ligne.vignette ? "Re-scan" : "Scanner"}
												</>
											)}
										</Button>
									</TableCell>
								</TableRow>
							);
						})}
					</TableBody>
				</Table>
			</div>

			<div className="flex items-center justify-end rounded-xl border border-border/60 bg-card px-5 py-4 shadow-sm">
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

function formatWarnings(warnings: VignetteWarning[]): string {
	const labels: Record<VignetteWarning, string> = {
		ppa_divergent: "PPA divergent du catalogue",
		missing_lot: "lot manquant",
		missing_fab: "date de fabrication manquante",
		missing_exp: "date de péremption manquante",
		missing_ppa: "PPA manquant",
	};
	return `Vérification : ${warnings.map((w) => labels[w]).join(", ")}`;
}
