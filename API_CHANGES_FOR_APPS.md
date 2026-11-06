# BeatX API changes for the apps

2026-10-29 mobile visual/gesture release (`e91f448`): **API contracts unchanged; no mobile app migration required.** Web player metadata/likes now select existing endpoints by content kind (chapter → parent audiobook; episode, including video → episode; video → video; song → song). Mobile layouts and song double-tap gestures are website changes. Deployment/verification details are in FIXES_LOG and shared work-state.

2026-10-29 frontend client-handoff follow-up: **no API request/response, endpoint or error-code changes; no mobile migration required**. Website-only changes include `/song/[songId]` share links, stream-error handling, cache/navigation/mobile polish and two labeled store illustration fallbacks. Existing API/payment contracts stay unchanged; FIXES_LOG records exact scope/checks.

This is for anyone building a client on the BeatX API (the mobile app, the listener web screens). It lists what changed in requests and responses, starting with what breaks if you change nothing. Admin-only changes and internal fixes are left out; `FIXES_LOG.md` has every fix and how it was tested.

- **Base URL (test server):** `https://fahimstack.tech/beatx-api/api/v1`
- **Swagger:** `https://fahimstack.tech/beatx-api/api/docs` is up to date with everything below.
- **Backend branch:** `dev-fahim`. Updated: 2026-10-29, typo-tolerant search, product reviews/wishlist, platform availability and coin rewards.

---

## 1. Must change (breaking)

### 1.1 Money is in paisa, as whole numbers
Every amount the API sends or accepts is **BDT in paisa**: ৳1 = 100, so ৳1,250.50 is `125050`. This covers `price`, `ticketPrice`, `minPrice`/`maxPrice`, and order `unitPrice`, `subtotal`, `shippingFee`, `vat` and `total`. It also covers revenue figures and payout `amount`.

- **Show:** use the accompanying `amountDisplay` string (see 1.1a). Keep the numeric amount for calculations.
- **Send:** `Math.round(taka * 100)`. A decimal is refused with 400 "… must be a whole number".
- **Not money:** coins (`coinReward`, `coinsAwarded`, `coinBalance`), `stock`, `quantity` and `totalTickets`. They must be whole numbers too.
- Existing data on the test server was converted on 2026-10-27. A product that was `1200` (taka) is now `120000`.

### 1.1a Ready-to-show taka strings (additive, 2026-10-29)

Money responses now include a sibling **`<field>Display`** string from the API's shared formatter. All original numeric fields stay in **whole paisa**. Display strings use `৳`, comma groups and two decimals: `0` → `"৳0.00"`, `125050` → `"৳1,250.50"`; negative earnings transactions use `"-৳25.00"`. A nullable money field has a null display when no amount is available. Show an empty-state marker for missing/null displays.

```json
{
  "price": 125050,
  "priceDisplay": "৳1,250.50"
}
```

- Products and ticket tiers: `priceDisplay`; events: `ticketPriceDisplay`.
- Creator/admin event lists and details also return numeric `revenue` and `revenueDisplay` from paid ticket orders. This uses historical paid totals across all tiers, rather than multiplying the current ticket price by the sold count; pending payments are excluded.
- Cart quotes, orders and ticket orders: `unitPriceDisplay`, `subtotalDisplay`, `shippingFeeDisplay`, `vatDisplay`, `totalDisplay` beside the corresponding amounts. Order/quote item lines also gain numeric `lineTotal` and `lineTotalDisplay` for `unitPrice × quantity`.
- Creator revenue and payout responses: display siblings for money such as `revenue`, `gross`, `net`, `amount`, `totalEarned`, `earned`, `paidOut`, `available`, `pending` (balance only), and `minWithdrawal`. Revenue comparison objects expose `valueDisplay` beside `value`; monthly money series expose display siblings beside their numeric values.
- Pagination `total`, ticket/stock/quantity counts, coins and percentages **are not currency** and do not gain taka strings. In particular, `/me/wallet` balances and transaction `amount` are **coins**.
- **Client migration:** render the server's display string in cards, lists, details, checkout and chart tooltips. Keep numeric paisa for calculations, sorting, filters and chart coordinates. Synthetic chart-axis ticks can still be formatted locally.
- **Requests do not change:** input taka converted with `Math.round(taka * 100)` is sent as numeric paisa. Never parse a display string or send `priceDisplay`, `totalDisplay`, etc. back in create/update requests; unknown request fields are rejected with 400. Prefill edit inputs from numeric paisa, not display strings.
- CSV exports retain numeric taka columns headed `(BDT)`; the JSON display strings do not change the CSV format. No database migration is needed.

**Ticket quantity preview:** call public `GET /events/:id/quote?quantity=2&tierId=<tier-id>` and render `unitPriceDisplay`/`totalDisplay`. `quantity` is required (whole number, 1–10); omitting `tierId` selects the first tier. The quote checks the current price and availability without holding seats or starting payment. Re-fetch when tier/quantity changes; only show the matching quote. Purchase still uses `POST /events/:id/buy` with numeric `quantity` and optional `tierId` and rechecks availability. A quote does not guarantee seats.

### 1.2 Checkout and ticket purchase: new payment flow (Stripe removed)
Stripe is gone. `clientSecret`, `paymentIntentId`, `paymentMethod` (`card`/`apple_pay`/`cash`) and `GET /payments/config`'s `publishableKey` no longer exist. **Sending `paymentMethod` now returns 400.** Cash orders are no longer marked paid on the spot.

Payments go through a gateway page instead: **bKash / SSLCommerz** later, and a **dummy test gateway** on the test server today. The app flow is the same for all of them:

