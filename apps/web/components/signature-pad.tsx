"use client";

import { Button } from "@/components/ui/button";
import { Eraser, Pen } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";

type SignaturePadProps = {
	onSave: (base64Png: string) => void;
	onCancel?: () => void;
	label?: string;
	width?: number;
	height?: number;
	saving?: boolean;
};

export function SignaturePad({
	onSave,
	onCancel,
	label = "Signez ici",
	width = 400,
	height = 200,
	saving = false,
}: SignaturePadProps) {
	const canvasRef = useRef<HTMLCanvasElement>(null);
	const [isDrawing, setIsDrawing] = useState(false);
	const [hasContent, setHasContent] = useState(false);

	useEffect(() => {
		const canvas = canvasRef.current;
		if (!canvas) return;
		const ctx = canvas.getContext("2d");
		if (!ctx) return;
		ctx.fillStyle = "#ffffff";
		ctx.fillRect(0, 0, canvas.width, canvas.height);
		ctx.strokeStyle = "#1a1a1a";
		ctx.lineWidth = 2;
		ctx.lineCap = "round";
		ctx.lineJoin = "round";
	}, []);

	const getPos = useCallback((e: React.MouseEvent | React.TouchEvent) => {
		const canvas = canvasRef.current;
		if (!canvas) return { x: 0, y: 0 };
		const rect = canvas.getBoundingClientRect();
		const scaleX = canvas.width / rect.width;
		const scaleY = canvas.height / rect.height;
		if ("touches" in e) {
			const touch = e.touches[0];
			return {
				x: (touch.clientX - rect.left) * scaleX,
				y: (touch.clientY - rect.top) * scaleY,
			};
		}
		return {
			x: (e.clientX - rect.left) * scaleX,
			y: (e.clientY - rect.top) * scaleY,
		};
	}, []);

	const startDraw = useCallback(
		(e: React.MouseEvent | React.TouchEvent) => {
			e.preventDefault();
			const ctx = canvasRef.current?.getContext("2d");
			if (!ctx) return;
			const { x, y } = getPos(e);
			ctx.beginPath();
			ctx.moveTo(x, y);
			setIsDrawing(true);
		},
		[getPos],
	);

	const draw = useCallback(
		(e: React.MouseEvent | React.TouchEvent) => {
			if (!isDrawing) return;
			e.preventDefault();
			const ctx = canvasRef.current?.getContext("2d");
			if (!ctx) return;
			const { x, y } = getPos(e);
			ctx.lineTo(x, y);
			ctx.stroke();
			setHasContent(true);
		},
		[isDrawing, getPos],
	);

	const endDraw = useCallback(() => {
		setIsDrawing(false);
	}, []);

	const clear = useCallback(() => {
		const canvas = canvasRef.current;
		if (!canvas) return;
		const ctx = canvas.getContext("2d");
		if (!ctx) return;
		ctx.fillStyle = "#ffffff";
		ctx.fillRect(0, 0, canvas.width, canvas.height);
		setHasContent(false);
	}, []);

	const save = useCallback(() => {
		const canvas = canvasRef.current;
		if (!canvas) return;
		const dataUrl = canvas.toDataURL("image/png");
		const base64 = dataUrl.replace(/^data:image\/png;base64,/, "");
		onSave(base64);
	}, [onSave]);

	return (
		<div className="flex flex-col gap-3">
			<div className="flex items-center gap-2">
				<Pen className="h-4 w-4 text-muted-foreground" />
				<span className="text-sm font-medium">{label}</span>
			</div>
			<div className="overflow-hidden rounded-xl border-2 border-dashed border-border/60 bg-white">
				<canvas
					ref={canvasRef}
					width={width}
					height={height}
					className="w-full cursor-crosshair touch-none"
					onMouseDown={startDraw}
					onMouseMove={draw}
					onMouseUp={endDraw}
					onMouseLeave={endDraw}
					onTouchStart={startDraw}
					onTouchMove={draw}
					onTouchEnd={endDraw}
				/>
			</div>
			<div className="flex items-center justify-between">
				<Button variant="ghost" size="sm" onClick={clear} className="gap-1.5 text-[12px]">
					<Eraser className="h-3.5 w-3.5" />
					Effacer
				</Button>
				<div className="flex gap-2">
					{onCancel && (
						<Button variant="outline" size="sm" onClick={onCancel} className="text-[12px]">
							Annuler
						</Button>
					)}
					<Button
						size="sm"
						onClick={save}
						disabled={!hasContent || saving}
						className="gap-1.5 rounded-lg bg-gradient-to-r from-[#0F766E] to-[#0D9488] text-[12px] font-semibold text-white shadow-sm hover:brightness-110"
					>
						Valider la signature
					</Button>
				</div>
			</div>
		</div>
	);
}
