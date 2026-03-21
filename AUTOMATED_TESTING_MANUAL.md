# JoyMini 自动化测试手册（Flutter）

> 目标：让你能快速上手本项目自动化测试，知道“测什么、怎么测、什么时候测”。

---

## 1. 这份手册解决什么问题

- 帮你搭建本地测试环境（FVM + Flutter 测试命令）
- 解释本项目当前有哪些自动化测试、覆盖哪些风险
- 给出可复制的测试命令与提交流程
- 提供最小可用的用例模板（Unit / Widget）

---

## 2. 当前项目测试现状（基于仓库代码）

当前已有测试目录：

- `test/providers/`
- `test/widgets/`

已存在测试文件：

- `test/providers/flash_sale_model_test.dart`
- `test/providers/purchase_state_flash_sale_test.dart`
- `test/providers/ad_res_model_test.dart`
- `test/widgets/flash_sale_product_page_test.dart`
- `test/widgets/home_ad_test.dart`
- `test/widgets/product_detail_html_overflow_test.dart`

现状结论：

- 已有 **Unit/Provider** 与 **Widget** 级测试
- 重点覆盖了：秒杀模型解析、广告模型/组件、详情页 HTML 溢出回归
- 当前仓库未发现 `integration_test/` 目录（可作为后续增强）

---

## 3. 环境准备

项目采用 FVM（见 `FVM_README.md`）。推荐所有命令使用 `fvm flutter`。

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm install
fvm flutter pub get
```

如果你本机未安装 FVM，可临时使用系统 Flutter：

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
flutter pub get
```

---

## 4. 常用自动化测试命令

### 4.1 跑全部测试

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter test
```

### 4.2 跑单个测试文件（推荐开发时用）

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter test test/providers/flash_sale_model_test.dart
```

### 4.3 跑某个目录

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter test test/providers
fvm flutter test test/widgets
```

### 4.4 静态检查（建议和测试一起跑）

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter analyze
```

### 4.5 生成覆盖率报告

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter test --coverage
```

执行后会生成：`coverage/lcov.info`

可选（本地查看 HTML 报告，需要 `lcov` 工具）：

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
genhtml coverage/lcov.info -o coverage/html
```

---

## 5. 本项目推荐测试分层

### 5.1 Unit（纯逻辑）

适合内容：

- `fromJson/toJson` 转换
- 价格/库存/倒计时计算
- 参数映射、状态机分支

典型文件参考：

- `test/providers/flash_sale_model_test.dart`
- `test/providers/ad_res_model_test.dart`

### 5.2 Widget（UI 分支 + 交互）

适合内容：

- 空态 / 错误态 / 加载态
- 长文本、极端数据的渲染稳定性
- 按钮可见性、禁用态

典型文件参考：

- `test/widgets/home_ad_test.dart`
- `test/widgets/product_detail_html_overflow_test.dart`

### 5.3 Integration（关键链路）

建议后续补齐：

- 登录 -> 商品详情 -> 下单 -> 支付入口
- Flash Sale 倒计时和结束态
- Lucky Draw 抽奖和结果页

---

## 6. 写测试时的统一规范

- 测试名写清行为和预期：`does not throw when ...`
- 一个测试只验证一个核心行为
- 优先覆盖“易回归分支”：空数据、异常数据、超长文本、边界时间
- Widget 测试尽量使用统一包装（`MaterialApp` + `ScreenUtilInit`）
- 发现 bug 后，先补回归测试，再修代码

---

## 7. 最小模板（可直接改）

### 7.1 Unit 模板（模型解析）

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('xxx.fromJson', () {
    test('parses required fields', () {
      final json = {'id': '1', 'name': 'demo'};
      // final model = Xxx.fromJson(json);
      // expect(model.id, '1');
    });

    test('uses safe default when field missing', () {
      final json = {'id': '1'};
      // final model = Xxx.fromJson(json);
      // expect(model.count, 0);
    });
  });
}
```

### 7.2 Widget 模板（稳定性回归）

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('does not throw on edge content', (tester) async {
    await tester.pumpWidget(wrap(const SizedBox()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
```

