// scripts/seed/seed-banners.ts
/**
 * Banner × 3
 *   1. 首页顶部轮播  — Flash Sale 主推   (bannerCate=1, position=0, showType=2)
 *   2. 首页中部单图  — 拼团入口          (bannerCate=1, position=1, showType=1)
 *   3. 活动页顶部    — 品牌大促活动       (bannerCate=2, position=0, showType=1)
 *
 * 字段枚举:
 *   bannerCate : 1=首页  2=活动页  3=产品页
 *   position   : 0=顶部  1=中部   2=底部
 *   fileType   : 1=图片  2=视频
 *   showType   : 1=单图  2=轮播
 *   jumpCate   : 1=无跳转  2=APP内页  3=产品详情  5=外链
 *
 * 幂等: 用 createdBy='seed' 作标记，已存在则整组跳过
 */
import { PrismaClient } from '@prisma/client';

const db = new PrismaClient();
const SEED_MARKER = 'seed';
const daysLater = (d: number) => new Date(Date.now() + d * 86_400_000);

export async function seedBanners() {
  const already = await db.banner.count({ where: { createdBy: SEED_MARKER } });
  if (already > 0) {
    console.log(`  ⏭️  Banner           skipped (${already} already exist)`);
    return;
  }

  const rows = [
    // ── 首页顶部轮播 ────────────────────────────────────────
    {
      title: '⚡ Flash Sale — Up to 60% OFF',
      bannerImgUrl: 'https://cdn.joyminis.com/banners/home-top-flashsale.jpg',
      fileType: 1,
      bannerCate: 1,
      position: 0,
      sortOrder: 1,
      showType: 2, // 轮播
      jumpCate: 2,
      jumpUrl: '/pages/flash-sale/index',
      state: 1,
      validState: 1,
      createdBy: SEED_MARKER,
      // bannerArray: 轮播每帧 {img, url}
      bannerArray: [
        {
          img: 'https://cdn.joyminis.com/banners/slide-iphone16pro.jpg',
          url: '/pages/product/detail?id=JM-001',
        },
        {
          img: 'https://cdn.joyminis.com/banners/slide-ps5slim.jpg',
          url: '/pages/product/detail?id=JM-003',
        },
        {
          img: 'https://cdn.joyminis.com/banners/slide-cash10k.jpg',
          url: '/pages/product/detail?id=JM-008',
        },
      ],
    },
    // ── 首页中部单图 ────────────────────────────────────────
    {
      title: '👥 Group Buy & Win Together',
      bannerImgUrl: 'https://cdn.joyminis.com/banners/home-mid-groupbuy.jpg',
      fileType: 1,
      bannerCate: 1,
      position: 1,
      sortOrder: 2,
      showType: 1,
      jumpCate: 2,
      jumpUrl: '/pages/group-buy/index',
      state: 1,
      validState: 1,
      createdBy: SEED_MARKER,
    },
    // ── 活动页顶部 ──────────────────────────────────────────
    {
      title: '🎉 JoyMinis Grand Lucky Draw',
      bannerImgUrl: 'https://cdn.joyminis.com/banners/activity-top-grand.jpg',
      fileType: 1,
      bannerCate: 2,
      position: 0,
      sortOrder: 1,
      showType: 1,
      jumpCate: 5, // 外链
      jumpUrl: 'https://joyminis.com/grand-event',
      activityAtStart: new Date(),
      activityAtEnd: daysLater(30),
      state: 1,
      validState: 1,
      createdBy: SEED_MARKER,
    },
  ];

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  await db.banner.createMany({ data: rows as any });
  console.log(`  ✅ Banner           +${rows.length} new`);
}
