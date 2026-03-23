import "@/app/globals.css";
import { AuthProvider } from "@/lib/auth";
import { cn } from "@/lib/utils";
import type { Metadata } from "next";
import { Figtree, Noto_Sans } from "next/font/google";
import { Toaster } from "sonner";

const figtree = Figtree({ subsets: ["latin"], variable: "--font-heading" });
const notoSans = Noto_Sans({ subsets: ["latin"], variable: "--font-sans" });

export const metadata: Metadata = {
	title: "DIMED - Gestion Logistique Pharmaceutique",
	description: "Systeme de gestion logistique pharmaceutique",
};

export default function RootLayout({
	children,
}: {
	children: React.ReactNode;
}) {
	return (
		<html lang="fr" className={cn("font-sans", figtree.variable, notoSans.variable)}>
			<body>
				<AuthProvider>
					{children}
					<Toaster richColors position="top-right" />
				</AuthProvider>
			</body>
		</html>
	);
}
