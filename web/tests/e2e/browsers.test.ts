import { expect, test } from 'playwright-test-coverage';

import config from '../../_config';

test('browsers', async ({ page }) => {
  await page.goto(`http://${config.server.host}:${config.server.port}`);

  await expect(page).toHaveTitle(config.metadata.title);
});
