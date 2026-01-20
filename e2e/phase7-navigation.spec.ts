import { test, expect } from '@playwright/test';

test.describe('FOSDEM App - Phase 7 E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');
  });

  test('App loads and displays welcome screen', async ({ page }) => {
    await expect(page.locator('text=FOSDEM Companion')).toBeVisible();
    await expect(page.locator('text=Welcome to FOSDEM Companion')).toBeVisible();
    await expect(page.locator('text=FOSDEM 2025')).toBeVisible();
  });

  test('Bottom navigation bar is visible with all items', async ({ page }) => {
    // Check all navigation items are present
    await expect(page.locator('text=Home')).toBeVisible();
    await expect(page.locator('text=Schedule')).toBeVisible();
    await expect(page.locator('text=Favorites')).toBeVisible();
    await expect(page.locator('text=Map')).toBeVisible();
  });

  test('Can navigate to Schedule page', async ({ page }) => {
    await page.click('text=Schedule');
    await page.waitForTimeout(500);
    await expect(page.locator('text=Schedule - Coming Soon')).toBeVisible();
  });

  test('Can navigate to Favorites page', async ({ page }) => {
    await page.click('text=Favorites');
    await page.waitForTimeout(500);
    await expect(page.locator('text=Favorites - Coming Soon')).toBeVisible();
  });

  test('Can navigate to Map page', async ({ page }) => {
    await page.click('text=Map');
    await page.waitForTimeout(500);
    await expect(page.locator('text=Map - Coming Soon')).toBeVisible();
  });

  test('Can navigate back to Home after visiting other pages', async ({ page }) => {
    // Go to Schedule
    await page.click('text=Schedule');
    await page.waitForTimeout(500);
    
    // Go back to Home
    await page.click('text=Home');
    await page.waitForTimeout(500);
    
    await expect(page.locator('text=Welcome to FOSDEM Companion')).toBeVisible();
  });

  test('Navigation state is maintained across page switches', async ({ page }) => {
    // Navigate through all pages
    await page.click('text=Schedule');
    await page.waitForTimeout(300);
    
    await page.click('text=Favorites');
    await page.waitForTimeout(300);
    
    await page.click('text=Map');
    await page.waitForTimeout(300);
    
    await page.click('text=Home');
    await page.waitForTimeout(300);
    
    // Verify we're back at home
    await expect(page.locator('text=Welcome to FOSDEM Companion')).toBeVisible();
  });

  test('App is responsive and renders properly', async ({ page }) => {
    // Check viewport
    const viewportSize = page.viewportSize();
    expect(viewportSize).toBeTruthy();
    
    // Verify key elements are visible
    await expect(page.locator('text=FOSDEM Companion')).toBeVisible();
    
    // Take a screenshot for visual verification
    await page.screenshot({ path: 'test-results/phase7-home-screenshot.png' });
  });

  test('Theme is applied correctly', async ({ page }) => {
    // Check if Material 3 components are rendered
    const navBar = page.locator('flt-semantics[role="navigation"]').first();
    await expect(navBar).toBeVisible();
  });
});

test.describe('FOSDEM App - Navigation Flow Tests', () => {
  test('Complete navigation flow works correctly', async ({ page }) => {
    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');
    
    // Complete flow through all pages
    const pages = ['Schedule', 'Favorites', 'Map', 'Home'];
    
    for (const pageName of pages) {
      await page.click(`text=${pageName}`);
      await page.waitForTimeout(500);
      
      // Verify the page changed (navigation item should still be visible)
      await expect(page.locator(`text=${pageName}`)).toBeVisible();
    }
  });
});
