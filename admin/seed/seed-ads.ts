// scripts/seed/seed-ads.ts
/**
 * Advertisement (广告位) × 3
 *   1. 首页顶部广告  (adPosition=1)
 *   2. 分类页广告    (adPosition=3)
 *   3. 详情页底部广告 (adPosition=4)
 *
 * adPosition : 1=首页顶  2=首页中  3=分类页  4=详情页
 * fileType   : 1=图片    2=视频
 * sortType   : 1=单图    2=三图
 *
 * 幂等: 按 title 查重
 */
import { PrismaClient } from '@prisma/client';

const db = new PrismaClient();
const daysLater = (d: number) => new Date(Date.now() + d * 86_400_000);

const ADS = [
  {
    title:      'JoyMinis — Win Big Every Day!',
    img:        'https://cdn.joyminis.com/ads/ad-homepage-top.jpg',
    fileType:   1,
    adPosition: 1,
    sortOrder:  1,
    sortType:   1,
    jumpCate:   2,
    jumpUrl:    '/pages/index/index',
    startTime:  new Date(),
    endTime:    daysLater(90),
    status:     1,
  },
  {
    title:      "Flash Sale Tonight — Don't Miss Out",
    img:        'https://cdn.joyminis.com/ads/ad-category-flashsale.jpg',
    fileType:   1,
    adPosition: 3,
    sortOrder:  1,
    sortType:   1,
    jumpCate:   2,
    jumpUrl:    '/pages/flash-sale/index',
    startTime:  new Date(),
    endTime:    daysLater(7),
    status:     1,
  },
  {
    title:      'Invite Friends, Earn ₱50 Bonus',
    img:        'https://cdn.joyminis.com/ads/ad-detail-referral.jpg',
    fileType:   1,
    adPosition: 4,
    sortOrder:  1,
    sortType:   1,
    jumpCate:   2,
    jumpUrl:    '/pages/referral/index',
    startTime:  new Date(),
    endTime:    daysLater(90),
    status:     1,
  },
];

export async function seedAdvertisements() {
  let created = 0;
  for (const ad of ADS) {
    const e = await db.advertisement.findFirst({ where: { title: ad.title } });
    if (!e) {
      await db.advertisement.create({ data: ad });
      created++;
    }
  }
  console.log(`  ✅ Advertisement    +${created} new`);
}
