"use client";

import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogClose,
	DialogContent,
	DialogDescription,
	DialogFooter,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import type { CamionResponse } from "@/lib/types";
import { Loader2 } from "lucide-react";
import { useEffect, useState } from "react";

type CamionDialogProps = {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	camion?: CamionResponse;
	onSubmit: (nom: string, plaque: string) => Promise<void>;
};

export function CamionDialog({ open, onOpenChange, camion, onSubmit }: CamionDialogProps) {
	const [nom, setNom] = useState("");
	const [plaque, setPlaque] = useState("");
	const [submitting, setSubmitting] = useState(false);

	useEffect(() => {
		if (open) {
			setNom(camion?.nom ?? "");
			setPlaque(camion?.plaque ?? "");
		}
	}, [open, camion]);

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault();
		if (!nom.trim() || !plaque.trim()) return;
		setSubmitting(true);
		try {
			await onSubmit(nom.trim(), plaque.trim());
			onOpenChange(false);
		} finally {
			setSubmitting(false);
		}
	}

	return (
		<Dialog open={open} onOpenChange={onOpenChange}>
			<DialogContent>
				<DialogHeader>
					<DialogTitle>{camion ? "Modifier le camion" : "Nouveau camion"}</DialogTitle>
					<DialogDescription>
						{camion
							? "Modifier les informations du camion."
							: "Ajouter un nouveau camion à la flotte."}
					</DialogDescription>
				</DialogHeader>
				<form onSubmit={handleSubmit} className="flex flex-col gap-4">
					<div className="flex flex-col gap-2">
						<label htmlFor="camion-nom" className="text-sm font-medium">
							Nom / identifiant
						</label>
						<Input
							id="camion-nom"
							value={nom}
							onChange={(e) => setNom(e.target.value)}
							placeholder="Camion A"
							required
						/>
					</div>
					<div className="flex flex-col gap-2">
						<label htmlFor="camion-plaque" className="text-sm font-medium">
							Plaque d'immatriculation
						</label>
						<Input
							id="camion-plaque"
							value={plaque}
							onChange={(e) => setPlaque(e.target.value)}
							placeholder="AB-123-CD"
							required
						/>
					</div>
					<DialogFooter>
						<DialogClose disabled={submitting}>Annuler</DialogClose>
						<Button type="submit" disabled={submitting}>
							{submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
							{camion ? "Enregistrer" : "Ajouter"}
						</Button>
					</DialogFooter>
				</form>
			</DialogContent>
		</Dialog>
	);
}
