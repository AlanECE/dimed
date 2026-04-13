"use client";

import { GoogleLoginButton } from "@/components/google-login-button";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ApiError } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import type { SignupRole } from "@/lib/types";
import { Loader2, Pill } from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useMemo, useState } from "react";
import { toast } from "sonner";

const ROLE_OPTIONS: { value: SignupRole; label: string; description: string }[] = [
	{
		value: "pharmacien",
		label: "Pharmacien",
		description: "Je gere une pharmacie et je passe des commandes",
	},
	{
		value: "operatrice",
		label: "Operatrice",
		description: "Je valide et gere les commandes",
	},
	{
		value: "preparateur",
		label: "Preparateur",
		description: "Je prepare les commandes a l'entrepot",
	},
	{
		value: "controleur",
		label: "Controleur",
		description: "Je verifie les preparations avant expedition",
	},
	{
		value: "livreur",
		label: "Livreur",
		description: "Je livre les commandes aux clients",
	},
];

export default function RegisterPage() {
	const router = useRouter();
	const searchParams = useSearchParams();
	const { signup, loginWithGoogle } = useAuth();

	const googleCredential = searchParams.get("google_credential");
	const isGoogleFlow = Boolean(googleCredential);

	const [nom, setNom] = useState("");
	const [email, setEmail] = useState("");
	const [password, setPassword] = useState("");
	const [passwordConfirm, setPasswordConfirm] = useState("");
	const [role, setRole] = useState<SignupRole>("pharmacien");
	const [adresse, setAdresse] = useState("");
	const [secteur, setSecteur] = useState("");
	const [telephone, setTelephone] = useState("");
	const [submitting, setSubmitting] = useState(false);

	const passwordMismatch = useMemo(
		() => Boolean(password && passwordConfirm && password !== passwordConfirm),
		[password, passwordConfirm],
	);

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault();
		if (!isGoogleFlow && passwordMismatch) {
			toast.error("Les mots de passe ne correspondent pas.");
			return;
		}
		setSubmitting(true);
		try {
			if (isGoogleFlow && googleCredential) {
				await loginWithGoogle({
					credential: googleCredential,
					role,
					adresse: adresse || undefined,
					secteur: secteur || undefined,
					telephone: telephone || undefined,
				});
				toast.success("Compte cree et connecte");
				router.push("/catalogue");
				return;
			}
			await signup({
				nom,
				email,
				password,
				role,
				adresse: adresse || undefined,
				secteur: secteur || undefined,
				telephone: telephone || undefined,
			});
			toast.success("Inscription enregistree. Un email de verification vient d'etre envoye.");
			router.push("/login?pending=1");
		} catch (err) {
			const message =
				err instanceof ApiError ? err.message : "Erreur lors de la creation du compte.";
			toast.error(message);
		} finally {
			setSubmitting(false);
		}
	}

	return (
		<div className="relative flex min-h-screen items-center justify-center overflow-hidden py-10">
			<div className="absolute inset-0 bg-gradient-to-br from-[#0F766E]/5 via-background to-[#0D9488]/5" />
			<div className="absolute -top-32 -right-32 h-96 w-96 rounded-full bg-[#0F766E]/8 blur-3xl" />
			<div className="absolute -bottom-32 -left-32 h-96 w-96 rounded-full bg-[#0D9488]/6 blur-3xl" />

			<div className="animate-scale-in relative z-10 w-full max-w-[520px] px-4">
				<div className="rounded-2xl border border-border/60 bg-card/80 p-8 shadow-xl shadow-black/[0.03] backdrop-blur-xl">
					<div className="mb-6 flex flex-col items-center gap-3">
						<div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-[#0F766E] to-[#0D9488] shadow-lg shadow-[#0F766E]/20">
							<Pill className="h-7 w-7 text-white" strokeWidth={2.5} />
						</div>
						<div className="text-center">
							<h1 className="font-heading text-2xl font-extrabold tracking-tight text-foreground">
								{isGoogleFlow ? "Finaliser votre compte" : "Creer un compte"}
							</h1>
							<p className="mt-1 text-[13px] font-medium tracking-wide text-muted-foreground">
								{isGoogleFlow
									? "Choisissez votre role pour continuer avec Google"
									: "Rejoignez la plateforme DIMED"}
							</p>
						</div>
					</div>

					{!isGoogleFlow && (
						<>
							<GoogleLoginButton />
							<div className="my-6 flex items-center gap-3">
								<div className="h-px flex-1 bg-border/60" />
								<span className="text-[11px] font-medium uppercase tracking-wider text-muted-foreground">
									ou avec email
								</span>
								<div className="h-px flex-1 bg-border/60" />
							</div>
						</>
					)}

					<form onSubmit={handleSubmit} className="space-y-4">
						{!isGoogleFlow && (
							<>
								<Field label="Nom complet *" htmlFor="nom">
									<Input
										id="nom"
										value={nom}
										onChange={(e) => setNom(e.target.value)}
										required
										minLength={2}
										autoComplete="name"
										placeholder="Jean Dupont"
										className="h-11 rounded-xl border-border/60 bg-muted/50 px-4 text-sm"
									/>
								</Field>

								<Field label="Email *" htmlFor="email">
									<Input
										id="email"
										type="email"
										value={email}
										onChange={(e) => setEmail(e.target.value)}
										required
										autoComplete="email"
										placeholder="pharmacien@example.com"
										className="h-11 rounded-xl border-border/60 bg-muted/50 px-4 text-sm"
									/>
								</Field>

								<div className="grid grid-cols-1 gap-4 md:grid-cols-2">
									<Field label="Mot de passe *" htmlFor="password">
										<Input
											id="password"
											type="password"
											value={password}
											onChange={(e) => setPassword(e.target.value)}
											required
											minLength={8}
											autoComplete="new-password"
											className="h-11 rounded-xl border-border/60 bg-muted/50 px-4 text-sm"
										/>
									</Field>
									<Field label="Confirmation *" htmlFor="password-confirm">
										<Input
											id="password-confirm"
											type="password"
											value={passwordConfirm}
											onChange={(e) => setPasswordConfirm(e.target.value)}
											required
											minLength={8}
											autoComplete="new-password"
											className="h-11 rounded-xl border-border/60 bg-muted/50 px-4 text-sm"
										/>
									</Field>
								</div>
								{passwordMismatch && (
									<p className="text-[12px] font-medium text-red-600">
										Les mots de passe ne correspondent pas.
									</p>
								)}
							</>
						)}

						<Field label="Role *" htmlFor="role">
							<div className="grid gap-2">
								{ROLE_OPTIONS.map((opt) => (
									<label
										key={opt.value}
										className={`flex cursor-pointer items-start gap-3 rounded-xl border px-4 py-3 transition-all ${
											role === opt.value
												? "border-[#0F766E]/60 bg-[#0F766E]/5 shadow-sm"
												: "border-border/60 bg-muted/30 hover:border-border"
										}`}
									>
										<input
											type="radio"
											name="role"
											value={opt.value}
											checked={role === opt.value}
											onChange={() => setRole(opt.value)}
											className="mt-0.5 accent-[#0F766E]"
										/>
										<div className="flex-1">
											<div className="text-[13px] font-semibold text-foreground">{opt.label}</div>
											<div className="text-[12px] text-muted-foreground">{opt.description}</div>
										</div>
									</label>
								))}
							</div>
						</Field>

						<div className="grid grid-cols-1 gap-4 md:grid-cols-2">
							<Field label="Adresse" htmlFor="adresse" optional>
								<Input
									id="adresse"
									value={adresse}
									onChange={(e) => setAdresse(e.target.value)}
									placeholder="12 rue de la pharmacie"
									className="h-11 rounded-xl border-border/60 bg-muted/50 px-4 text-sm"
								/>
							</Field>
							<Field label="Secteur / ville" htmlFor="secteur" optional>
								<Input
									id="secteur"
									value={secteur}
									onChange={(e) => setSecteur(e.target.value)}
									placeholder="Alger centre"
									className="h-11 rounded-xl border-border/60 bg-muted/50 px-4 text-sm"
								/>
							</Field>
						</div>

						<Field label="Telephone" htmlFor="telephone" optional>
							<Input
								id="telephone"
								type="tel"
								value={telephone}
								onChange={(e) => setTelephone(e.target.value)}
								placeholder="+213 ..."
								className="h-11 rounded-xl border-border/60 bg-muted/50 px-4 text-sm"
							/>
						</Field>

						<Button
							type="submit"
							disabled={submitting}
							className="mt-2 h-11 w-full rounded-xl bg-primary font-semibold shadow-md shadow-[#0F766E]/15 transition-all hover:shadow-lg hover:brightness-110"
						>
							{submitting ? (
								<>
									<Loader2 className="mr-2 h-4 w-4 animate-spin" />
									Creation...
								</>
							) : isGoogleFlow ? (
								"Finaliser et se connecter"
							) : (
								"Creer mon compte"
							)}
						</Button>
					</form>

					<p className="mt-6 text-center text-[13px] text-muted-foreground">
						Deja un compte ?{" "}
						<Link
							href="/login"
							className="font-semibold text-[#0F766E] underline-offset-2 hover:underline"
						>
							Se connecter
						</Link>
					</p>
				</div>
			</div>
		</div>
	);
}

function Field({
	label,
	htmlFor,
	optional,
	children,
}: {
	label: string;
	htmlFor: string;
	optional?: boolean;
	children: React.ReactNode;
}) {
	return (
		<div className="space-y-1.5">
			<label
				htmlFor={htmlFor}
				className="flex items-center gap-1.5 text-[13px] font-semibold text-foreground/80"
			>
				{label}
				{optional && (
					<span className="text-[10px] font-medium uppercase tracking-wider text-muted-foreground/70">
						(optionnel)
					</span>
				)}
			</label>
			{children}
		</div>
	);
}
