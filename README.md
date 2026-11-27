# مخزني | Makhzani

Flutter inventory and POS prototype for Android and iOS, designed for offline use with SQLite. Supports Arabic RTL and English LTR.

## Available in this prototype
- Local SQLite products and saved language selection.
- Product search/entry, camera barcode scan screen, basic POS cart, discounts, and cash/card payment selection.
- Transactional checkout with stock checks and stock movement records.
- Purchase entry that increases stock.
- Excel product-template export and `.xlsx` import.
- Multi-sheet Excel export for inventory, low-stock products, sales, and purchases.
- GitHub Actions for Flutter dependency resolution, static analysis, and tests.

## Run locally
Install the stable Flutter SDK and Android Studio/Android SDK. Clone or download this repository, then run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

If platform folders are absent, generate the Android/iOS scaffolding with `flutter create . --platforms android,ios`. Barcode camera behavior requires a camera-capable device or simulator. iOS builds require macOS and Xcode.

## Excel product import
Use an `.xlsx` workbook with a `Products` sheet (or first sheet) and header columns `name`, `barcode`, `price`, `quantity`. Names must be non-empty; prices and quantities must be non-negative numbers. Import is row-by-row, so validate the workbook before importing; keep a backup of business data.

## Important limitations
This is not yet a production-ready accounting system. It has not been verified on physical Android/iOS devices. Returns, detailed customer/supplier ledgers, receipt printing, database backup/restore, advanced profit analytics, access control, and signed release builds remain to be implemented and tested. Check the Actions workflow after pushing; CI does not replace device testing.
