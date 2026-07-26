# GLOBAL OPERATING RULES

1. **RESEARCH BEFORE ASSUMING**
   Before writing code that depends on a third-party API, service, library, pricing, platform limit, or any time-sensitive/environment-specific fact — research it first using real, current sources. State your assumption, verify it, then report findings (including limitations) before implementing. If you can't verify something, say so and ask, rather than guessing silently.

2. **NO FALSE "DONE" CLAIMS**
   A clean compile, "0 errors," or code that looks correct is NOT proof it works. Never say "done," "working," or "ready" unless it has been actually tested against the real thing. Use language like "implemented, not yet verified" until confirmed.

3. **SURFACE PROBLEMS IMMEDIATELY, DON'T HIDE THEM**
   If a requested approach turns out to be based on a false premise (hidden cost, blocked dependency, platform restriction, security issue), stop and report it right away — don't quietly build workarounds or keep going without flagging it.

4. **EXPLAIN TRADE-OFFS, DON'T JUST PICK ONE SILENTLY**
   When there are multiple ways to solve something (e.g. paid vs free, simple vs robust, fast vs correct), briefly state the real options and their downsides before implementing — don't silently choose the flashiest-sounding one.

5. **MINIMAL, RELEVANT CHANGES**
   Don't rewrite or refactor code outside the scope of what was asked. Don't add features, dependencies, or abstractions that weren't requested "just in case."

6. **FLAG SECURITY/DATA RISKS PROACTIVELY**
   If a task involves secrets, credentials, personal data, or anything security-sensitive, point out risks (e.g. plaintext secrets in files, exposed keys, missing auth) even if not explicitly asked to check.

7. **MATCH EXISTING CODE STYLE**
   Follow the project's existing conventions (naming, structure, formatting, patterns) rather than imposing a different style.

8. **BE HONEST ABOUT UNCERTAINTY**
   If you don't know something, say so directly instead of producing a confident-sounding but unverified answer. Confidence in tone should match actual confidence in correctness.

9. **TEST BEFORE CLAIMING SUCCESS**
   Where a task can be tested (run, compiled, executed against sample input), actually run it and show real output — don't just describe expected behavior.

10. **SUMMARIZE CLEARLY AT THE END**
    After implementation, give a short, accurate summary of what was actually changed, what was verified, and what still needs manual testing or follow-up — no inflated claims.

---

# 58MM THERMAL PRINTER & RECEIPT FORMATTING RULES

## 1. Physical Page Width & Margins
- **Line Width**: Standard 58mm POS thermal printers (e.g. Hoin, POS-58, Xprinter) print a maximum of **30 characters per line** in standard Font A.
- **Never Use 32 Width**: Setting line width to 32 characters causes text overflow past paper margins, triggering ugly single-letter line breaks (`c` / `om`, `juris` / `diction`). Always enforce `lineWidth = 30`.

## 2. Word-Wrapping & Text Centering
- **No Hard Truncation**: Never hard-cut text at 30 characters using `text.substring(0, 30)`.
- **Smart Word Wrapping**: Wrap text cleanly at word boundaries using `EscPosFormatter.wrapText()`.
- **Multi-Line Centering**: Center every wrapped line independently for headers and footers.

## 3. Item Table Grid Alignment (3 Columns)
- **Column Math**:
  - Column 1 (`ITEM`): 18 characters wide (`col 0..17`)
  - Column 2 (`QTY`): 4 characters wide (`col 18..21`, right-aligned)
  - Column 3 (`AMOUNT`): 8 characters wide (`col 22..29`, right-aligned)
  - Line Total = `18 + 4 + 8 = 30 characters`.
- **Header Line**: `ITEM                 QTY  AMOUNT`
- **Item Rows (Compact Paper-Saving)**:
  - Line 1: Col 0-17: Item Name (first 18 chars), Col 18-21: `[qty]` (directly under QTY), Col 22-29: `[numericAmount]` (directly under AMOUNT).
  - Line 2 (only if item name > 18 chars or multi-qty): Remainder of Item Name + parenthetical rate `([rate]/[type])`.

## 4. Amount Column & Formatting Rules
- **No `Rs.` in Item Table Rows**: Do NOT include `Rs.` prefix in item table row amounts. Print plain numeric values (e.g. `160.00`, `60.00`) to prevent column overflow.
- **`Rs.` Scope**: Keep `Rs.` prefix ONLY on `Subtotal`, `Discount`, `Tax`, and `TOTAL` summary lines.
- **No `@` Symbol**: Do NOT print `@` symbols in item rows. Use parenthetical rates `(12.00/Pc)` for multi-quantity items.
- **No Duplicate Unit Rates**: If quantity is 1 (`1Pk` or `1Pc`), do NOT print unit rate on the left because unit price equals total price. Print price ONLY ONCE under `AMOUNT`.

## 5. Hardware ESC/POS Byte Encoding
- **Multi-line Text Splitting**: When sending formatted text blocks to physical thermal printer hardware in `EscPosBuilder.textLine(String text)`, ALWAYS split `text` by `\n` and send each line as an explicit ASCII string followed by hardware byte `0x0A` (LF). Unsplit multi-line strings cause thermal printer firmwares to ignore line breaks or merge text.

## 6. Privacy & Sensitivity Toggles
- **Bank Details & PAN**: Keep company bank account numbers and PAN hidden from customer receipts unless explicitly enabled via Settings toggles (`showBankDetails` / `showPan`).
- **No Barcode Overflow**: Do NOT attempt to print CODE39 barcodes exceeding 58mm paper width. Barcodes are disabled on 58mm thermal receipts to prevent hardware printer timeouts.
