"use client";

import { QrScanner } from "@/components/qr-scanner";
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
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useExpedition } from "@/hooks/use-expedition";
import type { ColisDetail, ZoneExpeditionCommande } from "@/lib/types";
import {
	CheckCircle2,
	CircleDashed,
	Loader2,
	Package,
	PackageCheck,
	RotateCcw,
	ScanLine,
	Truck,
} from "lucide-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

const COLIS_STATUT_LABELS: Record<string, string> = {
	etiquete: "Étiqueté",
	sur_pad: "En zone d'expédition",
	charge: "Chargé",
	livre: "Livré",
};

/** Commande en cours de scan sur le diable du magasinier. */
interface ActiveCommande {
	commande_id: string;
	commande_ref: string;
	commande_statut: string;
	date_commande: string;
	pharmacien_nom: string;
	pharmacien_adresse: string | null;
	pharmacien_secteur: string | null;
	nb_colis: number;
	colis: ColisDetail[];
}

function aggregateFrom(detail: ColisDetail): ActiveCommande {
	return {
		commande_id: detail.commande_id,
		commande_ref: detail.commande_ref,
		commande_statut: detail.commande_statut,
		date_commande: detail.date_commande,
		pharmacien_nom: detail.pharmacien_nom,
		pharmacien_adresse: detail.pharmacien_adresse,
		pharmacien_secteur: detail.pharmacien_secteur,
		nb_colis: detail.nb_colis,
		colis: [detail],
	};
}

