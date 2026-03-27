# Aqar App — Claude Code Screen Prompts
### Airbnb UI · Golden Yellow #F5A623 · Flutter + Riverpod + Go Router

---

## HOW TO USE THIS DOCUMENT

1. Start every new Claude Code session by pasting the **Session Header** below
2. Then paste the prompt for the screen you want to build
3. Go screen by screen, in order
4. Never skip the Session Header — Claude Code has no memory between sessions

---

## SESSION HEADER
> Paste this at the start of EVERY Claude Code session

```
We are building "Aqar App" — a Flutter real estate marketplace (similar to Airbnb + Aqar.sa).

Tech stack:
- Flutter + Dart
- State management: Riverpod
- Navigation: Go Router
- Architecture: Clean Architecture (features / core / shared)
- RTL support (Arabic) + LTR (English)
- Dark mode + Light mode

Design system:
- We follow Airbnb's UI patterns exactly (layout, spacing, components, flows)
- Primary color: #F5A623 (Warm Golden Yellow) — replaces Airbnb's coral/pink everywhere
- Primary Dark: #E09400
- Background: #FFFFFF
- Surface: #F7F7F7
- Text Primary: #222222
- Text Secondary: #717171
- Divider: #EBEBEB
- Error: #FF5A5F
- Success: #00A699

Rules:
- No hardcoded colors — always use theme constants
- All screens are RTL-ready
- Use mock/dummy data — no real API calls yet
- Separate UI from logic always
- Follow the existing folder structure
```

---

## SCREEN 01 — Splash Screen

**Airbnb Equivalent:** Airbnb Splash Screen

```
Build the Splash Screen for the Aqar app.

Follow Airbnb's splash screen pattern:
- Full screen with brand color background (#F5A623)
- Centered app logo / app name "Aqar" in white
- Smooth fade-in animation on load
- After 2 seconds, auto-navigate to Onboarding 
  (if first time) or Home (if already logged in)
  
- Use a Riverpod provider to check if user 
  has seen onboarding before

Keep it clean, minimal, and fast.
```

---

## SCREEN 02 — Onboarding

**Airbnb Equivalent:** Airbnb first-launch onboarding slides

```
Build the Onboarding Screen for the Aqar app.

Follow Airbnb's onboarding pattern:
- 3 swipeable slides with page indicator dots
- Each slide has: full screen illustration area (top), 
  bold title, subtitle text, and next button
- Last slide has "Get Started" button instead of "Next"
- Skip button at top right on all slides except last
- Page indicator dots use primary color #F5A623 for active
- Smooth slide transition animation

Slide content:
1. "Find Your Dream Property" — browse thousands of listings
2. "Connect With Owners" — chat directly, no middleman
3. "Book or Buy with Ease" — safe, fast, verified

After Get Started → navigate to Login screen.
Mark onboarding as seen in local storage.
```

---

## SCREEN 03 — Login / Register

**Airbnb Equivalent:** Airbnb login/signup modal flow

```
Build the Login and Register screens for the Aqar app.

Follow Airbnb's auth flow pattern:
- Clean minimal screen, logo at top center
- "Continue with Phone" as primary option (large button, 
  primary color #F5A623)
- Divider "or" 
- "Continue with Google" (outlined button)
- "Continue with Apple" (outlined button)
- Bottom: "By continuing you agree to our Terms of Service"

For Phone Login:
- Step 1: Enter phone number with country code picker
- Step 2: Enter OTP code (4 or 6 digit input boxes, 
  Airbnb style centered boxes)
- Resend code option with countdown timer

For Register (if new user):
- After OTP verified: ask for Name, Email (optional)
- Choose role: "I want to browse" / "I'm an Owner or Broker"

Use Riverpod for auth state.
Navigate to Home after successful login.
```

---

## SCREEN 04 — Home Page (Real Estate Tab)

**Airbnb Equivalent:** Airbnb main home feed

