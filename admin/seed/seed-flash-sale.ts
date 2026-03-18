// scripts/seed/seed-flash-sale.ts
/**
 * 秒杀场次 (FlashSaleSession) × 1  +  秒杀商品 (FlashSaleProduct) × 3
 *
 * 场次: "Tonight's Flash Sale"  运行 seed 后 2h 开始，持续 4h
 *
 * 秒杀商品 (flashPrice < unitAmount):
 *   JM-001  iPhone 16 Pro    ₱250 → ₱150/份   库存 60份   (40% off)
 *   JM-003  PlayStation 5    ₱150 → ₱ 80/份   库存100份   (47% off)
 *   JM-007  Cash ₱5,000      ₱100 → ₱ 60/份   库存 30份   (40% off)
 *
 * flashStock : 秒杀专属库存份数，与主产品 seqShelvesQuantity 相互独立
 * flashPrice : 秒杀价，单位 PHP/份
 *
 * 幂等: 按 title 查找 session；按 (sessionId, treasureId) 查找 product
 */
import { PrismaClient } from '@prisma/client';

const db = new PrismaClient();
const hoursLater = (h: number) => new Date(Date.now() + h * 3_600_000);

const SESSION_TITLE = "⚡ Tonight's Flash Sale";

const FLASH_PRODUCTS: Array<{
  seq: string;
  flashPrice: number;
  flashStock: number;
  sortOrder: number;
}> = [
  { seq: 'JM-001', flashPrice: 150, flashStock: 60, sortOrder: 1 },
  { seq: 'JM-003', flashPrice: 80, flashStock: 100, sortOrder: 2 },
  { seq: 'JM-007', flashPrice: 60, flashStock: 30, sortOrder: 3 },
];

export async function seedFlashSale() {
  // ── FlashSaleSession ──────────────────────────────────────
  let session = await db.flashSaleSession.findFirst({
    where: { title: SESSION_TITLE },
  });
  let sCreated = 0;
  if (!session) {
    session = await db.flashSaleSession.create({
      data: {
        title: SESSION_TITLE,
        startTime: hoursLater(2), // 2h 后开始
        endTime: hoursLater(6), // 4h 持续
        status: 1,
      },
    });
    sCreated++;
  }

  // ── FlashSaleProduct ──────────────────────────────────────
  let pCreated = 0;
  for (const { seq, flashPrice, flashStock, sortOrder } of FLASH_PRODUCTS) {
    const t = await db.treasure.findUnique({ where: { treasureSeq: seq } });
    if (!t) continue;
    const exists = await db.flashSaleProduct.findFirst({
      where: { sessionId: session.id, treasureId: t.treasureId },
    });
    if (!exists) {
      await db.flashSaleProduct.create({
        data: {
          sessionId: session.id,
          treasureId: t.treasureId,
          flashPrice,
          flashStock,
          sortOrder,
        },
      });
      pCreated++;
    }
  }

  console.log(`  ✅ FlashSaleSession +${sCreated} new`);
  console.log(`  ✅ FlashSaleProduct +${pCreated} new`);
}
