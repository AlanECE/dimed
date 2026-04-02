"use client";

import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth";
import { KeyRound, Settings, UserCircle } from "lucide-react";
import Link from "next/link";

export default function ParametresPage() {
	const { user } = useAuth();

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gray-100">
					<Settings className="h-5 w-5 text-gray-600" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Paramètres</h2>
					<p className="text-[13px] text-muted-foreground">Préférences et configuration</p>
				</div>
			</div>

			<div className="grid gap-6 lg:grid-cols-2">
				{/* Compte */}
				<div className="animate-fade-in-up rounded-xl border border-border/60 bg-card p-6 shadow-sm">
					<h3 className="mb-4 font-heading text-[15px] font-bold">Compte</h3>
					<div className="space-y-3">
						<div className="flex items-center justify-between rounded-lg bg-muted/30 p-3">
							<div>
								<p className="text-[13px] font-semibold">{user?.nom}</p>
								<p className="text-[12px] text-muted-foreground">{user?.email}</p>
							</div>
							<Link href="/profil">
								<Button variant="outline" size="sm" className="h-8 gap-1.5 rounded-lg text-[12px]">
									<UserCircle className="h-3.5 w-3.5" />
									Modifier le profil
								</Button>
							</Link>
						</div>
						<Link href="/profil" className="block">
							<Button
								variant="outline"
								size="sm"
								className="h-8 w-full gap-1.5 rounded-lg text-[12px]"
							>
								<KeyRound className="h-3.5 w-3.5" />
								Changer le mot de passe
							</Button>
						</Link>
					</div>
				</div>

				{/* Affichage */}
				<div className="animate-fade-in-up delay-150 rounded-xl border border-border/60 bg-card p-6 shadow-sm">
					<h3 className="mb-4 font-heading text-[15px] font-bold">Affichage</h3>
					<div className="space-y-4">
						<div className="flex items-center justify-between">
							<div>
								<p className="text-[13px] font-semibold">Éléments par page</p>
								<p className="text-[12px] text-muted-foreground">
									Nombre d'éléments affichés dans les tableaux
								</p>
							</div>
							<span className="rounded-lg bg-muted/50 px-3 py-1.5 text-[13px] font-semibold tabular-nums">
								20
							</span>
						</div>
						<div className="flex items-center justify-between">
							<div>
								<p className="text-[13px] font-semibold">Thème</p>
								<p className="text-[12px] text-muted-foreground">
									Mode d'affichage de l'application
								</p>
							</div>
							<span className="rounded-lg bg-muted/50 px-3 py-1.5 text-[13px] font-semibold">
								Clair
							</span>
						</div>
					</div>
				</div>

				{/* Informations */}
				<div className="animate-fade-in-up delay-300 rounded-xl border border-border/60 bg-card p-6 shadow-sm">
					<h3 className="mb-4 font-heading text-[15px] font-bold">À propos</h3>
					<div className="space-y-2 text-[13px] text-muted-foreground">
						<div className="flex justify-between">
							<span>Version</span>
							<span className="font-semibold text-foreground">1.0.0</span>
						</div>
						<div className="flex justify-between">
							<span>Plateforme</span>
							<span className="font-semibold text-foreground">DIMED Web</span>
						</div>
						<div className="flex justify-between">
							<span>Rôle</span>
							<span className="font-semibold text-foreground capitalize">{user?.role}</span>
						</div>
					</div>
				</div>
			</div>
		</div>
	);
}
