"use client";

import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogFooter,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
import { fetchApi } from "@/lib/api";
import type { OrderResponse } from "@/lib/types";
import { PackagePlus } from "lucide-react";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { toast } from "sonner";

const LAST_SEEN_KEY = "dimed-orders-last-seen";
const JUST_LOGGED_IN_KEY = "dimed-just-logged-in";
const POLL_MS = 45000;

function formatHeure(iso: string): string {
	return new Date(iso).toLocaleString("fr-FR", {
		day: "2-digit",
		month: "2-digit",
		hour: "2-digit",
		minute: "2-digit",
	});
}

/**
 * Surveille les nouvelles commandes "créées" pour l'opératrice.
 * - À la connexion : popup listant les commandes arrivées depuis la dernière fois.
 * - Déjà connectée : notification (toast) en haut à droite à chaque nouvelle commande.
 */
export function NewOrdersWatcher() {
	const router = useRouter();
	const [dialogOpen, setDialogOpen] = useState(false);
	const [newOrders, setNewOrders] = useState<OrderResponse[]>([]);
	const lastSeenRef = useRef<number>(0);
	const startedRef = useRef(false);

	const check = useCallback(async () => {
		let data: { commandes: OrderResponse[]; total: number };
		try {
			data = await fetchApi<{ commandes: OrderResponse[]; total: number }>("/commandes", {
				params: { statut: "creee", limit: 50, offset: 0 },
			});
		} catch {
			return; // silencieux : on retentera au prochain tick
		}

		const fresh = (data.commandes ?? []).filter(
			(o) => new Date(o.created_at).getTime() > lastSeenRef.current,
		);
		if (fresh.length === 0) return;

		// Drapeau posé par le login : popup à la connexion, sinon toast.
		let justLoggedIn = false;
		try {
			justLoggedIn = sessionStorage.getItem(JUST_LOGGED_IN_KEY) === "1";
			if (justLoggedIn) sessionStorage.removeItem(JUST_LOGGED_IN_KEY);
		} catch {
			// sessionStorage indisponible
		}

		if (justLoggedIn) {
			setNewOrders(fresh);
			setDialogOpen(true);
		} else {
			toast.info(
				`${fresh.length} nouvelle${fresh.length > 1 ? "s" : ""} commande${
					fresh.length > 1 ? "s" : ""
				}`,
				{
					description: fresh
						.slice(0, 3)
						.map((o) => `${o.reference_id} — ${o.pharmacien_nom ?? "—"}`)
						.join("\n"),
					action: { label: "Voir", onClick: () => router.push("/dashboard?statut=creee") },
				},
			);
		}

		const newest = Math.max(...fresh.map((o) => new Date(o.created_at).getTime()));
		lastSeenRef.current = newest;
		try {
			localStorage.setItem(LAST_SEEN_KEY, String(newest));
		} catch {
			// localStorage indisponible
		}
	}, [router]);

	useEffect(() => {
		if (startedRef.current) return;
		startedRef.current = true;

		const stored = Number(localStorage.getItem(LAST_SEEN_KEY));
		if (stored && !Number.isNaN(stored)) {
			lastSeenRef.current = stored;
		} else {
			// Premier usage : pas de référence → on part de maintenant pour ne pas
			// présenter d'un coup toutes les commandes historiques.
			lastSeenRef.current = Date.now();
			try {
				localStorage.setItem(LAST_SEEN_KEY, String(lastSeenRef.current));
				sessionStorage.removeItem(JUST_LOGGED_IN_KEY);
			} catch {
				// stockage indisponible
			}
		}

		check();
		const id = setInterval(check, POLL_MS);
		return () => clearInterval(id);
	}, [check]);

	return (
		<Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
			<DialogContent>
				<DialogHeader>
					<div className="flex items-center gap-2.5">
						<div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/10">
							<PackagePlus className="h-4.5 w-4.5 text-primary" />
						</div>
						<DialogTitle>
							{newOrders.length} nouvelle{newOrders.length > 1 ? "s" : ""} commande
							{newOrders.length > 1 ? "s" : ""}
						</DialogTitle>
					</div>
					<DialogDescription>Depuis votre dernière connexion :</DialogDescription>
				</DialogHeader>

				<ul className="flex max-h-72 flex-col gap-1.5 overflow-y-auto">
					{newOrders.map((o) => (
						<li
							key={o.id}
							className="flex items-center justify-between rounded-lg border border-border/50 bg-muted/30 px-3 py-2 text-[13px]"
						>
							<span>
								<span className="font-mono font-semibold">{o.reference_id}</span>
								<span className="ml-2 text-muted-foreground">{o.pharmacien_nom ?? "—"}</span>
							</span>
							<span className="shrink-0 text-[12px] text-muted-foreground tabular-nums">
								{formatHeure(o.created_at)}
							</span>
						</li>
					))}
				</ul>

				<DialogFooter>
					<Button
						onClick={() => {
							setDialogOpen(false);
							router.push("/dashboard?statut=creee");
						}}
						className="bg-gradient-to-r from-[#0F766E] to-[#0D9488] font-semibold text-white"
					>
						Voir les commandes
					</Button>
				</DialogFooter>
			</DialogContent>
		</Dialog>
	);
}
