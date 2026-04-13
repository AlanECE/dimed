"use client";

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
import { Input } from "@/components/ui/input";
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from "@/components/ui/table";
import { fetchApi } from "@/lib/api";
import type { LigneResponse } from "@/lib/types";
import { Loader2 } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";

type RemiseDialogProps = {
	commandeId: string | null;
	commandeReference: string;
	onOpenChange: (open: boolean) => void;
	onSaved: (
		commandeId: string,
		payload: { lines: { ligne_id: string; remise_pct: number }[] },
	) => Promise<void>;
};

type EditableLine = LigneResponse & { remise_input: string };

export function RemiseDialog({
	commandeId,
	commandeReference,
	onOpenChange,
	onSaved,
}: RemiseDialogProps) {
	const open = commandeId !== null;
	const [lines, setLines] = useState<EditableLine[]>([]);
	const [loading, setLoading] = useState(false);
	const [submitting, setSubmitting] = useState(false);

	useEffect(() => {
		if (!commandeId) return;
		let cancelled = false;
		setLoading(true);
		fetchApi<{ lignes: LigneResponse[] }>(`/commandes/${commandeId}/lignes`)
			.then((data) => {
				if (cancelled) return;
				setLines(
					data.lignes.map((ln) => ({
						...ln,
						remise_input: ln.remise_pct ? String(ln.remise_pct) : "0",
					})),
				);
			})
			.catch(() => {
				if (!cancelled) toast.error("Impossible de charger les lignes");
			})
			.finally(() => {
				if (!cancelled) setLoading(false);
			});
		return () => {
			cancelled = true;
		};
	}, [commandeId]);

	function updateLine(id: string, remise_input: string) {
		setLines((prev) => prev.map((ln) => (ln.id === id ? { ...ln, remise_input } : ln)));
	}

	function parseRemise(input: string): number {
		const n = Number.parseFloat(input.replace(",", "."));
		if (Number.isNaN(n) || n < 0) return 0;
		if (n > 100) return 100;
		return Math.round(n * 100) / 100;
	}

	const enriched = lines.map((ln) => {
		const remise = parseRemise(ln.remise_input);
		const brut = ln.prix_unitaire * ln.qte_demandee;
		const net = brut * (1 - remise / 100);
		return { ...ln, remise, brut, net };
	});

	const totalBrut = enriched.reduce((s, l) => s + l.brut, 0);
	const remiseTotale = enriched.reduce((s, l) => s + (l.brut - l.net), 0);
	const netAPayer = totalBrut - remiseTotale;

	async function handleSave() {
		if (!commandeId) return;
		setSubmitting(true);
		try {
			await onSaved(commandeId, {
				lines: enriched.map((l) => ({
					ligne_id: l.id,
					remise_pct: l.remise,
				})),
			});
			toast.success("Remises appliquees, facture regeneree");
			onOpenChange(false);
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors de l'enregistrement");
		} finally {
			setSubmitting(false);
		}
	}

	return (
		<AlertDialog open={open} onOpenChange={onOpenChange}>
			<AlertDialogContent className="max-w-3xl rounded-xl">
				<AlertDialogHeader>
					<AlertDialogTitle className="font-heading font-bold">
						Remises — {commandeReference}
					</AlertDialogTitle>
					<AlertDialogDescription className="text-[13px]">
						Saisissez un pourcentage de remise par ligne. La facture sera regeneree.
					</AlertDialogDescription>
				</AlertDialogHeader>

				<div className="max-h-[50vh] overflow-auto rounded-lg border border-border/60">
					<Table>
						<TableHeader>
							<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Designation
								</TableHead>
								<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Qte
								</TableHead>
								<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									PU (DA)
								</TableHead>
								<TableHead className="w-24 text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									R%
								</TableHead>
								<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Total (DA)
								</TableHead>
							</TableRow>
						</TableHeader>
						<TableBody>
							{loading ? (
								<TableRow>
									<TableCell
										colSpan={5}
										className="py-8 text-center text-[13px] text-muted-foreground"
									>
										Chargement...
									</TableCell>
								</TableRow>
							) : (
								enriched.map((ln) => (
									<TableRow key={ln.id} className="border-border/30">
										<TableCell className="text-[13px]">{ln.designation}</TableCell>
										<TableCell className="text-center text-[13px] tabular-nums">
											{ln.qte_demandee}
										</TableCell>
										<TableCell className="text-right text-[13px] tabular-nums">
											{ln.prix_unitaire.toLocaleString("fr-FR", { minimumFractionDigits: 2 })}
										</TableCell>
										<TableCell className="text-center">
											<Input
												type="number"
												min={0}
												max={100}
												step={0.5}
												value={ln.remise_input}
												onChange={(e) => updateLine(ln.id, e.target.value)}
												className="h-8 w-20 rounded-md border-border/60 bg-card text-center text-[13px] tabular-nums"
												aria-label={`Remise ${ln.designation}`}
											/>
										</TableCell>
										<TableCell className="text-right text-[13px] font-semibold tabular-nums">
											{ln.net.toLocaleString("fr-FR", { minimumFractionDigits: 2 })}
										</TableCell>
									</TableRow>
								))
							)}
						</TableBody>
					</Table>
				</div>

				{/* Totals summary */}
				<div className="ml-auto w-full max-w-xs rounded-lg border border-border/60 bg-muted/30 p-3 text-[13px]">
					<div className="flex justify-between">
						<span className="text-muted-foreground">Total brut</span>
						<span className="tabular-nums">
							{totalBrut.toLocaleString("fr-FR", { minimumFractionDigits: 2 })} DA
						</span>
					</div>
					<div className="flex justify-between">
						<span className="text-muted-foreground">Remise totale</span>
						<span className="tabular-nums text-red-600">
							-{remiseTotale.toLocaleString("fr-FR", { minimumFractionDigits: 2 })} DA
						</span>
					</div>
					<div className="mt-2 flex justify-between border-t border-border/60 pt-2 font-semibold">
						<span>Net a payer</span>
						<span className="tabular-nums text-primary">
							{netAPayer.toLocaleString("fr-FR", { minimumFractionDigits: 2 })} DA
						</span>
					</div>
				</div>

				<AlertDialogFooter>
					<AlertDialogCancel disabled={submitting} className="rounded-lg">
						Annuler
					</AlertDialogCancel>
					<AlertDialogAction
						onClick={handleSave}
						disabled={submitting || loading}
						className="rounded-lg bg-primary font-semibold shadow-sm hover:brightness-110"
					>
						{submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
						Enregistrer & regenerer
					</AlertDialogAction>
				</AlertDialogFooter>
			</AlertDialogContent>
		</AlertDialog>
	);
}
