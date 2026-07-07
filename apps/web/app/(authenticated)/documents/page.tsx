"use client";

import { FactureTable } from "@/components/facture-table";
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
import { useBonsLivraison } from "@/hooks/use-bons-livraison";
import { useProformas } from "@/hooks/use-proformas";
import { useRouteSheets } from "@/hooks/use-route-sheets";
import { API_BASE } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { cn } from "@/lib/utils";
import { Download, FileStack } from "lucide-react";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense } from "react";

type Tab = "factures" | "bls" | "proforma" | "feuilles";

const SKELETON_ROWS = ["row-1", "row-2", "row-3", "row-4"] as const;
const SKELETON_CELLS = ["cell-1", "cell-2", "cell-3", "cell-4"] as const;

export default function DocumentsPage() {
	return (
		<Suspense>
			<DocumentsPageInner />
		</Suspense>
	);
}

function DocumentsPageInner() {
	const { user } = useAuth();
	const router = useRouter();
	const searchParams = useSearchParams();
	const canSeeRouteSheets = user?.role === "operatrice" || user?.role === "admin";
	const tabs = [
		["factures", "Factures"],
		["bls", "Bons de livraison"],
		["proforma", "Proforma"],
		...(canSeeRouteSheets ? ([["feuilles", "Feuilles de route"]] as const) : []),
	] as const;

	const validTabs = tabs.map(([key]) => key) as readonly string[];
	const paramTab = searchParams.get("tab");
	const tab: Tab = paramTab && validTabs.includes(paramTab) ? (paramTab as Tab) : "factures";

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-sky-50">
					<FileStack className="h-5 w-5 text-sky-600" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Centre de documents</h2>
					<p className="text-[13px] text-muted-foreground">
						Factures, bons de livraison et proformas
					</p>
				</div>
			</div>

			{/* Tabs */}
			<div className="flex gap-1 rounded-lg bg-muted/50 p-1">
				{tabs.map(([key, label]) => (
					<button
						key={key}
						type="button"
						onClick={() => router.push(`/documents?tab=${key}`)}
						className={cn(
							"rounded-md px-4 py-2 text-[13px] font-medium transition-colors",
							tab === key
								? "bg-card text-foreground shadow-sm"
								: "text-muted-foreground hover:text-foreground",
						)}
					>
						{label}
					</button>
				))}
			</div>

			{tab === "factures" && <FactureTable />}
			{tab === "bls" && <BLsTab />}
			{tab === "proforma" && <ProformaTab />}
			{tab === "feuilles" && canSeeRouteSheets && <FeuillesTab />}
		</div>
	);
}

