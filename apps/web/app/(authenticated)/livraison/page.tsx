"use client";

import { QrScanner } from "@/components/qr-scanner";
import { SignaturePad } from "@/components/signature-pad";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { useExpedition } from "@/hooks/use-expedition";
import { useOrderAction } from "@/hooks/use-order-action";
import { useTodayRoute } from "@/hooks/use-today-route";
import type { ChargementState, ColisManquants, RouteSheetTodayCommande } from "@/lib/types";
import {
	AlertTriangle,
	CheckCircle2,
	ClipboardCheck,
	Loader2,
	MapPin,
	Package,
	PackageCheck,
	PenLine,
	ScanLine,
	Truck,
	XCircle,
} from "lucide-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

function CounterCard({
	label,
	value,
	icon,
}: { label: string; value: number; icon: React.ReactNode }) {
	return (
		<div className="flex items-center gap-3 rounded-xl border border-border/60 bg-card px-4 py-3 shadow-sm">
			<div className="flex h-9 w-9 items-center justify-center rounded-lg bg-teal-50">{icon}</div>
			<div>
				<p className="text-[22px] font-bold tabular-nums leading-tight">{value}</p>
				<p className="text-[11px] text-muted-foreground">{label}</p>
			</div>
		</div>
	);
}

// ---------------------------------------------------------------------------
// Main page
// ---------------------------------------------------------------------------