1. **(Optional) Show the price.** Call `POST /orders/quote` with `{ items: [{productId, quantity, size?, color?}] }`. It returns `{items, subtotal, shippingFee, vat, total, coinsAwarded}`. Prices always come from the server.
2. **Create the order.** Call `POST /orders` with `{ items, shippingAddress }`, or `POST /events/:id/buy` with `{ quantity }`.
   - Send an **`Idempotency-Key`** header: a fresh UUID per checkout attempt, reused when retrying after a timeout. A retry then returns the first order instead of creating a second one.
   - Response `201`: `{ order, payment }`.
     - `order.status` is `"pending"`.
     - `order.orderNumber` is like `"BX-0042"`. Tickets have `order.bookingRef` instead, like `"BXT-0007"`.
     - `payment` is `{ provider, paymentId, redirectUrl }`.
   - **`payment` is `null` when nothing is due** (a free ticket). The order is then already `"paid"`.
3. **Open `payment.redirectUrl`** in an in-app browser or WebView. The buyer pays (on the test server: presses **Pay** or **Cancel**).
4. **Detect the return.** The gateway sends the browser to `…/api/v1/payments/callback/<provider>?…`. Watch for a URL containing `/payments/callback/` and close the browser as soon as it starts loading (read `orderId` from your own state). **Since 2026-10-28 the test server redirects that URL on to the web result page** (`…/beatx-frontend/shop/payment-result?kind=merch|ticket&orderId=…&reference=…&status=…`), so a WebView that waits for the callback page to finish loading lands on the website instead. Without `PAYMENT_RESULT_URL` the callback answers JSON `{kind, orderId, reference, status}`. A redirect to an app deep link can be added later.
5. **Read the final state.** Call `GET /orders/:id` or `GET /tickets/:id`. `status` is `"paid"`, `"failed"` (cancelled or declined) or still `"pending"`.

**Order statuses:**

| Status | Meaning | What happened to the stock or seats |
|---|---|---|
| `pending` | Waiting for payment | Held for the buyer for **15 minutes** (`GET /payments/config` → `holdMinutes`) |
| `paid` | Paid | Coins are credited at this point, no longer at checkout |
| `failed` | Cancelled or declined | Released |
| `expired` | Never paid in time | Released |

**New errors at checkout:**

| Error | When |
|---|---|
| 400 "Insufficient stock" | Not enough stock to start with |
| 409 "… just sold out" | Someone took the last units a moment earlier |
| 409 "Only N ticket(s) remaining" | Not enough seats left |
| 400 "Promo codes are not available yet" | Any `promoCode` |
| 400 | More than **10 tickets** in one order, or an event whose day has passed |
| 503 | The gateway couldn't be reached. Try again |

Paid ticket orders carry an **`entryCode`** (8 characters). Show it on the ticket; the organiser types it in at the door.

### 1.3 List keys are named after their content
These list responses gained new names. **The old names are still sent for now, but will be removed**, so read the new ones:

| Endpoint(s) | Old key | New key |
|---|---|---|
| album lists | `album` | `albums` |
| song lists (admin/creator) | `song` | `songs` |
| admin audiobook list | `audio` | `audiobooks` |
| activity log | `activity` | `activities` |
| `GET /me/wallet/transactions` | `wallet` | `transactions` |

### 1.4 A wrong confirmation password is 403, not 401
Self-delete (`DELETE /users/me` with a password) and every admin delete that asks for a password answer **403 "Incorrect password"** when it's wrong. It used to be 401. Show the message and keep the user signed in; treat **only 401** as an expired session.

### 1.5 Public event responses dropped four fields
`GET /events`, `/events/:id` and `/events/:id/related` no longer return `livestreamUrl`, `accessToken`, `coverKey` or `ownerId`. Ticket holders get the livestream link from `GET /events/:id/access` (see 1.11).

### 1.6 Artists don't send `artist` any more (creator app)
An artist's songs and albums are published under their own name: their stage name from verification, else their account name. An `artist` value sent by an artist is ignored. Show the name read-only. Admins still send it.

### 1.7 Products with sizes and ticket tiers
- A product with stock per size (`hasSizeVariants: true`, `variants: [{size, stock}]`) needs **`size`** on every order line: 400 "Please select a size" without it, 400 when that size doesn't have enough, 409 if someone took the last one first. Show the sizes from `variants` and grey out those with `stock: 0`.
- Events have **`ticketTiers: [{_id, name, price, quantity, sold}]`** (every event has at least one; older ones got "General"). Show the tiers and send **`tierId`** with `POST /events/:id/buy` (without it the first tier is used). A sold-out tier is 409. `ticketPrice` is the lowest tier price and `totalTickets` the sum.

### 1.8 Review fields are gone from listener responses
Public song, album, video, podcast, product, event and audiobook responses no longer include `pendingRevision`, `rejectionReason`, `adminNote`, `reviewedBy`, `reviewedAt` or the `submitted*` fields. The creator routes (`/creator/...`) still return them.

### 1.9 Delete account takes a body
`DELETE /users/me` needs `{ "password" }` (400 without it, 403 if wrong). Accounts that signed up with Google/Facebook/Apple send `{ "confirm": "DELETE" }` instead. Use `provider` from `GET /users/me` (`"local"` = has a password).

