import { PrismaClient } from '@prisma/client';
import { loadEnvForHost } from '../utils/load-env-for-host';

loadEnvForHost();

const db = new PrismaClient();

const TEST_PHONE = '+639171234567';
const SEED_LOGIN_DEVICE = 'Seed Demo Device';
const CURRENT_TREASURE_SEQS = Array.from(
  { length: 30 },
  (_, index) => `JM-${String(index + 1).padStart(3, '0')}`,
);
const SECTION_KEYS = [
  'HOT_PICKS',
  'NEW_ARRIVALS',
  'cash_zone',
  'gadgets',
  'game_corner',
  'home_essentials',
  'new_this_week',
  'phones',
  'voucher_deals',
] as const;
const FLASH_SALE_TITLES = ["⚡ Tonight's Flash Sale"] as const;
const LUCKY_DRAW_TITLES = [
  'Global Lucky Draw',
  'iPhone Bonus Lucky Draw',
] as const;
const AD_TITLES = [
  'JoyMinis — Win Big Every Day!',
  "Flash Sale Tonight — Don't Miss Out",
  'Invite Friends, Earn ₱50 Bonus',
] as const;

async function cleanupActSections() {
  const sections = await db.actSection.findMany({
    where: { key: { in: [...SECTION_KEYS] } },
    select: { id: true },
  });
  const sectionIds = sections.map((section) => section.id);

  const deletedItems =
    sectionIds.length > 0
      ? await db.actSectionItem.deleteMany({
          where: { sectionId: { in: sectionIds } },
        })
      : { count: 0 };
  const deletedSections = await db.actSection.deleteMany({
    where: { key: { in: [...SECTION_KEYS] } },
  });

  console.log(
    `  ♻️ ActSection cleanup -${deletedSections.count} sections, -${deletedItems.count} items`,
  );
}

async function cleanupFlashSale() {
  const sessions = await db.flashSaleSession.findMany({
    where: { title: { in: [...FLASH_SALE_TITLES] } },
    select: { id: true },
  });
  const sessionIds = sessions.map((session) => session.id);

  const deletedProducts =
    sessionIds.length > 0
      ? await db.flashSaleProduct.deleteMany({
          where: { sessionId: { in: sessionIds } },
        })
      : { count: 0 };
  const deletedSessions = await db.flashSaleSession.deleteMany({
    where: { title: { in: [...FLASH_SALE_TITLES] } },
  });

  console.log(
    `  ♻️ FlashSale cleanup -${deletedSessions.count} sessions, -${deletedProducts.count} products`,
  );
}

async function cleanupLuckyDraw() {
  const activities = await db.luckyDrawActivity.findMany({
    where: { title: { in: [...LUCKY_DRAW_TITLES] } },
    select: { id: true },
  });
  const activityIds = activities.map((activity) => activity.id);

  const tickets =
    activityIds.length > 0
      ? await db.luckyDrawTicket.findMany({
          where: { activityId: { in: activityIds } },
          select: { id: true },
        })
      : [];
  const prizes =
    activityIds.length > 0
      ? await db.luckyDrawPrize.findMany({
          where: { activityId: { in: activityIds } },
          select: { id: true },
        })
      : [];

  const ticketIds = tickets.map((ticket) => ticket.id);
  const prizeIds = prizes.map((prize) => prize.id);

  const deletedResults =
    ticketIds.length > 0 || prizeIds.length > 0
      ? await db.luckyDrawResult.deleteMany({
          where: {
            OR: [
              ...(ticketIds.length > 0
                ? [{ ticketId: { in: ticketIds } }]
                : []),
              ...(prizeIds.length > 0 ? [{ prizeId: { in: prizeIds } }] : []),
            ],
          },
        })
      : { count: 0 };
  const deletedTickets =
    activityIds.length > 0
      ? await db.luckyDrawTicket.deleteMany({
          where: { activityId: { in: activityIds } },
        })
      : { count: 0 };
  const deletedPrizes =
    activityIds.length > 0
      ? await db.luckyDrawPrize.deleteMany({
          where: { activityId: { in: activityIds } },
        })
      : { count: 0 };
  const deletedActivities = await db.luckyDrawActivity.deleteMany({
    where: { title: { in: [...LUCKY_DRAW_TITLES] } },
  });

  console.log(
    `  ♻️ LuckyDraw cleanup -${deletedActivities.count} activities, -${deletedPrizes.count} prizes, -${deletedTickets.count} tickets, -${deletedResults.count} results`,
  );
}

async function cleanupGroups() {
  const testUser = await db.user.findUnique({
    where: { phone: TEST_PHONE },
    select: { id: true },
  });

  if (!testUser) {
    console.log('  ♻️ Group cleanup   skipped (test user not found)');
    return;
  }

  const treasures = await db.treasure.findMany({
    where: { treasureSeq: { in: CURRENT_TREASURE_SEQS } },
    select: { treasureId: true },
  });
  const treasureIds = treasures.map((treasure) => treasure.treasureId);

  if (treasureIds.length === 0) {
    console.log('  ♻️ Group cleanup   skipped (seed treasures not found)');
    return;
  }

  const groups = await db.treasureGroup.findMany({
    where: {
      creatorId: testUser.id,
      treasureId: { in: treasureIds },
    },
    select: { groupId: true },
  });
  const groupIds = groups.map((group) => group.groupId);

  const deletedLotteryResults =
    groupIds.length > 0
      ? await db.lotteryResult.deleteMany({
          where: { groupId: { in: groupIds } },
        })
      : { count: 0 };
  const deletedMembers =
    groupIds.length > 0
      ? await db.treasureGroupMember.deleteMany({
          where: { groupId: { in: groupIds } },
        })
      : { count: 0 };
  const deletedGroups =
    groupIds.length > 0
      ? await db.treasureGroup.deleteMany({
          where: { groupId: { in: groupIds } },
        })
      : { count: 0 };

  console.log(
    `  ♻️ Group cleanup   -${deletedGroups.count} groups, -${deletedMembers.count} members, -${deletedLotteryResults.count} lottery results`,
  );
}

async function cleanupBannersAndAds() {
  const deletedBanners = await db.banner.deleteMany({
    where: { createdBy: 'seed' },
  });
  const deletedAds = await db.advertisement.deleteMany({
    where: { title: { in: [...AD_TITLES] } },
  });

  console.log(
    `  ♻️ Banner/Ads cleanup -${deletedBanners.count} banners, -${deletedAds.count} ads`,
  );
}

async function cleanupLoginLogs() {
  const deletedLogs = await db.userLoginLog.deleteMany({
    where: { loginDevice: SEED_LOGIN_DEVICE },
  });
  console.log(`  ♻️ LoginLog cleanup -${deletedLogs.count} logs`);
}

export async function cleanupSeedData(): Promise<void> {
  console.log('  🧹 Cleanup seed-managed demo data...');
  await cleanupLoginLogs();
  await cleanupBannersAndAds();
  await cleanupLuckyDraw();
  await cleanupFlashSale();
  await cleanupActSections();
  await cleanupGroups();
}
