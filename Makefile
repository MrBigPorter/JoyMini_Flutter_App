# 这样你点击 TASK EXPLORER 里的按钮就能跑了

# ─── 正常运行（增量构建，速度快）─────────────────────────────────
dev:
	fvm flutter run --dart-define-from-file=lib/core/config/env/dev.json

test:
	fvm flutter run --dart-define-from-file=lib/core/config/env/test.json

prod:
	fvm flutter run --dart-define-from-file=lib/core/config/env/prod.json

# ─── 出现 "Could not delete Debug-iphoneos" 报错时才用 ────────────
# Xcode 26 bug: 上次构建失败后遗留了脏目录，用这个恢复
dev-fix:
	@echo "🔧 清理 Xcode 26 遗留构建产物..."
	@rm -rf build/ios/Debug-iphoneos build/ios/Debug-iphonesimulator build/ios/XCBuildData 2>/dev/null; true
	fvm flutter run --dart-define-from-file=lib/core/config/env/dev.json

test-fix:
	@rm -rf build/ios/Debug-iphoneos build/ios/Debug-iphonesimulator build/ios/XCBuildData 2>/dev/null; true
	fvm flutter run --dart-define-from-file=lib/core/config/env/test.json

