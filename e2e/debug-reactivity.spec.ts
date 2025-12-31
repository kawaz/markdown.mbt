import { test, expect } from '@playwright/test';

test('editor reactivity', async ({ page }) => {
  await page.goto('/playground/');
  await page.waitForSelector('.editor-textarea');
  await page.waitForTimeout(1000);

  // Get textarea value
  const getTextareaValue = async () => {
    return page.evaluate(() => {
      const textarea = document.querySelector('.editor-textarea') as HTMLTextAreaElement;
      return textarea?.value?.slice(0, 50) || '';
    });
  };

  const initialValue = await getTextareaValue();
  console.log('Initial textarea value:', initialValue);

  // Type something using keyboard
  const textarea = page.locator('.editor-textarea');
  await textarea.click();
  await page.keyboard.press('End');
  await page.keyboard.type('\n\nTEST INPUT');

  await page.waitForTimeout(200);

  const afterValue = await getTextareaValue();
  console.log('After typing textarea value:', afterValue);

  // Check if textarea value changed
  const valueChanged = afterValue !== initialValue;
  console.log('Textarea value changed:', valueChanged);

  // Get highlight content
  const highlightText = await page.evaluate(() => {
    const highlight = document.querySelector('.editor-highlight');
    return highlight?.textContent?.slice(-50) || '';
  });
  console.log('Highlight text (end):', highlightText);

  // Check if highlight includes new text
  expect(highlightText).toContain('TEST INPUT');
});

test('preview reactivity', async ({ page }) => {
  await page.goto('/playground/');
  await page.waitForSelector('.preview');
  await page.waitForTimeout(1000);

  // Get initial preview child count
  const getPreviewInfo = async () => {
    return page.evaluate(() => {
      const preview = document.querySelector('.preview');
      return {
        childCount: preview?.children.length,
        textLength: preview?.textContent?.length,
        lastText: preview?.textContent?.slice(-50),
      };
    });
  };

  const initialInfo = await getPreviewInfo();
  console.log('Initial preview info:', initialInfo);

  // Type something at the end of textarea
  const textarea = page.locator('.editor-textarea');
  await textarea.click();
  await page.keyboard.press('End');
  await page.keyboard.type('\n\n## NEW SECTION\n\nThis is new content.');

  // Wait longer for debounced AST update (100ms delay + some buffer)
  await page.waitForTimeout(1000);

  const afterInfo = await getPreviewInfo();
  console.log('After typing preview info:', afterInfo);

  // Check if preview child count changed (indicating re-render)
  console.log('Child count changed:', initialInfo.childCount !== afterInfo.childCount);
  console.log('Text length changed:', initialInfo.textLength !== afterInfo.textLength);

  // Check if preview includes new content
  expect(afterInfo.lastText).toContain('new content');
});
