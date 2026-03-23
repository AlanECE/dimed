"use client";

import { API_BASE, ApiError, fetchApi } from "@/lib/api";
import type { UserResponse } from "@/lib/types";
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { ReactNode } from "react";

type AuthContextValue = {
	user: UserResponse | null;
	loading: boolean;
	login: (email: string, password: string) => Promise<void>;
	logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

function AuthProvider({ children }: { children: ReactNode }) {
	const [user, setUser] = useState<UserResponse | null>(null);
	const [loading, setLoading] = useState(true);

	useEffect(() => {
		fetchApi<UserResponse>("/auth/me")
			.then(setUser)
			.catch(() => setUser(null))
			.finally(() => setLoading(false));
	}, []);

	const login = useCallback(async (email: string, password: string) => {
		const res = await fetch(`${API_BASE}/auth/login`, {
			method: "POST",
			credentials: "include",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({ email, password }),
		});

		if (!res.ok) {
			const text = await res.text();
			throw new ApiError(res.status, text);
		}

		const userData: UserResponse = await res.json();
		setUser(userData);
	}, []);

	const logout = useCallback(async () => {
		try {
			await fetchApi("/auth/logout", { method: "POST" });
		} finally {
			setUser(null);
			window.location.href = "/login";
		}
	}, []);

	const value = useMemo(() => ({ user, loading, login, logout }), [user, loading, login, logout]);

	return <AuthContext value={value}>{children}</AuthContext>;
}

function useAuth() {
	const context = useContext(AuthContext);
	if (!context) {
		throw new Error("useAuth must be used within an AuthProvider");
	}
	return context;
}

export { AuthProvider, useAuth };
