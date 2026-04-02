"use client";

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
	AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from "@/components/ui/table";
import { fetchApi } from "@/lib/api";
import type { OrderDetailResponse } from "@/lib/types";
import { ArrowLeft, Loader2, XCircle } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

export default function CommandeDetailPage() {
	const { id } = useParams<{ id: string }>();
	const [order, setOrder] = useState<OrderDetailResponse | null>(null);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);
	const [cancelling, setCancelling] = useState(false);

	const fetchOrder = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<OrderDetailResponse>(`/commandes/${id}`);
			setOrder(data);
			setError(null);
		} catch (err) {
			setError(err instanceof Error ? err.message : "Commande introuvable");
		} finally {
			setLoading(false);
		}
	}, [id]);

	useEffect(() => {
		fetchOrder();
	}, [fetchOrder]);

	async function handleCancel() {
		setCancelling(true);
		try {
			await fetchApi(`/commandes/${id}/cancel`, { method: "PATCH" });
			toast.success("Commande annulée");
			fetchOrder();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors de l'annulation");
		} finally {
			setCancelling(false);
		}
	}

	if (loading) {
		return (
			<div className="flex flex-col gap-4">
				<Skeleton className="h-5 w-24" />
				<Skeleton className="h-8 w-64" />
				<Skeleton className="h-48 w-full rounded-xl" />
			</div>
		);
	}

	if (error || !order) {
		return (
			<div className="flex flex-col items-center gap-4 py-16">
				<p className="text-[13px] text-muted-foreground">{error ?? "Commande introuvable"}</p>
				<Link href="/commandes">
					<Button variant="outline" className="rounded-lg">
						<ArrowLeft className="mr-2 h-4 w-4" />
						Retour aux commandes
					</Button>
				</Link>
			</div>
		);
	}

	return (
		<div className="animate-fade-in-up flex flex-col gap-6">
			{/* Back link */}
			<Link
				href="/commandes"
				className="inline-flex items-center gap-1.5 text-[13px] font-medium text-muted-foreground transition-colors hover:text-foreground"
			>
				<ArrowLeft className="h-3.5 w-3.5" />
				Retour
			</Link>

			{/* Header */}
			<div className="flex items-center justify-between">
				<div>
					<h2 className="font-heading text-xl font-bold">Commande {order.reference_id}</h2>
					<p className="mt-0.5 text-[13px] text-muted-foreground">
						Passée le {new Date(order.created_at).toLocaleDateString("fr-FR")}
					</p>
				</div>
				<StatusBadge status={order.statut} />
			</div>

			{/* Articles table */}
			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Désignation
							</TableHead>
							<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Quantité
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70 tabular-nums">
								Prix unitaire
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70 tabular-nums">
								Total
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{order.lignes.map((ligne) => (
							<TableRow key={ligne.id} className="border-border/30">
								<TableCell className="text-[13px] font-medium">{ligne.designation}</TableCell>
								<TableCell className="text-center text-[13px] tabular-nums">
									{ligne.qte_demandee}
								</TableCell>
								<TableCell className="text-right text-[13px] tabular-nums">
									{ligne.prix_unitaire.toLocaleString("fr-FR")} DA
								</TableCell>
								<TableCell className="text-right text-[13px] font-semibold tabular-nums">
									{(ligne.qte_demandee * ligne.prix_unitaire).toLocaleString("fr-FR")} DA
								</TableCell>
							</TableRow>
						))}
					</TableBody>
				</Table>
			</div>

			{/* Total */}
			<div className="flex justify-end">
				<div className="rounded-xl border border-border/60 bg-muted/30 px-5 py-3">
					<span className="text-[13px] text-muted-foreground">Montant total : </span>
					<span className="font-heading text-lg font-bold tabular-nums">
						{order.montant_total.toLocaleString("fr-FR")} DA
					</span>
				</div>
			</div>

			{/* Cancel button */}
			{order.statut === "creee" && (
				<AlertDialog>
					<AlertDialogTrigger className="inline-flex w-fit items-center gap-2 rounded-lg border border-destructive/30 px-4 py-2.5 text-[13px] font-semibold text-destructive transition-colors hover:bg-destructive/5">
						<XCircle className="h-4 w-4" />
						Annuler la commande
					</AlertDialogTrigger>
					<AlertDialogContent className="rounded-xl">
						<AlertDialogHeader>
							<AlertDialogTitle>Annuler la commande</AlertDialogTitle>
							<AlertDialogDescription>
								Cette action est irréversible. Voulez-vous continuer ?
							</AlertDialogDescription>
						</AlertDialogHeader>
						<AlertDialogFooter>
							<AlertDialogCancel disabled={cancelling} className="rounded-lg">
								Non, garder
							</AlertDialogCancel>
							<AlertDialogAction
								onClick={handleCancel}
								disabled={cancelling}
								className="rounded-lg bg-destructive text-destructive-foreground hover:bg-destructive/90"
							>
								{cancelling && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
								Oui, annuler
							</AlertDialogAction>
						</AlertDialogFooter>
					</AlertDialogContent>
				</AlertDialog>
			)}
		</div>
	);
}
