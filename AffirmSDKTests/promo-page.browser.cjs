// Headless Chrome checks for affirm_promo.html. Not a WKWebView substitute.
// PLAYWRIGHT_CORE=<path to playwright-core> node AffirmSDKTests/promo-page.browser.cjs
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { test, before, after } = require('node:test');

const playwrightPath = process.env.PLAYWRIGHT_CORE;
if (!playwrightPath) {
    throw new Error('Set PLAYWRIGHT_CORE to the playwright-core package directory');
}
const { chromium } = require(playwrightPath);

const BUNDLE = path.resolve(__dirname, '../AffirmSDK/AffirmSDK.bundle');
const TEMPLATE = fs.readFileSync(path.join(BUNDLE, 'affirm_promo.html'), 'utf8');
const SANITIZER = fs.readFileSync(path.join(BUNDLE, 'purify.min.js'), 'utf8');
const BADGE_CSS = fs.readFileSync(path.join(BUNDLE, 'badge_styles.css'), 'utf8');
const CHROME_PATH = process.env.CHROME_PATH
    || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PAGE_URL = 'https://promo.test/';
const PNG_1X1 = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
    'base64');

let browser;

before(async () => {
    browser = await chromium.launch({ executablePath: CHROME_PATH, headless: true });
});

after(async () => {
    await browser.close();
});

function fillTemplate({ html, remoteCss = '', remoteFont = '', extraCss = '', timeoutMs = 5000 }) {
    const payload = {
        renderId: 'test-render',
        html,
        remoteCssURL: remoteCss,
        remoteFontURL: remoteFont,
        publicKey: 'test_key',
        jsURL: 'https://cdn.test/affirm.js',
        locale: 'en_US',
        countryCode: 'USA',
        bundledCSS: BADGE_CSS + extraCss,
        timeoutMs,
    };
    const json = JSON.stringify(payload).replace(/</g, '\\u003c').replace(/>/g, '\\u003e');
    return TEMPLATE.split('{{AFFIRM_PROMO_PAYLOAD}}').join(json);
}

async function render({
    html, remoteCss = '', remoteFont = '', extraCss = '', sanitizer = SANITIZER,
    resources = {}, hang = [], width = 360, waitMs = 3000, timeoutMs = 5000,
}) {
    const page = await browser.newPage();
    await page.setViewportSize({ width, height: 640 });
    const filled = fillTemplate({ html, remoteCss, remoteFont, extraCss, timeoutMs });
    await page.route('**/*', (route) => {
        const url = route.request().url();
        if (url === PAGE_URL) {
            return route.fulfill({ contentType: 'text/html', body: filled });
        }
        if (hang.includes(url)) {
            return undefined;
        }
        if (resources[url]) {
            return route.fulfill({ contentType: resources[url].type, body: resources[url].body });
        }
        if (url.startsWith('data:')) {
            return route.continue();
        }
        return route.abort();
    });
    await page.addInitScript(() => {
        window.hostCalls = [];
        window.sanitized = null;
        window.webkit = {
            messageHandlers: {
                affirmPromo: {
                    postMessage: (body) => {
                        if (body.event === 'sanitized') {
                            window.sanitized = body.usable;
                        } else {
                            window.hostCalls.push(body);
                        }
                    },
                },
            },
        };
    });
    if (sanitizer) {
        await page.addInitScript({ content: sanitizer });
    }
    await page.goto(PAGE_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => window.hostCalls.length > 0, null, { timeout: waitMs });
    const calls = await page.evaluate(() => window.hostCalls);
    const rootHtml = await page.$eval('#affirm-promo-root', (root) => root.innerHTML);
    const sanitized = await page.evaluate(() => window.sanitized);
    return { page, calls, rootHtml, sanitized };
}

function failureReason(calls) {
    const failure = calls.find((call) => call.event === 'failure');
    return failure && failure.reason;
}

test('script breakout, unsafe URLs, handlers and clobbering are removed', async () => {
    const { page, calls, rootHtml, sanitized } = await render({
        html: '<span class="affirm-ala-price">$50/mo</span>'
            + '<img src="x" onerror="window.pwned=1"><script>window.pwned=2</script>'
            + '<a href="javascript:alert(1)">js</a><a href="http://evil.test">http</a>'
            + '<a href="https://ok.test">ok</a>'
            + '<form id="AffirmPromoHost"><input name="onReady"></form>'
            + '<span style="color:red" id="clobber" name="n" aria-label="y">s</span>'
            + '<iframe src="https://frame.test"></iframe><img src="data:image/png;base64,AA">'
            + '</p></script><script>window.pwned=3</script>',
    });
    assert.equal(await page.evaluate(() => window.pwned), undefined);
    assert.equal(await page.$$eval('#affirm-promo-root', (roots) => roots.length), 1);
    assert.match(rootHtml, /class="affirm-ala-price"/);
    assert.match(rootHtml, /href="https:\/\/ok\.test"/);
    assert.doesNotMatch(rootHtml, /javascript:|http:\/\/evil|<script|<iframe|<form|<input/);
    assert.doesNotMatch(rootHtml, /style=|id=|name=|aria-|on\w+=/);
    assert.doesNotMatch(rootHtml, /src="x"|data:image/);
    assert.equal(calls[0].event, 'ready');
    assert.equal(sanitized, true);
    await page.close();
});

