"use client";

import { ChangePasswordForm } from "@/components/change-password-form";
import { ProfileForm } from "@/components/profile-form";
import { UserCircle } from "lucide-react";

export default function ProfilPage() {
	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center gap-3">
				<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10">
					<UserCircle className="h-5 w-5 text-primary" />
				</div>
				<div>
					<h2 className="font-heading text-xl font-bold">Mon Profil</h2>
					<p className="text-[13px] text-muted-foreground">Gérez vos informations personnelles</p>
				</div>
			</div>

			<div className="grid gap-6 lg:grid-cols-2">
				<div className="animate-fade-in-up">
					<ProfileForm />
				</div>
				<div className="animate-fade-in-up delay-150">
					<ChangePasswordForm />
				</div>
			</div>
		</div>
	);
}
