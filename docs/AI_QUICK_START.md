# AI Quick Start Guide

> **Purpose**:快速启动指南，让 AI 在新对话开始时快速获取上下文  
> **Last Updated**: 2026-03-28

---

## 🚀 第一步：必读文件（按顺序）

每次新对话开始，请立即读取以下文件：

1. **`.github/copilot-instructions.md`** - 当前任务状态和进度
2. **`.clinerules`** - 核心规则和技术栈约束
3. **本文件** - 快速上下文

---

## 📋 当前项目概况

### 项目名称
**JoyMini** - 综合性电商/社交/钱包 App

### 技术栈（强制要求）
- **状态管理**: Riverpod（必须使用）
- **路由系统**: GoRouter（必须使用）
- **Flutter 版本**: 通过 FVM 管理（所有命令必须加 `fvm` 前缀）
- **语言要求**: 仅限中英文，严禁韩文

### 核心功能模块
- 电商购物（商品、拼团、秒杀、订单）
- 即时通讯（Socket.io）
- 钱包与资产管理
- 幸运抽奖
- KYC 实名认证

---

## ⚡ 常用命令速查

### 开发环境
```bash
fvm flutter doctor          # 检查环境
fvm flutter pub get         # 获取依赖
fvm flutter clean           # 清理构建
make dev                    # 启动开发环境
```

### 代码质量
```bash
fvm flutter analyze         # 静态分析
dart format .               # 格式化代码
fvm flutter test            # 运行测试
```

### 构建命令
```bash
make prod                   # 生产构建
fvm flutter build apk --release  # Android
fvm flutter build ios --release  # iOS
fvm flutter build web --release  # Web
```

### 代码生成
```bash
dart run build_runner build --delete-conflicting-outputs  # 生成代码
tool/generate.sh            # 运行生成脚本
```

---

## 🎯 决策框架

### 何时自主执行
- ✅ 明确原因的 Bug 修复
- ✅ 文档更新
- ✅ UI 样式调整
- ✅ 依赖版本更新

### 何时询问用户
- ❓ 架构变更
- ❓ 新功能实现
- ❓ 安全相关修改
- ❓ 影响核心流程的性能优化

### 何时使用完整沟通协议
- 📋 所有"重大变更"（详见 `AI_COLLABORATION_WORKFLOW.md`）
- 📋 影响多个模块的变更
- 📋 回滚策略不明确的变更

---

## 📚 关键文档索引

| 文档 | 用途 | 何时查阅 |
|------|------|----------|
| `.github/copilot-instructions.md` | 任务追踪 | 每次对话开始 |
| `docs/AI_COLLABORATION_WORKFLOW.md` | 沟通协议 | 重大变更时 |
| `docs/Architecture & Design/Top-Level Architecture Blueprint.md` | 架构设计 | 技术决策时 |
| `docs/FLUTTER_COMMANDS_CHEATSHEET.md` | 命令参考 | 执行命令前 |
| `docs/DevOps & Infra/AUTOMATED_TESTING_MANUAL.md` | 测试指南 | 编写测试时 |
| `docs/templates/IMPORTANT_CODE_CHANGE_TEMPLATE.md` | 变更模板 | 重大变更沟通时 |

---

## 🔧 常见工作流

### 新功能开发
1. 阅读 `copilot-instructions.md` 了解当前阶段
2. 使用 `IMPORTANT_CODE_CHANGE_TEMPLATE.md` 进行沟通
3. 实现功能（遵循架构分层）
4. 编写测试（Unit + Widget）
5. 更新文档和任务状态

### Bug 修复
1. 复现问题
2. 分析根因
3. 实现修复
4. 添加回归测试
5. 更新 `DEBUG_NOTES/`（如适用）

### 性能优化
1. 性能分析（Profile 模式）
2. 识别瓶颈
3. 实施优化
4. 验证效果
5. 记录优化结果

---

## ⚠️ 重要提醒

### 架构铁律
1. **金融精度**: 金额字段必须使用 `JsonNumConverter.toDouble`
2. **UI 简洁**: `build()` 方法内业务逻辑不超过 3 行
3. **设计令牌**: 禁止硬编码颜色/尺寸，使用生成的设计令牌

### 代码质量
- 遵循 `analysis_options.yaml` 规则
- 使用有意义的变量名
- 复杂业务逻辑添加注释
- 函数保持在 50 行以内

### 测试要求
- 新功能：最少 1 个 Unit + 1 个 Widget 测试
- Bug 修复：必须添加回归测试
- 模型变更：必须测试 `fromJson/toJson`

---

## 🆘 遇到问题？

### 编译错误
→ 查看 `docs/ERROR_PATTERNS.md`（待创建）

### 运行时错误
→ 检查 `DEBUG_NOTES/` 目录

### 测试失败
→ 参考 `docs/DevOps & Infra/AUTOMATED_TESTING_MANUAL.md`

### 不确定如何决策
→ 遵循本文件的"决策框架"

---

**文档状态**: ✅ 活跃  
**维护者**: AI Assistant  
**更新频率**: 随项目演进持续更新