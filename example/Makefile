.PHONY: setup
setup:
	flutter channel stable
	flutter upgrade
	flutter pub get
	cd ios && pod install

.PHONY: pod
pod:
	cd ios && pod install

.PHONY: run-ios
run-ios:
	flutter run

.PHONY: run-android
run-android:
	flutter pub run flutter_unity:unity_export_transmogrify
	flutter run