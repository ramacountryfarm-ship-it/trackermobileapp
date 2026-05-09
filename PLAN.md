# RCF Tracker Mobile App - Complete Redesign Plan

## Problem
- Logo gets cut (1491x560 wide image forced into square)
- Livestock type (Poultry/Goat/Sheep) only on dashboard, not across all pages
- No way to know which animal data belongs to when entering forms
- Pages too simple, need glass/premium design throughout
- Need end-to-end consistency

## Architecture Change: Global Livestock Context

Every screen must know which livestock type is active. User selects once, it persists everywhere.

### How it works:
1. `LivestockProvider` - global state with `currentType` (poultry/goat/sheep)
2. Switcher appears in **AppBar** of main shell (always visible)
3. All list screens filter by livestock type
4. All forms auto-tag with current livestock type
5. Backend `Batch` model gets new field: `livestockType` (poultry/goat/sheep)

---

## Screen-by-Screen Plan

### 1. Login Screen
- [x] Logo: show full width (1491x560), `fit: BoxFit.contain`, height: 50
- [x] Glass card with username + password
- [x] Gradient background

### 2. Main Shell (Bottom Nav)
- Livestock switcher in a **sticky header** above all pages (not just dashboard)
- 3 pill buttons: 🐔 Poultry | 🐐 Goat | 🐑 Sheep
- Glass floating bottom nav bar
- Tabs: Home | Batches | Log | Eggs(poultry only) / Weight(goat/sheep) | More

### 3. Dashboard
- Greeting + date
- Stat cards change per livestock type:
  - **Poultry**: Birds Alive, Eggs Today, Feed Today, Egg Stock
  - **Goat**: Total Goats, Feed Today, Avg Weight, Deaths
  - **Sheep**: Total Sheep, Feed Today, Avg Weight, Deaths
- Financial card (shared across all)
- Alerts

### 4. Batches (filtered by livestock type)
- List shows only batches for current livestock type
- Each card shows: batch name, location, breed, gender badge, bird/animal count, date
- Form fields:
  - Batch Name*, Location*, Breed*, Gender*, Purchase Date*
  - Vendor (optional)
  - If NOT Mixed: Count*, Cost/animal
  - If Mixed: Female count+cost, Male count+cost, Grand Total
  - Notes
  - **livestockType** auto-set from current selection

### 5. Daily Log (filtered by livestock type)
- List with batch filter chips (only batches of current type)
- Swipe to delete
- **Poultry form**: Date, Batch, Morning Feed (commercial/own mix), Evening Feed, Eggs Collected, Broken Eggs, Bird Deaths, Medicine, Notes
- **Goat/Sheep form**: Date, Batch, Feed Given, Weight (kg), Deaths, Medicine, Notes

### 6. Eggs (Poultry only) / Weight Tracking (Goat/Sheep)
- 4th tab changes based on livestock type
- **Poultry**: Egg tabs (Inventory, Collection, Damages) - same as now
- **Goat/Sheep**: Weight tracking screen (weight history per animal/batch)

### 7. Sales
- Filter by livestock type
- Form: Date, Product Type (Eggs/Birds/Meat for poultry, Animals/Meat for goat/sheep), Quantity, Price/Unit, auto Total, Customer, Notes

### 8. Investments
- Shared across all livestock types (feed, medicine, structural costs)
- Category filter, Total display

### 9. Vaccination
- Filtered by livestock type (only shows batches of current type)
- Status toggle (Pending/Completed), overdue highlight

### 10. Feed Management
- Commercial Feed: CRUD (name, brand, price/kg, stock, vendor)
- Own Mix: ingredients with auto cost/kg calculation
- Shared across livestock types

### 11. Medicine & Supplements
- CRUD (name, type, unit, price, stock)
- Shared across livestock types

### 12. Vendors, Locations, Bird Breeds
- Shared across all livestock types
- Bird Breeds could be renamed "Animal Breeds" or filtered

### 13. Performance (Poultry only for now)
- Metrics, egg prediction, feed planner

### 14. Analytics
- Overview cards, charts, insights

---

## Backend Changes Needed

### Batch model - add livestockType field:
```js
livestockType: { type: String, enum: ['poultry', 'goat', 'sheep'], default: 'poultry' }
```

### Batch routes - support filtering:
```
GET /api/batches?livestockType=poultry
```

### DailyFarmLog model - already updated with morning/evening feed + medicine

---

## Flutter Changes

### New: LivestockProvider
```dart
class LivestockProvider extends ChangeNotifier {
  String _type = 'poultry'; // poultry, goat, sheep
  String get type => _type;
  void setType(String t) { _type = t; notifyListeners(); }
}
```

### Updated: main.dart
- Add LivestockProvider to MultiProvider
- Pass livestock type to all routes

### Updated: Every list screen
- Read livestock type from provider
- Pass as query param to API
- Filter results

### Updated: Every form screen
- Auto-set livestockType from provider
- Show livestock badge in form header

### New: LivestockSwitcher widget
- Reusable 3-pill toggle
- Used in main shell header

### Updated: Theme
- Glass cards on ALL screens (not just dashboard)
- Gradient backgrounds on list pages
- Consistent spacing, typography

---

