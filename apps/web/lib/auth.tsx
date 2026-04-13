"use client";

import { API_BASE, ApiError, fetchApi } from "@/lib/api";
import type { GoogleAuthPayload, SignupPayload, UserResponse } from "@/lib/types";
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { ReactNode } from "react";

type AuthContextValue = {
	user: UserResponse | null;
	loading: boolean;
	login: (email: string, password: string) => Promise<void>;
	logout: () => Promise<void>;
	signup: (payload: SignupPayload) => Promise<{ message: string }>;
	loginWithGoogle: (payload: GoogleAuthPayload) => Promise<void>;
	resendVerification: (email: string) => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

async function postJson<T>(path: string, body: unknown): Promise<T> {
	const res = await fetch(`${API_BASE}${path}`, {
		method: "POST",
		credentials: "include",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify(body),
	});
	if (!res.ok) {
		let message = "Erreur serveur";
		try {
			const json = await res.json();
			message = json.detail ?? json.message ?? message;
		} catch {
			// ignore
		}
		throw new ApiError(res.status, message);
	}
	return res.json() as Promise<T>;
}

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
		const userData = await postJson<UserResponse>("/auth/login", { email, password });
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

	const signup = useCallback(async (payload: SignupPayload) => {
		return postJson<{ message: string }>("/auth/signup", payload);
	}, []);

	const loginWithGoogle = useCallback(async (payload: GoogleAuthPayload) => {
		const userData = await postJson<UserResponse>("/auth/google", payload);
		setUser(userData);
	}, []);

	const resendVerification = useCallback(async (email: string) => {
		await postJson<{ message: string }>("/auth/resend-verification", { email });
	}, []);

	const value = useMemo(
		() => ({ user, loading, login, logout, signup, loginWithGoogle, resendVerification }),
		[user, loading, login, logout, signup, loginWithGoogle, resendVerification],
	);

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
