# 这样你点击 TASK EXPLORER 里的按钮就能跑了
dev:
	fvm flutter run --dart-define-from-file=dev.json

test:
	fvm flutter run --dart-define-from-file=test.json

prod:
	fvm flutter run --dart-define-from-file=prod.json

# ─────────────────────────────────────────────
# 快速清理（用 rm -rf 替代 flutter clean，快 50-100 倍）
# 根因：flutter clean 用 Dart I/O 逐文件删除，在外置 SSD 上几万个小文件会卡死
# ─────────────────────────────────────────────

# 只清 Flutter 构建产物（日常使用）
clean:
	@echo "🧹 快速清理 Flutter 构建产物..."
	rm -rf build/ .dart_tool/
	@echo "✅ 完成 (build/ + .dart_tool/ 已删除)"

# 深度清理：Flutter + iOS Pods（切分支/更新依赖后使用）
clean-ios:
	@echo "🧹 深度清理 Flutter + iOS..."
	killall -9 Xcode xcodebuild Simulator dart ibtoold 2>/dev/null || true
	rm -rf build/ .dart_tool/ ios/build/ ios/Pods/ ios/.symlinks/ ios/Podfile.lock
	@echo "✅ 完成，请执行: make pod"

# 重装 Pods
pod:
	@echo "📦 重装 iOS Pods..."
	cd ios && pod install --repo-update
	@echo "✅ Pod install 完成"

# 完整重建（核弹级，用于死活编不过时）
rebuild-ios: clean-ios
	@echo "🔄 重新拉取 Flutter 依赖..."
	fvm flutter pub get
	@echo "📦 重装 iOS Pods..."
	cd ios && pod install --repo-update
	@echo "🎉 重建完成！"

# ─────────────────────────────────────────────
# 环境健康检查（build 失败时先跑这个排查）
# ─────────────────────────────────────────────
health-check:
	@echo "🩺 Flutter 环境健康检查..."
	@echo ""
	@echo "── Flutter 版本 ──"
	@fvm flutter --version 2>/dev/null | head -1 || echo "❌ FVM flutter 不可用"
	@echo ""
	@echo "── build/ 目录大小 ──"
	@du -sh build/ .dart_tool/ 2>/dev/null || echo "✅ build/ 不存在（已清理）"
	@echo ""
	@echo "── pub 依赖状态 ──"
	@fvm flutter pub deps --no-dev 2>/dev/null | head -3 || echo "⚠️ 需要运行 flutter pub get"
	@echo ""
	@echo "── iOS Pods 状态 ──"
	@if [ -f ios/Podfile.lock ]; then echo "✅ Podfile.lock 存在"; else echo "❌ Podfile.lock 不存在 → 需要 make pod"; fi
	@if [ -d ios/Pods ]; then echo "✅ Pods/ 目录存在"; else echo "❌ Pods/ 不存在 → 需要 make pod"; fi
	@echo ""
	@echo "── FVM 版本锁定 ──"
	@cat .fvm/fvm_config.json 2>/dev/null || echo "⚠️ 未找到 .fvm/fvm_config.json"
	@echo ""
	@echo "🩺 检查完成"

# 新成员/新机器一键初始化
setup:
	@echo "🚀 初始化开发环境..."
	@command -v fvm >/dev/null || (echo "❌ 请先安装 FVM: brew tap leoafarias/fvm && brew install fvm" && exit 1)
	fvm install
	fvm flutter pub get
	cd ios && pod install
	@echo "✅ 环境初始化完成，可以运行 make dev"

