#!/bin/bash
set -euo pipefail

# Kalos Import — Headless Browser Capture
# Captures a URL via Puppeteer or Playwright when Chrome MCP is unavailable.
# Outputs: screenshot.png + dom.html + styles.json to output directory.
#
# Usage: capture.sh <url> <output-dir>
#        capture.sh --check   (verify browser tool availability)
#        capture.sh --help

# Allow injection for testing
NPX_CMD="${CAPTURE_NPX_CMD:-npx}"

usage() {
  cat <<'EOF'
Usage: capture.sh <url> <output-dir>
       capture.sh --check
       capture.sh --help

Captures a web page using Puppeteer or Playwright (headless).
Outputs screenshot.png, dom.html, and styles.json to <output-dir>.

Options:
  --check   Check which headless browser is available
  --help    Show this help message
EOF
}

detect_browser() {
  if $NPX_CMD --yes puppeteer --version >/dev/null 2>&1; then
    echo "puppeteer"
    return 0
  elif $NPX_CMD --yes playwright --version >/dev/null 2>&1; then
    echo "playwright"
    return 0
  fi
  return 1
}

# Handle flags
if [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "${1:-}" = "--check" ]; then
  BROWSER=$(detect_browser) || { echo "No headless browser available. Install puppeteer or playwright."; exit 2; }
  echo "Available: $BROWSER"
  exit 0
fi

# Validate arguments
if [ $# -lt 2 ]; then
  usage
  exit 1
fi

URL="$1"
OUTPUT_DIR="$2"

# Validate URL
if [[ ! "$URL" =~ ^https?:// ]]; then
  echo "Invalid URL: $URL (must start with http:// or https://)"
  exit 1
fi

# Validate output directory parent exists
OUTPUT_PARENT=$(dirname "$OUTPUT_DIR")
if [ ! -d "$OUTPUT_PARENT" ]; then
  echo "Output directory parent does not exist: $OUTPUT_PARENT"
  exit 1
fi

# Create output dir if needed
mkdir -p "$OUTPUT_DIR"

# Detect browser
BROWSER=$(detect_browser) || {
  echo "No headless browser available. Install with: npm install -g puppeteer"
  exit 2
}

# Generate capture script based on detected browser
if [ "$BROWSER" = "puppeteer" ]; then
  CAPTURE_SCRIPT=$(cat <<'SCRIPT'
const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });
  await page.goto(process.argv[2], { waitUntil: 'networkidle0', timeout: 30000 });

  // Screenshot
  await page.screenshot({ path: process.argv[3] + '/screenshot.png', fullPage: true });

  // DOM
  const html = await page.content();
  require('fs').writeFileSync(process.argv[3] + '/dom.html', html);

  // Computed styles for all visible elements
  const styles = await page.evaluate(() => {
    const elements = document.querySelectorAll('*');
    const result = [];
    elements.forEach(el => {
      const computed = window.getComputedStyle(el);
      const rect = el.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) {
        result.push({
          tag: el.tagName.toLowerCase(),
          classes: el.className,
          rect: { x: rect.x, y: rect.y, w: rect.width, h: rect.height },
          styles: {
            color: computed.color,
            backgroundColor: computed.backgroundColor,
            fontFamily: computed.fontFamily,
            fontSize: computed.fontSize,
            fontWeight: computed.fontWeight,
            padding: computed.padding,
            margin: computed.margin,
            gap: computed.gap,
            borderRadius: computed.borderRadius,
            display: computed.display,
            flexDirection: computed.flexDirection,
          }
        });
      }
    });
    return result;
  });
  require('fs').writeFileSync(
    process.argv[3] + '/styles.json',
    JSON.stringify(styles, null, 2)
  );

  await browser.close();
  console.log('Captured: screenshot.png, dom.html, styles.json');
})();
SCRIPT
  )
  node -e "$CAPTURE_SCRIPT" -- "$URL" "$OUTPUT_DIR"

elif [ "$BROWSER" = "playwright" ]; then
  CAPTURE_SCRIPT=$(cat <<'SCRIPT'
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  await page.goto(process.argv[2], { waitUntil: 'networkidle', timeout: 30000 });

  await page.screenshot({ path: process.argv[3] + '/screenshot.png', fullPage: true });

  const html = await page.content();
  require('fs').writeFileSync(process.argv[3] + '/dom.html', html);

  const styles = await page.evaluate(() => {
    const elements = document.querySelectorAll('*');
    const result = [];
    elements.forEach(el => {
      const computed = window.getComputedStyle(el);
      const rect = el.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) {
        result.push({
          tag: el.tagName.toLowerCase(),
          classes: el.className,
          rect: { x: rect.x, y: rect.y, w: rect.width, h: rect.height },
          styles: {
            color: computed.color,
            backgroundColor: computed.backgroundColor,
            fontFamily: computed.fontFamily,
            fontSize: computed.fontSize,
            fontWeight: computed.fontWeight,
            padding: computed.padding,
            margin: computed.margin,
            gap: computed.gap,
            borderRadius: computed.borderRadius,
            display: computed.display,
            flexDirection: computed.flexDirection,
          }
        });
      }
    });
    return result;
  });
  require('fs').writeFileSync(
    process.argv[3] + '/styles.json',
    JSON.stringify(styles, null, 2)
  );

  await browser.close();
  console.log('Captured: screenshot.png, dom.html, styles.json');
})();
SCRIPT
  )
  node -e "$CAPTURE_SCRIPT" -- "$URL" "$OUTPUT_DIR"
fi

echo "Output: $OUTPUT_DIR"
