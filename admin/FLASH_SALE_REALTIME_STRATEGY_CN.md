# Flash Sale 实时刷新策略（Phase 6 记录）

> 更新时间：2026-03-18
> 适用范围：`apps/api` + `apps/admin-next` 秒杀管理/展示链路

## 1. 结论（先做什么）

当前建议采用 **普通接口 + 轮询** 作为默认方案，WebSocket 作为二期增强。

- 低成本、改造快、稳定性高
- 与现有 `useRequest` 数据流一致
- 可通过服务端强校验保证价格/库存正确性

## 2. 是否需要 WebSocket

### 2.1 暂不强制上 WebSocket 的场景

- 管理端并发不高（少量运营同屏操作）
- 前端只需“近实时”更新（3~30s 级别）
- 关键一致性由下单接口兜底（时间窗/库存/价格）

### 2.2 建议上 WebSocket 的场景

- 高频运营编辑导致页面频繁失真
- 需要更即时的“变更通知体验”
- 后续要做跨端实时联动（后台改完，前台立刻变化）

## 3. MVP 刷新策略（不改业务语义）

- 场次列表：`GET /flash-sale/sessions/active`，轮询 `15~30s`
- 场次商品：`GET /flash-sale/sessions/:id/products`，轮询 `3~5s`（仅活动进行中）
- 商品详情：`GET /flash-sale/products/:id`，按页刷新或页面聚焦时刷新
- 倒计时：前端本地每秒递减，初次用服务端时间校准
- 下单：始终以服务端校验为准（活动状态、库存、价格）

## 4. WebSocket 二期设计（可落地）

## 4.1 事件设计（先轻后重）

建议先用单事件：`flash_sale_changed`

```ts
{
  event: 'flash_sale_changed',
  scope: 'session' | 'product',
  action: 'create' | 'update' | 'delete',
  sessionId?: string,
  productId?: string,
  updatedAt: number,
}
```

前端收到事件后不做本地复杂合并，直接触发对应 `refresh`。

## 4.2 后端落点

- 管理写操作来源：`apps/api/src/admin/flash-sale/flash-sale.service.ts`
- 推送网关：`apps/api/src/common/events/events.gateway.ts`
- 原则：写成功后再发事件，失败不发

## 4.3 前端落点

- 新建 Hook：`apps/admin-next/src/hooks/useFlashSaleSocket.ts`
- 页面接入：秒杀列表页 / 场次商品页
- 断线回退：保留轮询，不依赖单一 WS 通道

## 5. 风险与控制

- 权限风险：必须校验 admin token 与 role，避免越权订阅
- 事件风暴：前端 refresh 加节流（例如 300~500ms）
- 断连风险：轮询兜底，保证功能可用
- 一致性风险：不在前端“猜库存”，以服务端校验结果为准

## 6. 推荐实施顺序

1. 先完成轮询版（可上线）
2. 再加 `flash_sale_changed` 事件通知（MVP WS）
3. 观察真实流量后，再决定是否拆更细事件

## 7. 当前决策

- 现在可先不做“全实时推送”
- 优先普通接口 + 轮询
- WebSocket 作为二期优化，保持接口兼容即可平滑升级