export default function MagasinierPage() {
	const { lookupColis, deposeZoneExpedition, fetchZoneExpedition } = useExpedition();

	const [commande, setCommande] = useState<ActiveCommande | null>(null);
	const [lookupLoading, setLookupLoading] = useState(false);
	const [saving, setSaving] = useState(false);
	const [zone, setZone] = useState<ZoneExpeditionCommande[] | null>(null);
	const [zoneLoading, setZoneLoading] = useState(true);

	// Colis scanné appartenant à une AUTRE commande alors qu'une est en cours.
	const [conflict, setConflict] = useState<ColisDetail | null>(null);
	// Demande manuelle de changement de commande (bouton "Changer").
	const [askLeave, setAskLeave] = useState(false);

	const scannedCount = commande?.colis.length ?? 0;
	const isComplete = !!commande && scannedCount >= commande.nb_colis;

	const refreshZone = useCallback(async () => {
		setZoneLoading(true);
		try {
			setZone(await fetchZoneExpedition());
		} catch {
			// silencieux : la liste de la zone est secondaire par rapport au scan
		} finally {
			setZoneLoading(false);
		}
	}, [fetchZoneExpedition]);

	useEffect(() => {
		refreshZone();
	}, [refreshZone]);

	const resetCommande = useCallback(() => {
		setCommande(null);
		setConflict(null);
		setAskLeave(false);
	}, []);

	const startCommande = useCallback((detail: ColisDetail) => {
		setCommande(aggregateFrom(detail));
	}, []);

	const handleScan = useCallback(
		async (numero: string) => {
			if (saving || lookupLoading) return;
			setLookupLoading(true);
			try {
				const detail = await lookupColis(numero);

				if (detail.statut === "charge" || detail.statut === "livre") {
					toast.warning(
						`Colis ${detail.numero} déjà ${COLIS_STATUT_LABELS[detail.statut].toLowerCase()}`,
					);
					return;
				}

				if (!commande) {
					startCommande(detail);
					toast.success(`Colis 1 / ${detail.nb_colis} — commande ${detail.commande_ref}`);
					return;
				}

				if (detail.commande_id !== commande.commande_id) {
					setConflict(detail);
					return;
				}

				if (commande.colis.some((k) => k.numero === detail.numero)) {
					toast.info(`Colis ${detail.numero} déjà scanné (${scannedCount} / ${commande.nb_colis})`);
					return;
				}

				const next = { ...commande, colis: [...commande.colis, detail] };
				setCommande(next);
				const count = next.colis.length;
				if (count >= next.nb_colis) {
					toast.success(
						`Tous les cartons scannés (${count} / ${next.nb_colis}) — déposer en zone d'expédition`,
					);
				} else {
					toast.success(`Colis ${count} / ${next.nb_colis}`);
				}
			} catch (err) {
				toast.error(err instanceof Error ? err.message : `Colis ${numero} introuvable`);
			} finally {
				setLookupLoading(false);
			}
		},
		[commande, lookupColis, lookupLoading, saving, scannedCount, startCommande],
	);

	const handleDeposer = useCallback(async () => {
		if (!commande || !isComplete) return;
		setSaving(true);
		try {
			const res = await deposeZoneExpedition(commande.commande_id);
			toast.success(
				`Commande ${res.commande_ref ?? commande.commande_ref} déposée en zone d'expédition (${res.deposes.length} cartons)`,
			);
			resetCommande();
			refreshZone();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors du dépôt");
		} finally {
			setSaving(false);
		}
	}, [commande, isComplete, deposeZoneExpedition, resetCommande, refreshZone]);

	const switchToConflict = useCallback(() => {
		if (!conflict) return;
		startCommande(conflict);
		toast.message(`Commande ${conflict.commande_ref} — Colis 1 / ${conflict.nb_colis}`);
		setConflict(null);
	}, [conflict, startCommande]);

	const scannedIndexes = useMemo(
		() => new Set(commande?.colis.map((k) => k.index_colis) ?? []),
		[commande],
	);

	return (
		<div className="flex flex-col gap-8">
			{/* Header */}
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-violet-50">
					<PackageCheck className="h-5 w-5 text-violet-600" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Zone d'expédition</h2>
					<p className="text-[13px] text-muted-foreground">
						Scannez tous les cartons d'une commande, puis déposez-la en zone de chargement
					</p>
				</div>
			</div>

			<div className="grid gap-6 lg:grid-cols-2">
				{/* ===== Colonne scan ===== */}
				<section className="flex flex-col gap-4">
					<div className="flex items-center gap-2.5">
						<ScanLine className="h-4 w-4 text-violet-600" />
						<h3 className="text-[15px] font-semibold">
							{commande ? `Commande ${commande.commande_ref}` : "Scanner le 1ᵉʳ carton"}
						</h3>
					</div>

					<QrScanner onScan={handleScan} paused={saving} />

					{lookupLoading && (
						<div className="flex items-center justify-center rounded-xl border border-border/60 bg-card py-6">
							<Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
						</div>
					)}

					{!commande && !lookupLoading && (
						<div className="rounded-xl border border-dashed border-border/60 bg-muted/20 px-5 py-8 text-center text-[13px] text-muted-foreground">
							Scannez le premier carton d'une commande pour démarrer.
						</div>
					)}

					{/* ===== Carte commande en cours ===== */}
					{commande && (
						<div className="animate-fade-in-up overflow-hidden rounded-xl border border-violet-200 bg-card shadow-sm">
							<div className="border-b border-border/40 bg-violet-50/50 px-5 py-3">
								<div className="flex items-start justify-between gap-3">
									<div>
										<span className="flex items-center gap-2">
											<span className="font-mono text-[15px] font-bold">
												{commande.commande_ref}
											</span>
											<StatusBadge status={commande.commande_statut} />
										</span>
										<p className="text-[13px] font-semibold text-violet-700">
											{scannedCount} / {commande.nb_colis} cartons scannés
										</p>
									</div>
									<Button
										variant="ghost"
										size="sm"
										onClick={() => (isComplete ? resetCommande() : setAskLeave(true))}
										className="gap-1.5 text-[12px] text-muted-foreground"
									>
										<RotateCcw className="h-3.5 w-3.5" />
										Changer
									</Button>
								</div>

								<div className="mt-2 h-2 overflow-hidden rounded-full bg-violet-100">
									<div
										className={`h-full rounded-full transition-all duration-300 ${
											isComplete ? "bg-emerald-500" : "bg-violet-500"
										}`}
										style={{
											width: `${Math.min(100, (scannedCount / commande.nb_colis) * 100)}%`,
										}}
									/>
								</div>

								<div className="mt-2.5 flex flex-wrap gap-1.5">
									{Array.from({ length: commande.nb_colis }).map((_, i) => {
										const idx = i + 1;
										const done = scannedIndexes.has(idx);
										return (
											<span
												key={`colis-dot-${commande.commande_id}-${idx}`}
												className={`flex h-6 min-w-6 items-center justify-center rounded-md px-1.5 text-[11px] font-semibold ${
													done
														? "bg-emerald-100 text-emerald-700"
														: "bg-muted text-muted-foreground"
												}`}
											>
												{idx}
											</span>
										);
									})}
								</div>
							</div>

							<div className="flex flex-col gap-2 px-5 py-4">
								<div className="flex items-center justify-between text-[13px]">
									<span className="text-muted-foreground">Date</span>
									<span>{new Date(commande.date_commande).toLocaleDateString("fr-FR")}</span>
								</div>
								<div className="flex items-start justify-between gap-4 text-[13px]">
									<span className="text-muted-foreground">Destinataire</span>
									<span className="text-right">
										<span className="font-semibold">{commande.pharmacien_nom}</span>
										{commande.pharmacien_adresse && (
											<>
												<br />
												<span className="text-muted-foreground">{commande.pharmacien_adresse}</span>
											</>
										)}
										{commande.pharmacien_secteur && (
											<>
												<br />
												<span className="text-muted-foreground">
													Secteur : {commande.pharmacien_secteur}
												</span>
											</>
										)}
									</span>
								</div>

								<div className="mt-1 flex flex-col gap-2">
									{commande.colis
										.slice()
										.sort((a, b) => a.index_colis - b.index_colis)
										.map((k) => (
											<div key={k.numero} className="rounded-lg bg-muted/40 px-3 py-2">
												<div className="flex items-center justify-between">
													<span className="flex items-center gap-1.5 font-mono text-[12px] font-semibold">
														<CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />
														{k.numero}
													</span>
													<span className="text-[11px] text-muted-foreground">
														Carton {k.index_colis} / {k.nb_colis}
													</span>
												</div>
												{k.contenu.length > 0 && (
													<ul className="mt-1 flex flex-col gap-0.5">
														{k.contenu.slice(0, 4).map((item) => (
															<li
																key={`${k.numero}-${item.designation}`}
																className="flex items-center justify-between text-[12px]"
															>
																<span className="truncate">{item.designation}</span>
																<span className="ml-2 shrink-0 font-semibold tabular-nums">
																	× {item.quantite}
																</span>
															</li>
														))}
														{k.contenu.length > 4 && (
															<li className="text-[11px] text-muted-foreground">
																+ {k.contenu.length - 4} autres
															</li>
														)}
													</ul>
												)}
											</div>
										))}
								</div>

								{/* ===== Dépôt en zone (uniquement si complet) ===== */}
								{isComplete ? (
									<div className="mt-2 flex flex-col gap-2.5 rounded-lg border border-emerald-200 bg-emerald-50/60 p-3">
										<p className="flex items-center gap-1.5 text-[13px] font-semibold text-emerald-800">
											<CheckCircle2 className="h-4 w-4" />
											Tous les cartons sont scannés — déposez la commande en zone d'expédition
										</p>
										<Button
											onClick={handleDeposer}
											disabled={saving}
											className="gap-1.5 rounded-lg bg-gradient-to-r from-[#0F766E] to-[#0D9488] font-semibold text-white shadow-sm hover:brightness-110"
										>
											{saving ? (
												<Loader2 className="h-4 w-4 animate-spin" />
											) : (
												<Truck className="h-4 w-4" />
											)}
											Déposer en zone d'expédition
										</Button>
									</div>
								) : (
									<p className="mt-1 flex items-center gap-1.5 text-[12px] text-muted-foreground">
										<CircleDashed className="h-3.5 w-3.5" />
										Scannez les {commande.nb_colis - scannedCount} cartons restants pour pouvoir
										déposer la commande.
									</p>
								)}
							</div>
						</div>
					)}
				</section>

				{/* ===== Colonne zone d'expédition ===== */}
				<section className="flex flex-col gap-4">
					<div className="flex items-center gap-2.5">
						<Truck className="h-4 w-4 text-violet-600" />
						<h3 className="text-[15px] font-semibold">Commandes en zone d'expédition</h3>
					</div>

					{zoneLoading && !zone ? (
						<div className="flex flex-col gap-3">
							{Array.from({ length: 4 }).map((_, i) => (
								<Skeleton key={`zone-sk-${i}`} className="h-16 rounded-xl" />
							))}
						</div>
					) : (zone ?? []).length === 0 ? (
						<div className="rounded-xl border border-dashed border-border/60 bg-muted/20 px-5 py-8 text-center text-[13px] text-muted-foreground">
							Aucune commande en zone d'expédition.
						</div>
					) : (
						<ul className="flex flex-col gap-2">
							{(zone ?? []).map((c) => (
								<li
									key={c.commande_id}
									className="flex items-center justify-between rounded-xl border border-border/60 bg-card px-4 py-3 shadow-sm"
								>
									<span>
										<span className="font-mono text-[14px] font-bold">{c.commande_ref}</span>
										<span className="ml-2 text-[13px] text-muted-foreground">
											{c.pharmacien_nom}
										</span>
									</span>
									<span className="flex items-center gap-1.5 text-[13px] font-semibold text-emerald-600">
										<Package className="h-3.5 w-3.5" />
										{c.poses}/{c.total} prête à expédier
									</span>
								</li>
							))}
						</ul>
					)}
				</section>
			</div>

			{/* ===== Popup : carton d'une autre commande ===== */}
			<AlertDialog open={!!conflict} onOpenChange={(open) => !open && setConflict(null)}>
				<AlertDialogContent>
					<AlertDialogHeader>
						<AlertDialogTitle>Carton d'une autre commande</AlertDialogTitle>
						<AlertDialogDescription>
							{commande && conflict && (
								<>
									La commande <b>{commande.commande_ref}</b> n'est pas complète ({scannedCount} /{" "}
									{commande.nb_colis} cartons scannés). Le carton <b>{conflict.numero}</b>{" "}
									appartient à la commande <b>{conflict.commande_ref}</b>.
									<br />
									Voulez-vous abandonner la commande en cours et passer à celle-ci ?
								</>
							)}
						</AlertDialogDescription>
					</AlertDialogHeader>
					<AlertDialogFooter>
						<AlertDialogCancel onClick={() => setConflict(null)}>
							Rester sur {commande?.commande_ref}
						</AlertDialogCancel>
						<AlertDialogAction
							onClick={switchToConflict}
							className="bg-violet-600 text-white hover:bg-violet-700"
						>
							Passer à {conflict?.commande_ref}
						</AlertDialogAction>
					</AlertDialogFooter>
				</AlertDialogContent>
			</AlertDialog>

			{/* ===== Popup : changement manuel de commande (incomplète) ===== */}
			<AlertDialog open={askLeave} onOpenChange={setAskLeave}>
				<AlertDialogContent>
					<AlertDialogHeader>
						<AlertDialogTitle>Abandonner la commande en cours ?</AlertDialogTitle>
						<AlertDialogDescription>
							{commande && (
								<>
									Il manque <b>{commande.nb_colis - scannedCount}</b> cartons sur{" "}
									{commande.nb_colis} pour la commande <b>{commande.commande_ref}</b>. Si vous
									changez maintenant, rien ne sera déposé et vous repartirez à zéro.
								</>
							)}
						</AlertDialogDescription>
					</AlertDialogHeader>
					<AlertDialogFooter>
						<AlertDialogCancel>Continuer cette commande</AlertDialogCancel>
						<AlertDialogAction
							onClick={resetCommande}
							className="bg-amber-600 text-white hover:bg-amber-700"
						>
							Abandonner et recommencer
						</AlertDialogAction>
					</AlertDialogFooter>
				</AlertDialogContent>
			</AlertDialog>
		</div>
	);
}
