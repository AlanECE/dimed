import "@/app/globals.css";
import { AuthProvider } from "@/lib/auth";
import { cn } from "@/lib/utils";
import type { Metadata } from "next";
import { Inter, Sora } from "next/font/google";
import { Toaster } from "sonner";

const sora = Sora({
	subsets: ["latin"],
	variable: "--font-heading",
	weight: ["500", "600", "700", "800"],
});
const inter = Inter({ subsets: ["latin"], variable: "--font-sans" });

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
		<html lang="fr" className={cn("font-sans antialiased", sora.variable, inter.variable)}>
			<body>
				<AuthProvider>
					{children}
					<Toaster richColors position="top-right" />
				</AuthProvider>
			</body>
		</html>
	);
}
