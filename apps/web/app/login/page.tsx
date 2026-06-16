"use client";

import { GoogleLoginButton } from "@/components/google-login-button";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ApiError } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { Loader2, Pill } from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { toast } from "sonner";

export default function LoginPage() {
	const router = useRouter();
	const searchParams = useSearchParams();
	const { login, resendVerification } = useAuth();
	const [email, setEmail] = useState("");
	const [password, setPassword] = useState("");
	const [error, setError] = useState<"invalid" | "unverified" | "disabled" | "network" | null>(
		null,
	);
	const [submitting, setSubmitting] = useState(false);
	const [resending, setResending] = useState(false);
	const emailRef = useRef<HTMLInputElement>(null);

	useEffect(() => {
		if (searchParams.get("verified") === "1") {
			toast.success("Compte active. Vous pouvez maintenant vous connecter.");
		}
		if (searchParams.get("pending") === "1") {
			toast.info("Un email de verification a ete envoye. Consultez votre boite mail.");
		}
	}, [searchParams]);

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault();
		setError(null);
		setSubmitting(true);

		try {
			await login(email, password);
			// Redirige vers l'accueil, qui route ensuite vers la page du rôle.
			router.push("/");
		} catch (err) {
			if (err instanceof ApiError) {
				if (err.status === 403 && err.message === "email_not_verified") {
					setError("unverified");
				} else if (err.status === 403 && err.message === "account_disabled") {
					setError("disabled");
				} else {
					setError("invalid");
					emailRef.current?.focus();
				}
			} else {
				setError("network");
			}
		} finally {
			setSubmitting(false);
		}
	}

	async function handleResend() {
		if (!email) {
			toast.error("Saisissez votre email pour renvoyer le lien.");
			return;
		}
		setResending(true);
		try {
			await resendVerification(email);
			toast.success("Email renvoye si le compte existe.");
		} catch {
			toast.error("Impossible de renvoyer l'email.");
		} finally {
			setResending(false);
		}
	}

	return (
		<div className="relative flex min-h-screen items-center justify-center overflow-hidden">
			<div className="absolute inset-0 bg-gradient-to-br from-[#0F766E]/5 via-background to-[#0D9488]/5" />
			<div
				className="absolute inset-0 opacity-[0.02]"
				style={{
					backgroundImage:
						"radial-gradient(circle at 1px 1px, var(--foreground) 1px, transparent 0)",
					backgroundSize: "40px 40px",
				}}
			/>
			<div className="absolute -top-32 -right-32 h-96 w-96 rounded-full bg-[#0F766E]/8 blur-3xl" />
			<div className="absolute -bottom-32 -left-32 h-96 w-96 rounded-full bg-[#0D9488]/6 blur-3xl" />

			<div className="animate-scale-in relative z-10 w-full max-w-[420px] px-4">
				<div className="rounded-2xl border border-border/60 bg-card/80 p-8 shadow-xl shadow-black/[0.03] backdrop-blur-xl">
					<div className="mb-8 flex flex-col items-center gap-3">
						<div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-[#0F766E] to-[#0D9488] shadow-lg shadow-[#0F766E]/20">
							<Pill className="h-7 w-7 text-white" strokeWidth={2.5} />
						</div>
						<div className="text-center">
							<h1 className="font-heading text-3xl font-extrabold tracking-tight text-foreground">
								DIMED
							</h1>
							<p className="mt-1 text-[13px] font-medium tracking-wide text-muted-foreground">
								Gestion Logistique Pharmaceutique
							</p>
						</div>
					</div>

					<form onSubmit={handleSubmit} className="space-y-5">
						<div className="space-y-1.5">
							<label htmlFor="email" className="text-[13px] font-semibold text-foreground/80">
								Email
							</label>
							<Input
								ref={emailRef}
								id="email"
								type="email"
								value={email}
								onChange={(e) => setEmail(e.target.value)}
								placeholder="pharmacien@example.com"
								required
								autoComplete="email"
								autoFocus
								className="h-11 rounded-xl border-border/60 bg-muted/50 px-4 text-sm transition-all focus:border-primary/40 focus:bg-white focus:ring-2 focus:ring-primary/10"
							/>
						</div>
						<div className="space-y-1.5">
							<label htmlFor="password" className="text-[13px] font-semibold text-foreground/80">
								Mot de passe
							</label>
							<Input
								id="password"
								type="password"
								value={password}
								onChange={(e) => setPassword(e.target.value)}
								required
								autoComplete="current-password"
								className="h-11 rounded-xl border-border/60 bg-muted/50 px-4 text-sm transition-all focus:border-primary/40 focus:bg-white focus:ring-2 focus:ring-primary/10"
							/>
						</div>

						{error === "invalid" && (
							<div
								className="animate-fade-in rounded-lg bg-red-50 px-3 py-2.5 text-[13px] font-medium text-red-700"
								role="alert"
							>
								Email ou mot de passe incorrect. Verifiez vos identifiants.
							</div>
						)}
						{error === "unverified" && (
							<div
								className="animate-fade-in space-y-2 rounded-lg bg-amber-50 px-3 py-2.5 text-[13px] font-medium text-amber-800"
								role="alert"
							>
								<p>Votre email n'est pas verifie. Cliquez sur le lien recu par mail.</p>
								<button
									type="button"
									onClick={handleResend}
									disabled={resending}
									className="text-[12px] font-semibold text-amber-900 underline underline-offset-2 disabled:opacity-50"
								>
									{resending ? "Envoi..." : "Renvoyer l'email de verification"}
								</button>
							</div>
						)}
						{error === "disabled" && (
							<div
								className="animate-fade-in rounded-lg bg-red-50 px-3 py-2.5 text-[13px] font-medium text-red-700"
								role="alert"
							>
								Ce compte est desactive. Contactez un administrateur.
							</div>
						)}
						{error === "network" && (
							<div
								className="animate-fade-in rounded-lg bg-slate-100 px-3 py-2.5 text-[13px] font-medium text-slate-700"
								role="alert"
							>
								Impossible de contacter le serveur. Verifiez que l'API tourne sur le port 8000.
							</div>
						)}

						<Button
							type="submit"
							className="h-11 w-full rounded-xl bg-primary font-semibold shadow-md shadow-[#0F766E]/15 transition-all hover:shadow-lg hover:shadow-[#0F766E]/20 hover:brightness-110"
							disabled={submitting}
						>
							{submitting ? (
								<>
									<Loader2 className="mr-2 h-4 w-4 animate-spin" />
									Connexion...
								</>
							) : (
								"Se connecter"
							)}
						</Button>
					</form>

					<div className="my-6 flex items-center gap-3">
						<div className="h-px flex-1 bg-border/60" />
						<span className="text-[11px] font-medium uppercase tracking-wider text-muted-foreground">
							ou
						</span>
						<div className="h-px flex-1 bg-border/60" />
					</div>

					<GoogleLoginButton />

					<p className="mt-6 text-center text-[13px] text-muted-foreground">
						Pas encore de compte ?{" "}
						<Link
							href="/register"
							className="font-semibold text-[#0F766E] underline-offset-2 hover:underline"
						>
							Creer un compte
						</Link>
					</p>
				</div>

				<p className="mt-6 text-center text-xs text-muted-foreground/60">
					DIMED v1.0 — Distribution Pharmaceutique
				</p>
			</div>
		</div>
	);
}
