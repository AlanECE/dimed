"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from "@/components/ui/table";
import { useMedications } from "@/hooks/use-medications";
import { useCart } from "@/lib/cart";
import { Plus, Search } from "lucide-react";
import { useMemo, useState } from "react";

const PAGE_SIZE = 20;

export function MedicationTable() {
	const [searchTerm, setSearchTerm] = useState("");
	const [formeFilter, setFormeFilter] = useState<string>("all");
	const [fabricantFilter, setFabricantFilter] = useState<string>("all");
	const [page, setPage] = useState(0);

	const { medications, total, loading } = useMedications({
		search: searchTerm || undefined,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});

	const { addItem } = useCart();

	// Extract unique values for client-side filters
	const formes = useMemo(() => {
		const set = new Set(medications.map((m) => m.forme).filter(Boolean));
		return Array.from(set).sort() as string[];
	}, [medications]);

	const fabricants = useMemo(() => {
		const set = new Set(medications.map((m) => m.fabricant).filter(Boolean));
		return Array.from(set).sort() as string[];
	}, [medications]);

	// Apply client-side filters
	const filtered = useMemo(() => {
		return medications.filter((m) => {
			if (formeFilter !== "all" && m.forme !== formeFilter) return false;
			if (fabricantFilter !== "all" && m.fabricant !== fabricantFilter) return false;
			return true;
		});
	}, [medications, formeFilter, fabricantFilter]);

	const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

	return (
		<div className="flex flex-1 flex-col gap-4">
			{/* Search */}
			<div className="relative">
				<Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
				<Input
					placeholder="Rechercher un médicament..."
					value={searchTerm}
					onChange={(e) => {
						setSearchTerm(e.target.value);
						setPage(0);
					}}
					className="pl-10"
				/>
			</div>

			{/* Filters */}
			<div className="flex gap-3">
				<Select value={formeFilter} onValueChange={(v) => setFormeFilter(v ?? "all")}>
					<SelectTrigger className="w-48">
						<SelectValue placeholder="Forme" />
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="all">Toutes les formes</SelectItem>
						{formes.map((f) => (
							<SelectItem key={f} value={f}>
								{f}
							</SelectItem>
						))}
					</SelectContent>
				</Select>

				<Select value={fabricantFilter} onValueChange={(v) => setFabricantFilter(v ?? "all")}>
					<SelectTrigger className="w-48">
						<SelectValue placeholder="Fabricant" />
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="all">Tous les fabricants</SelectItem>
						{fabricants.map((f) => (
							<SelectItem key={f} value={f}>
								{f}
							</SelectItem>
						))}
					</SelectContent>
				</Select>
			</div>

			{/* Table */}
			<div className="overflow-x-auto rounded-md border">
				<Table>
					<TableHeader>
						<TableRow>
							<TableHead>Désignation</TableHead>
							<TableHead>DCI</TableHead>
							<TableHead>Dosage</TableHead>
							<TableHead>Forme</TableHead>
							<TableHead className="tabular-nums text-right">PPA</TableHead>
							<TableHead>Fabricant</TableHead>
							<TableHead className="w-16" />
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							// biome-ignore lint/suspicious/noArrayIndexKey: static skeleton rows
							Array.from({ length: 6 }).map((_, i) => (
								// biome-ignore lint/suspicious/noArrayIndexKey: static skeleton rows
								<TableRow key={`skeleton-${i}`}>
									{Array.from({ length: 7 }).map((_, j) => (
										// biome-ignore lint/suspicious/noArrayIndexKey: static skeleton cells
										<TableCell key={`cell-${i}-${j}`}>
											<Skeleton className="h-4 w-full" />
										</TableCell>
									))}
								</TableRow>
							))
						) : filtered.length === 0 ? (
							<TableRow>
								<TableCell colSpan={7} className="py-8 text-center text-muted-foreground">
									Aucun médicament trouvé
								</TableCell>
							</TableRow>
						) : (
							filtered.map((med) => (
								<TableRow key={med.id} className="hover:bg-muted/50">
									<TableCell className="font-medium">{med.designation}</TableCell>
									<TableCell>{med.dci ?? "—"}</TableCell>
									<TableCell>{med.dosage ?? "—"}</TableCell>
									<TableCell>{med.forme ?? "—"}</TableCell>
									<TableCell className="tabular-nums text-right">
										{med.ppa.toLocaleString("fr-FR")} DA
									</TableCell>
									<TableCell>{med.fabricant ?? "—"}</TableCell>
									<TableCell>
										<Button
											variant="ghost"
											size="icon"
											onClick={() => addItem(med)}
											aria-label={`Ajouter ${med.designation}`}
										>
											<Plus className="h-4 w-4" />
										</Button>
									</TableCell>
								</TableRow>
							))
						)}
					</TableBody>
				</Table>
			</div>

			{/* Pagination */}
			<div className="flex items-center justify-between">
				<span className="text-sm text-muted-foreground">
					Page {page + 1} sur {totalPages}
				</span>
				<div className="flex gap-2">
					<Button
						variant="outline"
						size="sm"
						disabled={page === 0}
						onClick={() => setPage((p) => p - 1)}
					>
						Précédent
					</Button>
					<Button
						variant="outline"
						size="sm"
						disabled={page >= totalPages - 1}
						onClick={() => setPage((p) => p + 1)}
					>
						Suivant
					</Button>
				</div>
			</div>
		</div>
	);
}
