"use client";

import { fetchApi } from "@/lib/api";
import type { UserResponse } from "@/lib/types";
import { useCallback, useEffect, useState } from "react";

type CreateUserData = {
	email: string;
	password: string;
	role: string;
	nom: string;
	adresse?: string;
	secteur?: string;
};

type UpdateUserData = {
	role?: string;
	is_active?: boolean;
	nom?: string;
};

export function useUsers(limit = 50, offset = 0) {
	const [users, setUsers] = useState<UserResponse[]>([]);
	const [total, setTotal] = useState(0);
	const [loading, setLoading] = useState(true);

	const fetch = useCallback(async () => {
		setLoading(true);
		try {
			const data = await fetchApi<{ users: UserResponse[]; total: number }>(
				`/admin/users?limit=${limit}&offset=${offset}`,
			);
			setUsers(data.users);
			setTotal(data.total);
		} catch {
			setUsers([]);
		} finally {
			setLoading(false);
		}
	}, [limit, offset]);

	useEffect(() => {
		fetch();
	}, [fetch]);

	async function createUser(data: CreateUserData) {
		await fetchApi("/admin/users", {
			method: "POST",
			body: JSON.stringify(data),
		});
		fetch();
	}

	async function updateUser(userId: string, data: UpdateUserData) {
		await fetchApi(`/admin/users/${userId}`, {
			method: "PATCH",
			body: JSON.stringify(data),
		});
		fetch();
	}

	return { users, total, loading, refetch: fetch, createUser, updateUser };
}
