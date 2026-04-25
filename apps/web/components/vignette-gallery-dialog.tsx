"use client";

import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";
import { API_BASE } from "@/lib/api";
import type { LignePreparationResponse, VignetteResponse } from "@/lib/types";
import { Check, Loader2, Trash2, Upload } from "lucide-react";
import { type ChangeEvent, type DragEvent, useCallback, useEffect, useRef, useState } from "react";
import { toast } from "sonner";

type UploadingItem = {
	id: string;
	file: File;
	previewUrl: string;
};

type Props = {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	commandeId: string;
	lignes: LignePreparationResponse[];
	fetchVignettes: (commandeId: string) => Promise<VignetteResponse[]>;
	uploadVignette: (commandeId: string, file: File) => Promise<VignetteResponse>;
	assignVignette: (
		commandeId: string,
		vignetteId: string,
		payload: { ligne_id: string | null; dlc?: string | null },
	) => Promise<VignetteResponse>;
	deleteVignette: (commandeId: string, vignetteId: string) => Promise<void>;
	onChange: () => void;
};

function formatDlc(iso: string | null): string {
	if (!iso) return "—";
	const d = new Date(iso);
	if (Number.isNaN(d.getTime())) return iso;
	return d.toLocaleDateString("fr-FR");
}

export function VignetteGalleryDialog({
	open,
	onOpenChange,
	commandeId,
	lignes,
	fetchVignettes,
	uploadVignette,
	assignVignette,
	deleteVignette,
	onChange,
}: Props) {
	const [vignettes, setVignettes] = useState<VignetteResponse[]>([]);
	const [loading, setLoading] = useState(false);
	const [uploading, setUploading] = useState<UploadingItem[]>([]);
	const [dragActive, setDragActive] = useState(false);
	const fileInputRef = useRef<HTMLInputElement>(null);

	const refresh = useCallback(async () => {
		setLoading(true);
		try {
			const list = await fetchVignettes(commandeId);
			setVignettes(list);
		} catch {
			toast.error("Erreur chargement galerie");
		} finally {
			setLoading(false);
		}
	}, [commandeId, fetchVignettes]);

	useEffect(() => {
		if (open) refresh();
	}, [open, refresh]);

	const handleFiles = useCallback(
		async (files: File[]) => {
			const images = files.filter((f) => f.type.startsWith("image/"));
			if (images.length === 0) {
				toast.warning("Seules les images sont acceptées");
				return;
			}
			const items: UploadingItem[] = images.map((file) => ({
				id: `${file.name}-${file.lastModified}-${Math.random()}`,
				file,
				previewUrl: URL.createObjectURL(file),
			}));
			setUploading((prev) => [...prev, ...items]);

			await Promise.all(
				items.map(async (item) => {
					try {
						await uploadVignette(commandeId, item.file);
					} catch (err) {
						toast.error(err instanceof Error ? err.message : `Upload KO: ${item.file.name}`);
					} finally {
						URL.revokeObjectURL(item.previewUrl);
						setUploading((prev) => prev.filter((u) => u.id !== item.id));
					}
				}),
			);
			await refresh();
			onChange();
		},
		[commandeId, uploadVignette, refresh, onChange],
	);

	const handleDrop = useCallback(
		(e: DragEvent<HTMLDivElement>) => {
			e.preventDefault();
			setDragActive(false);
			handleFiles(Array.from(e.dataTransfer.files));
		},
		[handleFiles],
	);

	const handleInputChange = useCallback(
		(e: ChangeEvent<HTMLInputElement>) => {
			if (e.target.files) handleFiles(Array.from(e.target.files));
			e.target.value = "";
		},
		[handleFiles],
	);

	const handleAssign = useCallback(
		async (vignette: VignetteResponse, ligneId: string | null) => {
			try {
				const updated = await assignVignette(commandeId, vignette.id, {
					ligne_id: ligneId,
					dlc: vignette.extracted_dlc ?? null,
				});
				setVignettes((prev) => prev.map((v) => (v.id === vignette.id ? updated : v)));
				onChange();
				if (ligneId) toast.success("Vignette assignée et DLC reportée");
			} catch (err) {
				toast.error(err instanceof Error ? err.message : "Erreur assignation");
			}
		},
		[assignVignette, commandeId, onChange],
	);

	const handleDelete = useCallback(
		async (vignetteId: string) => {
			try {
				await deleteVignette(commandeId, vignetteId);
				setVignettes((prev) => prev.filter((v) => v.id !== vignetteId));
				onChange();
			} catch (err) {
				toast.error(err instanceof Error ? err.message : "Erreur suppression");
			}
		},
		[deleteVignette, commandeId, onChange],
	);

	return (
		<Dialog open={open} onOpenChange={onOpenChange}>
			<DialogContent className="max-w-4xl sm:max-w-4xl">
				<DialogHeader>
					<DialogTitle>Galerie des vignettes</DialogTitle>
					<DialogDescription>
						Dépose des photos des vignettes pharmaceutiques. Le système extrait la DLC et te propose
						un matching avec les lignes de commande.
					</DialogDescription>
				</DialogHeader>

				{/* biome-ignore lint/a11y/useSemanticElements: drag-and-drop target needs <div>, not <button> */}
				<div
					role="button"
					tabIndex={0}
					onDragOver={(e) => {
						e.preventDefault();
						setDragActive(true);
					}}
					onDragLeave={() => setDragActive(false)}
					onDrop={handleDrop}
					onClick={() => fileInputRef.current?.click()}
					onKeyDown={(e) => {
						if (e.key === "Enter" || e.key === " ") {
							e.preventDefault();
							fileInputRef.current?.click();
						}
					}}
					className={`flex cursor-pointer flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed py-8 transition-colors ${
						dragActive
							? "border-primary bg-primary/5"
							: "border-border/60 hover:border-primary/40 hover:bg-muted/40"
					}`}
				>
					<Upload className="h-6 w-6 text-muted-foreground" />
					<p className="text-[13px] font-medium">
						Glisser des photos ici ou cliquer pour sélectionner
					</p>
					<p className="text-[11px] text-muted-foreground">JPG, PNG, WEBP — max 10 MiB par image</p>
					<input
						ref={fileInputRef}
						type="file"
						accept="image/*"
						multiple
						className="hidden"
						onChange={handleInputChange}
					/>
				</div>

				<div className="max-h-[60vh] overflow-y-auto">
					{loading && vignettes.length === 0 && uploading.length === 0 ? (
						<p className="py-8 text-center text-[13px] text-muted-foreground">Chargement...</p>
					) : vignettes.length === 0 && uploading.length === 0 ? (
						<p className="py-8 text-center text-[13px] text-muted-foreground">
							Aucune vignette pour le moment
						</p>
					) : (
						<div className="grid grid-cols-1 gap-3 sm:grid-cols-2 md:grid-cols-3">
							{uploading.map((u) => (
								<div
									key={u.id}
									className="relative overflow-hidden rounded-xl border border-border/60 bg-card p-2 shadow-sm"
								>
									{/* eslint-disable-next-line @next/next/no-img-element */}
									<img
										src={u.previewUrl}
										alt="vignette en cours"
										className="mb-2 h-32 w-full rounded-lg object-cover opacity-60"
									/>
									<div className="absolute inset-0 flex items-center justify-center">
										<Loader2 className="h-6 w-6 animate-spin text-primary" />
									</div>
									<p className="truncate text-[11px] text-muted-foreground">{u.file.name}</p>
								</div>
							))}

							{vignettes.map((v) => {
								const assigned = Boolean(v.ligne_id);
								return (
									<div
										key={v.id}
										className={`flex flex-col gap-2 rounded-xl border p-2 shadow-sm ${
											assigned ? "border-emerald-300 bg-emerald-50/40" : "border-border/60 bg-card"
										}`}
									>
										<div className="relative">
											{/* eslint-disable-next-line @next/next/no-img-element */}
											<img
												src={`${API_BASE}/static/${v.path}`}
												alt="vignette"
												className="h-32 w-full rounded-lg object-cover"
											/>
											{assigned && (
												<span className="absolute top-1 right-1 flex h-6 w-6 items-center justify-center rounded-full bg-emerald-500 text-white shadow">
													<Check className="h-3.5 w-3.5" />
												</span>
											)}
										</div>
										<div className="flex flex-col gap-1 px-1">
											<div className="flex items-center justify-between text-[12px]">
												<span className="text-muted-foreground">DLC</span>
												<span className="font-mono font-semibold">
													{formatDlc(v.extracted_dlc)}
												</span>
											</div>
											{v.extracted_code_article && (
												<div className="flex items-center justify-between text-[11px] text-muted-foreground">
													<span>Code</span>
													<span className="font-mono">{v.extracted_code_article}</span>
												</div>
											)}
											<Select
												value={v.ligne_id ?? "__none__"}
												onValueChange={(raw) =>
													handleAssign(v, raw === "__none__" ? null : (raw ?? null))
												}
											>
												<SelectTrigger className="h-8 w-full rounded-md text-[12px]">
													<SelectValue placeholder="Ligne..." />
												</SelectTrigger>
												<SelectContent>
													<SelectItem value="__none__">Non assignée</SelectItem>
													{lignes.map((ln) => (
														<SelectItem key={ln.id} value={ln.id}>
															{ln.designation}
														</SelectItem>
													))}
												</SelectContent>
											</Select>
											<Button
												variant="ghost"
												size="sm"
												onClick={() => handleDelete(v.id)}
												className="mt-1 h-7 gap-1 text-[11px] text-destructive hover:bg-destructive/10"
											>
												<Trash2 className="h-3 w-3" />
												Supprimer
											</Button>
										</div>
									</div>
								);
							})}
						</div>
					)}
				</div>
			</DialogContent>
		</Dialog>
	);
}
