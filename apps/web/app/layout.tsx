import type { Metadata } from "next";

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
		<html lang="fr">
			<body>{children}</body>
		</html>
	);
}
