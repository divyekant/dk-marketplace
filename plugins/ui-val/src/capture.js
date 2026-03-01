import { chromium } from 'playwright';
import { VIEWPORTS, DEFAULTS } from './config.js';
import { mkdir, writeFile, unlink, readdir, rm } from 'node:fs/promises';
import { join } from 'node:path';

/**
 * Capture screenshots at specified viewports, collecting console errors and DOM metrics.
 * @param {string} url - The URL to capture
 * @param {object} options - { viewports, wait, fullPage, screenshotDir }
 * @returns {Promise<Array<{viewport: string, size: object, screenshot: Buffer, consoleErrors: string[], domMetrics: object}>>}
 */
export async function captureUrl(url, options = {}) {
  const viewportNames = options.viewports || Object.keys(VIEWPORTS);
  const wait = options.wait ?? DEFAULTS.wait;
  const fullPage = options.fullPage ?? DEFAULTS.fullPage;
  const screenshotDir = options.screenshotDir ?? DEFAULTS.screenshotDir;

  // Ensure screenshot directory exists
  await mkdir(screenshotDir, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const results = [];

  try {
    for (const name of viewportNames) {
      const size = VIEWPORTS[name];
      if (!size) {
        throw new Error(`Unknown viewport: ${name}. Available: ${Object.keys(VIEWPORTS).join(', ')}`);
      }

      const context = await browser.newContext({ viewport: size });
      const page = await context.newPage();

      // Collect console errors
      const consoleErrors = [];
      page.on('console', (msg) => {
        if (msg.type() === 'error' || msg.type() === 'warning') {
          consoleErrors.push(`[${msg.type()}] ${msg.text()}`);
        }
      });
      page.on('pageerror', (err) => {
        consoleErrors.push(`[pageerror] ${err.message}`);
      });

      // Navigate
      await page.goto(url, {
        waitUntil: 'networkidle',
        timeout: DEFAULTS.timeout,
      });

      // Wait for SPA rendering
      if (wait > 0) {
        await page.waitForTimeout(wait);
      }

      // Capture screenshot
      const screenshot = await page.screenshot({ fullPage });

      // Save to disk
      const filename = `${name}-latest.png`;
      await writeFile(join(screenshotDir, filename), screenshot);

      // Collect DOM metrics
      const domMetrics = await page.evaluate(() => {
        const allElements = document.querySelectorAll('*');
        const images = document.querySelectorAll('img');
        const brokenImages = [...images].filter(
          (img) => !img.complete || img.naturalWidth === 0
        ).length;

        const bodyHtml = document.body?.innerHTML?.trim() || '';
        const visibleText = document.body?.innerText?.length || 0;

        return {
          totalElements: allElements.length,
          brokenImages,
          visibleTextLength: visibleText,
          bodyEmpty: bodyHtml.length < 100,
          title: document.title || '(no title)',
        };
      });

      results.push({
        viewport: name,
        size,
        screenshot,
        screenshotPath: join(screenshotDir, filename),
        consoleErrors,
        domMetrics,
      });

      await context.close();
    }
  } finally {
    await browser.close();
  }

  return results;
}

/**
 * Clean up screenshot files after evaluation is complete.
 * @param {string} screenshotDir - Directory to clean (default: DEFAULTS.screenshotDir)
 */
export async function cleanupScreenshots(screenshotDir = DEFAULTS.screenshotDir) {
  try {
    const files = await readdir(screenshotDir);
    const pngs = files.filter((f) => f.endsWith('.png'));
    await Promise.all(pngs.map((f) => unlink(join(screenshotDir, f))));
    return { deleted: pngs.length, files: pngs };
  } catch (err) {
    if (err.code === 'ENOENT') return { deleted: 0, files: [] };
    throw err;
  }
}
