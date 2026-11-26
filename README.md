# مخزني | Makhzani

Flutter inventory and point-of-sale app for Android and iOS, designed for offline use with SQLite. The interface supports Arabic RTL and English LTR.

## Current prototype features
- Local SQLite products and saved language setting.
- Product search and entry, barcode scan screen, basic POS cart, discounts and cash/card payment selection.
- Checkout persisted transactionally with stock validation and stock-movement records.
- Purchase entry that increases inventory.
- Excel inventory export, product template export, and `.xlsx` import.
- GitHub Actions workflow for dependency resolution, formatting, analysis and tests.

## Run
Install Flutter SDK (stable), then:

```sh
flutter pub get
flutter run
```

A camera-enabled Android/iOS device or simulator is needed to exercise barcode scanning. The app stores data locally on the device; it does not sync across devices.

## Excel import format
First sheet, columns in order: `name`, `barcode`, `price`, `quantity`. Use `.xlsx`, non-negative numeric price/quantity values, and unique barcodes. Back up your data before importing.

## Current limitations
This is an early prototype and has not been built or tested on a device in this environment. Returns, customer/supplier ledgers, receipt printing, backups/restoration, advanced analytics, authentication, and release signing remain future work. Review the Actions checks after pushing and resolve any platform or package API issues they find.