## Implementation Order
1. [DONE] Backend: Add livestockType to Batch model + filter support
2. [DONE] Flutter: Create LivestockProvider + LivestockSwitcher widget
3. [DONE] Flutter: Update main shell with global switcher + glass bottom nav
4. [DONE] Flutter: Fix logo on login (full width, fit: contain)
5. [DONE] Flutter: Update Dashboard per livestock type (poultry/goat/sheep stats)
6. [DONE] Flutter: Update Batch list + form with livestockType auto-tag
7. [DONE] Flutter: Update Daily Log list with livestock filter
8. [ ] Flutter: Update 4th tab (Eggs vs Weight)
9. [ ] Flutter: Update remaining screens (Sales, Vaccination, etc.)
10. [ ] Flutter: Glass design consistency across all pages

---

## Next Session: Egg Trading & Customer Module (Mobile)

These features exist in the web frontend but are NOT yet in the mobile app.
Services are already written and ready — only screens need building.

### Files already created (ready to use):
- `lib/services/customer_service.dart` — full CRUD for `/api/customers`
- `lib/services/egg_trading_service.dart` — all egg trading API calls
- `lib/screens/customers/customer_list_screen.dart` — customer list with search/filter

### Still to build:

#### 1. Customer Form Screen
File: `lib/screens/customers/customer_form_screen.dart`
Fields: name*, phone, address, type (Walk-in/Individual/Wholesaler/Retailer), notes
Route: `/customer-form` (pass customer ID as argument for edit)

#### 2. Egg Trading — Main Screen (tabs)
File: `lib/screens/egg_trading/egg_trading_screen.dart`
Tabs: Summary | Farmers | Procurement | Resale | Wastage | Pending
Route: `/egg-trading`
- Summary tab: trading stock card, total procured/sold/wasted, pending from customers, pending to farmers
- Use `EggTradingService().getSummary()` → fields: `tradingStock`, `totalProcured`, `totalSold`, `totalWasted`, `pendingFromCustomers`, `pendingToFarmers`

#### 3. Farmer List/Form
File: `lib/screens/egg_trading/farmer_form_screen.dart`
Fields: name*, phone, village, preferredPaymentTerms, notes
CRUD via `EggTradingService().getFarmers()` / `createFarmer()` / `updateFarmer()` / `deleteFarmer()`

#### 4. Procurement List/Form
File: `lib/screens/egg_trading/procurement_form_screen.dart`
Fields: date*, farmer* (dropdown), unit (pieces/dozens/trays), quantity*, pricePerUnit*, brokenOnArrival, qualityRating (1-5), paymentStatus (Paid/Partial/Pending), amountPaid, notes
CRUD via `EggTradingService().getProcurement()` / `createProcurement()` etc.

#### 5. Resale List/Form
File: `lib/screens/egg_trading/resale_form_screen.dart`
Fields: date*, customer* (dropdown from CustomerService), unit, quantity*, pricePerUnit*, paymentStatus, amountReceived, deliveryAddress, notes
CRUD via `EggTradingService().getResale()` / `createResale()` etc.

#### 6. Wastage List/Form
File: `lib/screens/egg_trading/wastage_form_screen.dart`
Fields: date*, quantity*, reason, notes
CRUD via `EggTradingService().getWastage()` etc.

#### 7. Register all routes in main.dart
```dart
'/customers': (_) => const CustomerListScreen(),
'/customer-form': (_) => const CustomerFormScreen(),
'/egg-trading': (_) => const EggTradingScreen(),
```

#### 8. Add to more_screen.dart
```dart
_MenuItem(Icons.swap_horiz_rounded, 'Egg Trading', '/egg-trading'),
_MenuItem(Icons.people_outline, 'Customers', '/customers'),
```

#### 9. Dashboard: Add trading stat cards
File: `lib/screens/dashboard/dashboard_screen.dart`
After the existing 4 stat cards (birds/eggs/feed/stock), add a 2-column row:
- Trading Stock: `_stats['tradingStock']` — blue accent (Color(0xFF3498DB))
- To Receive: `_stats['totalPendingReceivables']` — green if 0, red if > 0
- To Pay Farmers: `_stats['totalPendingPayables']` — red accent

#### 10. Sales Form: Add customer dropdown + payment fields
File: `lib/screens/sales/sale_form_screen.dart`
- Add `CustomerService` to load customers list
- Add customer dropdown (searchable or simple DropdownButtonFormField)
- Replace free-text customerName with `customerId` (auto-fills name)
- Add `paymentStatus` dropdown (Paid/Partial/Pending, default: Paid)
- Add `amountReceived` field (show when Partial/Pending)
- Add `paymentDueDate` date picker (show when Partial/Pending)

### Pattern reminders:
- `GlassCard(padding: ..., child: ...)` for cards
- `Fmt.currency()`, `Fmt.number()`, `Fmt.kg()`, `Fmt.date()` for display
- `AppTheme.success` = Color(0xFF34C759), `AppTheme.error` = Color(0xFFFF3B30)
- `AppTheme.warning` = Color(0xFFFF9500), `AppTheme.info` = Color(0xFF007AFF)
- `Future.wait([...])` for parallel API calls in `_load()`
- Confirm delete with `showDialog<bool>()` before calling delete API
