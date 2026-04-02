"use client";

import { StatusBadge } from "@/components/status-badge";
import {
	AlertDialog,
	AlertDialogAction,
	AlertDialogCancel,
	AlertDialogContent,
	AlertDialogFooter,
	AlertDialogHeader,
	AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Badge } from "@/components/ui/badge";
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
import { useUsers } from "@/hooks/use-users";
import { Loader2, Pencil, Plus, Power, Users } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

const ROLES = [
	{ value: "pharmacien", label: "Pharmacien" },
	{ value: "operatrice", label: "Opératrice" },
	{ value: "preparateur", label: "Préparateur" },
	{ value: "controleur", label: "Contrôleur" },
	{ value: "livreur", label: "Livreur" },
	{ value: "admin", label: "Administrateur" },
];

const ROLE_LABELS: Record<string, string> = Object.fromEntries(
	ROLES.map((r) => [r.value, r.label]),
);

export default function AdminUtilisateursPage() {
	const { users, total, loading, createUser, updateUser } = useUsers();
	const [dialogOpen, setDialogOpen] = useState(false);
	const [submitting, setSubmitting] = useState(false);

	const [email, setEmail] = useState("");
	const [password, setPassword] = useState("");
	const [nom, setNom] = useState("");
	const [role, setRole] = useState("pharmacien");
	const [adresse, setAdresse] = useState("");
	const [secteur, setSecteur] = useState("");

	function resetForm() {
		setEmail("");
		setPassword("");
		setNom("");
		setRole("pharmacien");
		setAdresse("");
		setSecteur("");
	}

	async function handleCreate() {
		if (!email || !password || !nom) {
			toast.error("Remplissez les champs obligatoires");
			return;
		}
		setSubmitting(true);
		try {
			await createUser({
				email,
				password,
				nom,
				role,
				adresse: adresse || undefined,
				secteur: secteur || undefined,
			});
			toast.success("Utilisateur créé");
			setDialogOpen(false);
			resetForm();
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		} finally {
			setSubmitting(false);
		}
	}

	async function handleToggleActive(userId: string, currentActive: boolean) {
		try {
			await updateUser(userId, { is_active: !currentActive });
			toast.success(currentActive ? "Compte désactivé" : "Compte activé");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur");
		}
	}

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center justify-between">
				<div className="flex items-center gap-3">
					<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50">
						<Users className="h-5 w-5 text-blue-600" />
					</div>
					<div>
						<h2 className="font-heading text-xl font-bold">Gestion des utilisateurs</h2>
						<p className="text-[13px] text-muted-foreground">
							{total} utilisateur{total > 1 ? "s" : ""} enregistré{total > 1 ? "s" : ""}
						</p>
					</div>
				</div>
				<Button
					onClick={() => setDialogOpen(true)}
					className="h-9 gap-1.5 rounded-lg bg-primary text-[13px] font-semibold shadow-sm hover:brightness-110"
				>
					<Plus className="h-4 w-4" />
					Ajouter un utilisateur
				</Button>
			</div>

			{/* Table */}
			<div className="overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm">
				<Table>
					<TableHeader>
						<TableRow className="border-border/40 bg-muted/40 hover:bg-muted/40">
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Nom
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Email
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Rôle
							</TableHead>
							<TableHead className="text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Statut
							</TableHead>
							<TableHead className="text-right text-[12px] font-semibold uppercase tracking-wider text-muted-foreground/70">
								Actions
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{loading
							? Array.from({ length: 5 }).map((_, i) => (
									<TableRow key={`sk-${i}`} className="border-border/30">
										{Array.from({ length: 5 }).map((_, j) => (
											<TableCell key={`sk-${i}-${j}`}>
												<Skeleton className="h-4 w-full" />
											</TableCell>
										))}
									</TableRow>
								))
							: users.map((u) => (
									<TableRow
										key={u.id}
										className="border-border/30 transition-colors hover:bg-muted/40"
									>
										<TableCell className="text-[13px] font-semibold">{u.nom}</TableCell>
										<TableCell className="text-[13px] text-muted-foreground">{u.email}</TableCell>
										<TableCell>
											<Badge variant="outline" className="rounded-full text-[11px]">
												{ROLE_LABELS[u.role] ?? u.role}
											</Badge>
										</TableCell>
										<TableCell>
											<Badge
												variant="outline"
												className={`rounded-full text-[11px] ${
													u.is_active
														? "border-emerald-200/80 bg-emerald-50 text-emerald-700"
														: "border-red-200/80 bg-red-50 text-red-700"
												}`}
											>
												{u.is_active ? "Actif" : "Inactif"}
											</Badge>
										</TableCell>
										<TableCell className="text-right">
											<Button
												variant="ghost"
												size="icon"
												className="h-8 w-8 rounded-lg"
												onClick={() => handleToggleActive(u.id, u.is_active)}
												aria-label={u.is_active ? "Désactiver" : "Activer"}
											>
												<Power
													className={`h-4 w-4 ${u.is_active ? "text-red-500" : "text-emerald-500"}`}
												/>
											</Button>
										</TableCell>
									</TableRow>
								))}
					</TableBody>
				</Table>
			</div>

			{/* Create dialog */}
			<AlertDialog open={dialogOpen} onOpenChange={setDialogOpen}>
				<AlertDialogContent className="rounded-xl">
					<AlertDialogHeader>
						<AlertDialogTitle className="font-heading font-bold">
							Nouvel utilisateur
						</AlertDialogTitle>
					</AlertDialogHeader>
					<div className="space-y-4">
						<div className="grid gap-4 sm:grid-cols-2">
							<div className="space-y-1.5">
								<label className="text-[13px] font-semibold text-foreground/80">Nom *</label>
								<Input
									value={nom}
									onChange={(e) => setNom(e.target.value)}
									className="h-10 rounded-lg border-border/60 text-[13px]"
									required
								/>
							</div>
							<div className="space-y-1.5">
								<label className="text-[13px] font-semibold text-foreground/80">Email *</label>
								<Input
									type="email"
									value={email}
									onChange={(e) => setEmail(e.target.value)}
									className="h-10 rounded-lg border-border/60 text-[13px]"
									required
								/>
							</div>
						</div>
						<div className="grid gap-4 sm:grid-cols-2">
							<div className="space-y-1.5">
								<label className="text-[13px] font-semibold text-foreground/80">
									Mot de passe *
								</label>
								<Input
									type="password"
									value={password}
									onChange={(e) => setPassword(e.target.value)}
									className="h-10 rounded-lg border-border/60 text-[13px]"
									required
								/>
							</div>
							<div className="space-y-1.5">
								<label className="text-[13px] font-semibold text-foreground/80">Rôle *</label>
								<Select value={role} onValueChange={(v) => setRole(v ?? "pharmacien")}>
									<SelectTrigger className="h-10 rounded-lg border-border/60 text-[13px]">
										<SelectValue />
									</SelectTrigger>
									<SelectContent>
										{ROLES.map((r) => (
											<SelectItem key={r.value} value={r.value}>
												{r.label}
											</SelectItem>
										))}
									</SelectContent>
								</Select>
							</div>
						</div>
						<div className="grid gap-4 sm:grid-cols-2">
							<div className="space-y-1.5">
								<label className="text-[13px] font-semibold text-foreground/80">Adresse</label>
								<Input
									value={adresse}
									onChange={(e) => setAdresse(e.target.value)}
									className="h-10 rounded-lg border-border/60 text-[13px]"
								/>
							</div>
							<div className="space-y-1.5">
								<label className="text-[13px] font-semibold text-foreground/80">Secteur</label>
								<Input
									value={secteur}
									onChange={(e) => setSecteur(e.target.value)}
									className="h-10 rounded-lg border-border/60 text-[13px]"
								/>
							</div>
						</div>
					</div>
					<AlertDialogFooter>
						<AlertDialogCancel className="rounded-lg" disabled={submitting}>
							Annuler
						</AlertDialogCancel>
						<AlertDialogAction
							onClick={handleCreate}
							disabled={submitting}
							className="rounded-lg bg-primary font-semibold shadow-sm hover:brightness-110"
						>
							{submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
							Créer l'utilisateur
						</AlertDialogAction>
					</AlertDialogFooter>
				</AlertDialogContent>
			</AlertDialog>
		</div>
	);
}
