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
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { useExpedition } from "@/hooks/use-expedition";
import type { ColisDetail, PadOccupation } from "@/lib/types";
import {
	AlertTriangle,
	CheckCircle2,
	CircleDashed,
	Grid3x3,
	Loader2,
	MapPin,
	Package,
	PackageCheck,
	RotateCcw,
	ScanLine,
} from "lucide-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

const COLIS_STATUT_LABELS: Record<string, string> = {
	etiquete: "Étiqueté",
	sur_pad: "Sur pad",
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
	pad_suggere: ColisDetail["pad_suggere"];
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
		pad_suggere: detail.pad_suggere,
		colis: [detail],
	};
}

export default function MagasinierPage() {
	const { lookupColis, deposePadCommande, fetchPads } = useExpedition();

	const [commande, setCommande] = useState<ActiveCommande | null>(null);
	const [lookupLoading, setLookupLoading] = useState(false);
	const [selectedPadId, setSelectedPadId] = useState<string>("");
	const [saving, setSaving] = useState(false);
	const [pads, setPads] = useState<PadOccupation[] | null>(null);
	const [padsLoading, setPadsLoading] = useState(true);

	// Colis scanné appartenant à une AUTRE commande alors qu'une est en cours.
	const [conflict, setConflict] = useState<ColisDetail | null>(null);
	// Demande manuelle de changement de commande (bouton "Changer").
	const [askLeave, setAskLeave] = useState(false);

	const scannedCount = commande?.colis.length ?? 0;
	const isComplete = !!commande && scannedCount >= commande.nb_colis;

	const refreshPads = useCallback(async () => {
		setPadsLoading(true);
		try {
			setPads(await fetchPads());
		} catch {
			// silencieux : la grille des pads est secondaire par rapport au scan
		} finally {
			setPadsLoading(false);
		}
	}, [fetchPads]);

	useEffect(() => {
		refreshPads();
	}, [refreshPads]);

	const resetCommande = useCallback(() => {
		setCommande(null);
		setSelectedPadId("");
		setConflict(null);
		setAskLeave(false);
	}, []);

	const startCommande = useCallback((detail: ColisDetail) => {
		const agg = aggregateFrom(detail);
		setCommande(agg);
		setSelectedPadId(agg.pad_suggere?.id ?? "");
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

				// Aucune commande en cours → on démarre avec ce colis.
				if (!commande) {
					startCommande(detail);
					toast.success(`Colis 1 / ${detail.nb_colis} — commande ${detail.commande_ref}`);
					return;
				}

				// Colis d'une autre commande → on demande quoi faire.
				if (detail.commande_id !== commande.commande_id) {
					setConflict(detail);
					return;
				}

				// Déjà scanné dans la commande en cours.
				if (commande.colis.some((k) => k.numero === detail.numero)) {
					toast.info(`Colis ${detail.numero} déjà scanné (${scannedCount} / ${commande.nb_colis})`);
					return;
				}

				// Ajout à la commande en cours.
				const next = { ...commande, colis: [...commande.colis, detail] };
				setCommande(next);
				const count = next.colis.length;
				if (count >= next.nb_colis) {
					toast.success(`Tous les colis scannés (${count} / ${next.nb_colis}) — choisir le pad`);
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

	const handleAffecter = useCallback(async () => {
		if (!commande || !selectedPadId || !isComplete) return;
		setSaving(true);
		try {
			const res = await deposePadCommande(commande.commande_id, selectedPadId);
			toast.success(
				`Commande ${res.commande_ref ?? commande.commande_ref} déposée sur ${res.pad.code} (${res.deposes.length} colis)`,
			);
			resetCommande();
			refreshPads();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors de l'affectation");
		} finally {
			setSaving(false);
		}
	}, [commande, selectedPadId, isComplete, deposePadCommande, resetCommande, refreshPads]);

	// Bascule vers la commande du colis en conflit (abandon de la commande en cours).
	const switchToConflict = useCallback(() => {
		if (!conflict) return;
		startCommande(conflict);
		toast.message(`Commande ${conflict.commande_ref} — Colis 1 / ${conflict.nb_colis}`);
		setConflict(null);
	}, [conflict, startCommande]);

	const padSuggereCode = commande?.pad_suggere?.code;
	const overriding =
		!!commande?.pad_suggere && !!selectedPadId && selectedPadId !== commande.pad_suggere.id;

	// Index déjà scannés pour l'affichage de la progression.
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
					<h2 className="font-heading text-xl font-bold">Mise sur pad de tir</h2>
					<p className="text-[13px] text-muted-foreground">
						Scannez tous les colis d'une commande, puis affectez-la à un pad
					</p>
				</div>
			</div>

			<div className="grid gap-6 lg:grid-cols-2">
				{/* ===== Colonne scan ===== */}
				<section className="flex flex-col gap-4">
					<div className="flex items-center gap-2.5">
						<ScanLine className="h-4 w-4 text-violet-600" />
						<h3 className="text-[15px] font-semibold">
							{commande ? `Commande ${commande.commande_ref}` : "Scanner le 1ᵉʳ colis"}
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
							Scannez le premier colis d'une commande pour démarrer.
						</div>
					)}

					{/* ===== Carte commande en cours ===== */}
					{commande && (
						<div className="animate-fade-in-up overflow-hidden rounded-xl border border-violet-200 bg-card shadow-sm">
							{/* Bandeau commande + progression */}
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
											{scannedCount} / {commande.nb_colis} colis scannés
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

								{/* Barre de progression */}
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

								{/* Pastilles 1..N */}
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

							{/* Destinataire */}
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

								{/* Détail des colis scannés */}
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
														Colis {k.index_colis} / {k.nb_colis}
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

								{/* ===== Zone affectation pad (uniquement si complet) ===== */}
								{isComplete ? (
									<div className="mt-2 flex flex-col gap-2.5 rounded-lg border border-emerald-200 bg-emerald-50/60 p-3">
										<p className="flex items-center gap-1.5 text-[13px] font-semibold text-emerald-800">
											<CheckCircle2 className="h-4 w-4" />
											Tous les colis sont scannés — affectez la commande à un pad
										</p>
										{commande.pad_suggere && (
											<div className="flex items-center gap-2 rounded-md bg-white/70 px-3 py-2 text-[13px] text-emerald-800">
												<MapPin className="h-4 w-4 shrink-0" />
												<span>
													Pad <b>{padSuggereCode}</b> suggéré
												</span>
											</div>
										)}
										<div className="flex items-center gap-2">
											<Select
												value={selectedPadId}
												onValueChange={(value) => setSelectedPadId(value ?? "")}
											>
												<SelectTrigger className="flex-1 rounded-lg border-border/60 bg-background text-[13px]">
													<SelectValue placeholder="Choisir un pad de tir" />
												</SelectTrigger>
												<SelectContent>
													{(pads ?? [])
														.filter((p) => p.actif)
														.map((p) => (
															<SelectItem key={p.id} value={p.id}>
																{p.code} — {p.nom} ({p.nb_colis} colis)
															</SelectItem>
														))}
												</SelectContent>
											</Select>
											<Button
												onClick={handleAffecter}
												disabled={!selectedPadId || saving}
												className="gap-1.5 rounded-lg bg-gradient-to-r from-[#0F766E] to-[#0D9488] font-semibold text-white shadow-sm hover:brightness-110"
											>
												{saving ? (
													<Loader2 className="h-4 w-4 animate-spin" />
												) : (
													<MapPin className="h-4 w-4" />
												)}
												Affecter au pad
											</Button>
										</div>
										{overriding && (
											<p className="flex items-center gap-1.5 text-[12px] text-amber-700">
												<AlertTriangle className="h-3.5 w-3.5" />
												Vous remplacez le pad suggéré ({padSuggereCode})
											</p>
										)}
									</div>
								) : (
									<p className="mt-1 flex items-center gap-1.5 text-[12px] text-muted-foreground">
										<CircleDashed className="h-3.5 w-3.5" />
										Scannez les {commande.nb_colis - scannedCount} colis restants pour pouvoir
										affecter un pad.
									</p>
								)}
							</div>
						</div>
					)}
				</section>

				{/* ===== Colonne pads ===== */}
				<section className="flex flex-col gap-4">
					<div className="flex items-center gap-2.5">
						<Grid3x3 className="h-4 w-4 text-violet-600" />
						<h3 className="text-[15px] font-semibold">État des pads de tir</h3>
					</div>

					{padsLoading && !pads ? (
						<div className="grid grid-cols-2 gap-3">
							{Array.from({ length: 6 }).map((_, i) => (
								<Skeleton key={`pad-sk-${i}`} className="h-28 rounded-xl" />
							))}
						</div>
					) : (
						<div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
							{(pads ?? []).map((pad) => (
								<div
									key={pad.id}
									className={`rounded-xl border px-4 py-3 shadow-sm ${
										pad.actif
											? "border-border/60 bg-card"
											: "border-border/40 bg-muted/30 opacity-60"
									}`}
								>
									<div className="flex items-center justify-between">
										<span className="font-mono text-[14px] font-bold">{pad.code}</span>
										<span className="flex items-center gap-1 text-[12px] text-muted-foreground">
											<Package className="h-3.5 w-3.5" />
											{pad.nb_colis}
										</span>
									</div>
									<p className="text-[11px] text-muted-foreground">{pad.nom}</p>
									{pad.commandes.length > 0 ? (
										<ul className="mt-2 flex flex-col gap-1">
											{pad.commandes.map((c) => (
												<li
													key={c.commande_ref}
													className="flex items-center justify-between rounded-md bg-muted/40 px-2 py-1 text-[12px]"
												>
													<span>
														<span className="font-mono font-medium">{c.commande_ref}</span>
														<span className="ml-1.5 text-muted-foreground">{c.pharmacien_nom}</span>
													</span>
													<span
														className={`font-semibold tabular-nums ${
															c.poses === c.total ? "text-emerald-600" : "text-amber-600"
														}`}
													>
														{c.poses}/{c.total}
													</span>
												</li>
											))}
										</ul>
									) : (
										<p className="mt-2 text-[12px] text-muted-foreground/70">Vide</p>
									)}
								</div>
							))}
						</div>
					)}
				</section>
			</div>

			{/* ===== Popup : colis d'une autre commande ===== */}
			<AlertDialog open={!!conflict} onOpenChange={(open) => !open && setConflict(null)}>
				<AlertDialogContent>
					<AlertDialogHeader>
						<AlertDialogTitle>Colis d'une autre commande</AlertDialogTitle>
						<AlertDialogDescription>
							{commande && conflict && (
								<>
									La commande <b>{commande.commande_ref}</b> n'est pas complète ({scannedCount} /{" "}
									{commande.nb_colis} colis scannés). Le colis <b>{conflict.numero}</b> appartient à
									la commande <b>{conflict.commande_ref}</b>.
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
									Il manque <b>{commande.nb_colis - scannedCount}</b> colis sur {commande.nb_colis}{" "}
									pour la commande <b>{commande.commande_ref}</b>. Si vous changez maintenant, aucun
									colis ne sera affecté à un pad et vous repartirez à zéro.
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
