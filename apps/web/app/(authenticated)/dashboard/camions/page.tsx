"use client";

import { CamionDialog } from "@/components/camion-dialog";
import {
	AlertDialog,
	AlertDialogAction,
	AlertDialogCancel,
	AlertDialogContent,
	AlertDialogDescription,
	AlertDialogFooter,
	AlertDialogHeader,
	AlertDialogTitle,
} from "@/components/ui/alert-dialog";
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
import { createCamion, deleteCamion, updateCamion, useCamions } from "@/hooks/use-camions";
import type { CamionResponse } from "@/lib/types";
import { Pencil, Plus, Trash2, Truck } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

export default function CamionsPage() {
	const { camions, loading, refetch } = useCamions();
	const [dialogOpen, setDialogOpen] = useState(false);
	const [editingCamion, setEditingCamion] = useState<CamionResponse | undefined>();
	const [deletingCamion, setDeletingCamion] = useState<CamionResponse | null>(null);

	async function handleCreate(nom: string, plaque: string) {
		await createCamion(nom, plaque);
		toast.success("Camion ajouté");
		refetch();
	}

	async function handleUpdate(nom: string, plaque: string) {
		if (!editingCamion) return;
		await updateCamion(editingCamion.id, { nom, plaque });
		toast.success("Camion modifié");
		refetch();
	}

	async function handleDelete() {
		if (!deletingCamion) return;
		try {
			await deleteCamion(deletingCamion.id);
			toast.success("Camion supprimé");
			refetch();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur de suppression");
		}
		setDeletingCamion(null);
	}

	return (
		<div className="flex flex-col gap-4">
			<div className="flex items-center justify-between">
				<h2 className="font-heading text-2xl font-semibold">Camions</h2>
				<Button
					onClick={() => {
						setEditingCamion(undefined);
						setDialogOpen(true);
					}}
				>
					<Plus className="mr-2 h-4 w-4" />
					Ajouter un camion
				</Button>
			</div>

			<div className="overflow-x-auto rounded-md border">
				<Table>
					<TableHeader>
						<TableRow>
							<TableHead>Nom</TableHead>
							<TableHead>Plaque</TableHead>
							<TableHead className="w-24">Actions</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading ? (
							Array.from({ length: 3 }).map((_, i) => (
								// biome-ignore lint/suspicious/noArrayIndexKey: static skeleton
								<TableRow key={i}>
									<TableCell>
										<Skeleton className="h-4 w-32" />
									</TableCell>
									<TableCell>
										<Skeleton className="h-4 w-24" />
									</TableCell>
									<TableCell>
										<Skeleton className="h-4 w-16" />
									</TableCell>
								</TableRow>
							))
						) : camions.length === 0 ? (
							<TableRow>
								<TableCell colSpan={3} className="py-12 text-center">
									<Truck className="mx-auto mb-2 h-10 w-10 text-muted-foreground/50" />
									<p className="font-medium text-muted-foreground">Aucun camion</p>
									<p className="text-sm text-muted-foreground">Ajoutez un camion pour commencer.</p>
								</TableCell>
							</TableRow>
						) : (
							camions.map((camion) => (
								<TableRow key={camion.id}>
									<TableCell className="font-medium">{camion.nom}</TableCell>
									<TableCell className="font-mono text-sm">{camion.plaque}</TableCell>
									<TableCell>
										<div className="flex gap-1">
											<Button
												variant="ghost"
												size="icon"
												onClick={() => {
													setEditingCamion(camion);
													setDialogOpen(true);
												}}
												aria-label={`Modifier ${camion.nom}`}
											>
												<Pencil className="h-4 w-4" />
											</Button>
											<Button
												variant="ghost"
												size="icon"
												onClick={() => setDeletingCamion(camion)}
												className="text-muted-foreground hover:text-destructive"
												aria-label={`Supprimer ${camion.nom}`}
											>
												<Trash2 className="h-4 w-4" />
											</Button>
										</div>
									</TableCell>
								</TableRow>
							))
						)}
					</TableBody>
				</Table>
			</div>

			<CamionDialog
				open={dialogOpen}
				onOpenChange={setDialogOpen}
				camion={editingCamion}
				onSubmit={editingCamion ? handleUpdate : handleCreate}
			/>

			<AlertDialog
				open={!!deletingCamion}
				onOpenChange={(open) => !open && setDeletingCamion(null)}
			>
				<AlertDialogContent>
					<AlertDialogHeader>
						<AlertDialogTitle>Supprimer le camion</AlertDialogTitle>
						<AlertDialogDescription>
							Supprimer ce camion ? Cette action est irréversible.
						</AlertDialogDescription>
					</AlertDialogHeader>
					<AlertDialogFooter>
						<AlertDialogCancel>Annuler</AlertDialogCancel>
						<AlertDialogAction
							onClick={handleDelete}
							className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
						>
							Supprimer
						</AlertDialogAction>
					</AlertDialogFooter>
				</AlertDialogContent>
			</AlertDialog>
		</div>
	);
}
