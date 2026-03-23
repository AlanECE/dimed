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
import { fetchApi } from "@/lib/api";
import type { OrderDetailResponse } from "@/lib/types";
import { ArrowLeft, Check, Loader2, XCircle } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

type CamionOption = { id: string; nom: string; plaque: string };

export default function OperatorOrderDetailPage() {
	const { id } = useParams<{ id: string }>();
	const [order, setOrder] = useState<
		(OrderDetailResponse & { pharmacien_nom?: string; pharmacien_email?: string }) | null
	>(null);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);
	const [accepting, setAccepting] = useState(false);
	const [rejecting, setRejecting] = useState(false);
	const [camions, setCamions] = useState<CamionOption[]>([]);
	const [assigning, setAssigning] = useState(false);

	const fetchOrder = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<
				OrderDetailResponse & { pharmacien_nom?: string; pharmacien_email?: string }
			>(`/commandes/${id}`);
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

	// Load camions for assignment dropdown
	useEffect(() => {
		fetchApi<{ camions: CamionOption[] }>("/camions")
			.then((data) => setCamions(data.camions))
			.catch(() => {});
	}, []);

	async function handleAccept() {
		setAccepting(true);
		try {
			await fetchApi(`/commandes/${id}/accept`, { method: "PATCH" });
			toast.success("Commande acceptée");
			fetchOrder();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		} finally {
			setAccepting(false);
		}
	}

	async function handleReject() {
		setRejecting(true);
		try {
			await fetchApi(`/commandes/${id}/reject`, { method: "PATCH" });
			toast.success("Commande rejetée");
			fetchOrder();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		} finally {
			setRejecting(false);
		}
	}

	async function handleAssignCamion(camionId: string | null) {
		if (!camionId) return;
		setAssigning(true);
		try {
			await fetchApi(`/commandes/${id}/assign-camion`, {
				method: "PATCH",
				body: JSON.stringify({ camion_id: camionId }),
			});
			const camion = camions.find((c) => c.id === camionId);
			toast.success(`Commande assignée au camion ${camion?.nom ?? camionId}`);
			fetchOrder();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur d'assignation");
		} finally {
			setAssigning(false);
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
				<Link href="/dashboard">
					<Button variant="outline">
						<ArrowLeft className="mr-2 h-4 w-4" />
						Retour au dashboard
					</Button>
				</Link>
			</div>
		);
	}

	return (
		<div className="flex flex-col gap-6">
			<Link
				href="/dashboard"
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
					{order.pharmacien_nom && (
						<p className="text-sm text-muted-foreground">
							Pharmacien : {order.pharmacien_nom}
							{order.pharmacien_email && ` (${order.pharmacien_email})`}
						</p>
					)}
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

			<div className="flex justify-end">
				<p className="text-lg font-semibold tabular-nums">
					Montant total : {order.montant_total.toLocaleString("fr-FR")} DA
				</p>
			</div>

			{/* Accept/Reject — only for Créée */}
			{order.statut === "creee" && (
				<div className="flex items-center gap-3">
					<AlertDialog>
						<AlertDialogTrigger className="inline-flex items-center gap-2 rounded-md border border-destructive px-4 py-2 text-sm font-medium text-destructive hover:bg-destructive/10">
							<XCircle className="h-4 w-4" />
							Rejeter
						</AlertDialogTrigger>
						<AlertDialogContent>
							<AlertDialogHeader>
								<AlertDialogTitle>Rejeter la commande</AlertDialogTitle>
								<AlertDialogDescription>
									Cette commande sera annulée. Voulez-vous continuer ?
								</AlertDialogDescription>
							</AlertDialogHeader>
							<AlertDialogFooter>
								<AlertDialogCancel disabled={rejecting}>Non, garder</AlertDialogCancel>
								<AlertDialogAction
									onClick={handleReject}
									disabled={rejecting}
									className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
								>
									{rejecting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
									Oui, rejeter
								</AlertDialogAction>
							</AlertDialogFooter>
						</AlertDialogContent>
					</AlertDialog>

					<Button
						onClick={handleAccept}
						disabled={accepting}
						className="bg-emerald-600 text-white hover:bg-emerald-700"
					>
						{accepting ? (
							<Loader2 className="mr-2 h-4 w-4 animate-spin" />
						) : (
							<Check className="mr-2 h-4 w-4" />
						)}
						Accepter
					</Button>
				</div>
			)}

			{/* Camion assignment — only for Acceptée */}
			{order.statut === "acceptee" && (
				<div className="flex items-center gap-3">
					<span className="text-sm font-medium">Camion :</span>
					<Select
						onValueChange={(v) => handleAssignCamion(v as string | null)}
						disabled={assigning}
					>
						<SelectTrigger className="w-64">
							<SelectValue placeholder="Sélectionner un camion" />
						</SelectTrigger>
						<SelectContent>
							{camions.map((c) => (
								<SelectItem key={c.id} value={c.id}>
									{c.nom} ({c.plaque})
								</SelectItem>
							))}
						</SelectContent>
					</Select>
					{assigning && <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />}
				</div>
			)}
		</div>
	);
}
