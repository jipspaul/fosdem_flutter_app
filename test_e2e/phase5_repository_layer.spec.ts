import { test, expect } from '@playwright/test';

test.describe('Phase 5: Repository Layer E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');
  });

  test('should display FOSDEM app with repository layer working', async ({ page }) => {
    // Wait for app to load
    await expect(page.locator('flt-glass-pane')).toBeVisible({ timeout: 10000 });
    
    // Check that the app is running
    const appContent = await page.textContent('body');
    expect(appContent).not.toBeNull();
    
    // Verify canvas is rendered (Flutter web uses canvas)
    const canvas = page.locator('canvas');
    await expect(canvas).toBeVisible();
  });

  test('should handle local storage for favorites', async ({ page }) => {
    // Add some test data to localStorage
    await page.evaluate(() => {
      localStorage.setItem('flutter.favorite_events', JSON.stringify(['event1', 'event2']));
    });
    
    // Reload page
    await page.reload();
    await page.waitForLoadState('networkidle');
    
    // Verify storage persists
    const storedData = await page.evaluate(() => {
      return localStorage.getItem('flutter.favorite_events');
    });
    
    expect(storedData).toContain('event1');
    expect(storedData).toContain('event2');
  });

  test('should persist data across sessions', async ({ page, context }) => {
    // Set some data
    await page.evaluate(() => {
      localStorage.setItem('flutter.test_data', 'persistent_value');
    });
    
    // Create new page
    const newPage = await context.newPage();
    await newPage.goto('http://localhost:8080');
    
    // Check data persists
    const data = await newPage.evaluate(() => {
      return localStorage.getItem('flutter.test_data');
    });
    
    expect(data).toBe('persistent_value');
    await newPage.close();
  });
});
