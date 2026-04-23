"use client";

import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from "@/components/ui/table";
import { useOrders } from "@/hooks/use-orders";
import { useAuth } from "@/lib/auth";
import { fetchApi } from "@/lib/api";
import type { OrderResponse } from "@/lib/types";
import {
	ChevronLeft,
	ChevronRight,
	Loader2,
	MessageSquareWarning,
	X,
} from "lucide-react";
import { useRouter, useSearchParams } from "next/navigation";
import { useCallback, useState } from "react";
import { toast } from "sonner";

const PAGE_SIZE = 20;

const STATUS_OPTIONS = [
	{ value: "all", label: "Toutes" },
	{ value: "creee", label: "Créée" },
	{ value: "acceptee", label: "Acceptée" },
	{ value: "en_preparation", label: "En préparation" },
	{ value: "prete_a_livrer", label: "Prête à livrer" },
	{ value: "en_livraison", label: "En livraison" },
	{ value: "livree", label: "Livrée" },
	{ value: "annulee", label: "Annulée" },
];

const MOTIF_OPTIONS = [
	{ value: "produit_endommage", label: "Produit endommagé" },
	{ value: "produit_manquant", label: "Produit manquant" },
	{ value: "erreur_facturation", label: "Erreur de facturation" },
	{ value: "erreur_produit", label: "Erreur de produit" },
	{ value: "autre", label: "Autre" },
];

