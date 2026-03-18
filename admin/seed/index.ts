import { seedSystemConfigExchangeRate } from './system-config-exchange-rate';
import { seedProductCategories } from './product-category-list';
import { seedAddressLite } from './seed-address-lite';
import { seedKycIdTypes } from './seed-kyc-id-types';
import { cleanupSeedData } from './cleanup-seed-data';
import { seedTreasures } from './seed-treasures';
import { seedBanners } from './seed-banners';
import { seedAdvertisements } from './seed-ads';
import { seedActSections } from './seed-sections';
import { seedPaymentChannels } from './seed-payment-channels';
import { seedFlashSale } from './seed-flash-sale';
import { seedCoupons } from './seed-coupons';
import { seedLuckyDraw } from './seed-lucky-draw';
import { seedTestUserWallet } from './seed-wallet';
import { seedRobotsLite } from './seed-robots-lite';
import { seedGroups } from './seed-groups';
import { seedLoginLogs } from './seed-login-logs';

async function main() {
  console.log('\n🌱  JoyMinis Demo Seed ─────────────────────────');
  console.log(`    ${new Date().toISOString()}\n`);

  const resetTreasures = process.env.SEED_TREASURES_RESET !== '0';
  const cleanupBeforeSeed = process.env.SEED_CLEANUP_BEFORE_INSERT !== '0';

  if (cleanupBeforeSeed) {
    await cleanupSeedData();
    console.log('');
  }

  // [1] 基础配置
  await seedSystemConfigExchangeRate();

  // [2] 产品分类（需在产品前执行，供 seedTreasures 内部查 id）
  await seedProductCategories();

  // [3] 地址基础数据（省/市/Barangay 最小可用集）
  await seedAddressLite();

  // [4] KYC 证件类型
  await seedKycIdTypes();

  // [5] 抽奖产品 + 产品-分类关联（依赖分类）
  await seedTreasures({ resetBeforeSeed: resetTreasures });

  // [6] 活动专区 + 关联商品（依赖产品）
  await seedActSections();

  // [7] 首页 / 活动页 Banner
  await seedBanners();

  // [8] 广告位
  await seedAdvertisements();

  // [9] 支付渠道
  await seedPaymentChannels();

  // [10] 秒杀场次 + 秒杀商品（依赖产品）
  await seedFlashSale();

  // [11] 优惠券模板
  await seedCoupons();

  // [12] 福利抽奖活动 + 奖品（依赖产品 + 优惠券）
  await seedLuckyDraw();

  // [13] 测试用户 + 钱包（本地开发用）
  await seedTestUserWallet();

  // [14] 机器人用户（供拼团补位与登录日志演示）
  await seedRobotsLite();

  // [15] 拼团演示数据（依赖产品 + 测试用户）
  await seedGroups();

  // [16] 登录日志演示数据（依赖测试用户 + 机器人）
  await seedLoginLogs();

  console.log('\n✨  Seed 完成！\n');
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error('❌  Seed 失败:', e);
    process.exit(1);
  });
