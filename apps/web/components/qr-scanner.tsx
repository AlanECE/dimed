"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import jsQR from "jsqr";
import { Keyboard, Loader2, ScanLine } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";

interface QrScannerProps {
	onScan: (code: string) => void | Promise<void>;
	/** Suspend le décodage (ex: pendant la confirmation d'un colis scanné). */
	paused?: boolean;
	/** Délai pendant lequel un même code n'est pas re-déclenché. */
	cooldownMs?: number;
	className?: string;
}

/**
 * Viseur caméra + décodage QR continu (jsQR), avec saisie manuelle en secours.
 * Réutilise le pattern getUserMedia de vignette-capture-dialog.tsx.
 */
export function QrScanner({
	onScan,
	paused = false,
	cooldownMs = 2500,
	className,
}: QrScannerProps) {
	const [error, setError] = useState<string | null>(null);
	const [starting, setStarting] = useState(true);
	const [flash, setFlash] = useState(false);
	const [manualCode, setManualCode] = useState("");
	const videoRef = useRef<HTMLVideoElement | null>(null);
	const canvasRef = useRef<HTMLCanvasElement | null>(null);
	const streamRef = useRef<MediaStream | null>(null);
	const rafRef = useRef<number>(0);
	const lastCodeRef = useRef<{ code: string; at: number } | null>(null);
	const pausedRef = useRef(paused);
	const onScanRef = useRef(onScan);

	pausedRef.current = paused;
	onScanRef.current = onScan;

	const emit = useCallback(
		(raw: string) => {
			const code = raw.trim().toUpperCase();
			if (!code) return;
			const now = Date.now();
			const last = lastCodeRef.current;
			if (last && last.code === code && now - last.at < cooldownMs) return;
			lastCodeRef.current = { code, at: now };
			setFlash(true);
			setTimeout(() => setFlash(false), 350);
			void onScanRef.current(code);
		},
		[cooldownMs],
	);

	// Camera lifecycle
	useEffect(() => {
		let cancelled = false;
		setStarting(true);
		setError(null);
		(async () => {
			if (!navigator.mediaDevices?.getUserMedia) {
				setError("Caméra non supportée — utilisez la saisie manuelle");
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
						? "Accès caméra refusé — utilisez la saisie manuelle"
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
			if (streamRef.current) {
				for (const track of streamRef.current.getTracks()) track.stop();
				streamRef.current = null;
			}
		};
	}, []);

	// Decode loop
	useEffect(() => {
		const tick = () => {
			rafRef.current = requestAnimationFrame(tick);
			if (pausedRef.current) return;
			const video = videoRef.current;
			const canvas = canvasRef.current;
			if (!video || !canvas || video.readyState < video.HAVE_ENOUGH_DATA) return;
			const w = video.videoWidth;
			const h = video.videoHeight;
			if (!w || !h) return;
			canvas.width = w;
			canvas.height = h;
			const ctx = canvas.getContext("2d", { willReadFrequently: true });
			if (!ctx) return;
			ctx.drawImage(video, 0, 0, w, h);
			const imageData = ctx.getImageData(0, 0, w, h);
			const result = jsQR(imageData.data, w, h, { inversionAttempts: "dontInvert" });
			if (result?.data) emit(result.data);
		};
		rafRef.current = requestAnimationFrame(tick);
		return () => cancelAnimationFrame(rafRef.current);
	}, [emit]);

	const handleManualSubmit = useCallback(() => {
		if (!manualCode.trim()) return;
		emit(manualCode);
		setManualCode("");
	}, [manualCode, emit]);

	return (
		<div className={`flex flex-col gap-3 ${className ?? ""}`}>
			<div className="relative aspect-[4/3] overflow-hidden rounded-xl bg-black">
				{/* biome-ignore lint/a11y/useMediaCaption: viewfinder */}
				<video ref={videoRef} className="h-full w-full object-cover" playsInline muted />
				{/* Viewfinder frame */}
				{!error && !starting && (
					<div className="pointer-events-none absolute inset-0 flex items-center justify-center">
						<div
							className={`h-3/5 w-3/5 rounded-2xl border-2 transition-colors duration-200 ${
								flash
									? "border-emerald-400 shadow-[0_0_30px_rgba(52,211,153,0.6)]"
									: "border-white/60"
							}`}
						/>
					</div>
				)}
				{paused && !starting && !error && (
					<div className="absolute inset-0 flex items-center justify-center bg-black/50 text-[13px] font-medium text-white">
						Scan en pause
					</div>
				)}
				{starting && (
					<div className="absolute inset-0 flex items-center justify-center bg-black/40 text-white">
						<Loader2 className="h-6 w-6 animate-spin" />
					</div>
				)}
				{error && (
					<div className="absolute inset-0 flex flex-col items-center justify-center gap-2 bg-black/70 px-4 text-center text-[13px] text-white">
						<ScanLine className="h-6 w-6 opacity-70" />
						<span>{error}</span>
					</div>
				)}
			</div>
			<canvas ref={canvasRef} className="hidden" />

			{/* Manual entry fallback */}
			<div className="flex items-center gap-2">
				<Keyboard className="h-4 w-4 shrink-0 text-muted-foreground" />
				<Input
					value={manualCode}
					onChange={(e) => setManualCode(e.target.value)}
					onKeyDown={(e) => {
						if (e.key === "Enter") {
							e.preventDefault();
							handleManualSubmit();
						}
					}}
					placeholder="Ou saisir le numéro du colis (ex: CLS00000001)"
					className="font-mono text-[13px]"
				/>
				<Button
					size="sm"
					variant="outline"
					onClick={handleManualSubmit}
					disabled={!manualCode.trim() || paused}
				>
					Valider
				</Button>
			</div>
		</div>
	);
}
