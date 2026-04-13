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
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useBulkClaim } from "@/hooks/use-bulk-claim";
import { useCaddieSuggestions } from "@/hooks/use-caddie-suggestions";
import { fetchApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import type { OrderResponse } from "@/lib/types";
import { Loader2, X } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

type Props = {
	open: boolean;
	commandes: OrderResponse[];
	onOpenChange: (open: boolean) => void;
	onDone: () => void;
};

type Preparateur = { id: string; nom: string };

export function BulkClaimDialog({ open, commandes, onOpenChange, onDone }: Props) {
	const { user } = useAuth();
	const { suggestions } = useCaddieSuggestions();
	const { bulkClaim, submitting } = useBulkClaim();

	const isOperatrice = user?.role === "operatrice" || user?.role === "admin";

	const [caddiesByCommande, setCaddiesByCommande] = useState<Record<string, string[]>>({});
	const [inputByCommande, setInputByCommande] = useState<Record<string, string>>({});
	const [preparateurs, setPreparateurs] = useState<Preparateur[]>([]);
	const [selectedPrep, setSelectedPrep] = useState<string>("");

	useEffect(() => {
		if (!open) return;
		const initial: Record<string, string[]> = {};
		const inputs: Record<string, string> = {};
		for (const c of commandes) {
			initial[c.id] = c.caddies?.map((x) => x.numero) ?? [];
			inputs[c.id] = "";
		}
		setCaddiesByCommande(initial);
		setInputByCommande(inputs);
		setSelectedPrep("");
	}, [open, commandes]);

	useEffect(() => {
		if (!open || !isOperatrice) return;
		fetchApi<{ preparateurs: Preparateur[] }>("/commandes/preparateurs")
			.then((data) => setPreparateurs(data.preparateurs))
			.catch(() => toast.error("Impossible de charger les preparateurs"));
	}, [open, isOperatrice]);

	function addCaddie(commandeId: string, raw: string) {
		const clean = raw.trim();
		if (!clean) return;
		setCaddiesByCommande((prev) => {
			const current = prev[commandeId] ?? [];
			if (current.includes(clean)) return prev;
			return { ...prev, [commandeId]: [...current, clean] };
		});
		setInputByCommande((prev) => ({ ...prev, [commandeId]: "" }));
	}

	function removeCaddie(commandeId: string, numero: string) {
		setCaddiesByCommande((prev) => ({
			...prev,
			[commandeId]: (prev[commandeId] ?? []).filter((n) => n !== numero),
		}));
	}

	function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>, commandeId: string) {
		if (e.key === "Enter" || e.key === ",") {
			e.preventDefault();
			addCaddie(commandeId, inputByCommande[commandeId] ?? "");
		} else if (
			e.key === "Backspace" &&
			(inputByCommande[commandeId] ?? "") === "" &&
			(caddiesByCommande[commandeId]?.length ?? 0) > 0
		) {
			const list = caddiesByCommande[commandeId] ?? [];
			removeCaddie(commandeId, list[list.length - 1]);
		}
	}

	const canSubmit = useMemo(() => {
		if (commandes.length === 0) return false;
		if (isOperatrice && !selectedPrep) return false;
		return commandes.every((c) => (caddiesByCommande[c.id]?.length ?? 0) > 0);
	}, [commandes, caddiesByCommande, isOperatrice, selectedPrep]);

	async function handleSubmit() {
		try {
			await bulkClaim({
				commande_ids: commandes.map((c) => c.id),
				preparateur_id: isOperatrice ? selectedPrep : null,
				caddies: commandes.map((c) => ({
					commande_id: c.id,
					numeros: caddiesByCommande[c.id] ?? [],
				})),
			});
			toast.success(
				`${commandes.length} commande${commandes.length > 1 ? "s" : ""} prise${commandes.length > 1 ? "s" : ""} en charge`,
			);
			onDone();
			onOpenChange(false);
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors de la prise en charge");
		}
	}

	return (
		<AlertDialog open={open} onOpenChange={onOpenChange}>
			<AlertDialogContent className="max-w-3xl rounded-xl">
				<AlertDialogHeader>
					<AlertDialogTitle className="font-heading font-bold">
						Prise en charge de {commandes.length} commande{commandes.length > 1 ? "s" : ""}
					</AlertDialogTitle>
					<AlertDialogDescription className="text-[13px]">
						Saisissez un ou plusieurs numeros de caddies par commande. Appuyez sur Entree ou virgule
						pour valider chaque numero.
					</AlertDialogDescription>
				</AlertDialogHeader>

				{isOperatrice && (
					<div className="flex items-center gap-3 rounded-lg border border-border/60 bg-muted/30 p-3">
						<label htmlFor="prep-select" className="text-[13px] font-medium">
							Preparateur :
						</label>
						<select
							id="prep-select"
							value={selectedPrep}
							onChange={(e) => setSelectedPrep(e.target.value)}
							className="h-9 flex-1 rounded-md border border-border/60 bg-card px-3 text-[13px]"
						>
							<option value="">— Choisir —</option>
							{preparateurs.map((p) => (
								<option key={p.id} value={p.id}>
									{p.nom}
								</option>
							))}
						</select>
					</div>
				)}

				<div className="max-h-[50vh] space-y-3 overflow-auto">
					{commandes.map((c) => {
						const chips = caddiesByCommande[c.id] ?? [];
						const inputVal = inputByCommande[c.id] ?? "";
						const listId = `sugg-${c.id}`;
						return (
							<div
								key={c.id}
								className="rounded-lg border border-border/60 bg-card p-3 text-[13px]"
							>
								<div className="mb-2 flex items-center justify-between">
									<span className="font-mono font-semibold">{c.reference_id}</span>
									<span className="text-muted-foreground">{c.pharmacien_nom ?? "—"}</span>
								</div>
								<div className="flex flex-wrap items-center gap-1.5 rounded-md border border-border/60 bg-background px-2 py-1.5">
									{chips.map((numero) => (
										<span
											key={numero}
											className="inline-flex items-center gap-1 rounded-md bg-primary/10 px-2 py-0.5 text-[12px] font-semibold text-primary"
										>
											{numero}
											<button
												type="button"
												onClick={() => removeCaddie(c.id, numero)}
												className="rounded hover:bg-primary/20"
												aria-label={`Retirer ${numero}`}
											>
												<X className="h-3 w-3" />
											</button>
										</span>
									))}
									<Input
										value={inputVal}
										onChange={(e) =>
											setInputByCommande((prev) => ({ ...prev, [c.id]: e.target.value }))
										}
										onKeyDown={(e) => handleKeyDown(e, c.id)}
										onBlur={() => addCaddie(c.id, inputVal)}
										placeholder={chips.length ? "" : "Ex: C-10, 47, A3..."}
										className="h-7 min-w-[120px] flex-1 border-0 bg-transparent p-0 text-[12px] shadow-none focus-visible:ring-0"
										list={listId}
									/>
									<datalist id={listId}>
										{suggestions.map((s) => (
											<option key={s} value={s} />
										))}
									</datalist>
								</div>
							</div>
						);
					})}
				</div>

				<AlertDialogFooter>
					<AlertDialogCancel disabled={submitting} className="rounded-lg">
						Annuler
					</AlertDialogCancel>
					<Button
						onClick={handleSubmit}
						disabled={!canSubmit || submitting}
						className="rounded-lg bg-primary font-semibold shadow-sm hover:brightness-110"
					>
						{submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
						Prendre en charge
					</Button>
				</AlertDialogFooter>
			</AlertDialogContent>
		</AlertDialog>
	);
}
