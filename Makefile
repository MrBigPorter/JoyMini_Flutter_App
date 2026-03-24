# 这样你点击 TASK EXPLORER 里的按钮就能跑了
dev:
	flutter run --dart-define-from-file=dev.json

test:
	flutter run --dart-define-from-file=test.json

prod:
	flutter run --dart-define-from-file=prod.json