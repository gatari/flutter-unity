.PHONY: setup
setup:
	flutter channel stable
	flutter upgrade
	flutter pub get
	cd ios && pod install

.PHONY: pod
pod:
	cd ios && pod install