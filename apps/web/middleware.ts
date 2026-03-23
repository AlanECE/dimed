import { type NextRequest, NextResponse } from "next/server";

const publicRoutes = ["/login"];

export function middleware(request: NextRequest) {
	const { pathname } = request.nextUrl;
	const isPublic = publicRoutes.some((route) => pathname.startsWith(route));
	const hasToken = request.cookies.has("access_token");

	if (!isPublic && !hasToken) {
		return NextResponse.redirect(new URL("/login", request.url));
	}

	if (isPublic && hasToken) {
		return NextResponse.redirect(new URL("/catalogue", request.url));
	}

	return NextResponse.next();
}

export const config = {
	matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
