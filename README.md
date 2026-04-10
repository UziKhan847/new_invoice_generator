# 🧾 Markaz Umaza Invoice Generator

> **An experiment in AI-assisted app development** — this Flutter app was built entirely using [Claude Sonnet 4.6](https://www.anthropic.com/claude) by Anthropic, as a real-world test of how far a single AI model can take a production-grade mobile application from scratch.

---

## 📱 About the App

A full-featured invoicing app built for small businesses, freelancers, and service-based organizations. It handles the complete invoicing lifecycle — from creating and sending invoices, to tracking payments, generating PDFs, and analyzing revenue trends over time.

The app is live in production and used by **Markaz Umaza**, an Islamic education institution in Hamilton, Ontario, Canada.

---

## ✨ Features

### Invoices
- Create invoices with line items, quantities, unit prices, and per-item discounts (% or flat $)
- Auto-number invoices sequentially
- Assign a customer, sender/employee, and optional due date
- Mark invoices as paid individually or in bulk
- Filter invoices by customer, sender, service, month, year, and status
- Multi-select mode — long-press to enter, then bulk mark paid or delete
- Swipe to delete individual invoices

### PDF Generation
- Generates a professional PDF with company logo, sender info, itemized line items, discounts, tax, and e-transfer payment instructions
- Download to device, share, print, or email directly from the app
- Loading overlay during generation so the UI never freezes

### Customers, Employees & Services
- Manage customers with name, email, address, and phone
- Manage employees (senders) with role and e-transfer email
- Manage services with name, description, unit price, and rate type (hourly, daily, monthly, etc.)
- All lists sorted alphabetically

### Recurring Invoices
- Set up recurring invoice templates that auto-generate on schedule

### Charts & Analytics
- Revenue bar chart, paid/unpaid donut, and invoice count line chart
- Filter charts by year, customer, and sender
- Responsive landscape layout with side panel
- Automatically refreshes when invoice data changes

### Company Profile
- Company name, address, email, phone, tax number
- Upload and crop a company logo (camera or gallery)
- Logo appears on all generated PDFs

### Auth & Multi-Account
- Email/password authentication via Supabase
- Full data isolation between accounts — logging out and into a new account always shows fresh data

### UX Details
- Dark/light mode toggle
- Persistent theme across sessions
- All slow operations (PDF, email, download) show a modal loading overlay

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Backend / Auth / DB | Supabase (PostgreSQL + RLS) |
| PDF Generation | `pdf` + `printing` packages |
| Image Cropping | `custom_image_crop` |
| Email | `flutter_email_sender` |
| File Download | `path_provider` + `share_plus` |

---

## 🤖 Built with Claude

This entire app — every screen, provider, model, repository, service, PDF layout, chart painter, and database schema — was written by **Claude Sonnet 4.6** through a series of conversational prompts. No code was written by hand.

The development process included:
- Designing the full Supabase schema from scratch
- Implementing Riverpod state management with AsyncNotifier
- Building custom Flutter painters for bar charts, line charts, and donuts
- Debugging RLS policies, Supabase FK hints, Dart type errors, and Android snackbar quirks
- Iterative UI refactoring as the app grew in complexity

This is an ongoing experiment to understand the real ceiling of AI-assisted software development on a production app with real users and real data.

---

## 🗄 Database Setup

The app uses Supabase. To set up:

1. Create a new Supabase project
2. Run `schema.sql` in the SQL Editor to create all tables, views, and RLS policies
3. Run `schema_v4_discount.sql` to add discount columns to invoice items
4. Add your Supabase URL and anon key to `lib/keys.dart`

---

## 🚀 Getting Started

```bash
git clone https://github.com/YOUR_USERNAME/new_invoice_generator.git
cd new_invoice_generator
flutter pub get
flutter run
```

Make sure you have Flutter 3.x installed and a connected device or emulator.

---

## 📂 Project Structure

```
lib/
  models/          # Invoice, Customer, Employee, Service, etc.
  providers/       # Riverpod AsyncNotifier providers
  repositories/    # Supabase data access layer
  screens/
    home/          # Home screen + chart widgets
    invoice/       # Invoice list, detail, create + widgets
    charts/        # Charts screen + layout widgets
    more/          # Settings, company profile navigation
    auth/          # Login and register forms
  services/        # PDF, email, download, storage
  utils/           # Loading overlay, helpers
```

---

## 📄 License

MIT — feel free to use, fork, and adapt.
