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

	const outOfStock = items.filter(
		(i) => i.medicament.stock_quantity <= 0 || i.qte > i.medicament.stock_quantity,
	);
	const hasBlockingStockIssue = outOfStock.length > 0;

	async function handleConfirm() {
		if (hasBlockingStockIssue) {
			toast.error(
				`Rupture de stock : ${outOfStock
					.map((i) => `${i.medicament.designation} (stock=${i.medicament.stock_quantity})`)
					.join(", ")}`,
			);
			return;
		}
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
			<AlertDialogContent className="max-w-lg rounded-xl">
				<AlertDialogHeader>
					<AlertDialogTitle className="font-heading font-bold">
						Confirmer la commande
					</AlertDialogTitle>
					<AlertDialogDescription className="text-[13px]">
						{itemCount} article{itemCount > 1 ? "s" : ""} — Montant total :{" "}
						{total.toLocaleString("fr-FR")} DA
					</AlertDialogDescription>
				</AlertDialogHeader>

				<div className="overflow-hidden rounded-lg border border-border/60">
					<Table>
						<TableHeader>
							<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Désignation
								</TableHead>
								<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Qté
								</TableHead>
								<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Prix
								</TableHead>
							</TableRow>
						</TableHeader>
						<TableBody>
							{items.map((item) => (
								<TableRow key={item.medicament.id} className="border-border/30">
									<TableCell className="text-[13px]">{item.medicament.designation}</TableCell>
									<TableCell className="text-center text-[13px] tabular-nums">{item.qte}</TableCell>
									<TableCell className="text-right text-[13px] font-semibold tabular-nums">
										{(item.medicament.ppa * item.qte).toLocaleString("fr-FR")} DA
									</TableCell>
								</TableRow>
							))}
						</TableBody>
					</Table>
				</div>

				<AlertDialogFooter>
					<AlertDialogCancel disabled={submitting} className="rounded-lg">
						Annuler
					</AlertDialogCancel>
					<AlertDialogAction
						onClick={handleConfirm}
						disabled={submitting || hasBlockingStockIssue}
						className="rounded-lg bg-primary font-semibold shadow-sm hover:brightness-110"
					>
						{submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
						Confirmer la commande
					</AlertDialogAction>
				</AlertDialogFooter>
			</AlertDialogContent>
		</AlertDialog>
	);
}