test('http stylesheet URLs fail and are not requested', async () => {
    const { page, calls } = await render({
        html: '<span>ok</span>',
        remoteCss: 'http://merchant.test/a.css',
        remoteFont: 'http://fonts.test/font.css',
    });
    assert.equal(failureReason(calls), 'resource_failed');
    assert.equal(await page.evaluate(() => document.querySelector('link[href^="http://"]')), null);
    await page.close();
});

test('badge classes survive and merchant CSS of equal specificity overrides them', async () => {
    const badge = '<span class="__apr_badge __apr_badge_indigo">0% APR</span>';
    const badgeColor = (page) => page.$eval('.__apr_badge', (el) => getComputedStyle(el).color);

    const bundledOnly = await render({ html: badge });
    assert.equal(bundledOnly.calls[0].event, 'ready');
    assert.equal(await badgeColor(bundledOnly.page), 'rgb(66, 66, 207)');
    await bundledOnly.page.close();

    const withMerchant = await render({
        html: badge,
        remoteCss: 'https://merchant.test/promo.css',
        resources: {
            'https://merchant.test/promo.css': {
                type: 'text/css',
                body: '.__apr_badge.__apr_badge_indigo{color:rgb(1, 2, 3)}',
            },
        },
    });
    assert.equal(withMerchant.calls[0].event, 'ready');
    assert.equal(await badgeColor(withMerchant.page), 'rgb(1, 2, 3)');
    await withMerchant.page.close();
});

test('remote CSS URL with a quote cannot inject attributes', async () => {
    const { page, calls } = await render({
        html: '<span>ok</span>',
        remoteCss: 'https://merchant.test/a.css" onload="window.pwned=7',
    });
    assert.equal(failureReason(calls), 'resource_failed');
    assert.equal(await page.evaluate(() => window.pwned), undefined);
    await page.close();
});

test('sanitizer missing or unsupported fails closed', async () => {
    const { page, calls, rootHtml, sanitized } = await render({
        html: '<span>ok</span>',
        sanitizer: '',
    });
    assert.equal(failureReason(calls), 'sanitizer_unavailable');
    assert.equal(rootHtml, '');
    assert.equal(sanitized, null);
    await page.close();
});

test('content that is empty after sanitizing fails', async () => {
    const { page, calls, sanitized } = await render({ html: '<script>window.pwned=6</script>' });
    assert.equal(failureReason(calls), 'html_empty');
    assert.equal(sanitized, false);
    await page.close();

    const strippedImg = await render({ html: '<img src="javascript:alert(1)" onerror="window.pwned=8">' });
    assert.equal(failureReason(strippedImg.calls), 'html_empty');
    assert.equal(strippedImg.sanitized, false);
    await strippedImg.page.close();
});

test('remote CSS, font CSS and image load errors fail', async () => {
    const css = await render({ html: '<span>ok</span>', remoteCss: 'https://merchant.test/missing.css' });
    assert.equal(failureReason(css.calls), 'resource_failed');
    await css.page.close();

    const fontCss = await render({
        html: '<span>ok</span>',
        remoteFont: 'https://fonts.test/missing.css',
    });
    assert.equal(failureReason(fontCss.calls), 'resource_failed');
    await fontCss.page.close();

    const image = await render({ html: '<img src="https://cdn.test/missing.png">' });
    assert.equal(failureReason(image.calls), 'image_failed');
    await image.page.close();

    const decodedButBroken = await render({
        html: '<span>ok</span><img src="https://cdn.test/not-an-image.png">',
        resources: {
            'https://cdn.test/not-an-image.png': { type: 'image/png', body: 'not-a-png' },
        },
    });
    assert.equal(failureReason(decodedButBroken.calls), 'image_failed');
    await decodedButBroken.page.close();
});

test('required resources that never settle fail with html_timeout', { timeout: 10000 }, async () => {
    const { page, calls } = await render({
        html: '<span>ok</span>',
        remoteCss: 'https://merchant.test/hang.css',
        hang: ['https://merchant.test/hang.css'],
        waitMs: 7000,
    });
    assert.equal(failureReason(calls), 'html_timeout');
    await page.close();
});

test('ready waits for images and reports the content height', async () => {
    const { page, calls } = await render({
        html: '<span>ok</span><img src="https://cdn.test/logo.png" width="10" height="40">',
        resources: { 'https://cdn.test/logo.png': { type: 'image/png', body: PNG_1X1 } },
    });
    assert.equal(calls[0].event, 'ready');
    assert.ok(calls[0].height >= 40 && calls[0].height < 200,
        `height ${calls[0].height} should follow the promo root, not the viewport`);
    await page.close();
});

test('long and localized text wraps inside the view and reports height changes', async () => {
    const longText = 'Paga en cuotas mensuales con Affirm 月々のお支払い '.repeat(12)
        + 'Supercalifragilisticexpialidocious'.repeat(4);
    const { page, calls } = await render({
        html: `<span class="affirm-ala-price">${longText}</span>`,
        extraCss: '#affirm-promo-root{word-wrap:break-word;overflow-wrap:break-word;}',
        width: 240,
    });
    assert.equal(calls[0].event, 'ready');
    const widths = await page.evaluate(() => ({
        content: document.documentElement.scrollWidth,
        viewport: document.documentElement.clientWidth,
    }));
    assert.ok(widths.content <= widths.viewport, JSON.stringify(widths));
    const before = calls[0].height;
    await page.$eval('#affirm-promo-root', (root) => { root.style.paddingBottom = '200px'; });
    await page.waitForFunction(
        (initial) => window.hostCalls.some((call) => call.event === 'height' && call.height > initial),
        before,
        { timeout: 3000 });
    await page.close();
});
