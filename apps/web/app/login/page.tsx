"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useAuth } from "@/lib/auth";
import { Loader2, Pill } from "lucide-react";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";

export default function LoginPage() {
	const router = useRouter();
	const { login } = useAuth();
	const [email, setEmail] = useState("");
	const [password, setPassword] = useState("");
	const [error, setError] = useState("");
	const [submitting, setSubmitting] = useState(false);
	const emailRef = useRef<HTMLInputElement>(null);

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault();
		setError("");
		setSubmitting(true);

		try {
			await login(email, password);
			router.push("/catalogue");
		} catch {
			setError("Email ou mot de passe incorrect. Vérifiez vos identifiants.");
			emailRef.current?.focus();
		} finally {
			setSubmitting(false);
		}
	}

	return (
		<div className="relative flex min-h-screen items-center justify-center overflow-hidden">
			{/* Background pattern */}
			<div className="absolute inset-0 bg-gradient-to-br from-[#0F766E]/5 via-background to-[#0D9488]/5" />
			<div
				className="absolute inset-0 opacity-[0.02]"
				style={{
					backgroundImage:
						"radial-gradient(circle at 1px 1px, var(--foreground) 1px, transparent 0)",
					backgroundSize: "40px 40px",
				}}
			/>

			{/* Decorative orbs */}
			<div className="absolute -top-32 -right-32 h-96 w-96 rounded-full bg-[#0F766E]/8 blur-3xl" />
			<div className="absolute -bottom-32 -left-32 h-96 w-96 rounded-full bg-[#0D9488]/6 blur-3xl" />

			{/* Login card */}
			<div className="animate-scale-in relative z-10 w-full max-w-[400px] px-4">
				<div className="rounded-2xl border border-border/60 bg-card/80 p-8 shadow-xl shadow-black/[0.03] backdrop-blur-xl">
					{/* Logo */}
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

						{error && (
							<div
								className="animate-fade-in rounded-lg bg-red-50 px-3 py-2.5 text-[13px] font-medium text-red-700"
								role="alert"
							>
								{error}
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
				</div>

				<p className="mt-6 text-center text-xs text-muted-foreground/60">
					DIMED v1.0 — Distribution Pharmaceutique
				</p>
			</div>
		</div>
	);
}
