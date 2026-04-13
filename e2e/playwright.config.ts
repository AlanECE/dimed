import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
	testDir: "./tests",
	timeout: 60_000,
	expect: { timeout: 10_000 },
	fullyParallel: false,
	retries: 0,
	workers: 1,
	reporter: [["list"], ["html", { outputFolder: "playwright-report", open: "never" }]],
	outputDir: "test-results",
	use: {
		baseURL: "http://localhost:3000",
		headless: true,
		screenshot: "on",
		video: "retain-on-failure",
		trace: "retain-on-failure",
		viewport: { width: 1440, height: 900 },
	},
	projects: [
		{
			name: "chromium",
			use: { ...devices["Desktop Chrome"] },
		},
	],
});