export function OrderTable() {
	const router = useRouter();
	const searchParams = useSearchParams();
	const { user } = useAuth();
	const isPharmacien = user?.role === "pharmacien";

	const statut = searchParams.get("statut") ?? "all";
	const dateFrom = searchParams.get("date_from") ?? "";
	const dateTo = searchParams.get("date_to") ?? "";
	const page = Number(searchParams.get("page") ?? "0");

	const { orders, total, loading } = useOrders({
		statut,
		dateFrom: dateFrom || undefined,
		dateTo: dateTo || undefined,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

	// ── Réclamation modal state ────────────────────────────────
	const [reclamOrder, setReclamOrder] = useState<OrderResponse | null>(null);
	const [motif, setMotif] = useState("produit_endommage");
	const [description, setDescription] = useState("");
	const [submitting, setSubmitting] = useState(false);

	function openReclam(order: OrderResponse, e: React.MouseEvent) {
		e.stopPropagation();
		setReclamOrder(order);
		setMotif("produit_endommage");
		setDescription("");
	}

	function closeReclam() {
		setReclamOrder(null);
		setDescription("");
	}

	async function handleSubmitReclam() {
		if (!reclamOrder) return;
		setSubmitting(true);
		try {
			await fetchApi("/reclamations", {
				method: "POST",
				body: JSON.stringify({
					commande_id: reclamOrder.id,
					motif,
					description,
				}),
			});
			toast.success("Réclamation envoyée");
			closeReclam();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors de l'envoi");
		} finally {
			setSubmitting(false);
		}
	}

	const updateParam = useCallback(
		(key: string, value: string) => {
			const params = new URLSearchParams(searchParams.toString());
			if (value && value !== "all" && value !== "0") {
				params.set(key, value);
			} else {
				params.delete(key);
			}
			if (key !== "page") params.delete("page");
			router.push(`/commandes?${params.toString()}`);
		},
		[searchParams, router],
	);

	return (
		<div className="flex flex-col gap-4">
			{/* Filters */}
			<div className="flex gap-3">
				<Select value={statut} onValueChange={(v) => updateParam("statut", v ?? "all")}>
					<SelectTrigger className="w-48 rounded-lg border-border/60 bg-card text-[13px]">
						<SelectValue placeholder="Statut" />
					</SelectTrigger>
					<SelectContent>
						{STATUS_OPTIONS.map((opt) => (
							<SelectItem key={opt.value} value={opt.value}>
								{opt.label}
							</SelectItem>
						))}
					</SelectContent>
				</Select>

				<Input
					type="date"
					value={dateFrom}
					onChange={(e) => updateParam("date_from", e.target.value)}
					className="w-40 rounded-lg border-border/60 bg-card text-[13px]"
					placeholder="Du"
				/>
				<Input
					type="date"
					value={dateTo}
					onChange={(e) => updateParam("date_to", e.target.value)}
					className="w-40 rounded-lg border-border/60 bg-card text-[13px]"
					placeholder="Au"
				/>
			</div>

			{/* Table */}
			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Référence
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Date
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Articles
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70 tabular-nums">
								Montant
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Statut
							</TableHead>
							{isPharmacien && (
								<TableHead className="w-12" />
							)}
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 6 }).map((_, i) => (
								<TableRow key={i} className="border-border/30">
									{Array.from({ length: isPharmacien ? 6 : 5 }).map((_, j) => (
										<TableCell key={j}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : orders.length === 0 ? (
							<TableRow>
								<TableCell colSpan={isPharmacien ? 6 : 5} className="py-16 text-center">
									<p className="text-[13px] font-medium text-muted-foreground">Aucune commande</p>
									<p className="mt-1 text-[12px] text-muted-foreground/70">
										Vos commandes apparaîtront ici une fois passées.
									</p>
								</TableCell>
							</TableRow>
						) : (
							orders.map((order) => (
								<TableRow
									key={order.id}
									className="cursor-pointer border-border/30 transition-colors hover:bg-muted/40"
									onClick={() => router.push(`/commandes/${order.id}`)}
								>
									<TableCell className="font-mono text-[13px]">{order.reference_id}</TableCell>
									<TableCell className="text-[13px] text-muted-foreground">
										{new Date(order.created_at).toLocaleDateString("fr-FR")}
									</TableCell>
									<TableCell className="text-center text-[13px] text-muted-foreground">—</TableCell>
									<TableCell className="text-right text-[13px] font-semibold tabular-nums">
										{order.montant_total.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell>
										<StatusBadge status={order.statut} />
									</TableCell>
									{isPharmacien && (
										<TableCell onClick={(e) => e.stopPropagation()}>
											<button
												type="button"
												onClick={(e) => openReclam(order, e)}
												title="Faire une réclamation"
												className="flex items-center justify-center w-7 h-7 rounded-lg text-orange-400 hover:text-orange-600 hover:bg-orange-50 transition-colors"
											>
												<MessageSquareWarning className="w-4 h-4" />
											</button>
										</TableCell>
									)}
								</TableRow>
							))
						)}
					</TableBody>
				</Table>
			</div>

			{/* Pagination */}
			<div className="flex items-center justify-between">
				<span className="text-[13px] text-muted-foreground">
					Page {page + 1} sur {totalPages}
				</span>
				<div className="flex gap-1.5">
					<Button
						variant="outline"
						size="sm"
						disabled={page === 0}
						onClick={() => updateParam("page", String(page - 1))}
						className="h-8 rounded-lg border-border/60 px-3 text-[12px]"
					>
						<ChevronLeft className="mr-1 h-3.5 w-3.5" />
						Précédent
					</Button>
					<Button
						variant="outline"
						size="sm"
						disabled={page >= totalPages - 1}
						onClick={() => updateParam("page", String(page + 1))}
						className="h-8 rounded-lg border-border/60 px-3 text-[12px]"
					>
						Suivant
						<ChevronRight className="ml-1 h-3.5 w-3.5" />
					</Button>
				</div>
			</div>

			{/* ── Réclamation modal ──────────────────────────────────── */}
			{reclamOrder && (
				<div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
					<div className="bg-white rounded-2xl shadow-xl w-full max-w-md p-6 space-y-5 mx-4">
						{/* Header */}
						<div className="flex items-center justify-between">
							<div className="flex items-center gap-3">
								<div className="w-9 h-9 rounded-full bg-orange-100 flex items-center justify-center">
									<MessageSquareWarning className="w-4 h-4 text-orange-600" />
								</div>
								<div>
									<h3 className="text-base font-semibold text-gray-900">Nouvelle réclamation</h3>
									<p className="text-xs text-gray-400 font-mono">{reclamOrder.reference_id}</p>
								</div>
							</div>
							<button
								type="button"
								onClick={closeReclam}
								className="text-gray-400 hover:text-gray-600"
							>
								<X className="w-5 h-5" />
							</button>
						</div>

						{/* Commande info */}
						<div className="bg-gray-50 rounded-lg px-4 py-3 text-sm flex justify-between items-center">
							<span className="text-gray-500">Commande du</span>
							<span className="font-medium text-gray-800">
								{new Date(reclamOrder.created_at).toLocaleDateString("fr-FR")}
							</span>
						</div>

						{/* Motif */}
						<div className="space-y-1.5">
							<label className="text-[13px] font-semibold text-gray-700">Motif</label>
							<Select value={motif} onValueChange={(v) => setMotif(v ?? "autre")}>
								<SelectTrigger className="rounded-lg border-border/60 text-[13px]">
									<SelectValue />
								</SelectTrigger>
								<SelectContent>
									{MOTIF_OPTIONS.map((o) => (
										<SelectItem key={o.value} value={o.value}>
											{o.label}
										</SelectItem>
									))}
								</SelectContent>
							</Select>
						</div>

						{/* Description */}
						<div className="space-y-1.5">
							<label className="text-[13px] font-semibold text-gray-700">Description</label>
							<textarea
								value={description}
								onChange={(e) => setDescription(e.target.value)}
								placeholder="Décrivez le problème en détail..."
								rows={4}
								className="w-full rounded-lg border border-border/60 bg-white px-3 py-2 text-[13px] outline-none focus:border-orange-300 focus:ring-2 focus:ring-orange-100 resize-none"
							/>
						</div>

						{/* Actions */}
						<div className="flex gap-3">
							<Button
								variant="outline"
								className="flex-1"
								onClick={closeReclam}
								disabled={submitting}
							>
								Annuler
							</Button>
							<Button
								className="flex-1 bg-orange-500 hover:bg-orange-600 text-white"
								onClick={handleSubmitReclam}
								disabled={submitting || !description.trim()}
							>
								{submitting ? (
									<><Loader2 className="w-4 h-4 mr-2 animate-spin" />Envoi...</>
								) : (
									"Envoyer la réclamation"
								)}
							</Button>
						</div>
					</div>
				</div>
			)}
		</div>
	);
}
