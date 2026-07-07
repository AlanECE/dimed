"use client";

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
import { API_BASE, fetchApi } from "@/lib/api";
import {
	CheckCircle2,
	Download,
	FileDown,
	Loader2,
	PackagePlus,
	Plus,
	ScanLine,
	Search,
	ShoppingBag,
	Trash2,
} from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

// ---------------------------------------------------------------------------
// Types locaux
// ---------------------------------------------------------------------------

type DraftLigne = {
	key: string;
	designation: string;
	quantite: number;
	ppa: string;
	n_lot: string;
	exp: string;
};

type ScanResult = {
	designation: string | null;
	ppa: string | null;
	n_lot: string | null;
	exp: string | null;
};

type ArrivageHistoryItem = {
	id: string;
	source: "ocr" | "commande";
	commande_reference: string | null;
	nb_lignes: number;
	created_at: string;
};

type CommandeLivree = {
	id: string;
	reference_id: string;
	statut: string;
	montant_total: number;
	date: string;
	deja_importee: boolean;
};

type CommandeImportPreview = {
	commande_id: string;
	reference_id: string;
	statut: string;
	deja_importee: boolean;
	lignes: {
		designation: string;
		quantite: number;
		ppa: string;
		n_lot: string | null;
		exp: string | null;
	}[];
};

