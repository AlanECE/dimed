"use client";

import { StatusBadge } from "@/components/status-badge";
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
import { useExpedition } from "@/hooks/use-expedition";
import { useOrders } from "@/hooks/use-orders";
import { API_BASE } from "@/lib/api";
import type { OrderResponse } from "@/lib/types";
import { FileText, QrCode, Receipt } from "lucide-react";
import { useCallback } from "react";
import { toast } from "sonner";

// Les colis (QR) existent une fois la commande contrôlée (prête et au-delà).
const QR_READY = new Set(["prete", "en_route", "livree", "livree_partiellement"]);

export default function FacturierPage() {
	const { orders, loading } = useOrders({ limit: 50 });
	const { downloadEtiquettes } = useExpedition();

	const handleEtiquettes = useCallback(
		async (order: OrderResponse) => {
			try {
				await downloadEtiquettes(order.id, order.reference_id);
			} catch (err) {
				toast.error(err instanceof Error ? err.message : "Erreur téléchargement étiquettes");
			}
		},
		[downloadEtiquettes],
	);

	return (
		<div className="flex flex-col gap-8">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50">
					<Receipt className="h-5 w-5 text-emerald-600" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Facturier</h2>
					<p className="text-[13px] text-muted-foreground">
						Factures et étiquettes QR des commandes en préparation et contrôlées
					</p>
				</div>
			</div>

			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Référence
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Pharmacien
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Date
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Statut
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Documents
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 5 }).map((_, i) => (
								<TableRow key={`sk-${i}`} className="border-border/30">
									{Array.from({ length: 5 }).map((_, j) => (
										<TableCell key={`sk-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : orders.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={5}
									className="py-16 text-center text-[13px] text-muted-foreground"
								>
									Aucune commande à facturer pour le moment
								</TableCell>
							</TableRow>
						) : (
							orders.map((order) => {
								const qrReady = QR_READY.has(order.statut);
								return (
									<TableRow key={order.id} className="border-border/30 hover:bg-muted/40">
										<TableCell className="font-mono text-[13px]">{order.reference_id}</TableCell>
										<TableCell className="text-[13px]">{order.pharmacien_nom ?? "—"}</TableCell>
										<TableCell className="text-[13px] text-muted-foreground tabular-nums">
											{new Date(order.created_at).toLocaleString("fr-FR", {
												day: "2-digit",
												month: "2-digit",
												year: "numeric",
												hour: "2-digit",
												minute: "2-digit",
											})}
										</TableCell>
										<TableCell>
											<StatusBadge status={order.statut} />
										</TableCell>
										<TableCell>
											<div className="flex items-center justify-end gap-1.5">
												<a
													href={`${API_BASE}/documents/facture/${order.id}`}
													target="_blank"
													rel="noopener noreferrer"
												>
													<Button variant="outline" size="sm" className="h-8 gap-1.5 text-[12px]">
														<FileText className="h-3.5 w-3.5" />
														Facture
													</Button>
												</a>
												<Button
													variant="outline"
													size="sm"
													disabled={!qrReady}
													onClick={() => handleEtiquettes(order)}
													className="h-8 gap-1.5 text-[12px]"
													title={
														qrReady
															? "Télécharger les étiquettes QR"
															: "Disponible après le contrôle (commande prête)"
													}
												>
													<QrCode className="h-3.5 w-3.5" />
													Étiquettes QR
												</Button>
											</div>
										</TableCell>
									</TableRow>
								);
							})
						)}
					</TableBody>
				</Table>
			</div>
		</div>
	);
}
