# RCF FarmLog — Full Product Roadmap

**Project:** Rama Country Farm — Farm Management System  
**Apps:** Web Dashboard (Angular) + Mobile App Flutter (RCF FarmLog)  
**Backend:** Node.js / Express / MongoDB on Render  
**Last updated:** 2026-05-16

---

## Important: How This App Is Used

- **Only one user — the farm owner.** No customer access, no staff login needed.
- **Primary device = Android APK.** Mobile app is the main daily tool.
- **Web dashboard = secondary.** Used for detailed reports and analysis only.
- **No customer-facing features.** Everything is internal for personal tracking.
- **Offline mode is critical** — data entered in the field where internet may be weak.

> Always build mobile-first. Web features are secondary.

---

## Current Status ✅ Already Built

| Module | Web | Mobile |
|---|---|---|
| Login / Auth | ✅ | ✅ |
| Dashboard (stats + charts) | ✅ | ✅ |
| Batches | ✅ | ✅ |
| Daily Farm Log (feed, eggs, medicine) | ✅ | ✅ |
| Egg Collection & Stock | ✅ | ✅ |
| Egg Damage | ✅ | ✅ |
| Sales (payment status, customer link) | ✅ | ✅ |
| Investments / Expenses | ✅ | ✅ |
| Feed Management (Commercial + Own Mix) | ✅ | ✅ |
| Medicine / Supplement Inventory | ✅ | ✅ |
| Vaccination Schedule | ✅ | ✅ |
| Egg Trading (Procurement, Resale, Wastage) | ✅ | ✅ |
| Customers Master | ✅ | ✅ |
| Vendors | ✅ | ✅ |
| Locations | ✅ | ✅ |
| Bird Breeds | ✅ | ✅ |
| Flock Performance | ✅ | ✅ |
| Analytics | ✅ | ✅ |
| Notifications (in-app only) | ✅ | ❌ |

---

## PHASE 1 — Money & Order Tracking
**Priority: HIGH — Build Next**

### 1.1 Payment Method Tracking

Add `paymentMethod` field to every Sale record.

**Options:** Cash / UPI-QR / Bank Transfer / Other

**What to build:**
- Backend: Add `paymentMethod` field to Sale model
- Sales form (web + mobile): Dropdown to pick payment method
- New page: **Collection Report**
  - Filter by date (today / week / month / custom)
  - Shows total received per method (Cash vs UPI vs Bank)
  - Running daily total

**Free tools that connect:**
- PhonePe Business — free merchant QR, 0% UPI fee
- Google Pay Business — free QR, links to existing bank account
- No API needed — manual entry in app after receiving payment

---

### 1.2 Order Source Tracking

Add `orderSource` field to every Sale record.

**Options:** Walk-in / WhatsApp / Instagram / Phone Call / Agent / Other

**What to build:**
- Backend: Add `orderSource` field to Sale model
- Sales form (web + mobile): Dropdown to pick source
- New page: **Order Source Report**
  - Shows orders count + revenue per source
  - Filter by date
  - See which channel brings most business

---

### 1.3 Files to Change for Phase 1

**Backend:**
- `models/Sale.js` — add `paymentMethod`, `orderSource` fields

**Frontend (web):**
- `modules/sales/pages/sale-form/` — add two dropdowns
- New page: `modules/reports/pages/collection-report/`
- New page: `modules/reports/pages/order-source-report/`
- Add "Reports" to sidebar

**Mobile:**
- `screens/sales/sale_form_screen.dart` — add two dropdowns
- New screen: `screens/reports/collection_report_screen.dart`
- New screen: `screens/reports/order_source_report_screen.dart`
- Add to More screen

---

## PHASE 2 — Background Push Notifications
**Priority: HIGH**

> **Important:** Notifications must arrive even when the app is fully closed.  
> In-app notifications are already built. This phase adds true background push.

### How it works (Free)

**Service:** Firebase Cloud Messaging (FCM) — completely free, no limits  
**Works:** Android + iOS, app open or closed or killed

### What notifications to send

