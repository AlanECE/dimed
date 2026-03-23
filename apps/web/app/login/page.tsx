"use client";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { useAuth } from "@/lib/auth";
import { Loader2 } from "lucide-react";
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
		<div className="flex min-h-screen items-center justify-center bg-background px-4">
			<Card className="w-full max-w-sm shadow-md">
				<CardHeader className="space-y-1 text-center">
					<h1 className="font-heading text-3xl font-bold tracking-tight text-primary">DIMED</h1>
					<p className="text-sm text-muted-foreground">Gestion Logistique Pharmaceutique</p>
				</CardHeader>
				<CardContent>
					<form onSubmit={handleSubmit} className="space-y-4">
						<div className="space-y-2">
							<label htmlFor="email" className="text-sm font-medium">
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
							/>
						</div>
						<div className="space-y-2">
							<label htmlFor="password" className="text-sm font-medium">
								Mot de passe
							</label>
							<Input
								id="password"
								type="password"
								value={password}
								onChange={(e) => setPassword(e.target.value)}
								required
								autoComplete="current-password"
							/>
						</div>
						{error && (
							<p className="text-sm text-destructive" role="alert">
								{error}
							</p>
						)}
						<Button type="submit" className="w-full" disabled={submitting}>
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
				</CardContent>
			</Card>
		</div>
	);
}
