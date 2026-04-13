"use client";

import { Button } from "@/components/ui/button";
import { API_BASE } from "@/lib/api";
import { CheckCircle2, Loader2, Pill, XCircle } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";

type Status = "loading" | "success" | "error";

export default function VerifyEmailPage() {
	const searchParams = useSearchParams();
	const token = searchParams.get("token");
	const [status, setStatus] = useState<Status>("loading");
	const [message, setMessage] = useState("");

	useEffect(() => {
		if (!token) {
			setStatus("error");
			setMessage("Lien invalide : jeton manquant.");
			return;
		}
		const url = `${API_BASE}/auth/verify-email?token=${encodeURIComponent(token)}`;
		fetch(url, { credentials: "include" })
			.then(async (res) => {
				if (res.ok) {
					setStatus("success");
					setMessage("Votre compte est active. Vous pouvez maintenant vous connecter.");
					return;
				}
				const json = await res.json().catch(() => null);
				setStatus("error");
				setMessage(
					json?.detail === "invalid_or_expired_token"
						? "Lien expire ou deja utilise. Demandez un nouvel email depuis la page de connexion."
						: "Impossible d'activer le compte.",
				);
			})
			.catch(() => {
				setStatus("error");
				setMessage("Impossible de contacter le serveur.");
			});
	}, [token]);

	return (
		<div className="relative flex min-h-screen items-center justify-center overflow-hidden">
			<div className="absolute inset-0 bg-gradient-to-br from-[#0F766E]/5 via-background to-[#0D9488]/5" />
			<div className="absolute -top-32 -right-32 h-96 w-96 rounded-full bg-[#0F766E]/8 blur-3xl" />
			<div className="absolute -bottom-32 -left-32 h-96 w-96 rounded-full bg-[#0D9488]/6 blur-3xl" />

			<div className="animate-scale-in relative z-10 w-full max-w-[420px] px-4">
				<div className="rounded-2xl border border-border/60 bg-card/80 p-8 text-center shadow-xl shadow-black/[0.03] backdrop-blur-xl">
					<div className="mb-4 flex justify-center">
						<div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-[#0F766E] to-[#0D9488] shadow-lg shadow-[#0F766E]/20">
							<Pill className="h-7 w-7 text-white" strokeWidth={2.5} />
						</div>
					</div>

					{status === "loading" && (
						<div className="flex flex-col items-center gap-3 py-4">
							<Loader2 className="h-10 w-10 animate-spin text-[#0F766E]" />
							<p className="text-[14px] text-muted-foreground">Verification en cours...</p>
						</div>
					)}

					{status === "success" && (
						<div className="flex flex-col items-center gap-4 py-2">
							<CheckCircle2 className="h-14 w-14 text-[#0F766E]" strokeWidth={1.8} />
							<h1 className="font-heading text-xl font-bold text-foreground">Compte active</h1>
							<p className="text-[13px] text-muted-foreground">{message}</p>
							<Link href="/login?verified=1" className="w-full">
								<Button className="h-11 w-full rounded-xl bg-primary font-semibold">
									Se connecter
								</Button>
							</Link>
						</div>
					)}

					{status === "error" && (
						<div className="flex flex-col items-center gap-4 py-2">
							<XCircle className="h-14 w-14 text-red-500" strokeWidth={1.8} />
							<h1 className="font-heading text-xl font-bold text-foreground">
								Activation impossible
							</h1>
							<p className="text-[13px] text-muted-foreground">{message}</p>
							<Link href="/login" className="w-full">
								<Button
									variant="outline"
									className="h-11 w-full rounded-xl border-border/60 font-semibold"
								>
									Retour a la connexion
								</Button>
							</Link>
						</div>
					)}
				</div>
			</div>
		</div>
	);
}