---

## 8. 提交前标准流程（建议固化为习惯）

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

提交 PR 时建议附上：

- 本次新增/修改的测试文件路径
- 本地测试结果（通过/失败）
- 覆盖了哪些关键分支（例如：售罄态、倒计时结束态、接口失败态）

---

## 9. 新人学习路径（3 步）

1. 先读 3 个现有测试：
   - `test/providers/flash_sale_model_test.dart`
   - `test/widgets/home_ad_test.dart`
   - `test/widgets/product_detail_html_overflow_test.dart`
2. 在同目录新增一个“边界条件”测试（例如字段缺失、超长内容）
3. 跑单测 -> 跑全量 -> 跑 analyze，保证三项通过

---

## 10. 常见问题（FAQ）

### Q1：为什么我本地跑不过，别人能过？

优先检查：

- 是否使用了项目指定 Flutter 版本（FVM）
- 是否执行了 `pub get`
- 是否在项目根目录执行命令

### Q2：Widget 测试经常报布局或字体问题怎么办？

优先在测试里补齐基础壳：

- `MaterialApp`
- `Scaffold`
- `ScreenUtilInit`

### Q3：我只改了模型，也要写测试吗？

要。模型解析错误会直接导致线上页面错价、空白或崩溃。最小要求是 `fromJson` 正常/缺字段兜底两条用例。

---

## 11. 当前验证记录（本次）

本手册编写时，已在仓库执行并通过以下代表性测试：

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter test test/providers/flash_sale_model_test.dart
```

输出结果：`All tests passed!`

---

## 12. 可选：接入 GitHub Actions 自动跑测

当前仓库未发现现成的 `.github/workflows` 测试流水线。可以按下面模板新增（可后续再细化）：

```yaml
name: Flutter Test

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Install deps
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Test
        run: flutter test --coverage
```

如果团队要求与本地完全一致，可把 `flutter` 替换为 `fvm flutter`，并在 job 中先安装 FVM。

---

## 13. 登录链路回归（OTP + OAuth）

为了避免登录改动引入回归，建议优先使用一键脚本：

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
./tool/test_login_regression.sh
```

脚本会自动使用 `fvm flutter`（如未安装 FVM 则回退到 `flutter`），并执行固定回归集。

等价原始命令（便于临时拆分定位）：

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter test \
  test/providers/auth_oauth_model_test.dart \
  test/widgets/login_page_oauth_test.dart \
  test/providers/flash_sale_model_test.dart \
  test/providers/purchase_state_flash_sale_test.dart \
  test/widgets/flash_sale_product_page_test.dart