function downloadCsv(arrivageId: string) {
	window.open(`${API_BASE}/pharmacie/arrivages/${arrivageId}/csv`, "_blank");
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

export default function ArrivagePharmaciePage() {
	// --- Draft OCR ---
	const [draft, setDraft] = useState<DraftLigne[]>([]);
	const [captureOpen, setCaptureOpen] = useState(false);
	const [scanning, setScanning] = useState(false);
	const [savingDraft, setSavingDraft] = useState(false);

	// --- Import commande ---
	const [refInput, setRefInput] = useState("");
	const [searchingRef, setSearchingRef] = useState(false);
	const [preview, setPreview] = useState<CommandeImportPreview | null>(null);
	const [importing, setImporting] = useState(false);
	const [commandesLivrees, setCommandesLivrees] = useState<CommandeLivree[]>([]);

	// --- Historique ---
	const [history, setHistory] = useState<ArrivageHistoryItem[]>([]);
	const [loadingHistory, setLoadingHistory] = useState(true);

	const refreshHistory = useCallback(async () => {
		setLoadingHistory(true);
		try {
			const data = await fetchApi<{ items: ArrivageHistoryItem[] }>("/pharmacie/arrivages");
			setHistory(data.items);
		} catch {
			setHistory([]);
		} finally {
			setLoadingHistory(false);
		}
	}, []);

	const refreshCommandesLivrees = useCallback(async () => {
		try {
			const data = await fetchApi<{ items: CommandeLivree[] }>("/pharmacie/commandes-livrees");
			setCommandesLivrees(data.items);
		} catch {
			setCommandesLivrees([]);
		}
	}, []);

	useEffect(() => {
		refreshHistory();
		refreshCommandesLivrees();
	}, [refreshHistory, refreshCommandesLivrees]);

	// -----------------------------------------------------------------------
	// OCR flow
	// -----------------------------------------------------------------------

	const handleCapture = useCallback(async (file: File) => {
		setScanning(true);
		try {
			const form = new FormData();
			form.append("file", file);
			const res = await fetch(`${API_BASE}/pharmacie/arrivages/scan`, {
				method: "POST",
				body: form,
				credentials: "include",
			});
			if (!res.ok) {
				const body = await res.json().catch(() => ({ detail: "Erreur OCR" }));
				throw new Error(body.detail ?? `Scan ${res.status}`);
			}
			const result: ScanResult = await res.json();
			if (!result.designation) {
				toast.warning("Désignation non lue — complétez-la manuellement");
			}
			setDraft((prev) => [
				...prev,
				{
					key: crypto.randomUUID(),
					designation: result.designation ?? "",
					quantite: 1,
					ppa: result.ppa ?? "",
					n_lot: result.n_lot ?? "",
					exp: result.exp ?? "",
				},
			]);
			toast.success("Étiquette scannée — ajustez la quantité reçue");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur OCR");
		} finally {
			setScanning(false);
		}
	}, []);

	const patchDraft = useCallback((key: string, patch: Partial<DraftLigne>) => {
		setDraft((prev) => prev.map((l) => (l.key === key ? { ...l, ...patch } : l)));
	}, []);

	const handleValidateDraft = useCallback(async () => {
		const valid = draft.filter((l) => l.designation.trim() && l.quantite >= 1);
		if (valid.length === 0) return;
		setSavingDraft(true);
		try {
			const res = await fetchApi<{ id: string }>("/pharmacie/arrivages", {
				method: "POST",
				body: JSON.stringify({
					source: "ocr",
					lignes: valid.map((l) => ({
						designation: l.designation.trim(),
						quantite: l.quantite,
						ppa: l.ppa.trim() || null,
						n_lot: l.n_lot.trim() || null,
						exp: l.exp || null,
					})),
				}),
			});
			toast.success("Arrivage enregistré — stock mis à jour");
			downloadCsv(res.id);
			setDraft([]);
			refreshHistory();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur d'enregistrement");
		} finally {
			setSavingDraft(false);
		}
	}, [draft, refreshHistory]);

	// -----------------------------------------------------------------------
	// Import commande flow
	// -----------------------------------------------------------------------

	const openPreviewFor = useCallback(async (reference: string) => {
		setSearchingRef(true);
		try {
			const data = await fetchApi<CommandeImportPreview>(
				`/pharmacie/commandes/${encodeURIComponent(reference.trim())}/lignes`,
			);
			setPreview(data);
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Commande introuvable");
		} finally {
			setSearchingRef(false);
		}
	}, []);

	const handleImportCommande = useCallback(async () => {
		if (!preview) return;
		setImporting(true);
		try {
			const res = await fetchApi<{ id: string }>("/pharmacie/arrivages", {
				method: "POST",
				body: JSON.stringify({
					source: "commande",
					commande_id: preview.commande_id,
					lignes: preview.lignes.map((l) => ({
						designation: l.designation,
						quantite: l.quantite,
						ppa: l.ppa,
						n_lot: l.n_lot,
						exp: l.exp,
					})),
				}),
			});
			toast.success(`Commande ${preview.reference_id} importée — stock incrémenté`);
			downloadCsv(res.id);
			setPreview(null);
			setRefInput("");
			refreshHistory();
			refreshCommandesLivrees();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur d'import");
		} finally {
			setImporting(false);
		}
	}, [preview, refreshHistory, refreshCommandesLivrees]);

	// -----------------------------------------------------------------------
	// Render
	// -----------------------------------------------------------------------

	const suggestions = commandesLivrees.filter((c) => !c.deja_importee).slice(0, 5);

	return (
		<div className="flex flex-col gap-8">
			{/* Header */}
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50">
					<PackagePlus className="h-5 w-5 text-emerald-600" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Arrivage</h2>
					<p className="text-[13px] text-muted-foreground">
						Scannez une étiquette ou importez une commande livrée pour alimenter votre stock
					</p>
				</div>
			</div>

			{/* ================================================================ */}
			{/* 1. Scan OCR */}
			{/* ================================================================ */}
			<section className="flex flex-col gap-3">
				<div className="flex items-center justify-between">
					<div className="flex items-center gap-2">
						<ScanLine className="h-4 w-4 text-emerald-600" />
						<h3 className="text-[15px] font-semibold">Scanner une étiquette</h3>
					</div>
					<Button
						onClick={() => setCaptureOpen(true)}
						disabled={scanning}
						className="gap-1.5 rounded-lg bg-gradient-to-r from-[#0F766E] to-[#0D9488] text-[13px] font-semibold text-white shadow-sm hover:brightness-110"
					>
						{scanning ? (
							<Loader2 className="h-4 w-4 animate-spin" />
						) : (
							<ScanLine className="h-4 w-4" />
						)}
						{scanning ? "Analyse en cours…" : "Scanner (OCR)"}
					</Button>
				</div>
				<p className="text-[12px] text-muted-foreground">
					Un seul scan suffit par produit : ajustez ensuite la quantité reçue (ex. scannez 1
					Doliprane, saisissez 54).
				</p>

				{draft.length > 0 && (
					<>
						<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
							<Table>
								<TableHeader>
									<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
										<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
											Désignation
										</TableHead>
										<TableHead className="w-28 text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
											Quantité
										</TableHead>
										<TableHead className="w-28 text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
											PPA
										</TableHead>
										<TableHead className="w-28 text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
											Lot
										</TableHead>
										<TableHead className="w-36 text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
											Exp
										</TableHead>
										<TableHead className="w-12" />
									</TableRow>
								</TableHeader>
								<TableBody>
									{draft.map((ligne) => (
										<TableRow key={ligne.key} className="border-border/30">
											<TableCell>
												<Input
													value={ligne.designation}
													onChange={(e) => patchDraft(ligne.key, { designation: e.target.value })}
													placeholder="Désignation du produit"
													className="h-8 text-[13px]"
												/>
											</TableCell>
											<TableCell>
												<Input
													type="number"
													min={1}
													value={ligne.quantite}
													onChange={(e) =>
														patchDraft(ligne.key, {
															quantite: Number.parseInt(e.target.value, 10) || 1,
														})
													}
													className="h-8 text-center text-[13px] font-semibold tabular-nums"
												/>
											</TableCell>
											<TableCell>
												<Input
													type="number"
													step="0.01"
													min={0}
													value={ligne.ppa}
													onChange={(e) => patchDraft(ligne.key, { ppa: e.target.value })}
													placeholder="—"
													className="h-8 font-mono text-[12px] tabular-nums"
												/>
											</TableCell>
											<TableCell>
												<Input
													value={ligne.n_lot}
													onChange={(e) => patchDraft(ligne.key, { n_lot: e.target.value })}
													placeholder="—"
													className="h-8 font-mono text-[12px]"
												/>
											</TableCell>
											<TableCell>
												<Input
													type="date"
													value={ligne.exp}
													onChange={(e) => patchDraft(ligne.key, { exp: e.target.value })}
													className="h-8 font-mono text-[12px]"
												/>
											</TableCell>
											<TableCell>
												<Button
													variant="ghost"
													size="icon"
													onClick={() =>
														setDraft((prev) => prev.filter((l) => l.key !== ligne.key))
													}
													className="h-8 w-8 text-muted-foreground hover:text-destructive"
													aria-label="Retirer la ligne"
												>
													<Trash2 className="h-4 w-4" />
												</Button>
											</TableCell>
										</TableRow>
									))}
								</TableBody>
							</Table>
						</div>

						<div className="flex items-center justify-between">
							<Button
								variant="outline"
								size="sm"
								onClick={() => setCaptureOpen(true)}
								disabled={scanning}
								className="gap-1.5 text-[12px]"
							>
								<Plus className="h-3.5 w-3.5" />
								Scanner un autre produit
							</Button>
							<Button
								onClick={handleValidateDraft}
								disabled={
									savingDraft || !draft.some((l) => l.designation.trim() && l.quantite >= 1)
								}
								className="gap-1.5 rounded-lg bg-gradient-to-r from-[#0F766E] to-[#0D9488] text-[13px] font-semibold text-white shadow-sm hover:brightness-110"
							>
								{savingDraft ? (
									<Loader2 className="h-4 w-4 animate-spin" />
								) : (
									<CheckCircle2 className="h-4 w-4" />
								)}
								Valider l'arrivage ({draft.length} ligne{draft.length > 1 ? "s" : ""}) — CSV + stock
							</Button>
						</div>
					</>
				)}
			</section>

			{/* ================================================================ */}
			{/* 2. Import depuis une commande livrée */}
			{/* ================================================================ */}
			<section className="flex flex-col gap-3">
				<div className="flex items-center gap-2">
					<ShoppingBag className="h-4 w-4 text-sky-600" />
					<h3 className="text-[15px] font-semibold">Importer une commande reçue</h3>
				</div>
				<p className="text-[12px] text-muted-foreground">
					Récupérez directement le contenu d'une commande livrée — sans repasser par l'OCR.
				</p>

				<div className="flex items-center gap-2">
					<div className="relative w-64">
						<Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
						<Input
							value={refInput}
							onChange={(e) => setRefInput(e.target.value)}
							onKeyDown={(e) => {
								if (e.key === "Enter" && refInput.trim()) {
									e.preventDefault();
									openPreviewFor(refInput);
								}
							}}
							placeholder="N° de commande (ex : C00000121)"
							className="pl-9 font-mono text-[13px]"
						/>
					</div>
					<Button
						variant="outline"
						onClick={() => openPreviewFor(refInput)}
						disabled={!refInput.trim() || searchingRef}
						className="gap-1.5 text-[13px]"
					>
						{searchingRef ? (
							<Loader2 className="h-4 w-4 animate-spin" />
						) : (
							<Search className="h-4 w-4" />
						)}
						Chercher
					</Button>
				</div>

				{suggestions.length > 0 && (
					<div className="overflow-hidden rounded-xl border border-sky-200 bg-sky-50/40">
						<div className="border-b border-sky-200/60 px-4 py-2 text-[12px] font-semibold text-sky-900">
							Suggestions — commandes livrées non importées
						</div>
						<div className="flex flex-col divide-y divide-sky-200/40">
							{suggestions.map((c) => (
								<div key={c.id} className="flex items-center justify-between gap-3 px-4 py-2">
									<div>
										<span className="font-mono text-[13px] font-semibold">{c.reference_id}</span>
										<span className="ml-2 text-[12px] text-muted-foreground">
											{new Date(c.date).toLocaleDateString("fr-FR")} —{" "}
											{c.montant_total.toLocaleString("fr-FR")} DA
										</span>
									</div>
									<Button
										size="sm"
										variant="outline"
										onClick={() => openPreviewFor(c.reference_id)}
										disabled={searchingRef}
										className="h-7 gap-1 text-[12px]"
									>
										<Download className="h-3 w-3" />
										Importer
									</Button>
								</div>
							))}
						</div>
					</div>
				)}
			</section>

			{/* ================================================================ */}
			{/* 3. Historique */}
			{/* ================================================================ */}
			<section className="flex flex-col gap-3">
				<div className="flex items-center gap-2">
					<FileDown className="h-4 w-4 text-muted-foreground" />
					<h3 className="text-[15px] font-semibold">Historique des arrivages</h3>
				</div>
				<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
					<Table>
						<TableHeader>
							<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Date
								</TableHead>
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Source
								</TableHead>
								<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Lignes
								</TableHead>
								<TableHead className="w-14 text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									CSV
								</TableHead>
							</TableRow>
						</TableHeader>
						<TableBody>
							{loadingHistory ? (
								["h1", "h2", "h3"].map((k) => (
									<TableRow key={k} className="border-border/30">
										{["c1", "c2", "c3", "c4"].map((c) => (
											<TableCell key={`${k}-${c}`}>
												<Skeleton className="h-4 w-full" />
											</TableCell>
										))}
									</TableRow>
								))
							) : history.length === 0 ? (
								<TableRow>
									<TableCell
										colSpan={4}
										className="py-10 text-center text-[13px] text-muted-foreground"
									>
										Aucun arrivage enregistré
									</TableCell>
								</TableRow>
							) : (
								history.map((a) => (
									<TableRow key={a.id} className="border-border/30 hover:bg-muted/40">
										<TableCell className="text-[13px] text-muted-foreground">
											{new Date(a.created_at).toLocaleString("fr-FR", {
												day: "2-digit",
												month: "2-digit",
												year: "numeric",
												hour: "2-digit",
												minute: "2-digit",
											})}
										</TableCell>
										<TableCell className="text-[13px]">
											{a.source === "commande" ? (
												<span>
													Commande{" "}
													<span className="font-mono font-semibold">
														{a.commande_reference ?? "—"}
													</span>
												</span>
											) : (
												"Scan OCR"
											)}
										</TableCell>
										<TableCell className="text-center text-[13px] tabular-nums">
											{a.nb_lignes}
										</TableCell>
										<TableCell>
											<Button
												variant="ghost"
												size="icon"
												onClick={() => downloadCsv(a.id)}
												className="h-8 w-8 rounded-lg text-primary/70 hover:bg-primary/10 hover:text-primary"
												aria-label="Télécharger le CSV"
											>
												<Download className="h-4 w-4" />
											</Button>
										</TableCell>
									</TableRow>
								))
							)}
						</TableBody>
					</Table>
				</div>
			</section>

			{/* Capture dialog (réutilise le module OCR existant) */}
			<VignetteCaptureDialog
				open={captureOpen}
				onOpenChange={setCaptureOpen}
				onCapture={(file) => void handleCapture(file)}
			/>

			{/* Preview import commande */}
			<Dialog open={!!preview} onOpenChange={(open) => !open && setPreview(null)}>
				<DialogContent className="max-h-[85vh] max-w-lg overflow-y-auto">
					<DialogHeader>
						<DialogTitle>Importer la commande {preview?.reference_id}</DialogTitle>
						<DialogDescription>
							{preview?.deja_importee
								? "⚠ Cette commande a déjà été importée dans votre stock."
								: "Le contenu ci-dessous sera ajouté à votre stock et exporté en CSV."}
						</DialogDescription>
					</DialogHeader>

					<div className="overflow-hidden rounded-lg border border-border/60">
						<Table>
							<TableHeader>
								<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
									<TableHead className="text-[11px] font-semibold uppercase text-muted-foreground/70">
										Désignation
									</TableHead>
									<TableHead className="text-center text-[11px] font-semibold uppercase text-muted-foreground/70">
										Qté
									</TableHead>
									<TableHead className="text-right text-[11px] font-semibold uppercase text-muted-foreground/70">
										PPA
									</TableHead>
								</TableRow>
							</TableHeader>
							<TableBody>
								{preview?.lignes.map((l) => (
									<TableRow key={`${preview.commande_id}-${l.designation}`}>
										<TableCell className="text-[13px]">{l.designation}</TableCell>
										<TableCell className="text-center text-[13px] font-semibold tabular-nums">
											{l.quantite}
										</TableCell>
										<TableCell className="text-right font-mono text-[12px] tabular-nums">
											{l.ppa}
										</TableCell>
									</TableRow>
								))}
							</TableBody>
						</Table>
					</div>

					<DialogFooter>
						<Button variant="outline" onClick={() => setPreview(null)} disabled={importing}>
							Annuler
						</Button>
						<Button
							onClick={handleImportCommande}
							disabled={importing || preview?.deja_importee}
							className="gap-1.5"
						>
							{importing && <Loader2 className="h-4 w-4 animate-spin" />}
							Accepter — CSV + stock
						</Button>
					</DialogFooter>
				</DialogContent>
			</Dialog>
		</div>
	);
}
