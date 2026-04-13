import { expect, test } from "@playwright/test";

const PHARMACIEN_EMAIL = "pharma@dimed.dz";
const PHARMACIEN_PASSWORD = "Pharma12345!";

test("pharmacien happy path: login → catalogue → ajout panier → valider → voir statut", async ({
	page,
}) => {
	test.setTimeout(90_000);

	const consoleErrors: string[] = [];
	page.on("console", (msg) => {
		if (msg.type() === "error") consoleErrors.push(msg.text());
	});
	page.on("pageerror", (err) => consoleErrors.push(`pageerror: ${err.message}`));

	// 1) LOGIN
	await test.step("login", async () => {
		await page.goto("/login");
		await page.screenshot({ path: "test-results/01-login.png", fullPage: true });
		await expect(page.getByRole("heading", { name: "DIMED" })).toBeVisible();

		await page.locator("#email").fill(PHARMACIEN_EMAIL);
		await page.locator("#password").fill(PHARMACIEN_PASSWORD);
		await page.getByRole("button", { name: "Se connecter" }).click();

		await page.waitForURL("**/catalogue", { timeout: 15_000 });
		await page.screenshot({ path: "test-results/02-catalogue-loaded.png", fullPage: true });
	});

	// 2) CATALOGUE — verify medicaments visible
	await test.step("catalogue: medicaments visibles", async () => {
		await expect(page.getByRole("heading", { name: "Catalogue" })).toBeVisible();
		// At least one of our seeded medicaments
		await expect(page.getByText("Doliprane 1000mg").first()).toBeVisible({ timeout: 10_000 });
		await expect(page.getByText("Amoxicilline 500mg").first()).toBeVisible();
	});

	// 3) ADD TO CART (2 different medicaments)
	await test.step("ajouter 2 articles au panier", async () => {
		// Add Doliprane (use aria-label from the table button)
		await page.getByRole("button", { name: "Ajouter Doliprane 1000mg" }).first().click();
		// Add Aspirine
		await page.getByRole("button", { name: "Ajouter Aspirine 500mg" }).first().click();
		await page.screenshot({ path: "test-results/03-cart-2-items.png", fullPage: true });

		// Cart sidebar should show items
		await expect(page.getByRole("heading", { name: "Panier" })).toBeVisible();
		await expect(page.locator("aside").getByText("Doliprane 1000mg").first()).toBeVisible();
	});

	// 4) CHANGE QUANTITY of first item to 3 (use the increase button)
	await test.step("changer quantite Doliprane (qte=3)", async () => {
		// First cart item = Doliprane (it was added first). Increase qty 1 → 3.
		const incBtn = page.locator('aside button[aria-label="Augmenter la quantité"]').first();
		await incBtn.click();
		await incBtn.click();
		await page.screenshot({ path: "test-results/04-cart-qty-updated.png", fullPage: true });
	});

	// 5) CONFIRM ORDER
	let orderRef: string | null = null;
	await test.step("valider la commande", async () => {
		await page.getByRole("button", { name: /Valider la commande/i }).click();
		// Confirmation dialog
		await expect(page.getByRole("heading", { name: "Confirmer la commande" })).toBeVisible();
		await page.screenshot({ path: "test-results/05-confirm-dialog.png", fullPage: true });

		await page.getByRole("button", { name: "Confirmer la commande" }).click();

		// Should redirect to /commandes/<id>
		await page.waitForURL(/\/commandes\/[a-f0-9-]+/, { timeout: 15_000 });

		// 6) ORDER DETAIL — verify status visible
		await expect(page.locator("h2").filter({ hasText: /Commande\s+/ })).toBeVisible({
			timeout: 10_000,
		});
		const heading = await page
			.locator("h2")
			.filter({ hasText: /Commande\s+/ })
			.textContent();
		orderRef = heading?.replace("Commande", "").trim() ?? null;
		await page.screenshot({ path: "test-results/06-order-detail.png", fullPage: true });
	});

	// 7) STATUS check — should be CREEE
	await test.step("verifier statut initial", async () => {
		// StatusBadge renders the order statut (CREEE for a fresh order)
		const badgeRegex = /CR[ÉE]+E|Cr[ée]+e/i;
		await expect(page.getByText(badgeRegex).first()).toBeVisible({ timeout: 5_000 });
		await page.screenshot({ path: "test-results/07-status-creee.png", fullPage: true });
	});

	// 8) Navigate to /commandes list — order should appear
	await test.step("liste des commandes contient la nouvelle", async () => {
		await page.goto("/commandes");
		await page.screenshot({ path: "test-results/08-commandes-list.png", fullPage: true });
		if (orderRef) {
			await expect(page.getByText(orderRef).first()).toBeVisible({ timeout: 10_000 });
		}
	});

	console.log("Console errors observed:", consoleErrors.length);
	for (const e of consoleErrors) console.log("  -", e);

	// Soft expectation: no JS errors during the run (don't fail the test on this — just log)
	if (consoleErrors.length > 0) {
		console.warn(`WARNING: ${consoleErrors.length} console errors during run`);
	}
});
