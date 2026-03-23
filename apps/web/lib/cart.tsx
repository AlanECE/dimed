"use client";

import type { MedicamentResponse } from "@/lib/types";
import { createContext, useCallback, useContext, useMemo, useState } from "react";

type CartItem = {
	medicament: MedicamentResponse;
	qte: number;
};

type CartContextValue = {
	items: CartItem[];
	addItem: (medicament: MedicamentResponse) => void;
	updateQte: (medicamentId: string, qte: number) => void;
	removeItem: (medicamentId: string) => void;
	clearCart: () => void;
	total: number;
	itemCount: number;
};

const CartContext = createContext<CartContextValue | null>(null);

export function CartProvider({ children }: { children: React.ReactNode }) {
	const [items, setItems] = useState<CartItem[]>([]);

	const addItem = useCallback((medicament: MedicamentResponse) => {
		setItems((prev) => {
			const existing = prev.find((i) => i.medicament.id === medicament.id);
			if (existing) {
				return prev.map((i) => (i.medicament.id === medicament.id ? { ...i, qte: i.qte + 1 } : i));
			}
			return [...prev, { medicament, qte: 1 }];
		});
	}, []);

	const updateQte = useCallback((medicamentId: string, qte: number) => {
		if (qte <= 0) {
			setItems((prev) => prev.filter((i) => i.medicament.id !== medicamentId));
		} else {
			setItems((prev) => prev.map((i) => (i.medicament.id === medicamentId ? { ...i, qte } : i)));
		}
	}, []);

	const removeItem = useCallback((medicamentId: string) => {
		setItems((prev) => prev.filter((i) => i.medicament.id !== medicamentId));
	}, []);

	const clearCart = useCallback(() => {
		setItems([]);
	}, []);

	const total = useMemo(() => items.reduce((sum, i) => sum + i.medicament.ppa * i.qte, 0), [items]);

	const itemCount = useMemo(() => items.reduce((sum, i) => sum + i.qte, 0), [items]);

	const value = useMemo(
		() => ({ items, addItem, updateQte, removeItem, clearCart, total, itemCount }),
		[items, addItem, updateQte, removeItem, clearCart, total, itemCount],
	);

	return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart() {
	const context = useContext(CartContext);
	if (!context) {
		throw new Error("useCart must be used within CartProvider");
	}
	return context;
}
