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
				<Skeleton className="h-6 w-32" />
				<Skeleton className="h-8 w-64" />
				<Skeleton className="h-48 w-full" />
			</div>
		);
	}

	if (error || !order) {
		return (
			<div className="flex flex-col items-center gap-4 py-12">
				<p className="text-muted-foreground">{error ?? "Commande introuvable"}</p>
				<Link href="/commandes">
					<Button variant="outline">
						<ArrowLeft className="mr-2 h-4 w-4" />
						Retour aux commandes
					</Button>
				</Link>
			</div>
		);
	}

	return (
		<div className="flex flex-col gap-6">
			{/* Back link */}
			<Link
				href="/commandes"
				className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
			>
				<ArrowLeft className="h-4 w-4" />
				Retour
			</Link>

			{/* Header */}
			<div className="flex items-center justify-between">
				<div>
					<h2 className="font-heading text-2xl font-semibold">Commande {order.reference_id}</h2>
					<p className="text-sm text-muted-foreground">
						Passée le {new Date(order.created_at).toLocaleDateString("fr-FR")}
					</p>
				</div>
				<StatusBadge status={order.statut} />
			</div>

			{/* Articles table */}
			<div className="overflow-x-auto rounded-md border">
				<Table>
					<TableHeader>
						<TableRow>
							<TableHead>Désignation</TableHead>
							<TableHead className="text-center">Quantité</TableHead>
							<TableHead className="tabular-nums text-right">Prix unitaire</TableHead>
							<TableHead className="tabular-nums text-right">Total</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{order.lignes.map((ligne) => (
							<TableRow key={ligne.id}>
								<TableCell>{ligne.designation}</TableCell>
								<TableCell className="text-center tabular-nums">{ligne.qte_demandee}</TableCell>
								<TableCell className="tabular-nums text-right">
									{ligne.prix_unitaire.toLocaleString("fr-FR")} DA
								</TableCell>
								<TableCell className="tabular-nums text-right">
									{(ligne.qte_demandee * ligne.prix_unitaire).toLocaleString("fr-FR")} DA
								</TableCell>
							</TableRow>
						))}
					</TableBody>
				</Table>
			</div>

			{/* Total */}
			<div className="flex justify-end">
				<p className="text-lg font-semibold tabular-nums">
					Montant total : {order.montant_total.toLocaleString("fr-FR")} DA
				</p>
			</div>

			{/* Cancel button — only for Créée status */}
			{order.statut === "creee" && (
				<AlertDialog>
					<AlertDialogTrigger className="inline-flex w-fit items-center gap-2 rounded-md border border-destructive px-4 py-2 text-sm font-medium text-destructive hover:bg-destructive/10">
						<XCircle className="h-4 w-4" />
						Annuler la commande
					</AlertDialogTrigger>
					<AlertDialogContent>
						<AlertDialogHeader>
							<AlertDialogTitle>Annuler la commande</AlertDialogTitle>
							<AlertDialogDescription>
								Cette action est irréversible. Voulez-vous continuer ?
							</AlertDialogDescription>
						</AlertDialogHeader>
						<AlertDialogFooter>
							<AlertDialogCancel disabled={cancelling}>Non, garder</AlertDialogCancel>
							<AlertDialogAction
								onClick={handleCancel}
								disabled={cancelling}
								className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
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