```
Build the Home Screen (Real Estate tab) for the Aqar app.

Follow Airbnb's home feed layout exactly:
- Top: Search bar (same style as Airbnb — rounded, 
  with location + dates + guests feel but adapted to:
  City | Category | More filters)
- Below search: Horizontal scrollable category chips 
  (Apartment, Villa, Land, Commercial, etc.) with icons
  Active chip uses #F5A623 background
- Main feed: Vertical list of property listing cards

Each listing card (Airbnb style):
- Full width photo (rounded corners, 12px radius)
- Heart/favorite icon top right on photo
- Below photo: City · Category (grey text)
- Bold price (total price in SAR)
- Area m² · Bedrooms · Bathrooms · Living rooms
- One line of description in grey
- Small spacing between cards

Bottom Navigation Bar (Airbnb style, 5 tabs):
- Home (active)
- Search
- Add Listing (center button, #F5A623 colored)
- Chats
- Account

Use mock listing data (10 items minimum).
```

---

## SCREEN 05 — Home Page (Projects Tab)

**Airbnb Equivalent:** Airbnb Experiences tab

```
Build the Projects tab on the Home Screen for the Aqar app.

Follow Airbnb's Experiences tab layout:
- Same top search bar adapted for projects 
  (City | Project Type)
- Horizontal city filter chips
- Project cards in vertical feed:

Each project card:
- Large photo (full width, rounded)
- Favorite icon top right
- Developer/Project name (bold)
- Location · City
- "Starting from SAR [price]"
- Availability badge (Ready / Off-Plan)
- One line description in grey

Same bottom navigation bar as Home screen.
Use mock project data (6 items minimum).
```

---

## SCREEN 06 — Home Page (Daily Rent Tab)

**Airbnb Equivalent:** Airbnb main home feed (this is the closest match)

```
Build the Daily Rent tab on the Home Screen for the Aqar app.

Follow Airbnb's home feed layout exactly — this tab 
is the most similar to core Airbnb:
- Top: Date picker bar (check-in / check-out) 
  Airbnb style — two rounded boxes side by side
- Below: Guest count selector
- Category chips: Apartment · Chalet · Rest House · Villa

Each rental card (identical to Airbnb listing card):
- Full width photo with favorite icon
- City · District
- Star rating + number of reviews
- Price per night in SAR (bold)
- Area · Bedrooms · Bathrooms

Tapping a date triggers the calendar modal 
(Airbnb style month calendar, range selector,
primary color #F5A623 for selected range).

Use mock rental data (10 items minimum).
```

---

## SCREEN 07 — Property Details

**Airbnb Equivalent:** Airbnb Listing Details screen — this is the most important screen

```
Build the Property Details screen for the Aqar app.

Follow Airbnb's listing details screen exactly:

PHOTO SECTION:
- Full width photo at top (no app bar, 
  overlaid back arrow and share button)
- Tap photo → full screen gallery viewer 
  (swipeable, shows photo count)

CONTENT SECTION (scrollable below):
- Property title (bold, large)
- City · District · Category (grey)
- Divider
- Quick stats row: Bedrooms · Bathrooms · 
  Living Rooms · Area m² (icons + numbers, Airbnb style)
- Divider
- Owner/Broker card:
  Profile photo · Name · Rating · Last active
  (Airbnb host card style)
- Divider
- "About this property" — description text 
  with "Show more" expand
- Divider
- Features section (water, electricity, etc.) 
  with icons — Airbnb amenities style grid
- Divider
- Location section — static map snapshot 
  with "Show on map" button
- Divider
- Price section (Total price bold + per m² calculated)

BOTTOM BAR (fixed, Airbnb style):
- Left: Price (bold)
- Right: Two buttons — WhatsApp (green) · Call (#F5A623)
- Also: Chat on app button (outlined)

Action buttons (top of screen overlay):
- Share · Favorite · Like · Report (as icon buttons)

Use mock property data.
```

---

## SCREEN 08 — Project Details

**Airbnb Equivalent:** Airbnb Experience Details screen

