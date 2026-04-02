"use client";

import { ConfirmOrderDialog } from "@/components/confirm-order-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useCart } from "@/lib/cart";
import { Minus, Plus, ShoppingCart, Trash2 } from "lucide-react";
import { useState } from "react";

export function CartSidebar() {
	const { items, updateQte, removeItem, total, itemCount } = useCart();
	const [confirmOpen, setConfirmOpen] = useState(false);

	return (
		<aside className="sticky top-0 flex h-screen w-80 shrink-0 flex-col border-l border-border/60 bg-card">
			{/* Header */}
			<div className="flex items-center gap-2.5 border-b border-border/60 px-5 py-4">
				<div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10">
					<ShoppingCart className="h-4 w-4 text-primary" />
				</div>
				<h3 className="font-heading text-[15px] font-bold">Panier</h3>
				{itemCount > 0 && (
					<Badge
						variant="secondary"
						className="ml-auto rounded-full bg-primary/10 px-2 text-[11px] font-bold text-primary"
					>
						{itemCount}
					</Badge>
				)}
			</div>

			{/* Items */}
			<div className="flex-1 overflow-y-auto p-4">
				{items.length === 0 ? (
					<div className="flex flex-col items-center justify-center gap-3 py-16 text-center">
						<div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-muted">
							<ShoppingCart className="h-7 w-7 text-muted-foreground/40" />
						</div>
						<div>
							<p className="text-[13px] font-semibold text-muted-foreground">
								Votre panier est vide
							</p>
							<p className="mt-1 text-[12px] text-muted-foreground/70">
								Ajoutez des médicaments depuis le catalogue.
							</p>
						</div>
					</div>
				) : (
					<div className="flex flex-col gap-3">
						{items.map((item) => (
							<div
								key={item.medicament.id}
								className="animate-fade-in rounded-xl border border-border/40 bg-muted/30 p-3 transition-colors hover:bg-muted/50"
							>
								<div className="flex items-start justify-between gap-2">
									<span className="text-[13px] font-semibold leading-tight text-foreground">
										{item.medicament.designation}
									</span>
									<Button
										variant="ghost"
										size="icon"
										className="h-6 w-6 shrink-0 text-muted-foreground/60 hover:text-destructive"
										onClick={() => removeItem(item.medicament.id)}
										aria-label={`Supprimer ${item.medicament.designation}`}
									>
										<Trash2 className="h-3 w-3" />
									</Button>
								</div>
								<div className="mt-2 flex items-center justify-between">
									<div className="flex items-center gap-0.5">
										<Button
											variant="ghost"
											size="icon"
											className="h-7 w-7 rounded-lg"
											onClick={() => updateQte(item.medicament.id, item.qte - 1)}
											aria-label="Diminuer la quantité"
										>
											<Minus className="h-3 w-3" />
										</Button>
										<Input
											type="number"
											min={1}
											value={item.qte}
											onChange={(e) =>
												updateQte(item.medicament.id, Number.parseInt(e.target.value, 10) || 1)
											}
											className="h-7 w-12 rounded-lg border-border/40 bg-card text-center text-[12px] tabular-nums"
										/>
										<Button
											variant="ghost"
											size="icon"
											className="h-7 w-7 rounded-lg"
											onClick={() => updateQte(item.medicament.id, item.qte + 1)}
											aria-label="Augmenter la quantité"
										>
											<Plus className="h-3 w-3" />
										</Button>
									</div>
									<span className="text-[12px] font-semibold tabular-nums text-muted-foreground">
										{(item.medicament.ppa * item.qte).toLocaleString("fr-FR")} DA
									</span>
								</div>
							</div>
						))}
					</div>
				)}
			</div>

			{/* Footer */}
			<div className="border-t border-border/60 p-4">
				<div className="mb-4 flex items-center justify-between">
					<span className="text-[13px] font-medium text-muted-foreground">Total</span>
					<span className="font-heading text-lg font-bold tabular-nums text-foreground">
						{total.toLocaleString("fr-FR")} DA
					</span>
				</div>
				<Button
					className="h-11 w-full rounded-xl bg-primary font-semibold shadow-md shadow-primary/15 transition-all hover:shadow-lg hover:shadow-primary/20 hover:brightness-110"
					disabled={items.length === 0}
					onClick={() => setConfirmOpen(true)}
				>
					<ShoppingCart className="mr-2 h-4 w-4" />
					Valider la commande
				</Button>
			</div>

			<ConfirmOrderDialog open={confirmOpen} onOpenChange={setConfirmOpen} />
		</aside>
	);
}
