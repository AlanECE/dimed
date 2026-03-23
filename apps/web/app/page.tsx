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
		if (user.role === "operatrice" || user.role === "admin") {
			router.push("/dashboard");
		} else {
			router.push("/catalogue");
		}
	}, [user, loading, router]);

	return null;
}
