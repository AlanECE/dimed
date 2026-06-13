"use client";

import { QrScanner } from "@/components/qr-scanner";
import { StatusBadge } from "@/components/status-badge";
import { Badge } from "@/components/ui/badge";
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
	Grid3x3,
	Loader2,
	MapPin,
	Package,
	PackageCheck,
	ScanLine,
	X,
} from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

const COLIS_STATUT_LABELS: Record<string, string> = {
	etiquete: "Étiqueté",
	sur_pad: "Sur pad",
	charge: "Chargé",
	livre: "Livré",
};

export default function MagasinierPage() {
	const { lookupColis, deposePad, fetchPads } = useExpedition();

	const [colis, setColis] = useState<ColisDetail | null>(null);
	const [lookupLoading, setLookupLoading] = useState(false);
	const [selectedPadId, setSelectedPadId] = useState<string>("");
	const [saving, setSaving] = useState(false);
	const [pads, setPads] = useState<PadOccupation[] | null>(null);
	const [padsLoading, setPadsLoading] = useState(true);

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

	const handleScan = useCallback(
		async (numero: string) => {
			if (lookupLoading || saving) return;
			setLookupLoading(true);
			try {
				const detail = await lookupColis(numero);
				setColis(detail);
				setSelectedPadId(detail.pad_suggere?.id ?? detail.pad?.id ?? "");
				if (detail.statut === "charge" || detail.statut === "livre") {
					toast.warning(
						`Colis ${detail.numero} déjà ${COLIS_STATUT_LABELS[detail.statut].toLowerCase()}`,
					);
				}
			} catch (err) {
				toast.error(err instanceof Error ? err.message : `Colis ${numero} introuvable`);
			} finally {
				setLookupLoading(false);
			}
		},
		[lookupColis, lookupLoading, saving],
	);

	const handleConfirm = useCallback(async () => {
		if (!colis || !selectedPadId) return;
		setSaving(true);
		try {
			const res = await deposePad(colis.numero, selectedPadId);
			toast.success(`Colis ${colis.numero} déposé sur ${res.pad.code}`);
			setColis(null);
			setSelectedPadId("");
			refreshPads();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors du dépôt");
		} finally {
			setSaving(false);
		}
	}, [colis, selectedPadId, deposePad, refreshPads]);

	const dismissColis = useCallback(() => {
		setColis(null);
		setSelectedPadId("");
	}, []);

	const overriding = colis?.pad_suggere && selectedPadId && selectedPadId !== colis.pad_suggere.id;
	const canDepose = colis && (colis.statut === "etiquete" || colis.statut === "sur_pad");

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
						Scannez chaque colis puis confirmez son pad de dépôt
					</p>
				</div>
			</div>

			<div className="grid gap-6 lg:grid-cols-2">
				{/* ===== Colonne scan ===== */}
				<section className="flex flex-col gap-4">
					<div className="flex items-center gap-2.5">
						<ScanLine className="h-4 w-4 text-violet-600" />
						<h3 className="text-[15px] font-semibold">Scanner un colis</h3>
					</div>

					<QrScanner onScan={handleScan} paused={lookupLoading || saving || !!colis} />

					{/* Carte colis scanné */}
					{lookupLoading && (
						<div className="flex items-center justify-center rounded-xl border border-border/60 bg-card py-8">
							<Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
						</div>
					)}

					{colis && !lookupLoading && (
						<div className="animate-fade-in-up overflow-hidden rounded-xl border border-violet-200 bg-card shadow-sm">
							<div className="flex items-start justify-between gap-3 border-b border-border/40 bg-violet-50/50 px-5 py-3">
								<div>
									<p className="font-mono text-[15px] font-bold">{colis.numero}</p>
									<p className="text-[13px] font-semibold text-violet-700">
										Colis {colis.index_colis} / {colis.nb_colis}
									</p>
								</div>
								<div className="flex items-center gap-2">
									<Badge variant="outline" className="text-[11px]">
										{COLIS_STATUT_LABELS[colis.statut] ?? colis.statut}
									</Badge>
									<button
										type="button"
										onClick={dismissColis}
										className="rounded-md p-1 text-muted-foreground hover:bg-muted"
									>
										<X className="h-4 w-4" />
									</button>
								</div>
							</div>

							<div className="flex flex-col gap-2 px-5 py-4">
								<div className="flex items-center justify-between text-[13px]">
									<span className="text-muted-foreground">Commande</span>
									<span className="flex items-center gap-2">
										<span className="font-mono font-medium">{colis.commande_ref}</span>
										<StatusBadge status={colis.commande_statut} />
									</span>
								</div>
								<div className="flex items-center justify-between text-[13px]">
									<span className="text-muted-foreground">Date</span>
									<span>{new Date(colis.date_commande).toLocaleDateString("fr-FR")}</span>
								</div>
								<div className="flex items-start justify-between gap-4 text-[13px]">
									<span className="text-muted-foreground">Destinataire</span>
									<span className="text-right">
										<span className="font-semibold">{colis.pharmacien_nom}</span>
										{colis.pharmacien_adresse && (
											<>
												<br />
												<span className="text-muted-foreground">{colis.pharmacien_adresse}</span>
											</>
										)}
										{colis.pharmacien_secteur && (
											<>
												<br />
												<span className="text-muted-foreground">
													Secteur : {colis.pharmacien_secteur}
												</span>
											</>
										)}
									</span>
								</div>

								{/* Contenu */}
								<div className="mt-1 rounded-lg bg-muted/40 px-3 py-2">
									<p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
										{colis.contenu_detaille ? "Contenu du colis" : "Contenu (commande complète)"}
									</p>
									<ul className="mt-1 flex flex-col gap-0.5">
										{colis.contenu.slice(0, 8).map((item) => (
											<li
												key={`${item.designation}-${item.quantite}`}
												className="flex items-center justify-between text-[12px]"
											>
												<span className="truncate">{item.designation}</span>
												<span className="ml-2 shrink-0 font-semibold tabular-nums">
													× {item.quantite}
												</span>
											</li>
										))}
										{colis.contenu.length > 8 && (
											<li className="text-[11px] text-muted-foreground">
												+ {colis.contenu.length - 8} autres articles
											</li>
										)}
										{colis.contenu.length === 0 && (
											<li className="text-[12px] text-muted-foreground">Contenu non détaillé</li>
										)}
									</ul>
								</div>

								{/* Pad actuel / suggestion */}
								{colis.pad && colis.statut === "sur_pad" && (
									<p className="text-[12px] text-muted-foreground">
										Déjà posé sur <span className="font-semibold">{colis.pad.code}</span> —
										re-scanner pour déplacer.
									</p>
								)}

								{canDepose ? (
									<div className="mt-2 flex flex-col gap-2.5">
										{colis.pad_suggere && (
											<div
												className={`flex items-center gap-2 rounded-lg px-3 py-2 text-[13px] ${
													colis.pad_impose
														? "bg-amber-50 text-amber-800"
														: "bg-emerald-50 text-emerald-800"
												}`}
											>
												<MapPin className="h-4 w-4 shrink-0" />
												{colis.pad_impose ? (
													<span>
														Pad <b>{colis.pad_suggere.code}</b> imposé — d&apos;autres colis de
														cette commande y sont déjà
													</span>
												) : (
													<span>
														Pad <b>{colis.pad_suggere.code}</b> suggéré (pad libre)
													</span>
												)}
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
												onClick={handleConfirm}
												disabled={!selectedPadId || saving}
												className="gap-1.5 rounded-lg bg-gradient-to-r from-[#0F766E] to-[#0D9488] font-semibold text-white shadow-sm hover:brightness-110"
											>
												{saving ? (
													<Loader2 className="h-4 w-4 animate-spin" />
												) : (
													<CheckCircle2 className="h-4 w-4" />
												)}
												Confirmer le dépôt
											</Button>
										</div>

										{overriding && (
											<p className="flex items-center gap-1.5 text-[12px] text-amber-700">
												<AlertTriangle className="h-3.5 w-3.5" />
												Vous remplacez le pad {colis.pad_impose ? "imposé" : "suggéré"} (
												{colis.pad_suggere?.code})
											</p>
										)}
									</div>
								) : (
									colis && (
										<p className="flex items-center gap-1.5 text-[12px] text-muted-foreground">
											<AlertTriangle className="h-3.5 w-3.5" />
											Ce colis est déjà {COLIS_STATUT_LABELS[colis.statut]?.toLowerCase()} — dépôt
											impossible.
										</p>
									)
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
		</div>
	);
}