export default function LivraisonPage() {
	const {
		feuille,
		loading,
		error,
		refetch,
		validateLoading,
		signSheet,
		deliverWithSignature,
		markFailed,
		claimToday,
	} = useTodayRoute();

	const { execute: startDeliveryAll, loading: startingAll } = useOrderAction(
		"start-delivery",
		refetch,
	);
	const { scanChargement, scanLivraison, fetchChargement } = useExpedition();

	// Per-parcel loading state (real-time truck content)
	const [chargement, setChargement] = useState<ChargementState | null>(null);
	const [manquants, setManquants] = useState<ColisManquants[] | null>(null);

	// Signature dialogs
	const [signDialog, setSignDialog] = useState<"expedition" | "chauffeur" | null>(null);
	const [deliverDialog, setDeliverDialog] = useState<RouteSheetTodayCommande | null>(null);
	const [failDialog, setFailDialog] = useState<RouteSheetTodayCommande | null>(null);
	const [failMotif, setFailMotif] = useState("");
	const [failAction, setFailAction] = useState<"refuse" | "retourne">("refuse");
	const [saving, setSaving] = useState(false);
	const [scanning, setScanning] = useState(false);
	const [claiming, setClaiming] = useState(false);

	// Computed
	const pretesOrders = useMemo(
		() => feuille?.commandes.filter((c) => c.statut === "prete") ?? [],
		[feuille],
	);
	const enRouteOrders = useMemo(
		() => feuille?.commandes.filter((c) => c.statut === "en_route") ?? [],
		[feuille],
	);
	const doneOrders = useMemo(
		() =>
			feuille?.commandes.filter((c) =>
				["livree", "refusee", "retournee", "livree_partiellement"].includes(c.statut),
			) ?? [],
		[feuille],
	);

	const canStartTournee =
		feuille?.chargement_valide && feuille?.signature_expedition && feuille?.signature_chauffeur;

	const refreshChargement = useCallback(async () => {
		if (!feuille) return;
		try {
			setChargement(await fetchChargement(feuille.id));
		} catch {
			// l'état du camion est complémentaire — ne bloque pas la page
		}
	}, [feuille, fetchChargement]);

	useEffect(() => {
		refreshChargement();
	}, [refreshChargement]);

	const handleScanChargement = useCallback(
		async (numero: string) => {
			if (scanning) return;
			setScanning(true);
			try {
				const res = await scanChargement(numero);
				if (res.deja_scanne) {
					toast.info(`${numero} déjà scanné (${res.charges}/${res.total})`);
				} else if (res.commande_complete) {
					toast.success(`Commande ${res.commande_ref} complète — ${res.charges}/${res.total}`);
				} else {
					toast.success(`${numero} chargé — ${res.commande_ref} : ${res.charges}/${res.total}`);
				}
				setManquants(null);
				await refreshChargement();
			} catch (err) {
				toast.error(err instanceof Error ? err.message : "Colis non reconnu");
			} finally {
				setScanning(false);
			}
		},
		[scanning, scanChargement, refreshChargement],
	);

	const handleValidateLoading = useCallback(async () => {
		if (!feuille) return;
		setSaving(true);
		try {
			const result = await validateLoading(feuille.id);
			if (result.ok) {
				setManquants(null);
				toast.success("Chargement validé");
			} else {
				setManquants(result.manquants);
				const nb = result.manquants.reduce((acc, m) => acc + m.colis.length, 0);
				toast.warning(`${nb} colis manquant${nb > 1 ? "s" : ""} — voir la liste`);
			}
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur validation");
		} finally {
			setSaving(false);
		}
	}, [feuille, validateLoading]);

	const handleSign = useCallback(
		async (base64: string) => {
			if (!feuille || !signDialog) return;
			setSaving(true);
			try {
				await signSheet(feuille.id, signDialog, base64);
				toast.success(
					`Signature ${signDialog === "expedition" ? "expédition" : "chauffeur"} enregistrée`,
				);
				setSignDialog(null);
			} catch (err) {
				toast.error(err instanceof Error ? err.message : "Erreur signature");
			} finally {
				setSaving(false);
			}
		},
		[feuille, signDialog, signSheet],
	);

	const handleStartTournee = useCallback(async () => {
		try {
			for (const order of pretesOrders) {
				await startDeliveryAll(order.id);
			}
			toast.success("Tournée démarrée");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur au démarrage");
			refetch();
		}
	}, [pretesOrders, startDeliveryAll, refetch]);

	const handleDeliver = useCallback(
		async (base64: string) => {
			if (!deliverDialog) return;
			setSaving(true);
			try {
				await deliverWithSignature(deliverDialog.id, base64);
				toast.success(`Commande ${deliverDialog.reference_id} livrée`);
				setDeliverDialog(null);
			} catch (err) {
				toast.error(err instanceof Error ? err.message : "Erreur livraison");
			} finally {
				setSaving(false);
			}
		},
		[deliverDialog, deliverWithSignature],
	);

	// Re-scan des colis à la réception (avant signature pharmacien)
	const deliverColis = useMemo(() => {
		if (!deliverDialog || !chargement) return [];
		return chargement.commandes.find((c) => c.commande_id === deliverDialog.id)?.colis ?? [];
	}, [deliverDialog, chargement]);
	const allColisLivres =
		deliverColis.length === 0 || deliverColis.every((c) => c.statut === "livre");

	const handleScanLivraison = useCallback(
		async (numero: string) => {
			if (scanning || !deliverDialog) return;
			setScanning(true);
			try {
				const res = await scanLivraison(numero);
				if (res.commande_ref !== deliverDialog.reference_id) {
					toast.warning(`${numero} appartient à la commande ${res.commande_ref}`);
				} else if (res.deja_scanne) {
					toast.info(`${numero} déjà scanné (${res.livres}/${res.total})`);
				} else {
					toast.success(`${numero} contrôlé — ${res.livres}/${res.total}`);
				}
				await refreshChargement();
			} catch (err) {
				toast.error(err instanceof Error ? err.message : "Colis non reconnu");
			} finally {
				setScanning(false);
			}
		},
		[scanning, deliverDialog, scanLivraison, refreshChargement],
	);

	const handleFail = useCallback(async () => {
		if (!failDialog || !failMotif.trim()) return;
		setSaving(true);
		try {
			await markFailed(failDialog.id, failAction, failMotif.trim());
			toast.success(
				`Commande ${failDialog.reference_id} marquée ${failAction === "refuse" ? "refusée" : "retournée"}`,
			);
			setFailDialog(null);
			setFailMotif("");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		} finally {
			setSaving(false);
		}
	}, [failDialog, failAction, failMotif, markFailed]);

	const handleClaim = useCallback(async () => {
		setClaiming(true);
		try {
			await claimToday();
			toast.success("Tournée réclamée avec succès");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Aucune tournée disponible");
		} finally {
			setClaiming(false);
		}
	}, [claimToday]);

	// -----------------------------------------------------------------------
	// Loading state
	// -----------------------------------------------------------------------
	if (loading) {
		return (
			<div className="flex flex-col gap-6">
				<Skeleton className="h-10 w-64" />
				<div className="grid grid-cols-4 gap-4">
					{Array.from({ length: 4 }).map((_, i) => (
						<Skeleton key={`sk-${i}`} className="h-20 rounded-xl" />
					))}
				</div>
				<Skeleton className="h-64 rounded-xl" />
			</div>
		);
	}

	// -----------------------------------------------------------------------
	// Error state
	// -----------------------------------------------------------------------
	if (error) {
		return (
			<div className="flex flex-col gap-6">
				<PageHeader />
				<div className="flex flex-col items-center justify-center gap-3 rounded-xl border border-red-200 bg-red-50 py-12">
					<AlertTriangle className="h-8 w-8 text-red-500" />
					<p className="text-[14px] font-medium text-red-700">{error}</p>
					<Button variant="outline" size="sm" onClick={refetch}>
						Réessayer
					</Button>
				</div>
			</div>
		);
	}

	if (!feuille) {
		return (
			<div className="flex flex-col gap-6">
				<PageHeader />
				<div className="flex flex-col items-center justify-center gap-4 rounded-xl border border-border/60 bg-card py-20 shadow-sm">
					<div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-muted">
						<Truck className="h-8 w-8 text-muted-foreground" />
					</div>
					<p className="text-[15px] font-medium text-muted-foreground">
						Aucune feuille de route assignée pour aujourd&apos;hui
					</p>
					<p className="max-w-md text-center text-[13px] text-muted-foreground/70">
						Si une tournée est disponible, vous pouvez la réclamer ci-dessous.
					</p>
					<Button
						onClick={handleClaim}
						disabled={claiming}
						className="mt-2 gap-2 rounded-lg bg-gradient-to-r from-[#0F766E] to-[#0D9488] font-semibold text-white shadow-sm hover:brightness-110"
					>
						{claiming ? (
							<Loader2 className="h-4 w-4 animate-spin" />
						) : (
							<Truck className="h-4 w-4" />
						)}
						Réclamer une tournée
					</Button>
				</div>
			</div>
		);
	}

	// -----------------------------------------------------------------------
	// Main render
	// -----------------------------------------------------------------------
	return (
		<div className="flex flex-col gap-8">
			<PageHeader />

			{/* Truck info */}
			<div className="animate-fade-in-up flex items-center gap-3 rounded-xl border border-border/60 bg-card px-5 py-3 shadow-sm">
				<Truck className="h-5 w-5 text-orange-600" />
				<div className="flex-1">
					<span className="text-[14px] font-semibold">{feuille.camion_nom}</span>
					<span className="ml-2 text-[12px] text-muted-foreground">{feuille.camion_plaque}</span>
				</div>
				<span className="text-[12px] text-muted-foreground">
					{new Date(feuille.date).toLocaleDateString("fr-FR", {
						weekday: "long",
						day: "numeric",
						month: "long",
					})}
				</span>
			</div>

			{/* Counters */}
			<div
				className="animate-fade-in-up grid grid-cols-2 gap-3 md:grid-cols-4"
				style={{ animationDelay: "50ms" }}
			>
				<CounterCard
					label="Colis standard"
					value={feuille.compteurs.colis_std}
					icon={<Package className="h-4 w-4 text-teal-600" />}
				/>
				<CounterCard
					label="Sachets standard"
					value={feuille.compteurs.sachets_std}
					icon={<Package className="h-4 w-4 text-teal-600" />}
				/>
				<CounterCard
					label="Colis frigo"
					value={feuille.compteurs.colis_frg}
					icon={<Package className="h-4 w-4 text-blue-600" />}
				/>
				<CounterCard
					label="Sachets frigo"
					value={feuille.compteurs.sachets_frg}
					icon={<Package className="h-4 w-4 text-blue-600" />}
				/>
			</div>

			{/* ============================================================= */}
			{/* Phase 2: Chargement par scan des colis (only if not yet validated) */}
			{/* ============================================================= */}
			{!feuille.chargement_valide && pretesOrders.length > 0 && (
				<section
					className="animate-fade-in-up flex flex-col gap-3"
					style={{ animationDelay: "100ms" }}
				>
					<div className="flex items-center gap-2.5">
						<ScanLine className="h-4 w-4 text-violet-600" />
						<h3 className="text-[15px] font-semibold">Chargement du camion — scan des colis</h3>
						<span className="flex h-6 min-w-6 items-center justify-center rounded-full bg-violet-100 px-2 text-[11px] font-bold text-violet-700">
							{chargement?.charges ?? 0}/{chargement?.total ?? 0}
						</span>
					</div>

					<div className="grid gap-4 lg:grid-cols-2">
						<QrScanner onScan={handleScanChargement} paused={scanning} />

						{/* Contenu du camion en temps réel */}
						<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
							<div className="flex items-center gap-2 border-b border-border/40 bg-muted/20 px-4 py-2.5">
								<PackageCheck className="h-4 w-4 text-teal-600" />
								<span className="text-[13px] font-semibold">Contenu du camion</span>
							</div>
							<div className="flex max-h-80 flex-col divide-y divide-border/30 overflow-y-auto">
								{(chargement?.commandes ?? [])
									.filter((c) => c.statut === "prete")
									.map((order) => (
										<div key={order.commande_id} className="px-4 py-2.5">
											<div className="flex items-center justify-between">
												<div>
													<span className="font-mono text-[12px] font-medium">
														{order.commande_ref}
													</span>
													<span className="ml-2 text-[12px] text-muted-foreground">
														{order.pharmacien_nom}
													</span>
												</div>
												<span
													className={`text-[12px] font-bold tabular-nums ${
														order.total > 0 && order.charges === order.total
															? "text-emerald-600"
															: "text-amber-600"
													}`}
												>
													{order.charges}/{order.total}
												</span>
											</div>
											{order.colis.length > 0 && (
												<div className="mt-1.5 flex flex-wrap gap-1">
													{order.colis.map((k) => (
														<span
															key={k.numero}
															className={`rounded-md px-1.5 py-0.5 font-mono text-[10px] font-medium ${
																k.statut === "charge" || k.statut === "livre"
																	? "bg-emerald-100 text-emerald-700"
																	: "bg-muted text-muted-foreground"
															}`}
														>
															{k.numero}
														</span>
													))}
												</div>
											)}
											{order.colis.length === 0 && (
												<p className="mt-1 text-[11px] text-muted-foreground/70">
													Pas de colis tracés (commande antérieure)
												</p>
											)}
										</div>
									))}
								{(chargement?.commandes.filter((c) => c.statut === "prete") ?? []).length === 0 && (
									<p className="px-4 py-6 text-center text-[12px] text-muted-foreground">
										Aucune commande prête à charger
									</p>
								)}
							</div>
						</div>
					</div>

					{/* Colis manquants après tentative de validation */}
					{manquants && manquants.length > 0 && (
						<div className="rounded-xl border border-red-200 bg-red-50 px-5 py-4">
							<div className="flex items-center gap-2">
								<AlertTriangle className="h-4 w-4 text-red-600" />
								<p className="text-[13px] font-semibold text-red-700">
									Colis manquants — le camion ne peut pas être validé
								</p>
							</div>
							<ul className="mt-2 flex flex-col gap-1.5">
								{manquants.map((m) => (
									<li key={m.commande_ref} className="text-[13px] text-red-700">
										<span className="font-mono font-semibold">{m.commande_ref}</span> :{" "}
										{m.colis.map((numero) => (
											<span
												key={numero}
												className="mr-1 rounded-md bg-red-100 px-1.5 py-0.5 font-mono text-[11px] font-medium"
											>
												{numero}
											</span>
										))}
									</li>
								))}
							</ul>
						</div>
					)}

					<div className="flex items-center justify-end">
						<Button
							size="sm"
							onClick={handleValidateLoading}
							disabled={saving}
							className="gap-1.5 rounded-lg bg-gradient-to-r from-[#0F766E] to-[#0D9488] text-[12px] font-semibold text-white shadow-sm hover:brightness-110"
						>
							{saving ? (
								<Loader2 className="h-3.5 w-3.5 animate-spin" />
							) : (
								<CheckCircle2 className="h-3.5 w-3.5" />
							)}
							Valider le chargement
						</Button>
					</div>
				</section>
			)}

			{/* ============================================================= */}
			{/* Phase 3: Signatures + start tournée */}
			{/* ============================================================= */}
			{feuille.chargement_valide && !canStartTournee && pretesOrders.length > 0 && (
				<section
					className="animate-fade-in-up flex flex-col gap-3"
					style={{ animationDelay: "100ms" }}
				>
					<div className="flex items-center gap-2.5">
						<PenLine className="h-4 w-4 text-amber-600" />
						<h3 className="text-[15px] font-semibold">Signatures avant départ</h3>
					</div>

					<div className="grid gap-3 md:grid-cols-2">
						<button
							type="button"
							onClick={() => !feuille.signature_expedition && setSignDialog("expedition")}
							className={`flex items-center gap-3 rounded-xl border px-5 py-4 text-left transition-all ${
								feuille.signature_expedition
									? "border-emerald-200 bg-emerald-50"
									: "cursor-pointer border-border/60 bg-card shadow-sm hover:border-amber-300"
							}`}
						>
							{feuille.signature_expedition ? (
								<CheckCircle2 className="h-5 w-5 text-emerald-600" />
							) : (
								<PenLine className="h-5 w-5 text-amber-600" />
							)}
							<div>
								<p className="text-[13px] font-semibold">
									{feuille.signature_expedition ? "Signé" : "Signer"} — Chargé d&apos;expédition
								</p>
								<p className="text-[11px] text-muted-foreground">
									{feuille.signature_expedition ? "Signature enregistrée" : "Cliquez pour signer"}
								</p>
							</div>
						</button>

						<button
							type="button"
							onClick={() => !feuille.signature_chauffeur && setSignDialog("chauffeur")}
							className={`flex items-center gap-3 rounded-xl border px-5 py-4 text-left transition-all ${
								feuille.signature_chauffeur
									? "border-emerald-200 bg-emerald-50"
									: "cursor-pointer border-border/60 bg-card shadow-sm hover:border-amber-300"
							}`}
						>
							{feuille.signature_chauffeur ? (
								<CheckCircle2 className="h-5 w-5 text-emerald-600" />
							) : (
								<PenLine className="h-5 w-5 text-amber-600" />
							)}
							<div>
								<p className="text-[13px] font-semibold">
									{feuille.signature_chauffeur ? "Signé" : "Signer"} — Chauffeur / Livreur
								</p>
								<p className="text-[11px] text-muted-foreground">
									{feuille.signature_chauffeur ? "Signature enregistrée" : "Cliquez pour signer"}
								</p>
							</div>
						</button>
					</div>
				</section>
			)}

			{/* Start tournée button */}
			{canStartTournee && pretesOrders.length > 0 && (
				<div className="animate-fade-in-up" style={{ animationDelay: "100ms" }}>
					<Button
						size="lg"
						onClick={handleStartTournee}
						disabled={startingAll}
						className="w-full gap-2 rounded-xl bg-gradient-to-r from-orange-500 to-amber-500 text-[14px] font-bold text-white shadow-md hover:brightness-110"
					>
						{startingAll ? (
							<Loader2 className="h-5 w-5 animate-spin" />
						) : (
							<MapPin className="h-5 w-5" />
						)}
						Démarrer la tournée ({pretesOrders.length} commande{pretesOrders.length > 1 ? "s" : ""})
					</Button>
				</div>
			)}

			{/* ============================================================= */}
			{/* Phase 4: Livraisons en cours (client par client) */}
			{/* ============================================================= */}
			{enRouteOrders.length > 0 && (
				<section
					className="animate-fade-in-up flex flex-col gap-3"
					style={{ animationDelay: "150ms" }}
				>
					<div className="flex items-center gap-2.5">
						<MapPin className="h-4 w-4 text-orange-600" />
						<h3 className="text-[15px] font-semibold">Livraisons en cours</h3>
						<span className="flex h-6 min-w-6 items-center justify-center rounded-full bg-orange-100 px-2 text-[11px] font-bold text-orange-700">
							{enRouteOrders.length}
						</span>
					</div>

					<div className="flex flex-col gap-3">
						{enRouteOrders.map((order, idx) => (
							<div
								key={order.id}
								className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm"
							>
								<div className="flex items-start gap-4 px-5 py-4">
									<div className="flex h-8 w-8 items-center justify-center rounded-lg bg-orange-50 text-[13px] font-bold text-orange-700">
										{idx + 1}
									</div>
									<div className="flex-1">
										<div className="flex items-center gap-2">
											<p className="text-[14px] font-semibold">{order.pharmacien_nom}</p>
											<StatusBadge status={order.statut} />
										</div>
										{order.pharmacien_adresse && (
											<p className="mt-0.5 text-[12px] text-muted-foreground">
												{order.pharmacien_adresse}
											</p>
										)}
										{order.pharmacien_secteur && (
											<p className="text-[11px] text-muted-foreground/70">
												Secteur : {order.pharmacien_secteur}
											</p>
										)}
										<div className="mt-1.5 flex items-center gap-4 text-[12px] text-muted-foreground">
											<span className="font-mono">{order.reference_id}</span>
											<span className="font-semibold tabular-nums text-foreground">
												{order.montant_total.toLocaleString("fr-FR")} DA
											</span>
										</div>
									</div>
								</div>
								<div className="flex items-center gap-2 border-t border-border/30 bg-muted/20 px-5 py-2.5">
									<Button
										size="sm"
										onClick={() => setDeliverDialog(order)}
										className="gap-1.5 rounded-lg bg-gradient-to-r from-[#0F766E] to-[#0D9488] text-[12px] font-semibold text-white shadow-sm hover:brightness-110"
									>
										<CheckCircle2 className="h-3.5 w-3.5" />
										Livré
									</Button>
									<Button
										size="sm"
										variant="outline"
										onClick={() => {
											setFailDialog(order);
											setFailAction("refuse");
											setFailMotif("");
										}}
										className="gap-1.5 rounded-lg border-red-200 text-[12px] font-semibold text-red-700 hover:bg-red-50"
									>
										<XCircle className="h-3.5 w-3.5" />
										Refusé
									</Button>
									<Button
										size="sm"
										variant="outline"
										onClick={() => {
											setFailDialog(order);
											setFailAction("retourne");
											setFailMotif("");
										}}
										className="gap-1.5 rounded-lg border-amber-200 text-[12px] font-semibold text-amber-700 hover:bg-amber-50"
									>
										<AlertTriangle className="h-3.5 w-3.5" />
										Absent
									</Button>
								</div>
							</div>
						))}
					</div>
				</section>
			)}

			{/* ============================================================= */}
			{/* Completed deliveries */}
			{/* ============================================================= */}
			{doneOrders.length > 0 && (
				<section
					className="animate-fade-in-up flex flex-col gap-3"
					style={{ animationDelay: "200ms" }}
				>
					<h3 className="text-[15px] font-semibold text-muted-foreground">
						Terminées ({doneOrders.length})
					</h3>
					<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
						<div className="flex flex-col divide-y divide-border/30">
							{doneOrders.map((order) => (
								<div
									key={order.id}
									className="flex items-center gap-4 px-5 py-3 opacity-60 hover:opacity-100 transition-opacity"
								>
									<div className="flex-1">
										<span className="text-[13px] font-medium">{order.pharmacien_nom}</span>
										<span className="ml-2 font-mono text-[12px] text-muted-foreground">
											{order.reference_id}
										</span>
									</div>
									<span className="text-[13px] font-semibold tabular-nums">
										{order.montant_total.toLocaleString("fr-FR")} DA
									</span>
									<StatusBadge status={order.statut} />
									{order.signature_pharmacien && (
										<CheckCircle2 className="h-4 w-4 text-emerald-500" />
									)}
								</div>
							))}
						</div>
					</div>
				</section>
			)}

			{/* ============================================================= */}
			{/* Dialogs */}
			{/* ============================================================= */}

			{/* Signature expedition/chauffeur dialog */}
			<Dialog open={signDialog !== null} onOpenChange={() => setSignDialog(null)}>
				<DialogContent className="sm:max-w-md">
					<DialogHeader>
						<DialogTitle>
							Signature —{" "}
							{signDialog === "expedition" ? "Chargé d'expédition" : "Chauffeur / Livreur"}
						</DialogTitle>
						<DialogDescription>Signez dans le cadre ci-dessous pour valider.</DialogDescription>
					</DialogHeader>
					<SignaturePad
						label={signDialog === "expedition" ? "Chargé d'expédition" : "Chauffeur / Livreur"}
						onSave={handleSign}
						onCancel={() => setSignDialog(null)}
						saving={saving}
					/>
				</DialogContent>
			</Dialog>

			{/* Deliver dialog: re-scan des colis puis signature pharmacien */}
			<Dialog open={deliverDialog !== null} onOpenChange={() => setDeliverDialog(null)}>
				<DialogContent className="sm:max-w-lg">
					<DialogHeader>
						<DialogTitle>
							{allColisLivres ? "Signature du pharmacien" : "Contrôle des colis à la réception"}
						</DialogTitle>
						<DialogDescription>
							{deliverDialog?.pharmacien_nom} — {deliverDialog?.reference_id}
						</DialogDescription>
					</DialogHeader>

					{deliverColis.length > 0 && (
						<div className="flex flex-wrap gap-1.5">
							{deliverColis.map((k) => (
								<span
									key={k.numero}
									className={`flex items-center gap-1 rounded-md px-2 py-1 font-mono text-[11px] font-medium ${
										k.statut === "livre"
											? "bg-emerald-100 text-emerald-700"
											: "bg-muted text-muted-foreground"
									}`}
								>
									{k.statut === "livre" && <CheckCircle2 className="h-3 w-3" />}
									{k.numero}
								</span>
							))}
						</div>
					)}

					{!allColisLivres ? (
						<div className="flex flex-col gap-2">
							<p className="text-[12px] text-muted-foreground">
								Re-scannez chaque colis remis au pharmacien — la signature se débloque quand tous
								les colis sont contrôlés.
							</p>
							<QrScanner onScan={handleScanLivraison} paused={scanning} />
						</div>
					) : (
						<SignaturePad
							label="Signature pharmacien (réception)"
							onSave={handleDeliver}
							onCancel={() => setDeliverDialog(null)}
							saving={saving}
						/>
					)}
				</DialogContent>
			</Dialog>

			{/* Fail dialog (refuse / retourne) */}
			<Dialog open={failDialog !== null} onOpenChange={() => setFailDialog(null)}>
				<DialogContent className="sm:max-w-md">
					<DialogHeader>
						<DialogTitle>
							{failAction === "refuse" ? "Commande refusée" : "Client absent / Retour"}
						</DialogTitle>
						<DialogDescription>
							{failDialog?.pharmacien_nom} — {failDialog?.reference_id}
						</DialogDescription>
					</DialogHeader>
					<div className="flex flex-col gap-4">
						<div>
							<label htmlFor="motif" className="text-[13px] font-medium">
								Motif
							</label>
							<Input
								id="motif"
								value={failMotif}
								onChange={(e) => setFailMotif(e.target.value)}
								placeholder={failAction === "refuse" ? "Raison du refus..." : "Raison du retour..."}
								className="mt-1.5"
							/>
						</div>
						<div className="flex justify-end gap-2">
							<Button variant="outline" size="sm" onClick={() => setFailDialog(null)}>
								Annuler
							</Button>
							<Button
								size="sm"
								variant="destructive"
								onClick={handleFail}
								disabled={!failMotif.trim() || saving}
							>
								{saving ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : null}
								Confirmer
							</Button>
						</div>
					</div>
				</DialogContent>
			</Dialog>
		</div>
	);
}

function PageHeader() {
	return (
		<div className="flex items-center gap-3">
			<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-orange-50">
				<Truck className="h-5 w-5 text-orange-600" />
			</div>
			<div>
				<h2 className="font-heading text-xl font-bold">Livraisons</h2>
				<p className="text-[13px] text-muted-foreground">Feuille de route du jour</p>
			</div>
		</div>
	);
}