| Trigger | Message | When |
|---|---|---|
| Daily evening summary | "Today: 450 eggs collected, ₹3,200 received" | Every day 7PM |
| Feed stock low | "Feed stock low — only 3 days remaining" | When stock < threshold |
| Vaccination due | "Batch A vaccination due tomorrow: Newcastle" | Day before due date |
| Payment overdue | "Ravi Kumar payment overdue — ₹1,500 pending 3 days" | After X days |
| Batch mortality high | "Alert: 5 deaths today in Batch B" | When log entered |

### What to build

**Backend:**
- Install `firebase-admin` npm package
- `services/fcmService.js` — send push via FCM
- `services/schedulerService.js` — cron jobs using `node-cron`
  - Daily 7PM: collect stats → send summary push
  - Every morning: check vaccinations due tomorrow → send push
  - Every morning: check overdue payments → send push
  - On save: check feed stock → send low stock push

**Mobile (Flutter):**
- Add `firebase_messaging` package
- Add `firebase_core` package
- `GoogleService-Info.plist` (iOS) + `google-services.json` (Android)
- Register device token on login → save to backend
- Handle notification tap → open correct screen

**Backend user model:**
- Add `fcmToken` field to User model
- Save token when mobile app logs in

### Free tier limits (Firebase)
- FCM push notifications: **unlimited, always free**
- No credit card required

---

## PHASE 3 — Smart Reports
**Priority: MEDIUM**

One page for each report, with date filters and summary numbers.

| Report | Description |
|---|---|
| Daily Summary | Eggs, feed, deaths, money received — one page per day |
| Monthly P&L | Total revenue vs total expenses vs profit per month |
| Batch Performance | Which batch gives best FCR (feed per egg), best profit |
| Customer Report | Top customers by revenue, who owes money, order frequency |
| Payment Collection | Cash vs UPI vs Bank breakdown with totals |
| Order Source | WhatsApp vs Instagram vs direct — count and revenue |
| Egg Production Trend | Daily/weekly/monthly egg count per batch |
| Feed Cost Analysis | Feed spend vs egg revenue to see efficiency |

**Export:** All reports can be downloaded as CSV and opened in Google Sheets (free)

---

## PHASE 4 — PDF Invoice Generation
**Priority: MEDIUM**

When a sale is made, generate a professional invoice PDF.

**Invoice includes:**
- Rama Country Farm header with logo
- Customer name, address, phone
- Item details (eggs / birds / meat), quantity, price
- Total amount, payment status
- Farm contact and UPI QR code for payment

**Share:** One tap → share PDF on WhatsApp to customer

**What to build:**
- Backend: `services/invoiceService.js` using `pdfkit` (free npm package)
- API: `GET /api/sales/:id/invoice` → returns PDF
- Web: Download button on sale detail page
- Mobile: Share button → opens WhatsApp with PDF

**Cost:** Free (`pdfkit` is open source)

---

## PHASE 5 — WhatsApp Payment Reminder
**Priority: MEDIUM**

When a customer payment is overdue, send a WhatsApp message automatically.

**Free approach (no API cost):**
- Use WhatsApp Business app click-to-chat link
- Backend detects overdue → sends push notification to your phone
- You tap notification → opens WhatsApp directly to that customer with pre-written message

**Message template:**
> "Hi [Name], this is Rama Country Farm. Your payment of ₹[amount] for [item] on [date] is due. Please pay at your earliest. Thank you."

**Future (paid upgrade):** WhatsApp Business API via Interakt or Wati (₹999/month) for fully automatic sending without you touching the phone.

---

## PHASE 6 — Google Sheets Export
**Priority: LOW-MEDIUM**

Monthly reports automatically synced to a Google Sheet.

**What it does:**
- End of month → backend writes all sales, expenses, profit to a Google Sheet
- Accountant gets read-only link to the sheet
- No manual export needed

**Free tool:** Google Sheets API (free, requires Google account)

**What to build:**
- `services/sheetsService.js` — Google Sheets API integration
- Monthly cron job → auto-export
- Web: "Export to Google Sheets" button on reports page

---

## PHASE 7 — Feed Efficiency (FCR) Analytics
**Priority: MEDIUM**

FCR = Feed Conversion Ratio = kg of feed used per egg produced.

Lower FCR = better efficiency = less cost per egg.

**Dashboard shows:**
- FCR per batch per week
- Compare batches side by side
- Alert when FCR worsens (feed going up, eggs going down)

**No extra data needed** — already capturing feed and eggs in Daily Log.

---

