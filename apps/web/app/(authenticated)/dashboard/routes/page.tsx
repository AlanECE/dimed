"use client";

import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useRouteSheets } from "@/hooks/use-route-sheets";
import { ExternalLink, FileText, Truck } from "lucide-react";

export default function RouteSheetsPage() {
	const { sheets, loading } = useRouteSheets();

	return (
		<div className="flex flex-col gap-4">
			<h2 className="font-heading text-2xl font-semibold">Feuilles de route</h2>

			{loading ? (
				<div className="flex flex-col gap-4">
					{Array.from({ length: 3 }).map((_, i) => (
						// biome-ignore lint/suspicious/noArrayIndexKey: static skeleton
						<Skeleton key={i} className="h-32 w-full rounded-lg" />
					))}
				</div>
			) : sheets.length === 0 ? (
				<div className="flex flex-col items-center gap-2 py-12 text-center">
					<Truck className="h-10 w-10 text-muted-foreground/50" />
					<p className="font-medium text-muted-foreground">Aucun camion configuré</p>
					<p className="text-sm text-muted-foreground">Ajoutez un camion d'abord.</p>
				</div>
			) : (
				<div className="flex flex-col gap-4">
					{sheets.map((sheet) => (
						<Card key={sheet.id} className="overflow-hidden border">
							{/* Header */}
							<div className="flex items-center justify-between border-b bg-muted/30 px-4 py-3">
								<div className="flex items-center gap-2">
									<Truck className="h-4 w-4 text-muted-foreground" />
									<span className="font-medium">
										{sheet.camion_nom} ({sheet.camion_plaque})
									</span>
								</div>
								<div className="flex items-center gap-3 text-sm text-muted-foreground">
									<span>{sheet.commandes.length} commande(s)</span>
									<span>{sheet.date}</span>
								</div>
							</div>

							{/* Commandes list */}
							<div className="px-4 py-3">
								{sheet.commandes.length === 0 ? (
									<p className="text-sm text-muted-foreground">Pas de commandes assignées</p>
								) : (
									<div className="flex flex-col gap-1">
										{sheet.commandes.map((cmd) => (
											<div key={cmd.id} className="flex items-center justify-between text-sm">
												<span className="font-mono">{cmd.reference_id}</span>
												<span className="tabular-nums text-muted-foreground">
													{cmd.montant_total.toLocaleString("fr-FR")} DA
												</span>
											</div>
										))}
									</div>
								)}
							</div>

							{/* Footer — counters */}
							<div className="flex items-center justify-between border-t bg-muted/10 px-4 py-2 text-xs text-muted-foreground">
								<div className="flex gap-4">
									<span>Colis std: {sheet.compteurs.colis_std}</span>
									<span>Sachets std: {sheet.compteurs.sachets_std}</span>
									<span>Frigo: {sheet.compteurs.colis_frg}</span>
									<span>Sachets frg: {sheet.compteurs.sachets_frg}</span>
								</div>
								<button
									type="button"
									className="inline-flex items-center gap-1 text-primary hover:underline"
									onClick={() => window.open(`/documents/feuilles-route/${sheet.id}`, "_blank")}
								>
									<FileText className="h-3 w-3" />
									Voir PDF
									<ExternalLink className="h-3 w-3" />
								</button>
							</div>
						</Card>
					))}
				</div>
			)}
		</div>
	);
}
