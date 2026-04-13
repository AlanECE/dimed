"use client";

import { GoogleOAuthProvider } from "@react-oauth/google";
import type { ReactNode } from "react";

const clientId = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "";

export function GoogleAuthProvider({ children }: { children: ReactNode }) {
	if (!clientId) {
		return <>{children}</>;
	}
	return <GoogleOAuthProvider clientId={clientId}>{children}</GoogleOAuthProvider>;
}
