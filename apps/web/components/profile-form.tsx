"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useProfile } from "@/hooks/use-profile";
import { useAuth } from "@/lib/auth";
import { Loader2, Save } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

export function ProfileForm() {
	const { user } = useAuth();
	const { updateProfile, loading } = useProfile();

	const [nom, setNom] = useState(user?.nom ?? "");
	const [adresse, setAdresse] = useState(user?.adresse ?? "");
	const [secteur, setSecteur] = useState(user?.secteur ?? "");

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault();
		try {
			await updateProfile({ nom, adresse, secteur });
			toast.success("Profil mis à jour");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors de la mise à jour");
		}
	}

	return (
		<div className="rounded-xl border border-border/60 bg-card p-6 shadow-sm">
			<h3 className="mb-4 font-heading text-[15px] font-bold">Informations personnelles</h3>
			<form onSubmit={handleSubmit} className="space-y-4">
				<div className="space-y-1.5">
					<label htmlFor="email" className="text-[13px] font-semibold text-foreground/80">
						Email
					</label>
					<Input
						id="email"
						value={user?.email ?? ""}
						disabled
						className="h-10 rounded-lg border-border/60 bg-muted/50 text-[13px] opacity-60"
					/>
				</div>
				<div className="space-y-1.5">
					<label htmlFor="nom" className="text-[13px] font-semibold text-foreground/80">
						Nom complet
					</label>
					<Input
						id="nom"
						value={nom}
						onChange={(e) => setNom(e.target.value)}
						className="h-10 rounded-lg border-border/60 bg-card text-[13px]"
						required
					/>
				</div>
				<div className="space-y-1.5">
					<label htmlFor="adresse" className="text-[13px] font-semibold text-foreground/80">
						Adresse
					</label>
					<Input
						id="adresse"
						value={adresse}
						onChange={(e) => setAdresse(e.target.value)}
						placeholder="Adresse de la pharmacie"
						className="h-10 rounded-lg border-border/60 bg-card text-[13px]"
					/>
				</div>
				<div className="space-y-1.5">
					<label htmlFor="secteur" className="text-[13px] font-semibold text-foreground/80">
						Secteur
					</label>
					<Input
						id="secteur"
						value={secteur}
						onChange={(e) => setSecteur(e.target.value)}
						placeholder="Zone géographique"
						className="h-10 rounded-lg border-border/60 bg-card text-[13px]"
					/>
				</div>
				<Button
					type="submit"
					disabled={loading}
					className="h-10 rounded-lg bg-primary text-[13px] font-semibold shadow-sm hover:brightness-110"
				>
					{loading ? (
						<Loader2 className="mr-2 h-4 w-4 animate-spin" />
					) : (
						<Save className="mr-2 h-4 w-4" />
					)}
					Enregistrer
				</Button>
			</form>
		</div>
	);
}
