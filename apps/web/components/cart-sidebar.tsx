"use client";

import { ConfirmOrderDialog } from "@/components/confirm-order-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Separator } from "@/components/ui/separator";
import { useCart } from "@/lib/cart";
import { Minus, Plus, ShoppingCart, Trash2 } from "lucide-react";
import { useState } from "react";

export function CartSidebar() {
	const { items, updateQte, removeItem, total, itemCount } = useCart();
	const [confirmOpen, setConfirmOpen] = useState(false);

	return (
		<aside className="sticky top-0 flex h-screen w-80 shrink-0 flex-col border-l bg-white">
			{/* Header */}
			<div className="flex items-center gap-2 border-b p-4">
				<h3 className="font-heading text-lg font-semibold">Panier</h3>
				{itemCount > 0 && <Badge variant="secondary">{itemCount}</Badge>}
			</div>

			{/* Items */}
			<div className="flex-1 overflow-y-auto p-4">
				{items.length === 0 ? (
					<div className="flex flex-col items-center justify-center gap-2 py-12 text-center">
						<ShoppingCart className="h-10 w-10 text-muted-foreground/50" />
						<p className="font-medium text-muted-foreground">Votre panier est vide</p>
						<p className="text-sm text-muted-foreground">
							Ajoutez des médicaments depuis le catalogue pour passer commande.
						</p>
					</div>
				) : (
					<div className="flex flex-col gap-4">
						{items.map((item) => (
							<div key={item.medicament.id} className="flex flex-col gap-1">
								<div className="flex items-start justify-between">
									<span className="text-sm font-medium leading-tight">
										{item.medicament.designation}
									</span>
									<Button
										variant="ghost"
										size="icon"
										className="h-6 w-6 shrink-0 text-muted-foreground hover:text-destructive"
										onClick={() => removeItem(item.medicament.id)}
										aria-label={`Supprimer ${item.medicament.designation}`}
									>
										<Trash2 className="h-3.5 w-3.5" />
									</Button>
								</div>
								<div className="flex items-center justify-between">
									<div className="flex items-center gap-1">
										<Button
											variant="ghost"
											size="icon"
											className="h-7 w-7"
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
											className="h-7 w-14 text-center tabular-nums"
										/>
										<Button
											variant="ghost"
											size="icon"
											className="h-7 w-7"
											onClick={() => updateQte(item.medicament.id, item.qte + 1)}
											aria-label="Augmenter la quantité"
										>
											<Plus className="h-3 w-3" />
										</Button>
									</div>
									<span className="text-sm tabular-nums text-muted-foreground">
										{(item.medicament.ppa * item.qte).toLocaleString("fr-FR")} DA
									</span>
								</div>
							</div>
						))}
					</div>
				)}
			</div>

			{/* Footer */}
			<div className="border-t p-4">
				<Separator className="mb-3" />
				<div className="mb-3 flex items-center justify-between">
					<span className="font-medium">Total</span>
					<span className="text-lg font-semibold tabular-nums">
						{total.toLocaleString("fr-FR")} DA
					</span>
				</div>
				<Button
					className="w-full"
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