```
Build the Project Details screen for the Aqar app.

Follow Airbnb's Experience details layout:

- Full width photo/banner at top
- Back button overlay
- Project name (bold, large)
- Developer name · Location · City
- Divider
- Quick stats: Total Units · Price Range (from - to) · 
  Delivery Date · Status (Ready/Off-Plan)
- Divider
- About the project — description with Show more
- Divider
- Available Units section:
  Horizontal filter chips (Studio, 1BR, 2BR, 3BR, Villa)
  Unit cards below: Space · Price · Availability badge
- Divider
- Location map snapshot
- Divider
- Developer info card

BOTTOM BAR:
- "Contact Developer" button (full width, #F5A623)
- Share icon button

Use mock project data.
```

---

## SCREEN 09 — Short Rental Details

**Airbnb Equivalent:** Airbnb listing details — this is the closest 1:1 match

```
Build the Short Rental Details screen for the Aqar app.

This screen is almost identical to Airbnb's listing 
details. Follow it exactly:

- Photo carousel at top (swipeable, dot indicators)
- Back button and share/favorite overlaid on photo
- Title (bold)
- City · District · Rating (stars + count)
- Quick stats: Bedrooms · Bathrooms · Living rooms · Area
- Divider
- Host card (photo, name, verified badge, response rate)
- Divider
- Description with Show more
- Divider
- Amenities grid (Airbnb style icons + labels)
- Divider
- Date availability section:
  Check-in / Check-out (tappable, opens calendar)
- Divider
- Location map
- Divider
- Reviews section (rating breakdown + 3 reviews shown)
  "Show all reviews" button

BOTTOM BAR (Airbnb style):
- Left: Price per night (bold) + total for selected dates
- Right: "Reserve" button (#F5A623, rounded)

HORIZONTAL SCROLL:
- "Other units from this host" — horizontal 
  scroll of similar rental cards at bottom

Like · Favorite · Share · Hide · Report as icon buttons.
Use mock data.
```

---

## SCREEN 10 — Search Screen

**Airbnb Equivalent:** Airbnb search and filter screen

```
Build the Search Screen for the Aqar app.

Follow Airbnb's search experience:

NORMAL SEARCH MODE:
- Search bar at top (auto-focused when screen opens)
- Below: Filter options as a form:
  1. Category picker (bottom sheet, grid of category cards)
  2. City picker (bottom sheet, searchable list)
  3. Direction/District picker (dropdown)
  4. "Marketing requests only" toggle switch
- "Search" button (#F5A623, full width at bottom)
- Results appear below as listing cards 
  (same card style as home feed)

AD / PHONE NUMBER SEARCH MODE:
- Tab switcher at top: "Filter Search" | "Ad or Phone"
- In this mode: single text input 
  "Enter ad number or phone number"
- Search button

FILTER BOTTOM SHEET (Airbnb filter modal style):
- Slides up from bottom
- Price range slider
- Property type checkboxes
- Bedrooms selector (0, 1, 2, 3, 4, 5+) 
  Airbnb style pill buttons
- Amenities checkboxes
- "Clear all" and "Show results" buttons at bottom

Use mock search results.
```

---

## SCREEN 11 — Add Listing Flow

**Airbnb Equivalent:** Airbnb "Host your home" multi-step flow

