"use client";

import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth";
import { cn } from "@/lib/utils";
import type { LucideIcon } from "lucide-react";
import {
	BarChart3,
	Boxes,
	CheckCircle,
	ChevronDown,
	ClipboardList,
	FileText,
	LayoutDashboard,
	LogOut,
	MessageSquareWarning,
	Package,
	PackageCheck,
	PackagePlus,
	PanelLeftClose,
	PanelLeftOpen,
	Pill,
	PlusCircle,
	Receipt,
	Route,
	ScrollText,
	Settings,
	Truck,
	UserCircle,
	Users,
	Wallet,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";

type NavChild = { href: string; label: string };
type NavItem = { href: string; label: string; icon: LucideIcon; children?: NavChild[] };

const DOCUMENTS_CHILDREN_BASE: NavChild[] = [
	{ href: "/documents?tab=factures", label: "Factures" },
	{ href: "/documents?tab=bls", label: "Bons de livraison" },
	{ href: "/documents?tab=proforma", label: "Proforma" },
];

const DOCUMENTS_ITEM_PHARMACIEN: NavItem = {
	href: "/documents",
	label: "Documents",
	icon: FileText,
	children: DOCUMENTS_CHILDREN_BASE,
};

const DOCUMENTS_ITEM_OPERATRICE: NavItem = {
	href: "/documents",
	label: "Documents",
	icon: FileText,
	children: [
		...DOCUMENTS_CHILDREN_BASE,
		{ href: "/documents?tab=feuilles", label: "Feuilles de route" },
	],
};

const NAV_ITEMS: Record<string, NavItem[]> = {
	pharmacien: [
		{ href: "/catalogue", label: "Catalogue", icon: Package },
		{ href: "/commandes", label: "Mes Commandes", icon: ClipboardList },
		{ href: "/pharmacie/arrivages", label: "Arrivage", icon: PackagePlus },
		{ href: "/pharmacie/stock", label: "Stock", icon: Boxes },
		{ href: "/creances", label: "Créances", icon: Wallet },
		{ href: "/reclamations", label: "Réclamations", icon: MessageSquareWarning },
		DOCUMENTS_ITEM_PHARMACIEN,
		{ href: "/rapports", label: "Statistiques", icon: BarChart3 },
	],
	operatrice: [
		{ href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
		{ href: "/dashboard/nouvelle-commande", label: "Nouvelle commande", icon: PlusCircle },
		{ href: "/dashboard/routes", label: "Feuilles de route", icon: Route },
		{ href: "/dashboard/camions", label: "Lignes de route", icon: Route },
		{ href: "/arrivages", label: "Arrivages", icon: PackagePlus },
		{ href: "/creances", label: "Créances", icon: Wallet },
		{ href: "/reclamations", label: "Réclamations", icon: MessageSquareWarning },
		DOCUMENTS_ITEM_OPERATRICE,
		{ href: "/rapports", label: "Rapports", icon: BarChart3 },
	],
	preparateur: [{ href: "/preparation", label: "Préparation", icon: Package }],
	controleur: [{ href: "/verification", label: "Vérification", icon: CheckCircle }],
	magasinier: [{ href: "/magasinier", label: "Zone d'expédition", icon: PackageCheck }],
	facturier: [{ href: "/facturier", label: "Facturier", icon: Receipt }],
	livreur: [{ href: "/livraison", label: "Livraisons", icon: Truck }],
	admin: [
		{ href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
		{ href: "/preparation", label: "Préparation", icon: Package },
		{ href: "/verification", label: "Vérification", icon: CheckCircle },
		{ href: "/magasinier", label: "Zone d'expédition", icon: PackageCheck },
		{ href: "/facturier", label: "Facturier", icon: Receipt },
		{ href: "/livraison", label: "Livraisons", icon: Truck },
		{ href: "/dashboard/routes", label: "Feuilles de route", icon: Route },
		{ href: "/dashboard/camions", label: "Lignes de route", icon: Route },
		{ href: "/arrivages", label: "Arrivages", icon: PackagePlus },
		{ href: "/creances", label: "Créances", icon: Wallet },
		{ href: "/reclamations", label: "Réclamations", icon: MessageSquareWarning },
		DOCUMENTS_ITEM_OPERATRICE,
		{ href: "/rapports", label: "Rapports", icon: BarChart3 },
		{ href: "/admin/catalogue", label: "Produits vedettes", icon: PackagePlus },
		{ href: "/admin/utilisateurs", label: "Utilisateurs", icon: Users },
		{ href: "/admin/journal", label: "Journal", icon: ScrollText },
	],
};

const COLLAPSED_KEY = "dimed-sidebar-collapsed";

const ROLE_LABELS: Record<string, string> = {
	pharmacien: "Pharmacien",
	operatrice: "Opératrice",
	preparateur: "Préparateur",
	controleur: "Contrôleur",
	magasinier: "Magasinier",
	facturier: "Facturier",
	livreur: "Livreur",
	admin: "Administrateur",
};

export function Sidebar() {
	return (
		<Suspense>
			<SidebarInner />
		</Suspense>
	);
}

function SidebarInner() {
	const pathname = usePathname();
	const searchParams = useSearchParams();
	const { user, logout } = useAuth();
	const [collapsed, setCollapsed] = useState(false);
	const [openGroups, setOpenGroups] = useState<Record<string, boolean>>({});

	useEffect(() => {
		const stored = localStorage.getItem(COLLAPSED_KEY);
		if (stored === "true") setCollapsed(true);
	}, []);

	function toggleCollapsed() {
		const next = !collapsed;
		setCollapsed(next);
		localStorage.setItem(COLLAPSED_KEY, String(next));
	}

	const navItems = NAV_ITEMS[user?.role ?? ""] ?? [];
	const initials = user?.nom
		? user.nom
				.split(" ")
				.map((w) => w[0])
				.join("")
				.slice(0, 2)
				.toUpperCase()
		: "?";

	function isActive(href: string) {
		if (href === "/dashboard") return pathname === "/dashboard";
		return pathname.startsWith(href);
	}

	// Un sous-lien "/documents?tab=x" est actif si on est sur /documents avec ce tab
	// (le premier sous-lien l'est aussi sans tab explicite).
	function isChildActive(child: NavChild, index: number) {
		const [childPath, childQuery] = child.href.split("?");
		if (pathname !== childPath) return false;
		const childTab = new URLSearchParams(childQuery).get("tab");
		const currentTab = searchParams.get("tab");
		return currentTab === childTab || (currentTab === null && index === 0);
	}

	return (
		<aside
			className={cn(
				"flex h-screen flex-col bg-sidebar/90 backdrop-blur-xl transition-all duration-300 ease-in-out",
				collapsed ? "w-[68px]" : "w-64",
			)}
		>
			{/* Header */}
			<div className="flex h-16 items-center justify-between px-4">
				{!collapsed && (
					<div className="flex items-center gap-2.5">
						<div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-[#2DD4BF] to-[#0D9488]">
							<Pill className="h-4 w-4 text-sidebar" strokeWidth={2.5} />
						</div>
						<span className="font-heading text-lg font-bold tracking-tight text-white">DIMED</span>
					</div>
				)}
				<Button
					variant="ghost"
					size="icon"
					onClick={toggleCollapsed}
					aria-label={collapsed ? "Ouvrir le menu" : "Fermer le menu"}
					className={cn(
						"h-8 w-8 text-sidebar-foreground/60 hover:bg-sidebar-accent hover:text-sidebar-foreground",
						collapsed && "mx-auto",
					)}
				>
					{collapsed ? (
						<PanelLeftOpen className="h-4 w-4" />
					) : (
						<PanelLeftClose className="h-4 w-4" />
					)}
				</Button>
			</div>

			<div className="mx-3 h-px bg-sidebar-border" />

			{/* Navigation */}
			<nav className="flex-1 space-y-0.5 overflow-y-auto px-3 py-4">
				{navItems.map((item) => {
					const active = isActive(item.href);
					const hasChildren = !collapsed && item.children && item.children.length > 0;
					const groupOpen = openGroups[item.href] ?? active;

					if (hasChildren) {
						return (
							<div key={item.href}>
								<button
									type="button"
									onClick={() => setOpenGroups((prev) => ({ ...prev, [item.href]: !groupOpen }))}
									className={cn(
										"group relative flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-[13px] font-medium transition-all duration-200",
										active
											? "bg-sidebar-accent text-white"
											: "text-sidebar-foreground/60 hover:bg-sidebar-accent/50 hover:text-sidebar-foreground",
									)}
									aria-expanded={groupOpen}
								>
									{active && (
										<span className="absolute left-0 top-1/2 h-5 w-[3px] -translate-y-1/2 rounded-r-full bg-sidebar-primary transition-all" />
									)}
									<item.icon
										className={cn(
											"h-[18px] w-[18px] shrink-0 transition-colors",
											active
												? "text-sidebar-primary"
												: "text-sidebar-foreground/40 group-hover:text-sidebar-foreground/70",
										)}
									/>
									<span className="flex-1 text-left">{item.label}</span>
									<ChevronDown
										className={cn(
											"h-3.5 w-3.5 shrink-0 transition-transform duration-200",
											groupOpen && "rotate-180",
										)}
									/>
								</button>
								{groupOpen && (
									<div className="ml-[26px] mt-0.5 space-y-0.5 border-l border-sidebar-border pl-3">
										{item.children?.map((child, childIndex) => {
											const childActive = isChildActive(child, childIndex);
											return (
												<Link
													key={child.href}
													href={child.href}
													className={cn(
														"block rounded-md px-2.5 py-1.5 text-[12px] font-medium transition-colors",
														childActive
															? "bg-sidebar-accent text-white"
															: "text-sidebar-foreground/50 hover:bg-sidebar-accent/40 hover:text-sidebar-foreground/80",
													)}
												>
													{child.label}
												</Link>
											);
										})}
									</div>
								)}
							</div>
						);
					}

					return (
						<Link
							key={item.href}
							href={item.href}
							className={cn(
								"group relative flex items-center gap-3 rounded-lg px-3 py-2.5 text-[13px] font-medium transition-all duration-200",
								active
									? "bg-sidebar-accent text-white"
									: "text-sidebar-foreground/60 hover:bg-sidebar-accent/50 hover:text-sidebar-foreground",
								collapsed && "justify-center px-0",
							)}
						>
							{active && (
								<span className="absolute left-0 top-1/2 h-5 w-[3px] -translate-y-1/2 rounded-r-full bg-sidebar-primary transition-all" />
							)}
							<item.icon
								className={cn(
									"h-[18px] w-[18px] shrink-0 transition-colors",
									active
										? "text-sidebar-primary"
										: "text-sidebar-foreground/40 group-hover:text-sidebar-foreground/70",
								)}
							/>
							{!collapsed && <span>{item.label}</span>}
						</Link>
					);
				})}
			</nav>

			<div className="mx-3 h-px bg-sidebar-border" />

			{/* User section */}
			<div className="p-3">
				{!collapsed && user && (
					<div className="mb-3 flex items-center gap-2.5 rounded-lg bg-sidebar-accent/50 px-3 py-2.5">
						<div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-[#2DD4BF] to-[#0D9488] text-[11px] font-bold text-sidebar">
							{initials}
						</div>
						<div className="min-w-0">
							<p className="truncate text-[13px] font-semibold text-white">{user.nom}</p>
							<p className="truncate text-[11px] text-sidebar-foreground/50">
								{ROLE_LABELS[user.role] ?? user.role}
							</p>
						</div>
					</div>
				)}

				{/* Profil + Parametres links */}
				<div className="mb-2 space-y-0.5">
					{[
						{ href: "/profil", label: "Mon Profil", icon: UserCircle },
						{ href: "/parametres", label: "Paramètres", icon: Settings },
					].map((link) => {
						const active = isActive(link.href);
						return (
							<Link
								key={link.href}
								href={link.href}
								className={cn(
									"flex items-center gap-2.5 rounded-lg px-3 py-2 text-[12px] font-medium transition-colors",
									active
										? "bg-sidebar-accent text-white"
										: "text-sidebar-foreground/50 hover:bg-sidebar-accent/40 hover:text-sidebar-foreground/80",
									collapsed && "justify-center px-0",
								)}
							>
								<link.icon className="h-4 w-4 shrink-0" />
								{!collapsed && <span>{link.label}</span>}
							</Link>
						);
					})}
				</div>

				<Button
					variant="ghost"
					size={collapsed ? "icon" : "default"}
					onClick={logout}
					className={cn(
						"h-9 text-sidebar-foreground/50 hover:bg-red-500/10 hover:text-red-400",
						!collapsed && "w-full justify-start",
						collapsed && "mx-auto",
					)}
					aria-label="Déconnexion"
				>
					<LogOut className="h-4 w-4 shrink-0" />
					{!collapsed && <span className="ml-2 text-[13px]">Déconnexion</span>}
				</Button>
			</div>
		</aside>
	);
}