function ProformaTab() {
	const { user } = useAuth();
	const { proformas, loading } = useProformas();
	const isPharmacien = user?.role === "pharmacien";

	return (
		<div className="flex flex-col gap-3">
			<p className="text-[12px] text-muted-foreground">
				La proforma reflète l'état actuel de la commande. La facture définitive n'est émise qu'après
				validation de la commande par l'opératrice.
			</p>
			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Référence
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Commande
							</TableHead>
							{!isPharmacien && (
								<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
									Pharmacien
								</TableHead>
							)}
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Date
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Montant
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Statut
							</TableHead>
							<TableHead className="w-14" />
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							SKELETON_ROWS.map((rowKey) => (
								<TableRow key={rowKey} className="border-border/30">
									{SKELETON_CELLS.map((cellKey) => (
										<TableCell key={`${rowKey}-${cellKey}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : proformas.length === 0 ? (
							<TableRow>
								<TableCell
									colSpan={isPharmacien ? 6 : 7}
									className="py-12 text-center text-[13px] text-muted-foreground"
								>
									Aucune proforma
								</TableCell>
							</TableRow>
						) : (
							proformas.map((p) => (
								<TableRow key={p.commande_id} className="border-border/30 hover:bg-muted/40">
									<TableCell className="font-mono text-[13px]">{p.reference_id}</TableCell>
									<TableCell className="font-mono text-[13px] text-muted-foreground">
										{p.commande_reference}
									</TableCell>
									{!isPharmacien && (
										<TableCell className="text-[13px]">{p.pharmacien_nom}</TableCell>
									)}
									<TableCell className="text-[13px] text-muted-foreground">
										{new Date(p.date).toLocaleDateString("fr-FR")}
									</TableCell>
									<TableCell className="text-right text-[13px] font-semibold tabular-nums">
										{p.montant_total.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell>
										<StatusBadge status={p.statut} />
									</TableCell>
									<TableCell>
										<a
											href={`${API_BASE}/documents/proforma/${p.commande_id}`}
											target="_blank"
											rel="noopener noreferrer"
										>
											<Button
												variant="ghost"
												size="icon"
												className="h-8 w-8 rounded-lg text-primary/70 hover:bg-primary/10 hover:text-primary"
												aria-label="Télécharger la proforma"
											>
												<Download className="h-4 w-4" />
											</Button>
										</a>
									</TableCell>
								</TableRow>
							))
						)}
					</TableBody>
				</Table>
			</div>
		</div>
	);
}

function BLsTab() {
	const { bls, loading } = useBonsLivraison();

	return (
		<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
			<Table>
				<TableHeader>
					<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
						<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
							Code-barres
						</TableHead>
						<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
							Commande
						</TableHead>
						<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
							Date
						</TableHead>
						<TableHead className="w-14" />
					</TableRow>
				</TableHeader>
				<TableBody>
					{loading ? (
						SKELETON_ROWS.map((rowKey) => (
							<TableRow key={rowKey} className="border-border/30">
								{SKELETON_CELLS.map((cellKey) => (
									<TableCell key={`${rowKey}-${cellKey}`}>
										<Skeleton className="h-4 w-full" />
									</TableCell>
								))}
							</TableRow>
						))
					) : bls.length === 0 ? (
						<TableRow>
							<TableCell
								colSpan={4}
								className="py-12 text-center text-[13px] text-muted-foreground"
							>
								Aucun bon de livraison
							</TableCell>
						</TableRow>
					) : (
						bls.map((bl) => (
							<TableRow key={bl.id} className="border-border/30 hover:bg-muted/40">
								<TableCell className="font-mono text-[13px]">{bl.code_barre}</TableCell>
								<TableCell className="font-mono text-[13px] text-muted-foreground">
									{bl.commande_reference}
								</TableCell>
								<TableCell className="text-[13px] text-muted-foreground">
									{new Date(bl.date_emission).toLocaleDateString("fr-FR")}
								</TableCell>
								<TableCell>
									<a
										href={`${API_BASE}/documents/bl/${bl.commande_id}`}
										target="_blank"
										rel="noopener noreferrer"
									>
										<Button
											variant="ghost"
											size="icon"
											className="h-8 w-8 rounded-lg text-primary/70 hover:bg-primary/10 hover:text-primary"
										>
											<Download className="h-4 w-4" />
										</Button>
									</a>
								</TableCell>
							</TableRow>
						))
					)}
				</TableBody>
			</Table>
		</div>
	);
}

function FeuillesTab() {
	const { sheets: routeSheets, loading } = useRouteSheets();

	return (
		<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
			<Table>
				<TableHeader>
					<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
						<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
							Camion
						</TableHead>
						<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
							Plaque
						</TableHead>
						<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
							Date
						</TableHead>
						<TableHead className="text-center text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
							Commandes
						</TableHead>
					</TableRow>
				</TableHeader>
				<TableBody>
					{loading ? (
						SKELETON_ROWS.map((rowKey) => (
							<TableRow key={rowKey} className="border-border/30">
								{SKELETON_CELLS.map((cellKey) => (
									<TableCell key={`${rowKey}-${cellKey}`}>
										<Skeleton className="h-4 w-full" />
									</TableCell>
								))}
							</TableRow>
						))
					) : routeSheets.length === 0 ? (
						<TableRow>
							<TableCell
								colSpan={4}
								className="py-12 text-center text-[13px] text-muted-foreground"
							>
								Aucune feuille de route
							</TableCell>
						</TableRow>
					) : (
						routeSheets.map((rs) => (
							<TableRow key={rs.id} className="border-border/30 hover:bg-muted/40">
								<TableCell className="text-[13px] font-semibold">{rs.camion_nom}</TableCell>
								<TableCell className="font-mono text-[13px] text-muted-foreground">
									{rs.camion_plaque}
								</TableCell>
								<TableCell className="text-[13px] text-muted-foreground">
									{new Date(rs.date).toLocaleDateString("fr-FR")}
								</TableCell>
								<TableCell className="text-center text-[13px] tabular-nums">
									{rs.commandes.length}
								</TableCell>
							</TableRow>
						))
					)}
				</TableBody>
			</Table>
		</div>
	);
}