### 1.10 Search response changed
`GET /search`:
- With `type=all` (the default), each section is now **`{ items, total }`** instead of a plain array.
- It adds `topResult: {type, item} | null` and the sections `artists`, `albums`, `playlists` and `episodes`.
- With one `type`, it returns `{ items, total, page, limit }` (default limit 20).
- Matching is now by word start, in any order (`"fah"` finds "Fahim").
- It also has an `events` section (`type=event`): live and upcoming events by title, venue or city.
- **Typo-tolerant (additive, 2026-10-29):** when a section has no word-start match, it falls back to spelling-tolerant matching (1-3 letter mistakes by word length; common Bangla/Urdu romanisations such as ee/i, oo/u, au/o, ph/f, w/v, z/j and doubled letters count as equal; words typed together or apart). The response adds **`fuzzy`** (`type=all`: the section keys that used the fallback, e.g. `["songs"]`; one `type`: `true`/`false`) and **`didYouMean`** (the closest record's name, or null). Show "Showing results for <didYouMean>" when it differs from the query. New records join the fallback within a minute.

### 1.11 Events browse and My Tickets changed
- **`GET /events` lists live and upcoming events by default**, soonest first. Completed and past events need `upcoming=false` (then latest first). Related events are upcoming only.
- **`GET /tickets` lists paid orders only by default.** Send `status=pending` for unpaid orders (show Pay now with `paymentUrl` until `expiresAt`), or `status=all`. Add `tab=upcoming|past` for the My Tickets tabs; past includes events cancelled by the organiser.
- Each ticket order (list and `GET /tickets/:id`) now has an **`event`** object: `{_id, title, coverUrl, venue, city, eventDate, eventTime, endsAt, eventType, status, isLive, hasStream}`, or `null` if the event was deleted. `GET /tickets/:id` adds `isUpcoming`. `limit` is capped at 50.
- **Virtual events:** `GET /events/:id/access` (signed in) returns `{verified, event, streamUrl, ticketCount, bookingRefs}`. `streamUrl` is set only when `verified` (a paid ticket, or the organiser). Use it for the lobby.

---

## 2. Behaviour to handle

**Product reviews and wishlist (2026-10-29):**

- Reviews require a **paid merchandise order containing that product**. Failed/pending orders and ticket purchases do not qualify. A seller cannot review their own product, even if they purchased it. One review per customer and product: `PUT` creates or replaces that review, not another row. Send integer `rating` 1–5 and optional plain `text` (at most 2,000 characters, trimmed; omitted text becomes empty).
- Read `/products/:id/reviews/me` before showing the editor. It returns `{review, canReview, reason}`; `reason` is `purchase_required`, `own_product` or null. A review contains `_id`, `rating`, `text`, `hidden`, `createdAt` and `updatedAt`. `PUT` returns this review directly. A 403 means the buyer is ineligible; a 404 means the product is missing or unpublished. Invalid IDs, ratings, text and pagination return 400.
- Public review lists return only visible reviews from currently active authors. The rating summary uses exactly those same reviews, across all pages: `{averageRating: number|null, reviewCount, ratings: {"1":count,...,"5":count}}`. No reviews means null average and zero counts. Public review entries include `_id`, `rating`, `text`, `author: {name, avatar}` (nullable fields), and timestamps; user IDs/emails and moderation metadata are excluded. Render review text as plain text.
- A hidden review remains visible to its author. Editing it **does not unhide it**. Deleting your own review is idempotent and works even after a product is unpublished/deleted. Clients cannot delete another customer's review through this endpoint. Public review reads require a published product. Admins have separate hide/show moderation controls.
- Wishlists belong to the signed-in account and persist across devices. Use explicit `PUT` to save and `DELETE` to unsave, both idempotent; do not implement a toggle request that might flip twice on retries. The product list contains **currently published products only**, with correct pagination/counts after filtering and the usual `priceDisplay`. The private IDs endpoint also retains saved IDs of unavailable products so they can be removed; it reveals no unavailable product details. Saving an unavailable product returns 404; removing it remains allowed.
- Refresh the relevant review list/summary/own state after review writes or moderation. Refresh wishlist IDs and lists after saves/removals. Do not store API wishlist state in a local-only store. Hard product deletion and account deletion clean up associated reviews/wishlist records; paid order history is preserved.

**Maintenance and closed registrations (2026-10-29):**

- Public `GET /settings/public` now returns `{ maintenanceMode, allowNewRegistrations, announcement }`. Read it at startup and refresh it periodically. Show a maintenance notice when `maintenanceMode` is true; hide new-account forms when `allowNewRegistrations` is false. Existing accounts can still sign in when only registration is closed.
- During maintenance, ordinary listener/artist API calls return **503** with `error: "Maintenance"` and a readable `message`. Authenticated admins remain exempt; public routes require a valid admin bearer too. Normal authentication/role validation still runs first, so an unauthenticated protected request may return 401 instead. **Do not discard a valid session on maintenance 503**; keep checking public status and resume when the switch is off.
- Authentication/recovery endpoints and payment callbacks remain reachable. Listener/artist login and refresh still return maintenance 503 before issuing tokens; admins can sign in and refresh. Existing support sockets cannot join/send or receive new support messages during maintenance; their error acknowledgement contains the maintenance message. Admin support access remains available.
- Closed registration returns **403** with `error: "RegistrationClosed"` from `POST /auth/register`, before account creation or email. This also applies when Google/Apple/Facebook would create a new account (browser callbacks and mobile token flows share the same creation path). Returning provider users and linking a verified provider to an existing email remain allowed while only registration is closed. Maintenance takes precedence over registration closure. Provider configuration/token validation errors can still occur before registration checks.

**Checkout coin rewards (2026-10-29):**

- Use server `coinsAwarded` from store quotes/orders and ticket quotes/orders, rather than calculating `coinReward × quantity` on the client. `GET /events/:id/quote` now also includes `coinsAwarded`.
- An admin multiplier (default 1, range 0–100) applies to the **total base reward once**, with exact decimal arithmetic and fractional coins rounded down: base reward 3 × quantity 3 × multiplier 1.5 gives 13 coins. Multiplier 0 disables new rewards. Product/event `coinReward` remains the base reward, not the final award.
- The reward is fixed when an order is created. Later multiplier changes do not affect that order or an idempotent retry. Payment settlement credits the saved reward only after payment; the multiplier does not change prices, commission, shipping or VAT.

**Auth**
- Login failure is always **401 "Invalid email or password"**, whether or not the email exists.
- **429** "Too many attempts…" on login, register, OTP and reset when they're hit too often. Show it and let the user wait.
- An OTP allows **5 wrong tries**. Then the user gets "Too many incorrect attempts. Please request a new code".
- **Register password minimum is 8.** Register works without `name` (it defaults to the email's first part). Register also takes `phone` (international format) and, for artists, `artistTypes: ["singer"|"podcaster"]`.
- Emails are trimmed and lower-cased. Two accounts differing only in capitals are refused (409).
- Reset-password checks its body before using the code: a 6-digit `otp` and a `newPassword` of at least 8.
- **401** "This account has been banned" / "This account is suspended" / "This account no longer exists" can arrive on any request. Sign the user out.
- Changing the password signs out the user's other devices at their next token refresh.

**Content**
- Streams of anything not live answer **404**. That covers songs, episodes (whose show must be live too), videos and audiobooks. An unpublished episode's list, detail and transcript also answer 404.
- A malformed id answers **400 "Invalid id"** instead of 500.
- `limit` is capped at **100**. A `page` or `limit` of 0, a negative number or text answers 400.
- `?read=false` and `?inStock=false` now mean false. Only true, false, 1 and 0 are accepted.
- A product with sizes needs a `size` at checkout. Quantity must be a whole number.
- Guests can open audiobooks (home, featured, new, bestsellers, search, detail, related, reviews), genres and categories without logging in.
- Only active **artists** can be followed: 404 for an unknown id, 400 for a non-artist.
- Playlists show only live songs and return **`songCount`**.
- Global search lists any section that errored in **`failed`** (e.g. `["videos"]`). If every section fails, it answers 503.

**Listener notifications**
- Listeners now get notifications: new releases from followed artists and shows (`music`), order confirmed / shipped / delivered (`system`), coins earned (`rewards`), ticket confirmations and a reminder about 24 h before an event (new category **`tickets`**). Each has an **`imageUrl`** (or null). Filter with `GET /notifications?type=tickets`.
- Podcast and audiobook plays count once per listening session. Progress saves no longer add plays.

**Artists publishing (creator app)**
- Everything an artist publishes waits for review: songs, videos, podcast shows, **episodes** and **products**. Creating with no status, or asking for `active`/`scheduled`, gives `status: "pending_review"`. `draft` stays a draft. Show "Waiting for review" for pending items.
- `rejected` items carry `rejectionReason`, and possibly `adminNote`. The artist edits the item, then sends `status: "active"` to resubmit.
- **Taken down** items are `archived`, with the reason in `rejectionReason`.
- **Editing live content:** text changes (description, tags, price, stock…) apply at once. A new **title, cover, audio, video or product images** waits in **`pendingRevision: { changes, submittedAt }`** while the live version stays up. Show "Changes waiting for review". A rejected revision disappears, and the reason arrives as a notification.
- Artists can't set `pending_review`, `rejected` or `archived` themselves (403).
- **Albums and events** follow the same flow now (an artist's event is a request that waits for review).
- New song fields: `description`, `releaseDate`, `explicit`, and, read from the file, `audioFormat`, `bitrateKbps` and `fileSize`. Album songs carry `trackNumber` and play in that order.
- New video fields: `explicit`, and, read from the file, `videoFormat`, `fileSize`, `width` and `height`.
- Episodes take a `cover` image, an `episodeNumber` (unique within a season: **409** on a clash) and `explicit`. Shows take `explicit`.
- **Events:** the price and ticket count an artist sends are a proposal; the admin sets the final ticket tiers. On a live event, a new price or ticket count **waits for review** (it applied at once before). Artists can't send `ticketTiers` (400).
- **Products:** artists send `variants` (a JSON string in multipart, e.g. `[{"size":"M","stock":5}]`) for stock per size; `stock` is then their sum. `artistName` comes from the profile, as for songs.
- **Audiobooks** follow the same review flow, including new chapters added to a live book.
- **Not everything waits any more.** An admin can switch a content type to publish without review, or mark an artist as trusted. Then creating or editing gives `status: "active"` (or `scheduled`) straight away, with `adminNote: "Approved automatically"` and no `pendingRevision`. Always show the status the response returns; don't assume "Waiting for review" after a submit.
- **Uploads can be paused:** while an admin has paused uploads, starting a new song, video, podcast, episode, album, audiobook, chapter, event, product or live session answers **403 "New uploads are paused right now. Please try again later."** Edits still work.
- **Artist applications can be closed:** `POST /artist-verification/submit` then answers **403 "New artist applications are closed right now. Please try again later."**

**Account**
- A **deactivated** user's token gets 401. Logging in reactivates the account and its content.
- `GET /users/me` adds `pendingEmail`, `status`, `provider` and `settings`.
- Sellers get a notification when an order or ticket is paid, unless `salesAlerts` is off.

**Notifications**
- The artist gets a notification (and an email) for submitted, approved, rejected, taken down and restored.
- **Live push (optional):** connect with Socket.IO to the `/notifications` namespace, passing the access token as `auth: { token }`. Each new notification arrives as a `notification` event: `{ notification, unreadCount }`. Reconnect with a fresh token after a refresh. `GET /notifications` is still the history and the fallback.

**Analytics (Phase 6)**
- **Send `x-platform: ios` or `x-platform: android` on every request** (at least on the stream endpoints). The artist and admin analytics show plays by platform; without the header the User-Agent is guessed (CFNetwork = iOS, okhttp = Android, Dart and others = unknown). Country comes from the IP, so there's nothing to send.

---

## 3. New endpoints you may use

| Endpoint | What it does |
|---|---|
| `GET /products/:id/reviews?page=1&limit=20` | Public `{reviews,total,page,limit,summary}`; newest first, hidden/inactive-author reviews excluded. `limit` 1–100; page at least 1 |
| `GET /products/:id/reviews/me` | Authenticated own review and paid-purchase eligibility; `{review,canReview,reason}` |
| `PUT /products/:id/reviews/me` | Create/replace own review with `{rating,text?}`; returns the review directly; paid purchaser only, never the seller |
| `DELETE /products/:id/reviews/me` | Remove own review idempotently; `{deleted:true}`, including unavailable products |
| `GET /me/wishlist?page=1&limit=20` | Authenticated `{products,total,page,limit}`; saved published products, newest saved first. Same pagination limits |
| `GET /me/wishlist/ids` | Authenticated `{productIds:[string]}` for the current account, including saved unavailable IDs |
| `PUT /me/wishlist/:productId` | Save a published product idempotently; `{isWishlisted:true}` |
| `DELETE /me/wishlist/:productId` | Unsave idempotently, including unavailable products; `{isWishlisted:false}` |
| `POST /orders/quote` | Prices a cart, without creating an order |
| `GET /payments/config` | `{provider, currency: "BDT", holdMinutes}` |
| `GET /settings/public` | No login needed, reachable during maintenance. `{ maintenanceMode, allowNewRegistrations, announcement: { text, updatedAt } \| null }`. Handle availability as described in section 2. Show the banner with a close button; remember the dismissed `updatedAt` and show it again when it changes |
| `GET /events` new params | `eventType=concert\|festival\|session\|virtual\|other`, `featured=true` (the hero), `sort=date\|popular\|price\|newest`, `upcoming` (default true) |
| New event fields | `eventType`, `endsAt` (or null), `isFeatured`, `teaserUrl`; derived `remaining`, `availability` (`available\|low\|sold_out`), `isLive`, and `remaining` on each ticket tier |
| `GET /events/:id/access` | Virtual lobby check (see 1.11) |
| `GET /events/:id/quote?quantity=2&tierId=…` | Public ticket price preview: `{eventId, tierId, tierName, quantity, unitPrice, unitPriceDisplay, total, totalDisplay}`. Does not hold seats. 400 for invalid quantity/tier or an active event whose sales have closed, 404 for a missing/unpublished event, 409 for insufficient seats (see 1.1a) |
| `GET /songs/:id/lyrics` | `{hasLyrics, synced, lyrics (plain text), syncedLyrics: [{timeMs, line}]}`; songs carry `hasLyrics`. Creator song create/edit take `lyrics` (plain or LRC `[mm:ss.xx] line`, `""` removes) |
| `GET /videos?type=` (also `/trending`, `/featured`) | `videoType`: `music_video` (default) \| `live_session` \| `behind_the_scenes` \| `interview` \| `other`; creator video create/edit take `videoType` |
| `GET /videos/continue-watching` | Started, unfinished live videos, last watched first, each with `progress {positionMs, percentComplete, lastWatchedAt}`; `GET /videos/home` adds `continueWatching` |
| Audiobook progress | `GET /audiobooks/:id` `userProgress` and continue-listening `progress` add `currentChapterId` (resume streaming that chapter). Don't send `completed: true` when one chapter ends: it means the whole book |
| `GET /discovery/charts?type=song\|video\|album&period=week\|month&limit` | Charts from real plays: each item adds `rank`, `plays`, `previousRank` (or null) and `trend` (`up\|down\|stable\|new`) |
| `GET /discovery/mixes` | Up to 3 personal mixes `{id, kind, title, description, basedOn, coverUrl, totalDurationMs, songs}` (signed in) |
| `GET /discovery/recommended-artists?limit` | Artists to watch (artist cards + `monthlyListeners`), minus the ones you follow |
| `GET /discovery/stats?period=week\|month` | Listening stats: `plays`, `totalListenMs`, `byType`, `topGenres` (with `share` %), `topArtists`, `mostActiveHour` (Dhaka time), `daily` |
| `GET /playlists/public?editorial=true&genre=&q=` | Public playlists, BeatX picks (`isEditorial`) first, with `owner` and `songCount` (no sign-in needed) |
| `PATCH /users/profile` | Also takes `gender` (`male\|female\|non_binary\|prefer_not_to_say`, `""` clears) and `onboardingCompleted`; `GET /users/me` returns both |
| `/support/tickets` (POST, GET, GET `:id`, POST `:id/messages`) | Open to listeners now (categories `billing`, `technical`, `account`, `other`; `event_management` is artists only). A listener's messages have `senderRole: "listener"` |
| `GET /legal` · `GET /legal/:slug` | Legal pages for the Privacy & Legal screens: `terms`, `privacy`, `refund`, `community-guidelines`, `cookies` → `{slug, title, body (markdown), updatedAt}`; 404 until published |
| `POST /auth/google/token {idToken}` · `POST /auth/apple/token {idToken, name?}` | Mobile social sign-in with the SDK's ID token (Apple: send the name the first time). Same response as `/auth/login`. 503 until the server has the client ids (`GOOGLE_CLIENT_IDS`, `APPLE_CLIENT_IDS`) |
| `POST /auth/become-artist` `{artistTypes}` | Turns a listener (including a Google/Apple user) into an artist and returns new tokens |
| `GET /artist-verification/status` | The artist's verification status with a 4-step `timeline` |
| Login, verify-email, `/users/me` | Now include `artistVerificationStatus` and `artistVerificationStep` for artists |

**For artists (creator app):**

| Endpoint | What it does |
|---|---|
| `GET /creator/orders` | Paid orders for their products: only their own lines, with `sellerSubtotal` and their `fulfilment` |
| `PATCH /creator/orders/:id/fulfilment` | `{status: processing\|shipped\|delivered\|cancelled, tracking?}` |
| `POST /creator/events/:id/check-in` | `{entryCode}` → the ticket order (409 if already used) |
| `GET /creator/products?tab=` | Tabs: `active`, `out_of_stock`, `draft`, `pending_review`, `rejected` |
| `GET /creator/events?tab=` | Tabs: `upcoming`, `live`, `completed`, `draft`, `pending_review`, `rejected` |
| `GET /artist/analytics?range=7d\|30d\|3m\|6m\|1y` | `plays`, `listeners`, `newFollowers`, `totalListenMs`, `playsByType` |
| Socket.IO `/notifications` | Live `notification` events (see section 2) |
| `GET /creator/albums?tab=&q=&page&limit` | The artist's albums. Each has its first 3 `tracks`, `trackCount` and `streams`, plus `stats: {albums, published, totalTracks, totalStreams}`. Tabs: `active`, `scheduled`, `draft`, `pending_review`, `rejected`, `archived` |
| `POST /creator/albums` (multipart) | `cover` (required), `title`, `genre`, `description?`, `explicit?`, `status` (`active` = submit for review, or `draft`) or `scheduledAt` |
| `GET /creator/albums/:id` | `{album, songs (in order, any status), stats: {tracks, durationMs, streams}}` |
| `PATCH /creator/albums/:id` (multipart or JSON) | Optional `cover`. On a live album a new title or cover waits in `pendingRevision`; `status: "draft"` unpublishes |
| `DELETE /creator/albums/:id` | Deletes the album; its songs stay |
| `POST /creator/albums/:id/tracks` `{songIds}` | Adds the artist's own songs at the end, in that order (400 if any isn't theirs) |
| `PATCH /creator/albums/:id/tracks/reorder` `{songIds}` | The full new order (every track once, or 400) |
| `DELETE /creator/albums/:id/tracks/:songId` | Takes a song off the album |
| `GET /creator/podcasts/episodes?tab=&podcastId=&q=` | All the artist's episodes across shows, each with its `podcast {_id,title,coverUrl,status}`, plus `stats: {totalEpisodes, published, pending, totalPlays, avgDurationMs, totalShows, activeShows}` |
| `POST /creator/podcasts/episodes` (multipart, streamed) | Upload without a show step: `podcastId` **or** `seriesName` (finds or creates the artist's show; a new one needs `category` and `cover` and goes to review), plus `audio`, `cover?`, `title`, `description`, `seasonNumber?`, `episodeNumber?`, `explicit?`, `status`/`scheduledAt` |
| `POST /creator/events` (multipart) | Artists can create events now: it's a request in `pending_review` |
| `GET /creator/events/:id/buyers?q=&page&limit` | `{buyers: [{bookingRef, buyer {name,email}, quantity, total, paidAt, checkedInAt, entryStatus}], totals: {ticketsSold, revenue, checkedIn}}` (`total` and `revenue` in paisa) |
| `DELETE /creator/events/:id` | Returns `{deleted, archived}`: once tickets are sold the event is archived ("Cancelled by the organiser") instead |
| `GET /creator/events`, `GET /creator/products` | Now also return `stats`: events `{total, upcoming, pending, ticketsSold, revenue}`, products `{total, active, pending, outOfStock, unitsSold, revenue}` (revenue in paisa, paid orders only) |
| `POST /users/me/email/change` `{newEmail, currentPassword}` | Sends a 6-digit code to the new address; returns `{pendingEmail}`. Wrong password 400, same email 400, taken 409, social login 400 |
| `POST /users/me/email/resend` · `POST /users/me/email/verify {otp}` | Verify returns `{user, accessToken, refreshToken}`: **replace the stored tokens**. Other sessions are signed out |
| `POST /users/me/deactivate` `{confirm: "DEACTIVATE"}` | Signs the user out and hides their content. Logging in again reactivates (`reactivated: true` in the login response) |
| `GET/PATCH /users/settings` | `emailNotifications`, `pushNotifications`, `newFollowerAlerts`, `salesAlerts`, `publicProfile`, `showRevenue` (booleans) |
| `PATCH /artist-verification/profile` (approved artists) | JSON `{stageName?, bio?, genres?: [ids, max 5], socialLinks?, legalName?, dateOfBirth?}`, or multipart with `profileImage` / `coverImage`. A new legal name or date of birth sends the profile back to review |
| `GET /artist-verification/me` | Now also returns `genres: [{_id, name}]`, `profileImageUrl`, `coverImageUrl` |
| `GET /creator/audiobooks?tab=&q=&page&limit` | The artist's audiobooks with `chapterCount`, `totalDurationMs`, `listeners`, `plays`, plus `stats: {total, published, pending, totalChapters, totalPlays, listeners, avgDurationMs}` |
| `POST /creator/audiobooks` (multipart) | `cover`, `title`, `author`, `narrator?`, `language?`, `genre`, `description`, `explicit?`, `status` (`active` = submit for review, or `draft`) or `scheduledAt` |
| `GET/PATCH/DELETE /creator/audiobooks/:id` | Details `{audiobook, chapters, stats}`; on a live book a new title, author or cover waits in `pendingRevision` |
| `POST /creator/audiobooks/:id/chapters` (multipart, streamed) | `audio` (or `sourceUploadId` from `/uploads/multipart` kind `audiobook-chapter`), `title`, `description?`, `order?`. On a live book the chapter waits for review |
| `PATCH/DELETE /creator/audiobooks/:id/chapters/:chapterId` · `PATCH /creator/audiobooks/:id/chapters/reorder {chapterIds}` | Edit (new audio optional), delete (renumbers), reorder (full list or 400) |
| `GET /artists/:id` | Public artist profile: `{stageName, avatar, coverImageUrl, isVerified, bio, genres, nationality, followerCount, isFollowing, monthlyListeners, counts{songs, albums, podcasts, episodes, videos, products, upcomingEvents}}`. 404 for non-artists and private profiles |
| `GET /artists/:id/related?limit` · `GET /artists/:id/episodes` | Related artists (plain array) · the artist's recent episodes `{episodes,total,page,limit}` |
| `ownerId` on `GET /songs` (`sort=plays\|latest`), `/albums`, `/videos`, `/podcasts`, `/products`, `/events` (`upcoming=true`) | Filter by artist. Events carry `soldOut`. Albums carry `releaseType` (album/ep/single/live) |
| `GET /users/:id/following?role=artist` | Each item adds `stageName`, `avatar`, `genres`, `nationality`, `isFollowing` |
| `GET /search/recent` · `POST /search/recent {query, type?, targetType?, targetId?}` · `DELETE /search/recent/:id` · `DELETE /search/recent` | Recent searches (signed in). Post when the user presses Enter or opens a result |
| `GET /genre?sort=popular\|new\|name` | Genres now have `imageUrl`, `description`, `isFeatured`; `popular` adds `monthlyListeners` |
| `POST /playlists`, `PATCH /playlists/:id` | Accept `description` and `isPublic`. Public playlists open for anyone signed in and show up in search |
| `POST /podcasts/:id/follow` · `GET /podcasts/following` | Follow a show `{following, followerCount}`; the show detail adds `isFollowing`, `followerCount` |
| `POST /albums/:id/like` · `GET /albums/liked` | Save an album `{liked, likeCount}`; the album detail adds `isLiked` |
| `POST /podcasts/episodes/:id/like` | Like one episode (the heart on Episode Details) `{liked, likeCount}`. Episode lists and details now carry `isLiked` and `likeCount`. The show's own like is unchanged |
| `GET /artist/analytics/content/:type/:id?range=7d\|30d\|3m\|6m\|1y` (creator app) | Analytics of one of your items, type `song\|video\|episode\|audiobook\|album`: `plays`, `listeners`, `thisMonth`, `avgDaily`, `avgListenMs`, `completionRate` (each `{value, changePercent}`), `lifetime`, `likes`, `series`, `byPlatform`, `topCountries` + `unknownCountryCount`, `peakHours`, `tracks` (album). 404 if it isn't yours |
| `GET /artist/dashboard` (creator app) | Adds `kpis {totalStreams, followers, revenue, monthlyListeners}` (each `{value, changePercent}` vs last month), `revenueSeries` (6 months), `upcomingEvents`, and albums/audiobooks in `content`. Old keys unchanged |
| `GET /artist/analytics?range=` (creator app) | Adds `totalStreams`, `monthlyListeners`, `followerGrowth`, `avgListenTimeMs` (each with change), `growthOverview`, `streamsByType`, `peakListeningHours`, `mostActive`, `genreDistribution`. `listeners` stays a number |
| `GET /artist/top-content?type=all\|song\|video\|episode\|audiobook&range=&limit=` | Most played items with `plays`, `listeners`, `changePercent`, `seriesName` |
| `GET /artist/revenue?range=` · `GET /artist/revenue/transactions?type=&page&limit` | Earnings in paisa after commission: `totalEarned`, `thisMonth`, `available`, `byType` (merchandise, tickets, streaming `comingSoon`), `monthly`. Transactions: sales (+) and payouts (−); none can be deleted |
| `GET /artist/balance` · `GET /artist/payouts` | `{earned, paidOut, pending, available, minWithdrawal}` · read-only payout history. Payout requests and methods aren't built yet |

---

## 4. Offline downloads (the app does this)
Downloads are an app feature: the app saves the files in its own protected storage, which isn't visible in the Files app or gallery. The website only lists downloads, removes them and changes the settings. All routes need sign-in.

**Flow**
1. **Download.** Call `POST /downloads {contentType, contentId, deviceId, deviceName?}`.
   - `contentType` is `song`, `album`, `episode`, `audiobook` or `video`.
   - `deviceId` is your own stable id for this install (generate it once and keep it).
   - `deviceName` is shown on the website ("Pixel 8").
   - Returns 201 `{download, files}`.
   - Each file is `{contentType: song|episode|chapter|video, contentId, title, url, sizeBytes, durationMs, format, trackNumber?}`.
   - `url` is a signed link that works for **1 hour**. Download every file and store it encrypted or in private storage.
   - An album or audiobook is one download whose files are its tracks or chapters, in order.
2. **Report the result.** Call `PATCH /downloads/:id {status: "completed" | "failed"}` (`id` is `download._id`).
3. **Resume or retry** after the links expired: `GET /downloads/:id/files` returns fresh links.
4. **Check in.** Call `POST /downloads/sync {deviceId, ids: [download ids on this device]}` on app start and at least every 30 days.
   - It returns `{keep, remove, validUntil}`.
   - **Delete the files of every id in `remove`.** These are items that were taken down, deleted, or removed from the website.
   - Without a successful sync before `validUntil`, hide the offline copies until the next sync.
5. **Remove.** When the user deletes a download in the app, call `DELETE /downloads/:id`.

**Limits and errors**
- Only published content can be downloaded (404 otherwise).
- An account can keep downloads on at most **5 devices**. A 6th device gets 400 "You can keep downloads on up to 5 devices. Remove one first." The user frees a slot on the website, or the app calls `DELETE /downloads?deviceId=`.
- Downloading the same item again on the same device refreshes it; it doesn't create a duplicate.

**Other routes**

| Endpoint | What it does |
|---|---|
| `GET /downloads?type=all\|song\|album\|episode\|audiobook\|video&deviceId=&page&limit` | The user's downloads on all devices, with `storage {totalBytes, audioBytes, videoBytes}` and `devices [{deviceId, deviceName, count, sizeBytes, lastAt}]`. Rows have `available: false` once the content is gone |
| `GET /downloads/recommended?limit=5` | Songs and albums the user plays most that aren't downloaded |
| `GET/PATCH /downloads/settings` | `{smartDownloads, wifiOnly}`, shared by all the user's devices. **The app does the work:** with Smart Downloads on, download the recommended items on its own, over Wi-Fi only when `wifiOnly` is on |

## 5. Live sessions
Live streams and premieres. BeatX doesn't host the video: each session plays a YouTube or Facebook embed, or an HLS stream (`.m3u8`, including Cloudflare Stream).

**Listener routes** (these work signed out; signed in, `isReminded` is filled in):

| Endpoint | What it does |
|---|---|
| `GET /live-sessions?tab=live\|upcoming\|ended&kind=livestream\|premiere\|exclusive&ownerId=&q=&page&limit` (limit ≤ 50) | `{items, total, page, limit, liveViewers}`. `liveViewers` (everyone watching, summed) comes with `tab=live` only. Each item: `_id, title, description, coverUrl, kind, startsAt, endsAt, endedAt, liveState (upcoming\|live\|ended), streamProvider (youtube\|facebook\|hls), host {_id, name, avatar}, viewers, reminderCount, isReminded, event {_id, title, eventDate} \| null` |
| `GET /live-sessions/:id` | The item plus `embedUrl`, `peakViewers` and `totalViewers` |
| `POST /live-sessions/:id/remind` | Toggles "Set Reminder" / "Notify Me" and returns `{reminded, reminderCount}` (400 once ended) |
| `POST /live-sessions/:id/heartbeat` | Send every ~30 s while the player is open and the session is live. Returns `{viewers}` (400 when not live) |

**Playing the stream**
- **YouTube or Facebook:** load `embedUrl` in a WebView or iframe, or use the YouTube player SDK with the video id taken from it.
- **HLS:** play `embedUrl` in the native player (AVPlayer / ExoPlayer).
- **Notifications:** the user gets one 15 minutes before the start (if reminded) and one when the session goes live (followers of the host and reminded users). Both have `targetType: "live_session"` and `targetId`: open the session.

**Creator app** (verified artists; admins too):

| Endpoint | What it does |
|---|---|
| `GET /creator/live-sessions?tab=upcoming\|live\|ended\|pending\|rejected\|draft\|archived` | The user's own sessions, with `counts` |
| `POST /creator/live-sessions` (multipart) | Fields:<br>• `cover` (image, required);<br>• `title`;<br>• `description?`;<br>• `kind?`;<br>• `streamUrl`: a YouTube, Facebook or Cloudflare Stream link, or an https `.m3u8`;<br>• `startsAt`: ISO, in the future or at most 10 minutes ago ("go live now");<br>• `endsAt?`: at most 12 hours after the start;<br>• `eventId?`;<br>• `genre?`;<br>• `status`: `active` (submit for review) or `draft`.<br>An artist's session waits for review. |
| `GET/PATCH /creator/live-sessions/:id` | `startsAt`, `endsAt` and `streamUrl` apply at once, even while live. On a published session, a new title, description, cover, kind or event waits for review |
| `POST /creator/live-sessions/:id/end` | Ends a live session now, or cancels an upcoming one (reminded users are told) |
| `DELETE /creator/live-sessions/:id` | Draft, rejected, pending or ended sessions only (end it first) |

---

## Change history

- 2026-10-29 (Codex, `e91f448`): mobile web visual alignment/song gestures and corrected web player content-kind routing; existing API contracts unchanged, no app migration.

- 2026-10-29 (Codex, listener client handoff): frontend-only fixes/artwork; no API contract changes or mobile migration. Terms/Privacy publication remains pending by user decision.

- **2026-10-29:** Product reviews for paid purchasers, public rating summaries, author edit/delete, hidden-review behavior, and persistent private wishlist endpoints (sections 2–3). Existing shop/payment fields unchanged.
- **2026-10-29:** Phase 7 settings enforcement: maintenance 503/admin exemption, closed-registration 403 including new OAuth accounts, public availability flags, and server-calculated multiplied `coinsAwarded` including ticket quotes (section 2). Request money remains whole paisa.
- **2026-10-29:** Additive taka display siblings for money responses, server order-line totals, and read-only ticket quotes (1.1a). Website screens and API guide use display strings; request amounts remain whole paisa. Coins and pagination counts are unchanged.
- **2026-10-27:** Phase 1, the Phase 1 follow-up, Phase 2 (all batches) and Phase 3 (paisa, checkout, orders, tickets).
- **2026-10-27:** Phase 4: the review flow for artists (episodes and products too), pending revisions of live content, notifications with a live socket, and 403 for a wrong confirmation password.
- **2026-10-27:** Admin Moderation screen (web admin only). No API changes for the apps.
- **2026-10-27:** Phase 5 batch 1: creator albums, song/video file details, the artist name from the profile, podcast upload by series name with episode covers and numbers, and artist events as requests with a buyers list.
- **2026-10-27:** Phase 5 batch 2: stock per size (`size` required at checkout), ticket tiers (`tierId`), review fields removed from listener responses, delete account with a body, change email, deactivate, settings toggles, artist profile edit, creator audiobooks.
- **2026-10-27:** Phase 8 batch 1: public artist profiles, the new search response (1.10), recent searches, listener notifications with `imageUrl` and a `tickets` category, podcast follow, saved albums.
- **2026-10-28:** Phase 8 batch 2: events browse defaults to upcoming with sort/type/featured, availability and `isLive` on events, My Tickets paid-only with tabs and the event attached (1.11), `GET /events/:id/access`, events in search. Creator app: events take `eventType`, `endsAt` and `teaserUrl`; on a live event a new end time or type waits for review.
- **2026-10-28:** Phase 8 batch 3: song lyrics, video type, continue watching, `currentChapterId` in audiobook progress. No breaking changes.
- **2026-10-28:** Phase 8 batch 4: discovery (charts, mixes, recommended artists, listening stats), public and editorial playlists, `gender` and `onboardingCompleted`, support for listeners, legal pages, mobile Google/Apple sign-in with an ID token. No breaking changes.
- **2026-10-28:** Phase 6 batch 1: send `x-platform`; episode likes; creator-app analytics per item, dashboard KPIs, top content, revenue, balance and payouts. No breaking changes.
- **2026-10-28:** Offline downloads for the app (section 4) and live sessions (section 5). No breaking changes.
- **2026-10-28:** Content approval settings: submissions can be published at once (auto-approve per type, trusted artists), uploads can be paused (403), artist applications can be closed (403). See "Artists publishing" in section 2. No breaking changes.
- **2026-10-28:** Announcement banner: `GET /settings/public` (section 3). No breaking changes.
- **2026-10-29:** Search: typo-tolerant fallback with `fuzzy` and `didYouMean` (1.10). No breaking changes.
- **2026-10-29:** Podcast episodes have `mediaKind` (`audio` | `video`); `GET /podcasts/episodes/:id/stream` adds `mediaKind` and can answer `streamType: "mp4"` for a video episode that isn't transcoded yet. Show a video player for `video`. No breaking changes.
