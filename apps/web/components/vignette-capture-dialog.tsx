"use client";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Camera, ImageIcon, Loader2 } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";

type Mode = "menu" | "camera";

interface Props {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	onCapture: (file: File) => void;
}

export function VignetteCaptureDialog({ open, onOpenChange, onCapture }: Props) {
	const [mode, setMode] = useState<Mode>("menu");
	const [error, setError] = useState<string | null>(null);
	const [starting, setStarting] = useState(false);
	const videoRef = useRef<HTMLVideoElement | null>(null);
	const canvasRef = useRef<HTMLCanvasElement | null>(null);
	const fileInputRef = useRef<HTMLInputElement | null>(null);
	const streamRef = useRef<MediaStream | null>(null);

	const stopStream = useCallback(() => {
		if (streamRef.current) {
			for (const track of streamRef.current.getTracks()) track.stop();
			streamRef.current = null;
		}
		if (videoRef.current) videoRef.current.srcObject = null;
	}, []);

	const close = useCallback(() => {
		stopStream();
		setMode("menu");
		setError(null);
		setStarting(false);
		onOpenChange(false);
	}, [onOpenChange, stopStream]);

	// Reset on close
	useEffect(() => {
		if (!open) {
			stopStream();
			setMode("menu");
			setError(null);
			setStarting(false);
		}
	}, [open, stopStream]);

	// Start camera when entering camera mode
	useEffect(() => {
		if (!open || mode !== "camera") return;
		let cancelled = false;
		setStarting(true);
		setError(null);
		(async () => {
			if (!navigator.mediaDevices?.getUserMedia) {
				setError("Caméra non supportée par ce navigateur");
				setStarting(false);
				return;
			}
			try {
				const stream = await navigator.mediaDevices.getUserMedia({
					video: { facingMode: { ideal: "environment" } },
					audio: false,
				});
				if (cancelled) {
					for (const track of stream.getTracks()) track.stop();
					return;
				}
				streamRef.current = stream;
				if (videoRef.current) {
					videoRef.current.srcObject = stream;
					await videoRef.current.play().catch(() => {});
				}
			} catch (err) {
				const msg =
					err instanceof DOMException && err.name === "NotAllowedError"
						? "Accès caméra refusé"
						: err instanceof Error
							? err.message
							: "Erreur caméra";
				setError(msg);
			} finally {
				if (!cancelled) setStarting(false);
			}
		})();
		return () => {
			cancelled = true;
		};
	}, [open, mode]);

	const handlePickGallery = useCallback(() => {
		fileInputRef.current?.click();
	}, []);

	const handleFileChange = useCallback(
		(e: React.ChangeEvent<HTMLInputElement>) => {
			const file = e.target.files?.[0];
			if (file) {
				onCapture(file);
				close();
			}
			e.target.value = "";
		},
		[onCapture, close],
	);

	const handleSnap = useCallback(() => {
		const video = videoRef.current;
		const canvas = canvasRef.current;
		if (!video || !canvas) return;
		const w = video.videoWidth;
		const h = video.videoHeight;
		if (!w || !h) return;
		canvas.width = w;
		canvas.height = h;
		const ctx = canvas.getContext("2d");
		if (!ctx) return;
		ctx.drawImage(video, 0, 0, w, h);
		canvas.toBlob(
			(blob) => {
				if (!blob) {
					setError("Impossible de capturer la photo");
					return;
				}
				const file = new File([blob], `capture-${Date.now()}.jpg`, { type: "image/jpeg" });
				onCapture(file);
				close();
			},
			"image/jpeg",
			0.92,
		);
	}, [onCapture, close]);

	return (
		<Dialog open={open} onOpenChange={(o) => (o ? onOpenChange(true) : close())}>
			<DialogContent className="max-w-lg">
				<DialogHeader>
					<DialogTitle>{mode === "menu" ? "Source de la photo" : "Prendre une photo"}</DialogTitle>
				</DialogHeader>

				{mode === "menu" && (
					<div className="grid grid-cols-2 gap-3">
						<button
							type="button"
							onClick={() => setMode("camera")}
							className="flex flex-col items-center gap-2 rounded-xl border border-border/60 bg-card px-4 py-6 transition hover:border-primary/60 hover:bg-primary/5"
						>
							<div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
								<Camera className="h-6 w-6 text-primary" />
							</div>
							<span className="text-[13px] font-semibold">Caméra</span>
							<span className="text-[11px] text-muted-foreground">Photo en direct</span>
						</button>
						<button
							type="button"
							onClick={handlePickGallery}
							className="flex flex-col items-center gap-2 rounded-xl border border-border/60 bg-card px-4 py-6 transition hover:border-primary/60 hover:bg-primary/5"
						>
							<div className="flex h-12 w-12 items-center justify-center rounded-full bg-amber-100">
								<ImageIcon className="h-6 w-6 text-amber-700" />
							</div>
							<span className="text-[13px] font-semibold">Galerie</span>
							<span className="text-[11px] text-muted-foreground">Fichier existant</span>
						</button>
					</div>
				)}

				{mode === "camera" && (
					<div className="flex flex-col gap-3">
						<div className="relative aspect-[4/3] overflow-hidden rounded-xl bg-black">
							{/* biome-ignore lint/a11y/useMediaCaption: viewfinder */}
							<video ref={videoRef} className="h-full w-full object-cover" playsInline muted />
							{starting && (
								<div className="absolute inset-0 flex items-center justify-center bg-black/40 text-white">
									<Loader2 className="h-6 w-6 animate-spin" />
								</div>
							)}
							{error && (
								<div className="absolute inset-0 flex flex-col items-center justify-center gap-2 bg-black/70 px-4 text-center text-[13px] text-white">
									<span>{error}</span>
								</div>
							)}
						</div>
						<canvas ref={canvasRef} className="hidden" />
						<div className="flex items-center justify-between gap-2">
							<Button variant="ghost" size="sm" onClick={() => setMode("menu")}>
								Retour
							</Button>
							<Button
								onClick={handleSnap}
								disabled={starting || !!error}
								className="gap-1.5 bg-gradient-to-r from-[#0F766E] to-[#0D9488] font-semibold text-white shadow-sm hover:brightness-110"
							>
								<Camera className="h-4 w-4" />
								Capturer
							</Button>
						</div>
					</div>
				)}

				<input
					ref={fileInputRef}
					type="file"
					accept="image/jpeg,image/png,image/webp"
					className="hidden"
					onChange={handleFileChange}
				/>
			</DialogContent>
		</Dialog>
	);
}