## PHASE 8 — Offline Mode (Mobile)
**Priority: LOW**

Farm may have poor internet. App should work offline and sync when connected.

**What it does:**
- Enter daily log, sales, egg collection without internet
- Data saved locally on phone
- When internet comes back → auto sync to backend

**Tool:** Hive (local database for Flutter) — free

---

## PHASE 9 — Role-Based Access (Multi User)
**Priority: LOW**

| Role | Access |
|---|---|
| Owner (you) | Everything |
| Manager | All except financials |
| Worker | Only daily log entry |
| Accountant | Read-only, reports only |

**What to build:**
- Add `role` field to User model
- Backend middleware checks role before each action
- Web: hide/show menu items by role
- Mobile: hide/show screens by role

---

## OPTIONAL FEATURES (Add Later If Needed)

### GST Billing *(optional)*
- Add GST number field to customer
- Invoice shows GST breakdown (CGST + SGST)
- Only needed if your farm is GST registered

### Labour / Staff Tracking *(optional)*
- Staff attendance (present / absent / half day)
- Daily wage calculation
- Monthly salary summary
- Add to investment/expense tracking

---

## Full Feature Map (Everything Interlinked)

```
CUSTOMER places order (WhatsApp / Instagram / Direct)
        ↓
Enter SALE in app → pick Source + Payment Method
        ↓
SALE links to → Customer + Batch + Payment status
        ↓
If Eggs sold → FARM EGG STOCK reduces automatically
If Country Eggs sold → TRADING STOCK reduces automatically
        ↓
DASHBOARD updates → Revenue, Profit, Pending
        ↓
If payment Pending after 3 days → PUSH NOTIFICATION sent to your phone
        ↓
Tap notification → WhatsApp opens to customer with reminder message
        ↓
Customer pays → mark Paid in app → pick Cash or UPI
        ↓
COLLECTION REPORT updates → Cash vs UPI totals
        ↓
End of month → PDF report ready → share with accountant
```

---

## Free Services Used (All Indian-Friendly)

| Service | What for | Cost |
|---|---|---|
| Render.com | Backend hosting | Free |
| MongoDB Atlas | Database | Free (512MB) |
| Firebase FCM | Push notifications (background) | Free forever |
| PhonePe Business | UPI QR for payments | Free, 0% MDR |
| Google Pay Business | Alternative UPI QR | Free, 0% MDR |
| WhatsApp Business | Receive orders | Free |
| Google Sheets API | Report export | Free |
| pdfkit (npm) | PDF invoice generation | Free |
| node-cron (npm) | Scheduled jobs (reminders) | Free |
| Hive (Flutter) | Offline storage | Free |

---

## Build Priority Order
*(Mobile APK first — that is the primary device)*

| # | Feature | Mobile | Web | Effort |
|---|---|---|---|---|
| 1 | Payment method + order source fields in Sales | ✅ First | Then | 1 day |
| 2 | Collection report + order source report | ✅ First | Then | 2 days |
| 3 | Firebase FCM — background push notifications | ✅ Only mobile | Not needed | 3 days |
| 4 | Scheduled cron jobs (daily summary, overdue alerts) | Receives push | — | 2 days |
| 5 | Offline mode (Hive local storage + sync) | ✅ Critical | Not needed | 4 days |
| 6 | PDF invoice → WhatsApp share | ✅ First | Then | 2 days |
| 7 | Smart reports (P&L, batch, customer) | ✅ First | Then | 3 days |
| 8 | FCR feed efficiency analytics | ✅ First | Then | 1 day |
| 9 | WhatsApp reminder (click-to-chat) | ✅ Only mobile | Not needed | 1 day |
| 10 | Google Sheets export | Web only | ✅ | 2 days |
| 11 | Role-based access | Skip — single user | Skip | — |
| 12 | GST billing | Optional | Optional | 2 days |
| 13 | Labour / staff tracking | Optional | Optional | 3 days |

---

## Notes

- All notifications require Firebase FCM setup (one-time, free)
- Background push works on Android without app being open
- iOS background push needs Apple Developer account (₹7,000/year) — Android is fully free
- WhatsApp Business API (fully automatic messages) costs money — use click-to-chat approach first (free)
- Google Sheets export requires one-time Google Cloud setup (free tier)
- Offline mode is the most complex feature — build last
