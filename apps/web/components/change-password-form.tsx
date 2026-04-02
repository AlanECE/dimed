"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useProfile } from "@/hooks/use-profile";
import { KeyRound, Loader2 } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

export function ChangePasswordForm() {
	const { changePassword, loading } = useProfile();
	const [currentPassword, setCurrentPassword] = useState("");
	const [newPassword, setNewPassword] = useState("");
	const [confirmPassword, setConfirmPassword] = useState("");

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault();
		if (newPassword !== confirmPassword) {
			toast.error("Les mots de passe ne correspondent pas");
			return;
		}
		if (newPassword.length < 8) {
			toast.error("Le mot de passe doit contenir au moins 8 caractères");
			return;
		}
		try {
			await changePassword({
				current_password: currentPassword,
				new_password: newPassword,
			});
			toast.success("Mot de passe modifié");
			setCurrentPassword("");
			setNewPassword("");
			setConfirmPassword("");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors du changement");
		}
	}

	return (
		<div className="rounded-xl border border-border/60 bg-card p-6 shadow-sm">
			<h3 className="mb-4 font-heading text-[15px] font-bold">Changer le mot de passe</h3>
			<form onSubmit={handleSubmit} className="space-y-4">
				<div className="space-y-1.5">
					<label
						htmlFor="current-password"
						className="text-[13px] font-semibold text-foreground/80"
					>
						Mot de passe actuel
					</label>
					<Input
						id="current-password"
						type="password"
						value={currentPassword}
						onChange={(e) => setCurrentPassword(e.target.value)}
						required
						autoComplete="current-password"
						className="h-10 rounded-lg border-border/60 bg-card text-[13px]"
					/>
				</div>
				<div className="space-y-1.5">
					<label htmlFor="new-password" className="text-[13px] font-semibold text-foreground/80">
						Nouveau mot de passe
					</label>
					<Input
						id="new-password"
						type="password"
						value={newPassword}
						onChange={(e) => setNewPassword(e.target.value)}
						required
						autoComplete="new-password"
						className="h-10 rounded-lg border-border/60 bg-card text-[13px]"
					/>
				</div>
				<div className="space-y-1.5">
					<label
						htmlFor="confirm-password"
						className="text-[13px] font-semibold text-foreground/80"
					>
						Confirmer le mot de passe
					</label>
					<Input
						id="confirm-password"
						type="password"
						value={confirmPassword}
						onChange={(e) => setConfirmPassword(e.target.value)}
						required
						autoComplete="new-password"
						className="h-10 rounded-lg border-border/60 bg-card text-[13px]"
					/>
				</div>
				<Button
					type="submit"
					disabled={loading}
					variant="outline"
					className="h-10 rounded-lg text-[13px] font-semibold"
				>
					{loading ? (
						<Loader2 className="mr-2 h-4 w-4 animate-spin" />
					) : (
						<KeyRound className="mr-2 h-4 w-4" />
					)}
					Modifier le mot de passe
				</Button>
			</form>
		</div>
	);
}
