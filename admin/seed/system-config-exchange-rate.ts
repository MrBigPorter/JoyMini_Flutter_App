// apps/api/scripts/seed/system-config-exchange-rate.ts
import { PrismaClient } from '@prisma/client';

const db = new PrismaClient();

export async function seedSystemConfigExchangeRate() {
  // 这里用 upsert，方便多次执行
  await db.systemConfig.upsert({
    where: { key: 'exchange_rate' },
    update: { value: '10' },
    create: {
      key: 'exchange_rate',
      value: '10', // PHP : 1 TreasureCoin = 10 PHP
    },
  });

  // 可以顺手放几个后续可能用到的配置
  await db.systemConfig.upsert({
    where: { key: 'kyc_and_phone_verification' },
    update: { value: '1' }, // 1 开启, 0 关闭
    create: {
      key: 'kyc_and_phone_verification',
      value: '1',
    },
  });

  // 可以顺手放几个后续可能用到的配置
  await db.systemConfig.upsert({
    where: { key: 'web_base_url' },
    update: { value: '127.0.0.1' }, // 1 开启, 0 关闭
    create: {
      key: 'web_base_url',
      value: '127.0.0.1',
    },
  });
}