```
Build the Add Listing multi-step flow for the Aqar app.

Follow Airbnb's hosting setup flow:
- Progress bar at top showing current step
- Back arrow on each step
- "Next" button at bottom (#F5A623)
- Smooth step transition animation

STEP 1 — Category:
- Title: "What type of property is this?"
- Grid of category cards with icons 
  (Apartment for Sale, Apartment for Rent, 
   Villa, Land, Commercial, etc.)
- Selected card highlights with #F5A623 border
- Airbnb category selection style

STEP 2 — Media:
- Title: "Add photos and videos"
- Large dashed upload area (tap to pick photos)
- Uploaded photos shown in draggable grid
- First photo = cover photo (labeled)
- Video upload option below
- Minimum 3 photos hint

STEP 3 — General Info:
- Total price (number input with SAR label)
- Area in m² (number input)
- Residential or Commercial (toggle/selector)
- Commission toggle — if ON: show commission % input
- Description (multiline text input)

STEP 4 — Features:
- Title: "What does this property offer?"
- Airbnb amenities selection style:
  Grid of feature cards with icons
  (Water, Electricity, Sewage, Private Roof, 
   In Villa, Two Entrances, Special Entrance)
  Tap to toggle — selected = #F5A623 background

STEP 5 — Details:
- Bedrooms (number stepper — Airbnb style + / -)
- Living Rooms (number stepper)
- Bathrooms/WC (number stepper)
- Facade direction (North/South/East/West — pill selector)
- Street Width (number input)
- Floor number (number input)
- Property age in years (number input)
- Checklist (Furnished, Kitchen, Extra Unit, 
  Car Entrance, Elevator) — toggle switches

STEP 6 — Location:
- Title: "Where is your property?"
- Full screen map (Google Maps)
- Draggable pin to set location
- Address auto-filled below map
- "Confirm Location" button

FINAL STEP — Review & Publish:
- Summary of all entered data
- Edit button next to each section
- "Publish Listing" button (#F5A623, full width)

Use Riverpod to manage form state across steps.
```

---

## SCREEN 12 — Account Screen

**Airbnb Equivalent:** Airbnb Profile / Account screen

```
Build the Account Screen for the Aqar app.

Follow Airbnb's profile screen layout:

TOP SECTION:
- If not logged in: "Log in to Aqar" prompt 
  with login button (#F5A623)
- If logged in:
  Profile photo (circular) + Name + 9-digit user number
  Establishment name and logo (if broker)
  Star rating display
  "View profile" link

WALLET CARD:
- Card with wallet balance (SAR amount, bold)
- "Top Up" button (#F5A623)
(Airbnb-style payment section card)

QUICK ACTIONS GRID:
- "Add Listing" button (icon + label)
- "Add Marketing Request" button

MENU SECTIONS (Airbnb settings list style):
Section: My Activity
- My Listings (icon + arrow)
- My Deals
- My Bookings
- Requests
- Unit Reservation Requests
- My Clients (CRM)
- Favorites

Section: Host Tools
- Listing Promotion
- Aqar+ Subscription

Section: Account
- Payments & Invoices
- Notifications
- Update Profile
- Change Mobile Number
- Establishment Account
- Settings

Bottom: Log Out button (text, red color)

Each menu item: left icon · label · right arrow
Use Airbnb's grouped list style with section headers.
```

---

## SCREEN 13 — My Listings

**Airbnb Equivalent:** Airbnb "Your listings" host dashboard

```
Build the My Listings screen for the Aqar app.

Follow Airbnb's host listings management screen:

TOP:
- Screen title "My Listings"
- Filter tab bar (Airbnb pill tab style):
  All · Published · Paused Temporarily · 
  Paused · Expired

Each listing card (horizontal layout):
- Left: thumbnail photo (rounded, square)
- Right: 
  Address/title (bold)
  Area m² · Bedrooms · Bathrooms · Living rooms
  Price (SAR, bold)
  Message requests count badge (#F5A623)
  Status badge (Published/Paused/Expired)

Swipe left on card → reveals Delete and Pause options
(Airbnb-style swipe actions)

Tap card → goes to listing details with edit option

FAB (Floating Action Button, #F5A623):
- "+" icon to add new listing

Empty state:
- Illustration + "No listings yet" 
- "Add your first listing" button

Use mock listing data.
```

---

## SCREEN 14 — Chats

**Airbnb Equivalent:** Airbnb Messages screen

