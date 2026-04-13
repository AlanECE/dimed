"use client";

import { SignaturePad } from "@/components/signature-pad";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { useOrderAction } from "@/hooks/use-order-action";
import { useTodayRoute } from "@/hooks/use-today-route";
import type { RouteSheetTodayCommande } from "@/lib/types";
import {
	AlertTriangle,
	CheckCircle2,
	ClipboardCheck,
	Loader2,
	MapPin,
	Package,
	PenLine,
	Truck,
	XCircle,
} from "lucide-react";
import { useCallback, useMemo, useState } from "react";
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

	// Checklist state
	const [checkedColis, setCheckedColis] = useState<Set<string>>(new Set());

	// Signature dialogs
	const [signDialog, setSignDialog] = useState<"expedition" | "chauffeur" | null>(null);
	const [deliverDialog, setDeliverDialog] = useState<RouteSheetTodayCommande | null>(null);
	const [failDialog, setFailDialog] = useState<RouteSheetTodayCommande | null>(null);
	const [failMotif, setFailMotif] = useState("");
	const [failAction, setFailAction] = useState<"refuse" | "retourne">("refuse");
	const [saving, setSaving] = useState(false);
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

	const allColisChecked =
		pretesOrders.length > 0 && pretesOrders.every((o) => checkedColis.has(o.reference_id));
	const canStartTournee =
		feuille?.chargement_valide && feuille?.signature_expedition && feuille?.signature_chauffeur;

	const toggleColis = useCallback((ref: string) => {
		setCheckedColis((prev) => {
			const next = new Set(prev);
			if (next.has(ref)) next.delete(ref);
			else next.add(ref);
			return next;
		});
	}, []);

	const handleValidateLoading = useCallback(async () => {
		if (!feuille) return;
		setSaving(true);
		try {
			await validateLoading(feuille.id, Array.from(checkedColis));
			toast.success("Chargement validé");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur validation");
		} finally {
			setSaving(false);
		}
	}, [feuille, checkedColis, validateLoading]);

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
			{/* Phase 2: Checklist chargement (only if not yet validated) */}
			{/* ============================================================= */}
			{!feuille.chargement_valide && pretesOrders.length > 0 && (
				<section
					className="animate-fade-in-up flex flex-col gap-3"
					style={{ animationDelay: "100ms" }}
				>
					<div className="flex items-center gap-2.5">
						<ClipboardCheck className="h-4 w-4 text-violet-600" />
						<h3 className="text-[15px] font-semibold">Checklist de chargement</h3>
						<span className="flex h-6 min-w-6 items-center justify-center rounded-full bg-violet-100 px-2 text-[11px] font-bold text-violet-700">
							{checkedColis.size}/{pretesOrders.length}
						</span>
					</div>

					<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
						<div className="flex flex-col divide-y divide-border/30">
							{pretesOrders.map((order) => (
								<label
									key={order.id}
									className="flex cursor-pointer items-center gap-4 px-5 py-3.5 transition-colors hover:bg-muted/40"
								>
									<Checkbox
										checked={checkedColis.has(order.reference_id)}
										onCheckedChange={() => toggleColis(order.reference_id)}
									/>
									<div className="flex-1">
										<span className="font-mono text-[13px] font-medium">{order.reference_id}</span>
										<span className="ml-3 text-[13px] text-muted-foreground">
											{order.pharmacien_nom}
										</span>
									</div>
									<span className="text-[13px] font-semibold tabular-nums">
										{order.montant_total.toLocaleString("fr-FR")} DA
									</span>
								</label>
							))}
						</div>
						<div className="flex items-center justify-end border-t border-border/40 bg-muted/20 px-5 py-3">
							<Button
								size="sm"
								onClick={handleValidateLoading}
								disabled={!allColisChecked || saving}
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

			{/* Deliver with pharmacist signature dialog */}
			<Dialog open={deliverDialog !== null} onOpenChange={() => setDeliverDialog(null)}>
				<DialogContent className="sm:max-w-md">
					<DialogHeader>
						<DialogTitle>Signature du pharmacien</DialogTitle>
						<DialogDescription>
							{deliverDialog?.pharmacien_nom} — {deliverDialog?.reference_id}
						</DialogDescription>
					</DialogHeader>
					<SignaturePad
						label="Signature pharmacien (réception)"
						onSave={handleDeliver}
						onCancel={() => setDeliverDialog(null)}
						saving={saving}
					/>
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
