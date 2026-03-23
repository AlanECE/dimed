export function relativeTime(dateStr: string): string {
	const now = Date.now();
	const then = new Date(dateStr).getTime();
	const diffSec = Math.round((then - now) / 1000);

	const units: [Intl.RelativeTimeFormatUnit, number][] = [
		["day", 86400],
		["hour", 3600],
		["minute", 60],
		["second", 1],
	];

	const rtf = new Intl.RelativeTimeFormat("fr", { numeric: "auto" });

	for (const [unit, sec] of units) {
		if (Math.abs(diffSec) >= sec || unit === "second") {
			return rtf.format(Math.round(diffSec / sec), unit);
		}
	}

	return "";
}
