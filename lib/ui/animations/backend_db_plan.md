# 后端数据库规划（MA标签快照）

## 目标

取代前端的 IndexedDB，由后端服务统一存储和提供多周期资金流历史数据。

## 数据表结构

### `ma_snapshots`

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint PK | 自增主键 |
| symbol | varchar(20) | BTCUSDT |
| recorded_at | datetime | 快照时间（UTC） |
| price | decimal(18,8) | 记录时的价格 |
| timeframe | varchar(5) | 15m/1h/4h/6h/8h/12h/1d |
| ma_value | decimal(18,8) | SMA30均线价 |
| cmd | decimal(24,4) | 24K累计净资金流 |
| total_in | decimal(24,4) | 24K总买入 |
| total_out | decimal(24,4) | 24K总卖出 |
| mf_cur | decimal(24,4) | 最新单KCMD |
| mult | decimal(8,4) | 战力倍数 |
| speed_ratio | decimal(8,4) | 增速比 |

**索引：** `(symbol, timeframe, recorded_at)` 复合索引

### 写入频率

每15分钟写入一次。每次写入 7 行（每个周期一行）。

一天 = 7周期 × 96次 = **672行**
一月 ≈ 20,000行

### API 接口

```
GET /api/ma-snapshots?symbol=BTCUSDT&days=7
返回指定币种最近N天的快照数据

GET /api/ma-snapshots/latest?symbol=BTCUSDT
返回最新的一个快照（7周期）

POST /api/ma-snapshots
接收当前数据写入
```

### 集成方式

前端伪代码：
```javascript
// 替代现有的 saveSnapshot()
async function saveSnapshot() {
  const data = buildSnapshotData(); // 从 tfData 取
  await fetch('/api/ma-snapshots', {
    method: 'POST',
    body: JSON.stringify(data)
  });
}

// 替代现有的 getHistory()
async function getHistory(days) {
  const res = await fetch(`/api/ma-snapshots?symbol=${SYMBOL}&days=${days}`);
  return res.json();
}
```

### 与现有 IndexedDB 的关系

过渡期：两个同时存。后端稳定后去掉 IndexedDB。
