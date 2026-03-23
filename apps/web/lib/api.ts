const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

type FetchOptions = RequestInit & {
	params?: Record<string, string | number | undefined>;
};

class ApiError extends Error {
	constructor(
		public status: number,
		message: string,
	) {
		super(message);
		this.name = "ApiError";
	}
}

async function fetchApi<T>(path: string, options: FetchOptions = {}): Promise<T> {
	const { params, ...init } = options;

	let url = `${API_BASE}${path}`;
	if (params) {
		const searchParams = new URLSearchParams();
		for (const [key, value] of Object.entries(params)) {
			if (value !== undefined && value !== null && value !== "") {
				searchParams.set(key, String(value));
			}
		}
		const qs = searchParams.toString();
		if (qs) url += `?${qs}`;
	}

	const response = await fetch(url, {
		...init,
		credentials: "include",
		headers: {
			"Content-Type": "application/json",
			...init.headers,
		},
	});

	if (response.status === 401) {
		// Try refresh once
		const refreshRes = await fetch(`${API_BASE}/auth/refresh`, {
			method: "POST",
			credentials: "include",
		});
		if (refreshRes.ok) {
			// Retry original request
			const retryRes = await fetch(url, {
				...init,
				credentials: "include",
				headers: { "Content-Type": "application/json", ...init.headers },
			});
			if (!retryRes.ok) {
				throw new ApiError(retryRes.status, await retryRes.text());
			}
			return retryRes.json();
		}
		// Refresh failed — redirect to login
		if (typeof window !== "undefined") {
			window.location.href = "/login";
		}
		throw new ApiError(401, "Session expired");
	}

	if (!response.ok) {
		const text = await response.text();
		throw new ApiError(response.status, text);
	}

	return response.json();
}

export { fetchApi, ApiError, API_BASE };