```
Build the Chats screen for the Aqar app.

Follow Airbnb's messages/inbox screen exactly:

LIST VIEW:
- Screen title "Messages"
- Each chat row:
  Left: Profile photo (circular, with online indicator dot)
  Center: Name (bold) · Ad number (grey, small)
          Last message preview (grey, one line)
  Right: Date/time · Unread count badge (#F5A623)

Swipe left on chat → Delete option

Tap chat row → opens Chat Detail screen

CHAT DETAIL SCREEN (Airbnb message thread style):
- Top: back arrow · contact name · 
  property thumbnail (tap → property details)
- Message bubbles:
  Sent: right aligned, #F5A623 background, white text
  Received: left aligned, #F7F7F7 background, dark text
  Timestamp below each bubble group
- Bottom input bar:
  Text input (rounded) + Send button (#F5A623)

Empty state:
- "No messages yet"
- "Start by browsing listings" button

Use mock chat data.
```

---

## SCREEN 15 — Notifications

**Airbnb Equivalent:** Airbnb Notifications screen

```
Build the Notifications screen for the Aqar app.

Follow Airbnb's notifications list:

- Screen title "Notifications"
- Each notification row:
  Left: Icon or profile photo (circular)
  Center: Notification text (bold first line, 
          grey details second line)
  Right: Time ago (grey, small)
  Unread notifications: slightly highlighted 
  background (#FFF8EC — light yellow tint)

Notification types (different icons):
- New message (chat icon, #F5A623)
- New booking request (calendar icon)
- Listing approved/rejected (home icon)
- Search alert match (search icon, #F5A623)
- Payment confirmed (wallet icon)
- System announcement (bell icon)

Tap notification → navigates to relevant screen
(chat, listing, booking, etc.)

"Mark all as read" button at top right.

Empty state: bell illustration + "You're all caught up"

Use mock notification data (8 items minimum, 
mix of read and unread).
```

---

## SCREEN 16 — Favorites

**Airbnb Equivalent:** Airbnb Wishlists screen

```
Build the Favorites screen for the Aqar app.

Follow Airbnb's Wishlists screen:

GRID VIEW (2 columns, Airbnb style):
- Each favorite card:
  Photo (rounded, full width of column)
  Heart icon top right (filled red)
  Title below photo
  Price (SAR, bold)
  City · Category (grey, small)

Toggle between grid and list view 
(icon button at top right)

LIST VIEW:
- Horizontal photo left + details right
- Same heart icon to unfavorite

Tap card → goes to property/project details

Empty state:
- Heart illustration
- "No favorites yet"
- "Start exploring" button (#F5A623)

Use mock favorited properties data.
```

---

## SCREEN 17 — Wallet

**Airbnb Equivalent:** Airbnb Payments & Payouts screen

```
Build the Wallet screen for the Aqar app.

Follow Airbnb's payments screen layout:

TOP CARD (prominent):
- "Your Balance" label
- Balance amount (large bold, SAR)
- "Top Up" button (#F5A623, rounded)
Card has subtle shadow, rounded corners

PAYMENT HISTORY:
- Section title "Transaction History"
- Each transaction row:
  Left: Icon (payment type icon)
  Center: Description (what was paid for — 
          ad title or service name)
          Date · Time (grey, small)
  Right: Amount (red for debit -SAR, 
         green for credit +SAR)

Filter chips at top of list:
All · Top Ups · Promotions · Subscriptions · Bookings

TOP UP BOTTOM SHEET (slides up):
- "How much would you like to add?"
- Quick amount buttons: 50 · 100 · 200 · 500 SAR
- Custom amount input
- Payment method selector 
  (Credit Card · Apple Pay · Mada)
- "Top Up" confirm button (#F5A623)

Use mock transaction data (10 items minimum).
```

---

## SCREEN 18 — Profile (Public)

**Airbnb Equivalent:** Airbnb public host/user profile screen

