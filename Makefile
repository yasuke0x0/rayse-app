.PHONY: web android ios clean get analyze

web:
	flutter run -d chrome

android:
	flutter run -d android

ios:
	flutter run -d ios

get:
	flutter pub get

analyze:
	flutter analyze

clean:
	flutter clean && flutter pub get

build-apk:
	flutter build apk --release

commit:
	git add . && git commit -m "$(m)" && git push