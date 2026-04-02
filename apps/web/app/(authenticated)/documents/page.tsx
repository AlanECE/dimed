"use client";

import { FactureTable } from "@/components/facture-table";
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
import { useRouteSheets } from "@/hooks/use-route-sheets";
import { API_BASE } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { cn } from "@/lib/utils";
import { Download, FileStack } from "lucide-react";
import { useState } from "react";

type Tab = "factures" | "bls" | "feuilles";

const SKELETON_ROWS = ["row-1", "row-2", "row-3", "row-4"] as const;
const SKELETON_CELLS = ["cell-1", "cell-2", "cell-3", "cell-4"] as const;

export default function DocumentsPage() {
	const { user } = useAuth();
	const canSeeRouteSheets = user?.role === "operatrice" || user?.role === "admin";
	const tabs = [
		["factures", "Factures"],
		["bls", "Bons de livraison"],
		...(canSeeRouteSheets ? ([["feuilles", "Feuilles de route"]] as const) : []),
	] as const;
	const [tab, setTab] = useState<Tab>("factures");

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-sky-50">
					<FileStack className="h-5 w-5 text-sky-600" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Centre de documents</h2>
					<p className="text-[13px] text-muted-foreground">
						Factures, bons de livraison et feuilles de route
					</p>
				</div>
			</div>

			{/* Tabs */}
			<div className="flex gap-1 rounded-lg bg-muted/50 p-1">
				{tabs.map(([key, label]) => (
					<button
						key={key}
						type="button"
						onClick={() => setTab(key)}
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
			{tab === "feuilles" && canSeeRouteSheets && <FeuillesTab />}
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
