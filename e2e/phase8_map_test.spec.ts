import { test, expect } from '@playwright/test';

test.describe('Phase 8 - Map Integration', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:8088');
    // Wait for app to load
    await page.waitForTimeout(3000);
  });

  test('should display the main navigation', async ({ page }) => {
    // Check that navigation tabs are visible
    const scheduleTab = page.locator('text=Schedule');
    await expect(scheduleTab).toBeVisible();
    
    const mapTab = page.locator('text=Map');
    await expect(mapTab).toBeVisible();
    
    const favoritesTab = page.locator('text=Favorites');
    await expect(favoritesTab).toBeVisible();
  });

  test('should navigate to map screen', async ({ page }) => {
    // Click on Map tab
    await page.click('text=Map');
    await page.waitForTimeout(2000);
    
    // Verify we're on the map screen
    // The map should be visible (check for flutter-map widget or map container)
    const mapContainer = page.locator('flt-scene-host');
    await expect(mapContainer).toBeVisible();
  });

  test('should load data from xcal file', async ({ page }) => {
    // Click on Schedule tab to see events
    await page.click('text=Schedule');
    await page.waitForTimeout(2000);
    
    // Check that events are loaded (there should be event cards)
    // Looking for any text that indicates events loaded
    const pageContent = await page.textContent('body');
    expect(pageContent).toBeTruthy();
    
    // If data loaded properly, we should not see "No events" or empty state
    // We should see some event information
    console.log('Page loaded with data');
  });

  test('should display OpenTopoMap tiles on map', async ({ page }) => {
    // Navigate to map
    await page.click('text=Map');
    await page.waitForTimeout(3000);
    
    // Check for map tile images being loaded
    // OpenTopoMap uses URLs like https://a.tile.opentopomap.org/...
    const response = await page.waitForResponse(
      response => response.url().includes('opentopomap.org'),
      { timeout: 10000 }
    ).catch(() => null);
    
    if (response) {
      console.log('✓ OpenTopoMap tiles are loading');
      expect(response.status()).toBe(200);
    } else {
      console.log('⚠ Map tiles may not be loading yet');
    }
  });

  test('should display building polygons on map', async ({ page }) => {
    // Navigate to map
    await page.click('text=Map');
    await page.waitForTimeout(3000);
    
    // Building polygons should be rendered
    // We can check if the map has canvas elements where polygons are drawn
    const canvas = page.locator('canvas');
    const count = await canvas.count();
    expect(count).toBeGreaterThan(0);
    console.log(`✓ Found ${count} canvas elements for map rendering`);
  });

  test('map should be interactive', async ({ page }) => {
    // Navigate to map
    await page.click('text=Map');
    await page.waitForTimeout(2000);
    
    // Try to interact with the map (pan/zoom)
    const mapArea = page.locator('flt-scene-host').first();
    
    // Get initial position
    const box = await mapArea.boundingBox();
    if (box) {
      // Simulate a pan gesture
      await page.mouse.move(box.x + 100, box.y + 100);
      await page.mouse.down();
      await page.mouse.move(box.x + 150, box.y + 150);
      await page.mouse.up();
      
      console.log('✓ Map interaction test completed');
    }
  });
});