```
Build the Public Profile screen for the Aqar app.

Follow Airbnb's host profile page:

TOP SECTION:
- Large profile photo (circular, centered)
- User name (bold, large)
- Star rating + number of reviews
- Member since date
- Verified badge (if applicable)
- Subscription badge (Aqar+ label, #F5A623)
- Last active (grey, small)
- Bio text (Show more if long)

STATS ROW:
- Total listings · Total deals · Response rate
(3 stats in a row, Airbnb style)

ACTIVE LISTINGS SECTION:
- Section title "Listings"
- Horizontal scroll of listing cards 
  (same card style as home feed)
- "See all" link

REVIEWS SECTION:
- Star rating breakdown (5 to 1 star bars)
- 3 most recent reviews shown
- "Show all reviews" button

CONTACT OPTIONS (if not own profile):
- "Send Message" button (#F5A623, full width)
- "Call" button (outlined)

Use mock profile data.
```

---

## SCREEN 19 — Settings

**Airbnb Equivalent:** Airbnb Settings screen

```
Build the Settings screen for the Aqar app.

Follow Airbnb's settings screen (clean grouped list):

SECTION: Preferences
- Language: Arabic / English 
  (tapping opens language picker bottom sheet)
- Theme: Light / Dark / System Default
  (segmented control, #F5A623 for selected)

SECTION: Notifications
- Push Notifications master toggle
- New Messages toggle
- Booking Updates toggle
- Search Alerts toggle
- Promotions & Offers toggle
All toggles use #F5A623 color when on.

SECTION: Danger Zone
- "Delete Account" (red text)
  Tapping shows confirmation alert dialog 
  (Airbnb style modal)

App version shown at very bottom (grey, centered).
```

---

## SCREEN 20 — Aqar+ Subscription

**Airbnb Equivalent:** Airbnb Plus / upgrade screen

```
Build the Aqar+ Subscription screen for the Aqar app.

Follow Airbnb's premium/upgrade screen style:

TOP HERO:
- #F5A623 gradient background header
- "Aqar+" logo/badge in white
- Tagline: "Grow your real estate business"

BUNDLES SECTION:
- 2 or 3 subscription cards (Airbnb comparison card style)
- Each card:
  Bundle name (Basic / Pro / Elite)
  Price per month (bold)
  List of included services (checkmarks)
  "Most Popular" badge on middle card
- Selected card: #F5A623 border highlight

FEATURES LIST:
- Each feature row: checkmark icon (#F5A623) + description
  Examples: Featured listings, Priority support, 
  CRM access, Advanced analytics, etc.

BOTTOM:
- "Subscribe Now" button (#F5A623, full width)
- Cancel anytime note (grey, small)
- Billing handled via wallet balance

Use mock bundle data (3 bundles).
```

---

## SCREEN 21 — Listing Promotion

**Airbnb Equivalent:** No direct equivalent — custom screen

```
Build the Listing Promotion screen for the Aqar app.

Style: Follow Airbnb's clean card-list style for 
service selection.

PROMOTION TYPES (vertical list of service cards):

Each card:
- Icon (relevant to service type)
- Service name (bold)
- Short one-line description
- Arrow icon (right)
- Subtle border, rounded, light shadow

Services:
1. Featured Ad — pin listing to top of search results
2. Interested Buyers Alert — notify matched buyers
3. Golden Ad — premium badge on listing
4. Social Media Ads — promote on social platforms

Tapping a card → opens that service's detail screen

FEATURED AD SCREEN:
- User's listings in a selectable list
  (same card style as My Listings)
- Tap listing to select (checkbox, #F5A623)
- Pricing info shown below
- "Activate" button (#F5A623)

GOLDEN AD / INTERESTED BUYERS ALERT SCREENS:
- Service description (illustration + text)
- Benefits list (checkmarks)
- Price
- "Start Service" button (#F5A623)

SOCIAL MEDIA ADS SCREEN:
- Two option cards: 
  "Advertising Campaign" vs "Post via Aqar Accounts"
- Selecting one shows its specific description
- "Start Service" button (#F5A623)
```

---

## SCREEN 22 — My Clients (CRM)

**Airbnb Equivalent:** No direct equivalent — custom CRM screen

