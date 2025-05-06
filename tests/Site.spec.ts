import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('http://localhost:9292/');
});

test('has Rods And Cods title', async ({ page }) => {
  await page.goto('http://localhost:9292/');
  

  await expect(page).toHaveTitle(/Rods and Cods/);
});

test('Klicka på Bass, testa att beskrivning finns, gå tillbaks till produktsidan', async ({ page }) => {
  await page.getByRole('link', { name: 'Bass' }).click();
  

  await expect(page.getByText('Ergonomic')).toBeVisible();

  await page.getByRole('link', { name: 'Rods and Cods' }).click();
  
});

test('Logga in som admin, lägg till en produkt och testa så den finns i listan på förstasidan sedan ta bort den ', async ({ page }) => {
  await page.getByRole('link', { name: 'Login' }).click();

  await page.fill('input[name="username"]', 'admin');
  await page.fill('input[name="password"]', '123');
  await page.locator('button:text("Login")').click();

  const article = crypto.randomUUID();
  const value = '100.0'
  const description = crypto.randomUUID();
  const SKU = crypto.randomUUID();
  
  await page.fill('input[name="article"]', article);
  await page.fill('input[name="value"]', value);
  await page.fill('input[name="description"]', description);
  await page.fill('input[name="SKU"]', SKU);
  await page.getByLabel('Category').selectOption('rods');

  await page.click('input[type="submit"]');

  await expect(page.getByText(article)).toBeVisible();

  const articleCard = await page.locator('.product-card', {
    has: page.locator('h3', { hasText: article })
  });

  await articleCard.locator('form.delete >> input[type="submit"]').click();

  await expect(page.getByText(article)).not.toBeAttached();
});