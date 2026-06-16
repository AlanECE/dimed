"use client";

import { useAuth } from "@/lib/auth";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

export default function Home() {
	const { user, loading } = useAuth();
	const router = useRouter();

	useEffect(() => {
		if (loading) return;
		if (!user) {
			router.push("/login");
			return;
		}
		const routes: Record<string, string> = {
			operatrice: "/dashboard",
			admin: "/dashboard",
			preparateur: "/preparation",
			controleur: "/verification",
			magasinier: "/magasinier",
			livreur: "/livraison",
			facturier: "/facturier",
		};
		router.push(routes[user.role] || "/catalogue");
	}, [user, loading, router]);

	return null;
}
