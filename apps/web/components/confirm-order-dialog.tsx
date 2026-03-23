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
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from "@/components/ui/table";
import { fetchApi } from "@/lib/api";
import { useCart } from "@/lib/cart";
import type { OrderDetailResponse } from "@/lib/types";
import { Loader2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { toast } from "sonner";

type ConfirmOrderDialogProps = {
	open: boolean;
	onOpenChange: (open: boolean) => void;
};

export function ConfirmOrderDialog({ open, onOpenChange }: ConfirmOrderDialogProps) {
	const { items, total, itemCount, clearCart } = useCart();
	const [submitting, setSubmitting] = useState(false);
	const router = useRouter();

	async function handleConfirm() {
		setSubmitting(true);
		try {
			const payload = {
				articles: items.map((i) => ({
					medicament_id: i.medicament.id,
					qte: i.qte,
				})),
			};
			const order = await fetchApi<OrderDetailResponse>("/commandes", {
				method: "POST",
				body: JSON.stringify(payload),
			});
			clearCart();
			onOpenChange(false);
			toast.success("Commande créée avec succès");
			router.push(`/commandes/${order.id}`);
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors de la création");
		} finally {
			setSubmitting(false);
		}
	}

	return (
		<AlertDialog open={open} onOpenChange={onOpenChange}>
			<AlertDialogContent className="max-w-lg">
				<AlertDialogHeader>
					<AlertDialogTitle>Confirmer la commande</AlertDialogTitle>
					<AlertDialogDescription>
						Articles : {itemCount} — Montant total : {total.toLocaleString("fr-FR")} DA
					</AlertDialogDescription>
				</AlertDialogHeader>

				<div className="overflow-x-auto rounded-md border">
					<Table>
						<TableHeader>
							<TableRow>
								<TableHead>Désignation</TableHead>
								<TableHead className="text-center">Qté</TableHead>
								<TableHead className="text-right">Prix</TableHead>
							</TableRow>
						</TableHeader>
						<TableBody>
							{items.map((item) => (
								<TableRow key={item.medicament.id}>
									<TableCell className="text-sm">{item.medicament.designation}</TableCell>
									<TableCell className="text-center tabular-nums">{item.qte}</TableCell>
									<TableCell className="text-right tabular-nums">
										{(item.medicament.ppa * item.qte).toLocaleString("fr-FR")} DA
									</TableCell>
								</TableRow>
							))}
						</TableBody>
					</Table>
				</div>

				<AlertDialogFooter>
					<AlertDialogCancel disabled={submitting}>Annuler</AlertDialogCancel>
					<AlertDialogAction onClick={handleConfirm} disabled={submitting}>
						{submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
						Confirmer la commande
					</AlertDialogAction>
				</AlertDialogFooter>
			</AlertDialogContent>
		</AlertDialog>
	);
}
