# مخزني | Makhzani

Flutter inventory/POS prototype using local SQLite, Arabic RTL and English LTR.

## Features implemented so far
- Product catalogue, barcode lookup/scanning, and basic POS cart.
- Transactional checkout with stock validation, discount/payment method, sale lines and stock movement ledger.
- Purchase entry with supplier text, cost snapshots, and inventory replenishment.
- Excel product-template export/import and multi-sheet inventory, low-stock, sales and purchase reports.
- Local database schema migrations and a CI workflow for Flutter analysis/tests.

## Run
Install Flutter 3.32.8 (or a compatible stable SDK), Android Studio/Android SDK, then:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

If platform folders are missing, generate scaffolding with `flutter create . --platforms android,ios`. Camera testing requires a camera-capable device. iOS builds require macOS and Xcode.

## Important
This is a prototype, not yet suitable as the only business accounting system. Test migrations on a copy of existing data and back up business records. Returns, persistent customer/supplier profiles, receipt printing, backup/restore, full profit analytics, access control, and signed production builds need more implementation and physical-device verification.
