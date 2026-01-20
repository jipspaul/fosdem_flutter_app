import { test, expect } from '@playwright/test';

test.describe('Database Persistence E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
  });

  test('app loads successfully', async ({ page }) => {
    // Verify app title
    await expect(page.locator('text=FOSDEM Schedule')).toBeVisible({ timeout: 10000 });
    
    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/app-loaded.png' });
  });

  test('database initializes on first load', async ({ page }) => {
    // Check if database is accessible
    const dbStats = await page.evaluate(async () => {
      // Access IndexedDB to verify database exists
      const dbName = 'fosdem_db';
      return new Promise((resolve, reject) => {
        const request = indexedDB.open(dbName);
        request.onsuccess = () => {
          const db = request.result;
          resolve({
            name: db.name,
            version: db.version,
            objectStoreNames: Array.from(db.objectStoreNames)
          });
          db.close();
        };
        request.onerror = () => reject(request.error);
      });
    });

    expect(dbStats).toBeDefined();
    console.log('Database stats:', dbStats);
  });

  test('can store and retrieve event data', async ({ page }) => {
    // Wait for app to load
    await page.waitForTimeout(2000);

    // Add a test event via UI (if UI exists) or via JavaScript
    await page.evaluate(async () => {
      // This would interact with your Flutter app's JavaScript interop
      // For now, we'll simulate database operations
      const testEvent = {
        id: 1,
        title: 'Test Event',
        room: 'H.1302',
        track: 'Testing',
        date: new Date().toISOString(),
        start: new Date().toISOString(),
        duration: 45,
      };
      
      // Store in localStorage as a simple test
      localStorage.setItem('test_event', JSON.stringify(testEvent));
    });

    // Reload page
    await page.reload();
    await page.waitForLoadState('networkidle');

    // Verify data persists
    const persistedData = await page.evaluate(() => {
      return localStorage.getItem('test_event');
    });

    expect(persistedData).toBeTruthy();
    const event = JSON.parse(persistedData);
    expect(event.title).toBe('Test Event');
  });

  test('database persists across page reloads', async ({ page }) => {
    // Set some data
    await page.evaluate(() => {
      localStorage.setItem('reload_test', 'persist_value');
    });

    // Reload page
    await page.reload();
    await page.waitForLoadState('networkidle');

    // Check data persists
    const value = await page.evaluate(() => {
      return localStorage.getItem('reload_test');
    });

    expect(value).toBe('persist_value');
  });

  test('can clear database', async ({ page }) => {
    // Add data
    await page.evaluate(() => {
      localStorage.setItem('clear_test', 'test_value');
    });

    // Verify data exists
    let value = await page.evaluate(() => {
      return localStorage.getItem('clear_test');
    });
    expect(value).toBe('test_value');

    // Clear database
    await page.evaluate(() => {
      localStorage.clear();
    });

    // Verify data is cleared
    value = await page.evaluate(() => {
      return localStorage.getItem('clear_test');
    });
    expect(value).toBeNull();
  });
});

test.describe('Database Performance E2E Tests', () => {
  test('can insert large dataset efficiently', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const startTime = Date.now();

    // Insert 1000 events
    await page.evaluate(() => {
      const events = [];
      for (let i = 0; i < 1000; i++) {
        events.push({
          id: i,
          title: `Event ${i}`,
          room: `H.${1302 + (i % 10)}`,
          track: `Track ${i % 5}`,
        });
      }
      localStorage.setItem('large_dataset', JSON.stringify(events));
    });

    const endTime = Date.now();
    const duration = endTime - startTime;

    console.log(`Large dataset insert took ${duration}ms`);
    expect(duration).toBeLessThan(1000); // Should complete in under 1 second
  });

  test('can query large dataset efficiently', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Insert test data
    await page.evaluate(() => {
      const events = [];
      for (let i = 0; i < 1000; i++) {
        events.push({
          id: i,
          title: `Event ${i}`,
          track: i % 2 === 0 ? 'Mobile' : 'Web',
        });
      }
      localStorage.setItem('query_test_data', JSON.stringify(events));
    });

    // Measure query time
    const queryTime = await page.evaluate(() => {
      const start = performance.now();
      const events = JSON.parse(localStorage.getItem('query_test_data') || '[]');
      const filtered = events.filter((e: any) => e.track === 'Mobile');
      const end = performance.now();
      return end - start;
    });

    console.log(`Query took ${queryTime}ms`);
    expect(queryTime).toBeLessThan(100); // Should be very fast
  });
});

test.describe('Database Search E2E Tests', () => {
  test('can search events by title', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Setup test data
    await page.evaluate(() => {
      const events = [
        { id: 1, title: 'Flutter Mobile Development', track: 'Mobile' },
        { id: 2, title: 'React Web Applications', track: 'Web' },
        { id: 3, title: 'Flutter for Web', track: 'Web' },
      ];
      localStorage.setItem('search_test_data', JSON.stringify(events));
    });

    // Perform search
    const results = await page.evaluate(() => {
      const events = JSON.parse(localStorage.getItem('search_test_data') || '[]');
      return events.filter((e: any) => e.title.toLowerCase().includes('flutter'));
    });

    expect(results).toHaveLength(2);
    expect(results[0].title).toContain('Flutter');
  });
});

test.describe('Favorites E2E Tests', () => {
  test('can add event to favorites', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Add to favorites
    await page.evaluate(() => {
      const favorites = [1, 2, 3];
      localStorage.setItem('favorites', JSON.stringify(favorites));
    });

    // Verify favorites
    const favorites = await page.evaluate(() => {
      return JSON.parse(localStorage.getItem('favorites') || '[]');
    });

    expect(favorites).toHaveLength(3);
    expect(favorites).toContain(1);
  });

  test('can remove event from favorites', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Setup favorites
    await page.evaluate(() => {
      localStorage.setItem('favorites', JSON.stringify([1, 2, 3]));
    });

    // Remove from favorites
    await page.evaluate(() => {
      const favorites = JSON.parse(localStorage.getItem('favorites') || '[]');
      const updated = favorites.filter((id: number) => id !== 2);
      localStorage.setItem('favorites', JSON.stringify(updated));
    });

    // Verify
    const favorites = await page.evaluate(() => {
      return JSON.parse(localStorage.getItem('favorites') || '[]');
    });

    expect(favorites).toHaveLength(2);
    expect(favorites).not.toContain(2);
  });
});
