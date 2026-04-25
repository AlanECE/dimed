"use client";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent } from "@/components/ui/dialog";
import { API_BASE } from "@/lib/api";
import type { VignetteResponse } from "@/lib/types";
import { RotateCcw, Trash2 } from "lucide-react";

interface Props {
	vignette: VignetteResponse | null;
	onClose: () => void;
	onRescan?: () => void;
	onDelete?: () => void;
}

export function VignettePreviewModal({ vignette, onClose, onRescan, onDelete }: Props) {
	return (
		<Dialog open={!!vignette} onOpenChange={(o) => !o && onClose()}>
			<DialogContent className="max-w-2xl">
				{vignette && (
					<div className="grid gap-4">
						<img
							src={`${API_BASE}${vignette.file_url}`}
							alt="Vignette scannée"
							className="w-full max-h-[60vh] object-contain rounded-lg border bg-[#F8F7F4]"
						/>
						<dl className="grid grid-cols-[6rem_1fr] gap-x-6 gap-y-2 font-mono text-sm">
							<dt className="text-muted-foreground">Lot</dt>
							<dd>{vignette.extracted_lot ?? "—"}</dd>
							<dt className="text-muted-foreground">Fab</dt>
							<dd>{vignette.extracted_fab ?? "—"}</dd>
							<dt className="text-muted-foreground">Exp</dt>
							<dd>{vignette.extracted_exp ?? "—"}</dd>
							<dt className="text-muted-foreground">PPA</dt>
							<dd>{vignette.extracted_ppa ? `${vignette.extracted_ppa} DA` : "—"}</dd>
							{vignette.extracted_designation && (
								<>
									<dt className="text-muted-foreground">Désignation</dt>
									<dd className="break-words">{vignette.extracted_designation}</dd>
								</>
							)}
						</dl>
						{(onRescan || onDelete) && (
							<div className="flex items-center justify-end gap-2 border-t border-border/40 pt-3">
								{onDelete && (
									<Button
										variant="outline"
										size="sm"
										onClick={onDelete}
										className="gap-1.5 text-red-600 hover:bg-red-50 hover:text-red-700"
									>
										<Trash2 className="h-3.5 w-3.5" />
										Supprimer
									</Button>
								)}
								{onRescan && (
									<Button
										size="sm"
										onClick={onRescan}
										className="gap-1.5 bg-gradient-to-r from-[#0F766E] to-[#0D9488] font-semibold text-white shadow-sm hover:brightness-110"
									>
										<RotateCcw className="h-3.5 w-3.5" />
										Re-scanner
									</Button>
								)}
							</div>
						)}
					</div>
				)}
			</DialogContent>
		</Dialog>
	);
}
