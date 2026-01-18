const { chromium } = require('playwright');

(async () => {
  console.log('🚀 Playwright 테스트 시작...\n');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  // 테스트 1: Google 접속
  console.log('1️⃣ Google 접속 테스트');
  await page.goto('https://www.google.com');
  const title = await page.title();
  console.log(`   페이지 타이틀: ${title}`);
  console.log(`   ✅ 통과\n`);

  // 테스트 2: 스크린샷
  console.log('2️⃣ 스크린샷 테스트');
  await page.screenshot({ path: 'tests/google-screenshot.png' });
  console.log('   스크린샷 저장: tests/google-screenshot.png');
  console.log(`   ✅ 통과\n`);

  // 테스트 3: 검색
  console.log('3️⃣ 검색 테스트');
  await page.fill('textarea[name="q"]', 'Claude Code');
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'domcontentloaded' }),
    page.keyboard.press('Enter')
  ]);
  const searchTitle = await page.title();
  console.log(`   검색 결과 타이틀: ${searchTitle}`);
  console.log(`   ✅ 통과\n`);

  await browser.close();

  console.log('🎉 모든 테스트 통과!');
})();
