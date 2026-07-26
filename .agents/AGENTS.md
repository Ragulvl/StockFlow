# StockFlow — AI Agent Operating Guide
# READ THIS ENTIRE FILE BEFORE MAKING ANY CODE CHANGE

This file applies to ALL AI models and ALL chat sessions working on the StockFlow project.
These rules are not optional. Follow them in every chat, even if you have no prior context.

---

## 1. WHAT IS THIS APP?

**StockFlow** is a production Android POS (Point of Sale) application built with **Flutter + Dart**.
It is used by a real business (a chocolate retail shop) to:
- Manage product inventory (stock levels, categories, pricing)
- Create and print customer invoices/bills
- Print receipts on a 58mm USB thermal printer (ESC/POS protocol)
- Track daily sales analytics
- Receive wireless (OTA) app updates from GitHub

**Target Device**: Samsung Galaxy S24 Ultra (Android)
**Build System**: Flutter / Dart, with native Android Kotlin channels
**State Management**: Riverpod (flutter_riverpod)
**Navigation**: GoRouter (go_router)
**Database**: Drift (SQLite ORM — local, offline)
**OTA Updates**: GitHub raw file hosting (`version.json` + APK on `main` branch)

---

## 2. PROJECT STRUCTURE

```
lib/
  main.dart                          ← App entry point
  features/
    dashboard/                       ← Home screen, daily summary, notifications bell
    billing/                         ← Invoice creation, cart, payment dialog
    bills_history/                   ← Past invoices list
    inventory/                       ← Product management, stock adjustment
    analytics/                       ← Sales charts and reports
    settings/                        ← Business info, printer, backup, OTA updates
  core/
    database/app_database.dart       ← Drift DB schema + queries
    printer/
      esc_pos_formatter.dart         ← Receipt text formatting (58mm rules)
      esc_pos_builder.dart           ← ESC/POS byte builder (hardware commands)
      usb_printer_adapter.dart       ← USB serial communication layer
      print_queue.dart               ← Job queue for print tasks
    services/
      app_update_service.dart        ← Wireless OTA update: check / download / install
    notifications/
      notification_service.dart      ← flutter_local_notifications wrapper
    theme/                           ← AppColors, AppTypography (dark theme)
    router/                          ← GoRouter route definitions
  models/
    product_model.dart
    bill_model.dart
  repositories/
    inventory_repository.dart
    bill_repository.dart
    settings_repository.dart
    printer_repository.dart
    backup_repository.dart
  providers/
    repository_providers.dart        ← Riverpod providers for all repositories
    billing_providers.dart
    inventory_providers.dart
    dashboard_providers.dart
    analytics_providers.dart
```

---

## 3. MANDATORY CODING RULES (FOLLOW IN EVERY SESSION)

### 3.1 General AI Behaviour
1. **Read before writing** — Always read the relevant files before editing. Never guess at class names, field names, or method signatures.
2. **No false "done" claims** — Only say "done" or "working" after running `flutter analyze` with 0 errors AND verifying real behaviour. Use "implemented, not yet verified" otherwise.
3. **Minimal changes** — Do not refactor, rename, or restructure code outside the direct scope of what was asked.
4. **Match existing style** — Follow the project's existing naming, spacing, and widget patterns. Do not impose a new style.
5. **Surface problems immediately** — If you find a bug, a blocked API, or a wrong assumption, stop and report it. Do not silently work around it.
6. **No placeholder content** — Do not add stub functions, TODO comments, or placeholder data without explicitly flagging them.

### 3.2 Flutter / Dart Rules
- Always run `flutter analyze` after making code changes and fix all `error` and `warning` level issues before committing.
- Remove unused imports when removing features.
- Prefer `!` (non-null assert) over `?.` when a variable is guaranteed non-null at that code path.
- Do NOT use `const` for variables that reference non-const values.

### 3.3 Version Management
- **`pubspec.yaml` and `version.json` must always stay in sync.**
- When releasing any update, bump BOTH files to the same version string.
- `version.json` format:
  ```json
  {
    "version": "X.Y.Z+N",
    "url": "https://raw.githubusercontent.com/Ragulvl/StockFlow/main/app-release.apk",
    "notes": "Short human-readable release notes",
    "force_update": false
  }
  ```
- The APK at the `url` in `version.json` must be the **compiled release build** for that version.
  If no new APK is compiled, do NOT bump the version — the OTA system will try to install the wrong file.

### 3.4 OTA Wireless Update System — CRITICAL RULES
The wireless update system (`app_update_service.dart`) works as follows:
1. `checkForUpdates()` fetches `version.json` from GitHub raw.
2. It compares `version.json["version"]` to the currently installed version via native `getAppVersion` MethodChannel.
3. If newer → shows "Update Available". User taps Download → `downloadApk()` fetches the APK file from `version.json["url"]`.
4. APK is saved to temp dir, verified as a valid ZIP (PK header `0x50 0x4B`), then passed to native `installApkFile` MethodChannel.

