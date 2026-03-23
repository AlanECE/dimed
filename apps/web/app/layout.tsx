import { cn } from "@/lib/utils";
import type { Metadata } from "next";
import { Geist } from "next/font/google";

const geist = Geist({ subsets: ["latin"], variable: "--font-sans" });

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
		<html lang="fr" className={cn("font-sans", geist.variable)}>
			<body>{children}</body>
		</html>
	);
}
