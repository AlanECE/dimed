"use client";

import { fetchApi } from "@/lib/api";
import type { ChangePasswordRequest, UpdateProfileRequest, UserResponse } from "@/lib/types";
import { useState } from "react";

export function useProfile() {
	const [loading, setLoading] = useState(false);

	async function updateProfile(data: UpdateProfileRequest): Promise<UserResponse> {
		setLoading(true);
		try {
			return await fetchApi<UserResponse>("/auth/me", {
				method: "PATCH",
				body: JSON.stringify(data),
			});
		} finally {
			setLoading(false);
		}
	}

	async function changePassword(data: ChangePasswordRequest): Promise<void> {
		setLoading(true);
		try {
			await fetchApi("/auth/change-password", {
				method: "POST",
				body: JSON.stringify(data),
			});
		} finally {
			setLoading(false);
		}
	}

	return { updateProfile, changePassword, loading };
}