```

覆盖范围：

- OAuth 模型字段与兼容逻辑（`avatar/avartar`、`lastLoginAt`）
- 登录页 OAuth 按钮分支（Google/Facebook/Apple 条件显示）
- Flash Sale 模型与购买状态回归（防止商业链路连带回归）

### 本次执行记录（2026-03-19）

- 执行结果：`All tests passed!`
- 观察到的非阻塞提示：
  - `flutter_facebook_auth` 在 macOS 下的 `facebook_auth_desktop` 插件提示（当前不阻塞测试通过）
  - Easy Localization 的 key 警告（测试环境未注入完整多语言资源）

建议：把这组命令加入 PR 前自检或本地脚本，作为登录功能改动的最小回归门禁。

---

## 14. 看这些就能“完全掌握” Flutter 自动化测试（通俗版）

下面这 7 项是最短学习路径。每项都按「看什么 -> 跑什么 -> 学会标准」来做。

| 关键点 | 看什么（文件） | 跑什么（命令） | 学会标准（自测） |
|------|------|------|------|
| 1. 先懂测试分层 | `AUTOMATED_TESTING_MANUAL.md` 第 5 章 | `fvm flutter test` | 你能说清 Unit/Widget/Integration 各自解决什么问题 |
| 2. 掌握模型解析测试 | `test/providers/flash_sale_model_test.dart` | `fvm flutter test test/providers/flash_sale_model_test.dart` | 你能写出“字段缺失也有默认值”的断言 |
| 3. 掌握业务状态测试 | `test/providers/purchase_state_flash_sale_test.dart` | `fvm flutter test test/providers/purchase_state_flash_sale_test.dart` | 你能验证秒杀参数（如 `flashSaleProductId`）在状态流里不丢失 |
| 4. 掌握 UI 稳定性测试 | `test/widgets/product_detail_html_overflow_test.dart` | `fvm flutter test test/widgets/product_detail_html_overflow_test.dart` | 你会用 `tester.takeException()` 做“无崩溃”回归 |
| 5. 掌握组件边界测试 | `test/widgets/home_ad_test.dart` | `fvm flutter test test/widgets/home_ad_test.dart` | 你能覆盖空态/少数据态，并确保组件不抛异常 |
| 6. 掌握页面分支测试 | `test/widgets/flash_sale_product_page_test.dart` | `fvm flutter test test/widgets/flash_sale_product_page_test.dart` | 你能覆盖加载态、错误态、结束态、售罄态至少 2 个分支 |
| 7. 掌握提交流程（防回归） | `FVM_README.md` + 本文第 8 章 | `fvm flutter analyze && fvm flutter test --coverage` | 你提交前能稳定执行 analyze + test，并产出 `coverage/lcov.info` |

### 一句话记忆

**会分层、会断言、会测边界、会看覆盖率、会走提交流程。**

### 什么时候算“完全掌握”？

满足这 3 条即可：

1. 你能独立给一个新功能补 1 个 Unit + 1 个 Widget 测试。
2. 你能在 10 分钟内定位“是模型问题、状态问题还是 UI 渲染问题”。
3. 你能在提 PR 前稳定跑完：`analyze + test + coverage`。

---

## 15. 要“完整掌握”你需要会这 6 件事（最终清单）

如果你把下面 6 件事都做熟，就可以认为已经完整掌握本项目 Flutter 自动化测试。

### 1) 会分层设计测试（先想测什么）

- 能区分：Unit 测逻辑、Widget 测渲染分支、Integration 测业务链路。
- 新功能进来时，能先写出“该放哪一层测”。

### 2) 会写稳定的断言（再想怎么证明）

- Unit：能覆盖正常值 + 缺字段兜底 + 边界值。
- Widget：能覆盖空态/错误态/加载态，且使用 `tester.takeException()` 防崩回归。

### 3) 会覆盖高风险业务分支（避免线上回归）

- 价格、库存、倒计时、售罄、结束态、接口失败态。
- 能把一次线上 bug 转成一个回归测试用例。

### 4) 会跑全流程命令（本地自检闭环）

- `fvm flutter analyze`
- `fvm flutter test`
- `fvm flutter test --coverage`

### 5) 会看失败原因并定位（10 分钟内判断方向）

- 能快速判断失败属于：模型解析、状态流、UI 渲染、测试环境壳子缺失。
- 能从报错堆栈定位到对应测试文件与业务代码。

### 6) 会把测试纳入提交流程（团队可持续）

- 每次改动都能补最小测试，不做“裸改业务逻辑”。
- PR 描述能说明：新增了哪些测试、覆盖了哪些分支、结果是否通过。

### 最终自测（全部满足=完整掌握）

- [ ] 你能独立给一个新需求补 1 个 Unit + 1 个 Widget 测试并通过
- [ ] 你能在一次失败中快速定位根因并修复
- [ ] 你能稳定跑完 `analyze + test + coverage`
- [ ] 你写的测试能被团队成员复现并长期稳定通过


