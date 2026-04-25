"use client";

import { Dialog, DialogContent } from "@/components/ui/dialog";
import { API_BASE } from "@/lib/api";
import type { VignetteResponse } from "@/lib/types";

interface Props {
	vignette: VignetteResponse | null;
	onClose: () => void;
}

export function VignettePreviewModal({ vignette, onClose }: Props) {
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
					</div>
				)}
			</DialogContent>
		</Dialog>
	);
}
