"use client";

import { ApiError } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import type { SignupRole } from "@/lib/types";
import { type CredentialResponse, GoogleLogin } from "@react-oauth/google";
import { useRouter } from "next/navigation";
import { useCallback } from "react";
import { toast } from "sonner";

type Props = {
	role?: SignupRole;
	onSuccessRedirect?: string;
};

const GOOGLE_CLIENT_ID = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "";

export function GoogleLoginButton({ role, onSuccessRedirect = "/catalogue" }: Props) {
	const router = useRouter();
	const { loginWithGoogle } = useAuth();

	const handleSuccess = useCallback(
		async (resp: CredentialResponse) => {
			if (!resp.credential) {
				toast.error("Impossible de recuperer le jeton Google.");
				return;
			}
			try {
				await loginWithGoogle({ credential: resp.credential, role });
				toast.success("Connexion reussie");
				router.push(onSuccessRedirect);
			} catch (err) {
				if (err instanceof ApiError && err.status === 409) {
					const params = new URLSearchParams({ google_credential: resp.credential });
					router.push(`/register?${params.toString()}`);
					return;
				}
				const message =
					err instanceof ApiError ? err.message : "Erreur lors de la connexion Google.";
				toast.error(message);
			}
		},
		[loginWithGoogle, role, router, onSuccessRedirect],
	);

	if (!GOOGLE_CLIENT_ID) {
		return (
			<div className="rounded-lg border border-dashed border-border/60 bg-muted/40 px-3 py-2 text-center text-[12px] text-muted-foreground">
				Google OAuth non configure (NEXT_PUBLIC_GOOGLE_CLIENT_ID manquant)
			</div>
		);
	}

	return (
		<div className="flex justify-center">
			<GoogleLogin
				onSuccess={handleSuccess}
				onError={() => toast.error("Echec de la connexion Google.")}
				text="continue_with"
				shape="pill"
				theme="outline"
				size="large"
				width="320"
			/>
		</div>
	);
}
