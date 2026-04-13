"use client";

import {
	AlertDialog,
	AlertDialogCancel,
	AlertDialogContent,
	AlertDialogDescription,
	AlertDialogFooter,
	AlertDialogHeader,
	AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { useCaddiesPool } from "@/hooks/use-caddies-pool";
import type { CaddiePoolResponse } from "@/lib/types";
import { Loader2, ShoppingCart } from "lucide-react";
import { useEffect, useState } from "react";

type Props = {
	open: boolean;
	commandeRef: string;
	onOpenChange: (open: boolean) => void;
	onConfirm: (caddie: CaddiePoolResponse) => Promise<void> | void;
};

export function CaddieSelectDialog({ open, commandeRef, onOpenChange, onConfirm }: Props) {
	const { pool, loading, refetch } = useCaddiesPool(false);
	const [submitting, setSubmitting] = useState(false);

	useEffect(() => {
		if (open) refetch();
	}, [open, refetch]);

	const availableCount = pool.filter((c) => c.is_available).length;

	async function handleClick(caddie: CaddiePoolResponse) {
		if (!caddie.is_available || submitting) return;
		setSubmitting(true);
		try {
			await onConfirm(caddie);
			onOpenChange(false);
		} finally {
			setSubmitting(false);
		}
	}

	return (
		<AlertDialog open={open} onOpenChange={onOpenChange}>
			<AlertDialogContent className="max-w-md">
				<AlertDialogHeader>
					<AlertDialogTitle>Choisir un caddie — {commandeRef}</AlertDialogTitle>
					<AlertDialogDescription>
						{availableCount === 0 && !loading
							? "Aucun caddie libre pour le moment."
							: "Sélectionnez un caddie libre pour commencer la préparation."}
					</AlertDialogDescription>
				</AlertDialogHeader>

				{loading ? (
					<div className="flex justify-center py-8">
						<Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
					</div>
				) : (
					<div className="grid grid-cols-5 gap-2.5 py-2">
						{pool.map((caddie) => {
							const disabled = !caddie.is_available || submitting;
							return (
								<button
									key={caddie.id}
									type="button"
									disabled={disabled}
									onClick={() => handleClick(caddie)}
									title={
										caddie.is_available
											? "Libre"
											: `Occupé par ${caddie.current_commande_ref ?? "?"}`
									}
									className={`flex aspect-square flex-col items-center justify-center gap-1 rounded-lg border text-[12px] font-semibold transition-all ${
										caddie.is_available
											? "border-primary/40 bg-primary/5 text-primary hover:scale-105 hover:bg-primary/15 hover:shadow-sm"
											: "cursor-not-allowed border-border/60 bg-muted/50 text-muted-foreground/60"
									}`}
								>
									<ShoppingCart className="h-4 w-4" />
									{caddie.numero}
								</button>
							);
						})}
					</div>
				)}

				<AlertDialogFooter>
					<AlertDialogCancel disabled={submitting}>Annuler</AlertDialogCancel>
				</AlertDialogFooter>
			</AlertDialogContent>
		</AlertDialog>
	);
}
