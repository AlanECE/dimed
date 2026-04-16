"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { fetchApi } from "@/lib/api";
import type { MedicamentResponse, OrderDetailResponse, UserResponse } from "@/lib/types";
import { usePharmaciens } from "@/hooks/use-pharmaciens";
import { useMedications } from "@/hooks/use-medications";
import {
	Building2,
	CheckCircle2,
	ChevronLeft,
	ChevronRight,
	Loader2,
	Mail,
	MapPin,
	Minus,
	Phone,
	Plus,
	Receipt,
	Search,
	Trash2,
	User,
	X,
} from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { toast } from "sonner";

type CartItem = {
	medicament: MedicamentResponse;
	qte: number;
};

const PAGE_SIZE = 20;

export default function NouvelleCommandePage() {
	const router = useRouter();
	const { pharmaciens, loading: loadingPharmaciens } = usePharmaciens();

	// ── Pharmacien selection ──────────────────────────────────
	const [selectedPharmacien, setSelectedPharmacien] = useState<UserResponse | null>(null);
	const [pharmSearch, setPharmSearch] = useState("");
	const [pharmDropdownOpen, setPharmDropdownOpen] = useState(false);

	// ── Catalog ───────────────────────────────────────────────
	const [medSearch, setMedSearch] = useState("");
	const [page, setPage] = useState(0);
	const { medications, total, loading: loadingMeds } = useMedications({
		search: medSearch || undefined,
		limit: PAGE_SIZE,
		offset: page * PAGE_SIZE,
	});
	const totalPages = Math.ceil(total / PAGE_SIZE);

	// ── Cart ──────────────────────────────────────────────────
	const [cart, setCart] = useState<CartItem[]>([]);
	const [confirmOpen, setConfirmOpen] = useState(false);
	const [submitting, setSubmitting] = useState(false);

	// ── Pharmacien filter ─────────────────────────────────────
	const filteredPharmaciens = pharmaciens.filter(
		(p) =>
			p.nom.toLowerCase().includes(pharmSearch.toLowerCase()) ||
			p.email.toLowerCase().includes(pharmSearch.toLowerCase()),
	);

	function selectPharmacien(p: UserResponse) {
		setSelectedPharmacien(p);
		setPharmSearch(p.nom);
		setPharmDropdownOpen(false);
	}

	function clearPharmacien() {
		setSelectedPharmacien(null);
		setPharmSearch("");
	}

	// ── Cart helpers ──────────────────────────────────────────
	function addToCart(med: MedicamentResponse) {
		setCart((prev) => {
			const existing = prev.find((i) => i.medicament.id === med.id);
			if (existing) return prev.map((i) => i.medicament.id === med.id ? { ...i, qte: i.qte + 1 } : i);
			return [...prev, { medicament: med, qte: 1 }];
		});
	}

	function updateQte(medicamentId: string, qte: number) {
		if (qte <= 0) {
			setCart((prev) => prev.filter((i) => i.medicament.id !== medicamentId));
		} else {
			setCart((prev) => prev.map((i) => i.medicament.id === medicamentId ? { ...i, qte } : i));
		}
	}

	function removeFromCart(medicamentId: string) {
		setCart((prev) => prev.filter((i) => i.medicament.id !== medicamentId));
	}

	const totalAmount = cart.reduce((sum, i) => sum + i.medicament.ppa * i.qte, 0);

	// ── Submit ────────────────────────────────────────────────
	async function handleConfirm() {
		if (!selectedPharmacien || cart.length === 0) return;
		setSubmitting(true);
		try {
			await fetchApi<OrderDetailResponse>("/commandes", {
				method: "POST",
				body: JSON.stringify({
					pharmacien_id: selectedPharmacien.id,
					articles: cart.map((i) => ({ medicament_id: i.medicament.id, qte: i.qte })),
				}),
			});
			toast.success("Commande créée avec succès");
			router.push("/dashboard");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Erreur lors de la création");
		} finally {
			setSubmitting(false);
			setConfirmOpen(false);
		}
	}

	return (
		<div className="flex flex-col h-[calc(100vh-64px)] overflow-hidden">
			{/* Header */}
			<div className="shrink-0 px-6 py-4 border-b border-gray-200 bg-white">
				<h1 className="text-xl font-bold text-gray-900">Nouvelle commande</h1>
			</div>

			<div className="flex flex-1 overflow-hidden">
				{/* ── LEFT PANEL : Pharmacien + Catalogue ──────────────── */}
				<div className="flex flex-col flex-1 overflow-hidden border-r border-gray-200">

					{/* Pharmacien selector */}
					<div className="shrink-0 px-4 pt-4 pb-3 border-b border-gray-100 bg-white">
						<p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2 flex items-center gap-1.5">
							<User className="w-3.5 h-3.5" /> Pharmacien
						</p>
						<div className="relative">
							<Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
							<Input
								placeholder="Rechercher un pharmacien..."
								value={pharmSearch}
								onChange={(e) => {
									setPharmSearch(e.target.value);
									setPharmDropdownOpen(true);
									if (!e.target.value) setSelectedPharmacien(null);
								}}
								onFocus={() => setPharmDropdownOpen(true)}
								className="pl-9 pr-8 h-9 text-sm"
							/>
							{pharmSearch && (
								<button
									type="button"
									onClick={clearPharmacien}
									className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
								>
									<X className="w-3.5 h-3.5" />
								</button>
							)}

							{pharmDropdownOpen && pharmSearch && !selectedPharmacien && (
								<div className="absolute z-20 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-lg max-h-48 overflow-y-auto">
									{loadingPharmaciens ? (
										<div className="p-3 text-sm text-gray-500 flex items-center gap-2">
											<Loader2 className="w-4 h-4 animate-spin" /> Chargement...
										</div>
									) : filteredPharmaciens.length === 0 ? (
										<div className="p-3 text-sm text-gray-500">Aucun pharmacien trouvé</div>
									) : (
										filteredPharmaciens.map((p) => (
											<button
												key={p.id}
												type="button"
												onClick={() => selectPharmacien(p)}
												className="w-full text-left px-4 py-2.5 hover:bg-teal-50 text-sm transition-colors border-b last:border-b-0"
											>
												<span className="font-medium text-gray-900">{p.nom}</span>
												<span className="ml-2 text-gray-400 text-xs">{p.email}</span>
												{p.secteur && <span className="ml-2 text-teal-600 text-xs">· {p.secteur}</span>}
											</button>
										))
									)}
								</div>
							)}
						</div>

						{/* Selected pharmacien pill */}
						{selectedPharmacien && (
							<div className="mt-2 flex items-center gap-3 bg-teal-50 border border-teal-200 rounded-lg px-3 py-2 text-sm">
								<CheckCircle2 className="w-4 h-4 text-teal-600 shrink-0" />
								<div className="flex-1 min-w-0">
									<span className="font-semibold text-teal-900">{selectedPharmacien.nom}</span>
									{selectedPharmacien.secteur && (
										<span className="ml-2 text-teal-600 text-xs">{selectedPharmacien.secteur}</span>
									)}
									{selectedPharmacien.telephone && (
										<span className="ml-2 text-gray-500 text-xs">{selectedPharmacien.telephone}</span>
									)}
								</div>
								<button type="button" onClick={clearPharmacien} className="text-teal-400 hover:text-teal-700 shrink-0">
									<X className="w-3.5 h-3.5" />
								</button>
							</div>
						)}
					</div>

					{/* Catalog search */}
					<div className="shrink-0 px-4 pt-3 pb-2 bg-white border-b border-gray-100">
						<div className="relative">
							<Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
							<Input
								placeholder="Rechercher dans le catalogue..."
								value={medSearch}
								onChange={(e) => {
									setMedSearch(e.target.value);
									setPage(0);
								}}
								className="pl-9 h-9 text-sm"
							/>
							{medSearch && (
								<button
									type="button"
									onClick={() => { setMedSearch(""); setPage(0); }}
									className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
								>
									<X className="w-3.5 h-3.5" />
								</button>
							)}
						</div>
						<p className="mt-1.5 text-xs text-gray-400">
							{loadingMeds ? "Chargement..." : `${total} produit${total !== 1 ? "s" : ""}`}
						</p>
					</div>

					{/* Catalog list */}
					<div className="flex-1 overflow-y-auto">
						{loadingMeds ? (
							<div className="flex items-center justify-center h-32 gap-2 text-sm text-gray-400">
								<Loader2 className="w-4 h-4 animate-spin" /> Chargement du catalogue...
							</div>
						) : medications.length === 0 ? (
							<div className="flex items-center justify-center h-32 text-sm text-gray-400">
								Aucun produit trouvé
							</div>
						) : (
							<table className="w-full text-sm">
								<thead className="sticky top-0 bg-gray-50 border-b border-gray-200 z-10">
									<tr>
										<th className="text-left px-4 py-2.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Désignation</th>
										<th className="text-left px-3 py-2.5 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden md:table-cell">Code</th>
										<th className="text-right px-3 py-2.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">PPA</th>
										<th className="text-right px-3 py-2.5 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden lg:table-cell">Stock</th>
										<th className="px-3 py-2.5" />
									</tr>
								</thead>
								<tbody>
									{medications.map((med) => {
										const cartItem = cart.find((i) => i.medicament.id === med.id);
										return (
											<tr
												key={med.id}
												className="border-b border-gray-100 hover:bg-teal-50/40 transition-colors"
											>
												<td className="px-4 py-3">
													<p className="font-medium text-gray-900 leading-tight">{med.designation}</p>
													{(med.dosage || med.forme) && (
														<p className="text-xs text-gray-400 mt-0.5">
															{[med.dosage, med.forme].filter(Boolean).join(" · ")}
														</p>
													)}
												</td>
												<td className="px-3 py-3 text-xs text-gray-400 hidden md:table-cell">{med.code_article}</td>
												<td className="px-3 py-3 text-right font-semibold text-teal-700 whitespace-nowrap">
													{med.ppa.toFixed(2)} DA
												</td>
												<td className="px-3 py-3 text-right text-xs text-gray-400 hidden lg:table-cell">
													{med.stock_quantity}
												</td>
												<td className="px-3 py-3 text-right">
													{cartItem ? (
														<div className="flex items-center justify-end gap-1">
															<button
																type="button"
																onClick={() => updateQte(med.id, cartItem.qte - 1)}
																className="w-6 h-6 rounded border border-gray-200 flex items-center justify-center hover:bg-gray-100 shrink-0"
															>
																<Minus className="w-3 h-3" />
															</button>
															<span className="w-8 text-center font-semibold text-sm tabular-nums">{cartItem.qte}</span>
															<button
																type="button"
																onClick={() => updateQte(med.id, cartItem.qte + 1)}
																className="w-6 h-6 rounded border border-gray-200 flex items-center justify-center hover:bg-gray-100 shrink-0"
															>
																<Plus className="w-3 h-3" />
															</button>
														</div>
													) : (
														<button
															type="button"
															onClick={() => addToCart(med)}
															className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-teal-600 hover:bg-teal-700 text-white text-xs font-medium transition-colors"
														>
															<Plus className="w-3 h-3" />
															Ajouter
														</button>
													)}
												</td>
											</tr>
										);
									})}
								</tbody>
							</table>
						)}
					</div>

					{/* Pagination */}
					{totalPages > 1 && (
						<div className="shrink-0 flex items-center justify-between px-4 py-3 border-t border-gray-100 bg-white text-sm">
							<button
								type="button"
								onClick={() => setPage((p) => Math.max(0, p - 1))}
								disabled={page === 0}
								className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed text-xs"
							>
								<ChevronLeft className="w-3.5 h-3.5" /> Précédent
							</button>
							<span className="text-xs text-gray-500">
								Page {page + 1} / {totalPages}
							</span>
							<button
								type="button"
								onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
								disabled={page >= totalPages - 1}
								className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed text-xs"
							>
								Suivant <ChevronRight className="w-3.5 h-3.5" />
							</button>
						</div>
					)}
				</div>

				{/* ── RIGHT PANEL : Ticket de caisse ────────────────────── */}
				<div className="w-80 shrink-0 flex flex-col bg-gray-50 border-l border-gray-200">
					{/* Receipt header */}
					<div className="shrink-0 px-4 py-4 bg-white border-b border-gray-200">
						<div className="flex items-center gap-2">
							<Receipt className="w-4 h-4 text-teal-600" />
							<h2 className="font-semibold text-gray-900 text-sm">Récapitulatif</h2>
							{cart.length > 0 && (
								<span className="ml-auto bg-teal-600 text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center">
									{cart.length}
								</span>
							)}
						</div>
						{selectedPharmacien && (
							<p className="mt-2 text-xs text-gray-500 truncate">
								<span className="font-medium text-gray-700">{selectedPharmacien.nom}</span>
								{selectedPharmacien.secteur && ` · ${selectedPharmacien.secteur}`}
							</p>
						)}
					</div>

					{/* Cart items */}
					<div className="flex-1 overflow-y-auto">
						{cart.length === 0 ? (
							<div className="flex flex-col items-center justify-center h-48 gap-2 text-gray-400 px-4">
								<Receipt className="w-8 h-8 opacity-30" />
								<p className="text-sm text-center">Aucun article — cliquez sur Ajouter dans le catalogue</p>
							</div>
						) : (
							<div className="p-3 space-y-1.5">
								{cart.map((item, idx) => (
									<div
										key={item.medicament.id}
										className="bg-white rounded-lg border border-gray-100 px-3 py-2.5 shadow-sm"
									>
										<div className="flex items-start justify-between gap-2">
											<div className="flex-1 min-w-0">
												<p className="text-xs font-semibold text-gray-900 leading-tight truncate">
													{item.medicament.designation}
												</p>
												<p className="text-[10px] text-gray-400 mt-0.5">{item.medicament.ppa.toFixed(2)} DA/u</p>
											</div>
											<button
												type="button"
												onClick={() => removeFromCart(item.medicament.id)}
												className="text-red-300 hover:text-red-500 shrink-0 mt-0.5"
											>
												<Trash2 className="w-3.5 h-3.5" />
											</button>
										</div>
										<div className="flex items-center justify-between mt-2">
											<div className="flex items-center gap-1.5">
												<button
													type="button"
													onClick={() => updateQte(item.medicament.id, item.qte - 1)}
													className="w-5 h-5 rounded border border-gray-200 flex items-center justify-center hover:bg-gray-100"
												>
													<Minus className="w-2.5 h-2.5" />
												</button>
												<Input
													type="number"
													min={1}
													value={item.qte}
													onChange={(e) => updateQte(item.medicament.id, Number.parseInt(e.target.value) || 1)}
													className="w-12 h-6 text-center text-xs px-1"
												/>
												<button
													type="button"
													onClick={() => updateQte(item.medicament.id, item.qte + 1)}
													className="w-5 h-5 rounded border border-gray-200 flex items-center justify-center hover:bg-gray-100"
												>
													<Plus className="w-2.5 h-2.5" />
												</button>
											</div>
											<span className="text-xs font-bold text-gray-800 tabular-nums">
												{(item.medicament.ppa * item.qte).toFixed(2)} DA
											</span>
										</div>
									</div>
								))}
							</div>
						)}
					</div>

					{/* Divider + total */}
					<div className="shrink-0 border-t border-dashed border-gray-300 mx-4 my-1" />
					<div className="shrink-0 px-4 py-3 space-y-2">
						<div className="flex justify-between text-xs text-gray-500">
							<span>Articles</span>
							<span>{cart.reduce((s, i) => s + i.qte, 0)} unité{cart.reduce((s, i) => s + i.qte, 0) > 1 ? "s" : ""}</span>
						</div>
						<div className="flex justify-between text-sm font-bold text-gray-900">
							<span>Total estimé</span>
							<span className="text-teal-700 tabular-nums">{totalAmount.toFixed(2)} DA</span>
						</div>
					</div>

					{/* Validate button */}
					<div className="shrink-0 px-4 pb-4">
						<Button
							onClick={() => setConfirmOpen(true)}
							disabled={!selectedPharmacien || cart.length === 0}
							className="w-full bg-teal-600 hover:bg-teal-700 text-white"
						>
							Valider la commande
						</Button>
						{!selectedPharmacien && (
							<p className="mt-1.5 text-center text-xs text-gray-400">Sélectionnez d'abord un pharmacien</p>
						)}
					</div>
				</div>
			</div>

			{/* ── Confirmation modal ─────────────────────────────────── */}
			{confirmOpen && selectedPharmacien && (
				<div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
					<div className="bg-white rounded-2xl shadow-xl w-full max-w-md p-6 space-y-5 mx-4">
						<div className="flex items-center justify-between">
							<div className="flex items-center gap-3">
								<div className="w-10 h-10 rounded-full bg-teal-100 flex items-center justify-center">
									<CheckCircle2 className="w-5 h-5 text-teal-600" />
								</div>
								<h3 className="text-lg font-semibold text-gray-900">Confirmer la commande</h3>
							</div>
							<button type="button" onClick={() => setConfirmOpen(false)} className="text-gray-400 hover:text-gray-600">
								<X className="w-5 h-5" />
							</button>
						</div>

						<p className="text-sm text-gray-600">
							La commande sera envoyée en validation. Un email de confirmation sera envoyé à :
						</p>

						<div className="flex items-center gap-3 bg-teal-50 rounded-lg px-4 py-3">
							<Mail className="w-4 h-4 text-teal-600 shrink-0" />
							<span className="font-semibold text-teal-800">{selectedPharmacien.email}</span>
						</div>

						<div className="bg-gray-50 rounded-lg p-3 text-sm space-y-1.5">
							<div className="flex justify-between text-gray-600">
								<span>Pharmacien</span>
								<span className="font-medium text-gray-900">{selectedPharmacien.nom}</span>
							</div>
							<div className="flex justify-between text-gray-600">
								<span>Médicaments</span>
								<span className="font-medium text-gray-900">{cart.length} réf. · {cart.reduce((s, i) => s + i.qte, 0)} unités</span>
							</div>
							<div className="flex justify-between text-gray-600 border-t pt-1.5 mt-1.5">
								<span className="font-semibold">Montant estimé</span>
								<span className="font-bold text-gray-900">{totalAmount.toFixed(2)} DA</span>
							</div>
						</div>

						<div className="flex gap-3 pt-1">
							<Button
								variant="outline"
								className="flex-1"
								onClick={() => setConfirmOpen(false)}
								disabled={submitting}
							>
								Annuler
							</Button>
							<Button
								className="flex-1 bg-teal-600 hover:bg-teal-700"
								onClick={handleConfirm}
								disabled={submitting}
							>
								{submitting ? (
									<><Loader2 className="w-4 h-4 mr-2 animate-spin" />Envoi...</>
								) : (
									"Confirmer"
								)}
							</Button>
						</div>
					</div>
				</div>
			)}
		</div>
	);
}