```
Build the My Clients CRM screen for the Aqar app.

Style: Follow Airbnb's clean list style 
with colored priority indicators.

MAIN LIST:
- Search bar at top
- Filter chips: All · High Priority · Medium · Low
- Filter by client request button (icon button)

Each client card:
- Left: Colored priority dot 
  (Red=High, Orange=Medium, Green=Low)
- Center: Client name (bold) 
          Phone number (grey)
          Client desire / request (one line, grey)
          Next step note (italic, small)
- Right: Reminder date (if set, #F5A623 text)
         Arrow icon

Tap card → Client Detail screen
Long press → Quick actions (Call, WhatsApp, Edit, Delete)

ADD NEW CLIENT SCREEN (bottom sheet, Airbnb form style):
- Name input
- Phone number input
- Ad number (optional)
- Priority selector (High / Medium / Low — pill buttons)
- Client request textarea
- Next step textarea
- Set Reminder: date + time picker
- "Save Client" button (#F5A623)

FAB: "+" to add new client (#F5A623)

Empty state: people illustration + "No clients yet"

Use mock client data (5 minimum).
```

---

## SCREEN 23 — My Deals

**Airbnb Equivalent:** No direct equivalent — custom

```
Build the My Deals screen for the Aqar app.

Style: Follow Airbnb's trips/bookings list style.

DEALS LIST:
- Screen title "My Deals"
- Each deal card:
  Property thumbnail (left, rounded square)
  Deal title / property name (bold)
  Deal date
  Deal value (SAR, bold, #F5A623)
  Verified badge (green checkmark)
  Buyer name (grey)

Empty state:
- Handshake illustration
- "No deals recorded yet"
- "Add your first deal" button (#F5A623)

ADD DEAL SCREEN:
- Property search/select (search input)
- Buyer name input
- Deal value input (SAR)
- Deal date picker
- Notes textarea
- "Save Deal" button (#F5A623)

FAB: "+" to add new deal (#F5A623)

Use mock deals data.
```

---

## SCREEN 24 — Bookings

**Airbnb Equivalent:** Airbnb Trips screen

```
Build the Bookings screen for the Aqar app.

Follow Airbnb's Trips screen exactly:

TAB BAR at top:
- "Upcoming" | "Completed" | "Cancelled"

Each booking card:
- Property photo (full width, rounded top)
- Below photo: Property name (bold)
- Check-in → Check-out dates
- Duration (X nights or X months)
- Total price (SAR, bold)
- Booking status badge 
  (Confirmed=green, Pending=#F5A623, Cancelled=red)
- Host name + profile photo (small, bottom of card)

Tap card → Booking detail screen:
- Full property details summary
- Booking dates and total
- Host contact options (Call, WhatsApp, Chat)
- Cancel booking option (if upcoming)

Empty state per tab:
- Upcoming: "No upcoming bookings" + explore button
- Completed: "No completed stays yet"
- Cancelled: "No cancelled bookings"

Use mock booking data.
```

---

## SCREEN 25 — Update Profile

**Airbnb Equivalent:** Airbnb Edit Profile screen

```
Build the Update Profile screen for the Aqar app.

Follow Airbnb's edit profile screen:

TOP:
- Profile photo (large, circular, centered)
- "Change photo" text below (#F5A623)
- Tapping opens: Camera / Gallery / Remove photo 
  action sheet (Airbnb style)

FORM FIELDS (Airbnb input style — labeled, 
full width, subtle border):
- Full Name
- Email address
- Bio / About me (multiline, max 200 chars, 
  character counter shown)

Each field:
- Label above input
- Subtle rounded border
- Clear button inside input when filled

BOTTOM:
- "Save Changes" button (#F5A623, full width)
- Changes trigger success toast notification 
  (Airbnb style, bottom of screen)

Show current user data pre-filled in all fields.
Use Riverpod form state management.
```

---

## NOTES FOR CLAUDE CODE

1. Always build screens with mock data first
2. Never hardcode colors — always reference theme
3. Each screen should have its own feature folder
4. Connect navigation with Go Router after each screen
5. Test RTL layout on every screen by switching to Arabic
6. After all screens are done, we replace mock data with real API calls

---
*Aqar App — Flutter Screen Prompts v1.0*
