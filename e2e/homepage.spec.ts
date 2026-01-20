import { test, expect } from '@playwright/test';

test.describe('FOSDEM App - Basic Tests', () => {
  test('homepage loads successfully', async ({ page }) => {
    await page.goto('/');
    
    // Wait for Flutter app to load
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // Check that the page has loaded - title should be "FOSDEM"
    const title = await page.title();
    expect(title).toContain('FOSDEM');
  });

  test('app initializes without critical errors', async ({ page }) => {
    const errors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });
    
    await page.goto('/');
    await page.waitForLoadState('load');
    await page.waitForTimeout(3000);
    
    // No critical errors should occur (ignore common benign errors)
    const criticalErrors = errors.filter(e => 
      !e.includes('404') && 
      !e.includes('favicon') &&
      !e.includes('DevTools') &&
      !e.includes('manifest')
    );
    expect(criticalErrors.length).toBe(0);
  });

  test('flutter app element exists', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('load');
    await page.waitForTimeout(2000);
    
    // Check for flutter-view or flt-glass-pane elements
    const flutterElements = await page.locator('flt-glass-pane, flutter-view, [flt-renderer]').count();
    expect(flutterElements).toBeGreaterThan(0);
  });
});
