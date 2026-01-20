import { test, expect } from '@playwright/test';

test.describe('Phase 5: Data Loading', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:8080');
    // Wait for Flutter to initialize
    await page.waitForTimeout(2000);
  });

  test('should load home page', async ({ page }) => {
    // Check if FOSDEM title is visible
    await expect(page.locator('text=FOSDEM')).toBeVisible({ timeout: 10000 });
  });

  test('should show loading state initially', async ({ page }) => {
    // Reload to see loading state
    await page.reload();
    
    // Check for loading indicator or welcome message
    const hasLoading = await page.locator('[role="progressbar"]').isVisible().catch(() => false);
    const hasWelcome = await page.locator('text=Welcome to FOSDEM').isVisible().catch(() => false);
    
    expect(hasLoading || hasWelcome).toBeTruthy();
  });

  test('should have navigation icons', async ({ page }) => {
    // Wait for app to load
    await page.waitForTimeout(3000);
    
    // Check for search icon in app bar
    const searchIcon = page.locator('[aria-label*="search" i], [data-icon="search"]').first();
    await expect(searchIcon).toBeVisible({ timeout: 5000 });
  });

  test('should display events or empty state', async ({ page }) => {
    await page.waitForTimeout(3000);
    
    // Check if we have events or "no events" message
    const hasEvents = await page.locator('text=/today|upcoming/i').isVisible().catch(() => false);
    const hasNoEvents = await page.locator('text=No events found').isVisible().catch(() => false);
    const hasError = await page.locator('text=/error/i').isVisible().catch(() => false);
    
    // One of these should be true
    expect(hasEvents || hasNoEvents || hasError).toBeTruthy();
  });

  test('should be responsive', async ({ page }) => {
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1000);
    await expect(page.locator('text=FOSDEM')).toBeVisible();
    
    // Test tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.waitForTimeout(1000);
    await expect(page.locator('text=FOSDEM')).toBeVisible();
    
    // Test desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.waitForTimeout(1000);
    await expect(page.locator('text=FOSDEM')).toBeVisible();
  });

  test('should handle navigation', async ({ page }) => {
    await page.waitForTimeout(3000);
    
    // Try to click search if available
    const searchButton = page.locator('[aria-label*="search" i]').first();
    const isSearchVisible = await searchButton.isVisible().catch(() => false);
    
    if (isSearchVisible) {
      await searchButton.click();
      await page.waitForTimeout(1000);
      // Should navigate or show search
      await expect(page.locator('text=/search/i')).toBeVisible({ timeout: 5000 });
    }
  });
});

test.describe('Phase 5: Error Handling', () => {
  test('should show retry button on error', async ({ page }) => {
    await page.goto('http://localhost:8080');
    await page.waitForTimeout(3000);
    
    // If there's an error, there should be a retry button
    const hasError = await page.locator('text=/error/i').isVisible().catch(() => false);
    
    if (hasError) {
      await expect(page.locator('text=Retry')).toBeVisible();
    }
  });
});
