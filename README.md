# 🧾 Markaz Umaza Invoice Generator

A full-featured invoicing and bookkeeping app built for a small Canadian
service business. It handles the complete invoicing lifecycle — creating and
sending invoices, tracking payments, generating PDFs, managing customers and
recurring billing, logging expenses, and exporting CRA-ready tax reports — on
phone, tablet, and desktop, with everything synced through a single cloud
database.

The app is in production use by **Markaz Umaza**, an Islamic education
institution in Hamilton, Ontario, Canada.

Built with **Flutter** and **Supabase**, using **Riverpod** for state
management. It runs on Android, iOS, and Linux desktop from one codebase, with a
layout that adapts from a compact mobile view to a full desktop workspace.

---

## 📱 About the App

A complete invoicing solution for small businesses, freelancers, and
service-based organizations. Beyond basic invoicing it covers Canadian sales
tax, expenses, recurring billing, and annual tax reporting, so a small operator
can run their books end to end without leaving the app.

---

## ✨ Features

### Invoices
- Create, edit, and duplicate invoices with line items, quantities, unit prices, and per-item discounts (% or flat $)
- Decimal quantities for partial hours/weeks (e.g. 3.5)
- Auto-numbered sequentially; assign a customer, sender/employee, and due date
- Email, download as PDF, or share directly from the app
- Mark invoices paid individually or in bulk; multi-select to bulk mark/delete
- Filter by customer, sender, service, month, year, and status

### Canadian Tax Handling
- Tax applied automatically by province (e.g. 13% HST in Ontario, 5% GST in Alberta)
- Exports to international customers are zero-rated at 0%
- The tax rate is frozen on each invoice at creation, so changing your province later never alters past invoices

### Payments
- E-transfer and Stripe payment links
- Stripe is aimed at international customers; amounts are charged in CAD
- Stripe fees can be logged as deductible business expenses

### PDF Generation
- Professional PDF with company logo, sender info, itemized lines, discounts, tax, and payment instructions
- Download, share, print, or email; loading overlay during generation so the UI never freezes

### Customers, Employees & Services
- Customers with structured addresses, tags, and per-customer billing totals
- XLSX import that fuzzy-matches columns and normalizes provinces, countries, and phone numbers
- Employees (senders) with role and e-transfer email
- Services with description, unit price, and rate type (hourly, daily, monthly, etc.)

### Recurring & Private Invoices
- Recurring invoice templates you can generate from on demand for monthly billing
- Private invoices stay out of all official totals, charts, and tax reports while still being emailable, downloadable, and manageable — and they sync across devices

### Expenses & Tax Report
- Categorized expense tracking that feeds input tax credits into the tax report
- Annual tax report: revenue, HST/GST collected, input tax credits, net tax owing, and net profit — exportable as a PDF

### Charts & Analytics
- Revenue bar chart, paid/unpaid donut, and invoice count line chart
- Tap-to-select bars; filter by year, customer, and sender
- Auto-refreshes when invoice data changes

### Company Profile
- Company name, structured address, email, phone, business/RT number
- Upload and crop a company logo; it appears on all generated PDFs

### Layout & Theming
- Mobile layout (bottom nav, cards) and desktop layout (persistent sidebar, master-detail invoice view, data tables)
- Layout chosen automatically by platform and screen size; can be toggled manually on tablets and desktop
- Light, dark, and OLED-black themes, persisted across sessions

### Auth & Multi-Account
- Email/password authentication via Supabase, with password reset
- Full data isolation between accounts via row-level security

> Note: the tax report is a summary tool to assist with bookkeeping. Always
> consult an accountant for official filing.

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Platforms | Android, iOS, Linux desktop |
| State Management | Riverpod (`Notifier` / `AsyncNotifier`) |
| Backend / Auth / DB | Supabase (PostgreSQL + RLS) |
| PDF Generation | `pdf` + `printing` |
| Spreadsheet Import | `excel` + `file_picker` |
| Image Cropping | `image_cropper` / `custom_image_crop` |
| Email | `flutter_email_sender` |
| File Download / Share | `path_provider` + `share_plus` + `open_filex` |
| Fonts | Plus Jakarta Sans (UI) + Spline Sans Mono (numerals) |

---

## 🗄 Database Setup

The app uses Supabase. To set up:

1. Create a new Supabase project.
2. In the SQL Editor, run the schema files **in order**:

   ```
   schema.sql
   schema_additions.sql
   schema_v2_additions.sql
   schema_v3_services.sql
   schema_v4_discount.sql
   schema_v5_notes.sql
   schema_v6_expenses.sql
   schema_v7_quantity_decimal.sql
   schema_v8_province.sql
   schema_v9_payment_method.sql
   schema_v10_private_and_recurring.sql
   schema_v11_structured_address.sql
   schema_v12_tags_and_events.sql
   ```

   (`migration_owner_fix.sql` sets `owner_id` for row-level security if you have existing rows.)

3. Add your Supabase URL and anon key in `lib/main.dart`:

   ```dart
   const supabaseUrl     = 'YOUR_SUPABASE_URL';
   const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

---

## 🚀 Getting Started

```bash
git clone https://github.com/YOUR_USERNAME/new_invoice_generator.git
cd new_invoice_generator
flutter pub get
flutter run
```

Make sure you have Flutter 3.x installed and a connected device or emulator.
For Linux desktop builds you'll also need:
`clang cmake ninja-build pkg-config libgtk-3-dev`.

---

## 📦 Building for Release

**Android**

```bash
flutter build apk --release
```

**Linux desktop**

```bash
flutter build linux --release
```

The desktop bundle is at `build/linux/x64/release/bundle/`. To package it as a
portable AppImage:

```bash
dart pub global activate flutter_distributor
flutter_distributor package --platform linux --targets appimage
```

---

## 📂 Project Structure

```
lib/
  models/          # Invoice, Customer, Employee, Service, Expense, etc.
  providers/       # Riverpod state (Notifier / AsyncNotifier)
  repositories/    # Supabase data access layer
  services/        # PDF, email, download, import, receipts
  utils/           # Theme, formatting, loading overlay, helpers
  screens/
    home/          # Home/overview + chart widgets
    invoice/       # Invoice list, detail, create + widgets
    charts/        # Charts screen + widgets
    auth/          # Login / register
    more/          # Settings hub (mobile)
    desktop/       # Desktop sidebar shell + desktop screens
```

---

## 📄 License

MIT — feel free to use, fork, and adapt.
