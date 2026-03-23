"use client";

import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { useAuth } from "@/lib/auth";
import { cn } from "@/lib/utils";
import { ClipboardList, LogOut, Package, PanelLeftClose, PanelLeftOpen } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

const navItems = [
	{ href: "/catalogue", label: "Catalogue", icon: Package },
	{ href: "/commandes", label: "Mes Commandes", icon: ClipboardList },
];

const COLLAPSED_KEY = "dimed-sidebar-collapsed";

export function Sidebar() {
	const pathname = usePathname();
	const { user, logout } = useAuth();
	const [collapsed, setCollapsed] = useState(false);

	useEffect(() => {
		const stored = localStorage.getItem(COLLAPSED_KEY);
		if (stored === "true") setCollapsed(true);
	}, []);

	function toggleCollapsed() {
		const next = !collapsed;
		setCollapsed(next);
		localStorage.setItem(COLLAPSED_KEY, String(next));
	}

	return (
		<aside
			className={cn(
				"flex h-screen flex-col border-r border-border bg-card transition-all duration-200",
				collapsed ? "w-16" : "w-64",
			)}
		>
			{/* Header */}
			<div className="flex h-14 items-center justify-between px-4">
				{!collapsed && <span className="font-heading text-xl font-bold text-primary">DIMED</span>}
				<Button
					variant="ghost"
					size="icon"
					onClick={toggleCollapsed}
					aria-label={collapsed ? "Ouvrir le menu" : "Fermer le menu"}
					className={cn(collapsed && "mx-auto")}
				>
					{collapsed ? (
						<PanelLeftOpen className="h-5 w-5" />
					) : (
						<PanelLeftClose className="h-5 w-5" />
					)}
				</Button>
			</div>

			<Separator />

			{/* Navigation */}
			<nav className="flex-1 space-y-1 p-2">
				{navItems.map((item) => {
					const isActive = pathname.startsWith(item.href);
					return (
						<Link
							key={item.href}
							href={item.href}
							className={cn(
								"flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
								isActive
									? "border-l-[3px] border-primary bg-muted text-foreground"
									: "text-muted-foreground hover:bg-muted hover:text-foreground",
								collapsed && "justify-center px-0",
							)}
						>
							<item.icon className="h-5 w-5 shrink-0" />
							{!collapsed && <span>{item.label}</span>}
						</Link>
					);
				})}
			</nav>

			<Separator />

			{/* User info + logout */}
			<div className="p-3">
				{!collapsed && user && (
					<p className="mb-2 truncate text-sm font-medium text-foreground">
						{user.prenom} {user.nom}
					</p>
				)}
				<Button
					variant="ghost"
					size={collapsed ? "icon" : "default"}
					onClick={logout}
					className={cn(
						"text-muted-foreground hover:text-destructive",
						!collapsed && "w-full justify-start",
					)}
					aria-label="Déconnexion"
				>
					<LogOut className="h-4 w-4 shrink-0" />
					{!collapsed && <span className="ml-2">Déconnexion</span>}
				</Button>
			</div>
		</aside>
	);
}