**Known Issues / Do Not Break:**
- The `getSelfApkPath` fallback (when download fails) copies the **currently installed APK** as the update file. Android will silently reject installing the same version. This fallback only exists for debugging — never rely on it for production.
- The `_kDefaultVersion = '1.0.0+1'` constant MUST be kept in sync with `pubspec.yaml`. If it falls behind, the offline fallback will always report a false "update available".
- The offline fallback must return `currentVersion` (not a hardcoded stale version string) so that no phantom update is shown when offline.
- `const fallbackVersion = currentVersion;` is a **Dart compile error** — `currentVersion` is a runtime `final String`, not a compile-time const. Use `final fallbackVersion = currentVersion;` instead.

### 3.5 No Test / Debug Code in Production
The following are **permanently banned** from the production app:
- "Test Notification" / "Send Test Alert" buttons
- "Test Thermal Printer" / "Execute ESC/POS Test Print" buttons
- Any hardcoded test version strings (e.g. `'1.0.3+4'` in service files)
- Any snackbar/toast that says "test" in the message
- VID/PID hex codes shown to the user in printer dialogs
- `print()` statements in production code (use `AppLogger` instead)

---

## 4. 58MM THERMAL PRINTER RECEIPT FORMATTING RULES

### 4.1 Physical Page Width
- **Line width = 30 characters** for 58mm thermal printers (Hoin, POS-58, Xprinter, etc.)
- NEVER use 32 characters — causes single-letter overflow line breaks

### 4.2 Text Wrapping
- Use `EscPosFormatter.wrapText()` for smart word-boundary wrapping — never `substring(0, 30)`
- Center each wrapped line independently

### 4.3 Item Table Layout (3 columns, 30 chars total)
```
Column 1: ITEM    → chars 0-17  (18 chars, left-aligned)
Column 2: QTY     → chars 18-21 (4 chars, right-aligned)
Column 3: AMOUNT  → chars 22-29 (8 chars, right-aligned)
Total = 18 + 4 + 8 = 30 ✓
```
- Header: `ITEM                 QTY  AMOUNT`
- Line 1: Item name (first 18 chars) | qty | amount (no `Rs.` prefix)
- Line 2 (only if name > 18 chars or qty > 1): remainder of name + `(rate/unit)`

### 4.4 Currency Formatting
- **Item rows**: Plain number only → `160.00` (no `Rs.` prefix — prevents overflow)
- **Summary lines** (Subtotal, Tax, TOTAL): Include `Rs.` prefix → `Rs. 160.00`
- No `@` symbols — use parenthetical format: `(12.00/Pc)`
- If qty = 1, do NOT print unit rate (unit price = total price, no need to repeat)

### 4.5 ESC/POS Byte Encoding
- In `EscPosBuilder.textLine(String text)`: **ALWAYS split by `\n`** and send each line as ASCII + `0x0A` byte
- Do not pass unsplit multi-line strings to the printer — firmware ignores embedded `\n`

### 4.6 Privacy Toggles
- Bank account number & IFSC: hidden by default, shown only if `showBankDetails = true` in Settings
- Company PAN: hidden by default, shown only if `showPan = true` in Settings
- Never print CODE39 barcodes on 58mm receipts (causes hardware timeout)

---

## 5. UI / CUSTOMER-FACING TEXT RULES

This app is delivered to non-technical business owners. All UI text must follow these rules:

| ❌ Technical (banned) | ✅ Customer-friendly |
|---|---|
| "USB ESC/POS Thermal Printer" | "Receipt Printer" |
| "System Diagnostics & Info" | "App Updates" |
| "App Settings & Hardware" | "Settings" |
| "Configure USB ESC/POS..." | "Manage your business details, printer & receipt settings" |
| "VID: 0x0456 \| PID: 0x0808" | "USB Printer Device" |
| "Offline Version Control" | "Keep your app up to date wirelessly" |
| "All test sales cleared" | "All bills and sales history have been cleared." |
| "ESC/POS byte sequence" | (remove entirely — never show to user) |

---

## 6. DATABASE (DRIFT) PATTERNS

- Schema lives in `lib/core/database/app_database.dart`
- All DB writes that affect multiple tables (e.g. create bill + reduce stock) must be wrapped in `transaction(() async { ... })`
- Repository classes live in `lib/repositories/` and are provided via Riverpod in `lib/providers/repository_providers.dart`
- Never call database methods directly from UI widgets — always go through the repository

---

## 7. COMMIT AND RELEASE WORKFLOW

When pushing any update:
1. Run `flutter analyze` → fix all errors/warnings
2. Bump `pubspec.yaml` version
3. Bump `version.json` version to match (same string)
4. Write clear commit message: `fix:`, `feat:`, or `polish:` prefix
5. `git add . && git commit -m "..." && git push origin main`
6. If it's a version the customer's phone should receive: compile release APK (`flutter build apk --release`) and upload to GitHub as `app-release.apk` on `main` branch

**The phone gets updates wirelessly via `version.json` on GitHub. The update only works if the actual APK file at the URL is the new version.**

---

## 8. WHAT NOT TO DO (EVER)

- Do NOT remove the Products / Inventory section
- Do NOT remove the Billing / Invoice creation flow
- Do NOT remove the USB printer pairing or `_buildPrinterStatusCard()`
- Do NOT remove the OTA update modal (`_showDiagnosticsModal`)
- Do NOT add new dependencies without checking `pubspec.yaml` first
- Do NOT hardcode store-specific data (store name, address, PAN) in code — it lives in Settings DB
- Do NOT call `print()` for logging — use `AppLogger.info()`, `AppLogger.warning()`, `AppLogger.error()`
