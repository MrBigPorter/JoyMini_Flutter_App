// scripts/seed/seed-sections.ts
/**
 * 活动专区 (ActSection) × 2  +  专区-产品关联 (ActSectionItem)
 *
 *  HOT_PICKS    🔥 Hot Picks    → JM-001, JM-002, JM-007, JM-008
 *  NEW_ARRIVALS ✨ New Arrivals → JM-005, JM-006, JM-003, JM-004
 *
 * imgStyleType: 0=标准卡片  1=大图横滑  2=小图列表
 * 幂等: ActSection 按 key (@unique) upsert；ActSectionItem 按 (sectionId, treasureId) 查重
 */
import { PrismaClient } from '@prisma/client';

const db = new PrismaClient();

const SECTIONS = [
  {
    key: 'HOT_PICKS',
    title: '🔥 Hot Picks',
    imgStyleType: 0,
    status: 1,
    sortOrder: 1,
    limit: 8,
    items: ['JM-001', 'JM-002', 'JM-007', 'JM-008'],
  },
  {
    key: 'NEW_ARRIVALS',
    title: '✨ New Arrivals',
    imgStyleType: 0,
    status: 1,
    sortOrder: 2,
    limit: 8,
    items: ['JM-005', 'JM-006', 'JM-003', 'JM-004'],
  },
];

export async function seedActSections() {
  let sCreated = 0;
  let iCreated = 0;

  for (const { items, ...sData } of SECTIONS) {
    // upsert section（key 是 @unique）
    const existing = await db.actSection.findUnique({
      where: { key: sData.key },
    });
    let sectionId: string;
    if (existing) {
      sectionId = existing.id;
    } else {
      const s = await db.actSection.create({ data: sData });
      sectionId = s.id;
      sCreated++;
    }

    // 按 treasureSeq 查找 treasureId，并建立关联
    for (let i = 0; i < items.length; i++) {
      const t = await db.treasure.findUnique({
        where: { treasureSeq: items[i] },
      });
      if (!t) continue;
      const exists = await db.actSectionItem.findFirst({
        where: { sectionId, treasureId: t.treasureId },
      });
      if (!exists) {
        await db.actSectionItem.create({
          data: { sectionId, treasureId: t.treasureId, sortOrder: i + 1 },
        });
        iCreated++;
      }
    }
  }

  console.log(`  ✅ ActSection       +${sCreated} new`);
  console.log(`  ✅ ActSectionItem   +${iCreated} new`);
}
