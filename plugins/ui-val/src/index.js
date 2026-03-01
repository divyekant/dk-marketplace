import { captureUrl, cleanupScreenshots } from './capture.js';
import { VIEWPORTS } from './config.js';

export { cleanupScreenshots };

/**
 * Capture screenshots and metadata. No API calls — the agent evaluates visually.
 * @param {string} url - URL to validate
 * @param {object} options - CLI options
 * @returns {Promise<string>} JSON with screenshot paths + metadata
 */
export async function capture(url, options = {}) {
  // Parse viewports
  const viewports = options.viewports
    ? options.viewports.split(',').map((v) => v.trim())
    : Object.keys(VIEWPORTS);

  // Validate viewport names
  for (const v of viewports) {
    if (!VIEWPORTS[v]) {
      throw new Error(`Unknown viewport "${v}". Available: ${Object.keys(VIEWPORTS).join(', ')}`);
    }
  }

  // Preflight: check URL is reachable (HEAD first, fall back to GET)
  try {
    let res = await fetch(url, { method: 'HEAD', signal: AbortSignal.timeout(10000) });
    if (res.status === 405 || res.status === 501) {
      res = await fetch(url, { method: 'GET', signal: AbortSignal.timeout(10000) });
    }
    if (!res.ok && res.status !== 304) {
      throw new Error(`HTTP ${res.status}`);
    }
  } catch (err) {
    throw new Error(
      `Cannot reach ${url} — ${err.message}. Is the dev server running?`
    );
  }

  // Capture screenshots
  const captures = await captureUrl(url, {
    viewports,
    wait: options.wait ? parseInt(options.wait, 10) : undefined,
    fullPage: options.fullPage,
    screenshotDir: options.screenshotDir,
  });

  // Build result (no vision analysis — agent will read screenshots directly)
  const result = {
    url,
    timestamp: new Date().toISOString(),
    viewports: {},
    consoleErrors: [],
  };

  for (const cap of captures) {
    result.viewports[cap.viewport] = {
      screenshot: cap.screenshotPath,
      size: cap.size,
      domMetrics: cap.domMetrics,
    };
    for (const err of cap.consoleErrors) {
      result.consoleErrors.push(`[${cap.viewport}] ${err}`);
    }
  }

  return JSON.stringify(result, null, 2);
}
