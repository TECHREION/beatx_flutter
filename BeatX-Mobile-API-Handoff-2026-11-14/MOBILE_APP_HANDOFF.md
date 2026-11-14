# BeatX mobile app developer handoff — 2026-11-14

This package documents the API changes already implemented for BeatX and the updates required in the native listener/creator apps. Start with the checklist below, then use `API_CHANGES_FOR_APPS.md` for the complete migration details. The included Postman collections replace the old collections entirely.

## Backend address and setup

| Setting | Value |
|---|---|
| API base URL | `https://fahimstack.tech/beatx-api/api/v1` |
| Public browser Swagger | `https://fahimstack.tech/beatx-api/api/docs` |
| Public OpenAPI JSON | `https://fahimstack.tech/beatx-api/api/docs-json` |
| Notification socket origin | `https://fahimstack.tech` |
| Socket.IO path / namespace | `/beatx-api/socket.io` / `/notifications` |
| Access token header | `Authorization: Bearer <accessToken>` |
| App analytics header | `x-platform: android` or `x-platform: ios` |
| Payments | **Dummy test gateway; no real money. No Stripe.** |

The public API address was checked on 2026-11-14: the safe Postman smoke collection passed **6 requests / 12 assertions**. This is the test server. Do not use the VPS IP or its internal service port as the app base URL.

Import `postman/BeatX-Mobile.postman_collection.json` and `postman/BeatX-Test.postman_environment.json`. Select the environment and set `platform`, `loginEmail` and `loginPassword` using your own test account. All credentials/tokens are intentionally empty. The full role-based collection includes admin endpoints for reference; the mobile collection includes **295 operations**, and the full collection includes **448**.

`POST /auth/login` saves the returned tokens to that role's environment variables. Set `activeRole` to `user`, `artist` or `admin` for shared endpoints; creator/admin folders use their own role tokens. Fill resource ID variables using data from your own fixtures. Clear `idempotencyKey` when beginning a new payment or redemption attempt; reuse it for retries of that attempt. Do not run the entire collection as a batch: it contains purchases, account deletion, OTP sends and stream GETs that count plays. The separate SafeSmoke collection makes only six public read requests.

## Required migration checklist

1. **Money:** treat monetary numbers as integer **BDT paisa** (`125050` = Tk 1,250.50). Display the server's `<field>Display` strings. Convert entered taka to paisa once before sending. Coin balances/rewards and pagination totals are not currency. Never send display strings back to the API.
2. **Checkout and tickets:** remove Stripe SDK/config, `paymentMethod`, `clientSecret`, `paymentIntentId` and `publishableKey` handling. Quote first, then create the order with an `Idempotency-Key`. The response is `{order, payment}` inside `data`; open `payment.redirectUrl`, then poll your own `GET /orders/:id` or `GET /tickets/:id`. `payment: null` means no payment is due and the order is already paid. Verify status with the API; do not trust callback URL parameters as proof of payment. Pending stock/seats expire after the configured hold period. See the payment-browser detail below.
3. **Response parsing:** unwrap the normal envelope shown below. Content lists use domain keys such as `songs`, `videos`, `products`, `orders`, `transactions` or `items`; they are not all `data[]`. Read each endpoint schema/example and accept additive fields. Public content no longer exposes moderation fields.
4. **Auth/onboarding:** save both access/refresh tokens securely; the app sends `{refreshToken}` to `POST /auth/refresh`, saves both replacements, and retries the original request once. Password login accepts `rememberMe: true` for a 30-day refresh lifetime (otherwise 7 days). A listener login/verification includes `onboardingCompleted`; if false, show or skip onboarding, then save `PATCH /users/profile {onboardingCompleted:true}`. Password minimum is 8 characters. Preserve auth on maintenance 503; handle banned/suspended/revoked 401 appropriately.
5. **Passwordless account actions:** phone/social accounts have no local password. Account deletion uses `DELETE /users/me {confirm:"DELETE"}` for them; password accounts send `{password}`. A wrong confirmation password is 403, not an expired-session 401. Hide the internal `@phone.beatx.invalid` email address.
6. **Search:** `type=all` returns `{items,total}` per content section plus `topResult`, `failed`, `fuzzy` and `didYouMean`. A single type returns `{items,total,page,limit,fuzzy,didYouMean}`. Types include artists, albums, playlists, episodes and events. Render partial failures separately from empty results. Add debounced suggestions, trending chips and persistent recent-search actions using the new routes.
7. **Variants and tiers:** send `size` for a product using size stock, `color` for a colour variant, and the selected `tierId` for tiered tickets. Product size and colour stock modes are mutually exclusive. Prices and stock always come from fresh server quotes; a quote does not reserve inventory.
8. **Playback/analytics:** send `x-platform`. Normal stream requests record plays; owner/admin previews do not. Only song streams support `prefetch=true` to warm a next item without counting a play; call normally when it actually starts. Audio HLS now has real 64k/128k/256k renditions with unchanged URLs. Use content-specific likes/progress (episode, video, song; chapter likes belong to the parent audiobook).
9. **Wallet:** display coins as coins; use `/me/wallet` and `/me/wallet/transactions`. Redemption supports `Idempotency-Key`; same key/amount replays the original balance, different amount returns 409. Refresh balance afterward. Show `sourceRef` (order number or booking ref) when present. Paid-order rewards are server-owned and credited once.
10. **Errors:** strict bodies reject unknown keys with 400. Handle 400 validation, 401 auth/account restrictions, 403 permissions/closed registration, 404 unavailable content, 409 conflicts and 429 rate limits. On 503 maintenance, retain the session and check `/settings/public`. Never assume all 403s mean an expired login.

## Newer features to reflect in the apps

| Feature | API / client action |
|---|---|
| Phone sign-up and login | `POST /auth/phone/send-otp {phone}`, then `POST /auth/phone/verify {phone,otp,name?}`. Bangladeshi mobiles only; normalized `+8801…`. Show a 60-second resend countdown, validation/429/503 errors, 5-minute code lifetime and 5 tries. Verification creates a new listener or logs into the existing phone account. `isNewUser` appears as true only for a newly created account. |
| Native Google/Apple login | SDK ID token to `POST /auth/google/token` or `/auth/apple/token`; Apple can include the first-sign-in name. Configuration/acceptance remains pending; do not promise a working provider just because the route exists. `/auth/providers` describes configured **website** providers. |
| Search UX | `GET /search/suggestions`, `GET /search/trending`, and `GET/POST/DELETE /search/recent`. Use the result's type/id to open the correct screen. Respect `trackSearchHistory`. |
| Creator Videos | `GET /creator/videos` includes `stats` across all owned videos, partial-title `q` and `type` filtering. `height`/`width` provide resolution. Existing CRUD, upload and content analytics support the creator screen. |
| Creator previews | Owner/admin stream endpoints can preview unpublished songs/videos/episodes/chapters without counting plays. Other listeners receive 404 for unavailable content. |
| Followers insights | `/artist/followers/stats?range=7d|30d|3m|6m|1y`: calendar/week/month counts, growth buckets and streams by country. Growth counts current surviving follow relationships, not historical net follower totals. Include Unknown country. |
| Reviews/wishlist | Paid merchandise buyers can edit their own review; public lists include rating summaries. Wishlists persist on the server and use idempotent PUT/DELETE. Fetch eligibility before showing the review editor. |
| Notifications | List/history/read actions, `GET /notifications/:id`, Socket.IO `notification` events with `{notification,unreadCount}` and routing metadata. Open the relevant content/order/ticket by `targetType`, `targetId` and metadata. `tickets` is a supported category. |
| Offline downloads | Device-scoped download registration, expiring file URLs, completion/failure reporting, renew, sync/remove and settings endpoints already exist. See section 4 of the full guide. Save files privately, enforce sync validity and delete IDs returned in `remove`. |
| Live sessions | Browse, detail, reminders, heartbeat and creator lifecycle APIs already exist. Play external embed/HLS URLs; this is not a managed native virtual-room API. |
| Public artists/discovery/library | Artist profiles, related content, charts/mixes/recommendations, public playlists, lyrics and listening/library routes are in the new collection. Use the inventory instead of requesting endpoints based on the old collection. |

## Wire format and payments

Normal success:

```json
{"status":true,"message":"Success","data":{"balance":250},"timestamp":"2026-11-14T00:00:00.000Z","path":"/api/v1/me/wallet","metadata":{"duration":"12ms"}}
```

Normal error:

```json
{"status":false,"message":"Invalid OTP","error":"Bad Request","data":null,"timestamp":"2026-11-14T00:00:00.000Z","path":"/api/v1/auth/phone/verify"}
```

The payment browser, redirects, downloads/CSV, upload SSE and presigned storage PUTs have their own content types. The payment callback can redirect to the website's result page. **Allow the callback request to reach the server and settlement to complete. Do not cancel it merely because the callback URL appeared.** Close/return from the browser after its return navigation, or independently poll the app's own order until a terminal result. Order state from the API is authoritative. The mobile app does not call the provider callback itself. Keep payment and order IDs in app state before opening the browser.

## Creator uploads and review states

Small/simple uploads use multipart fields and the correct file names from Postman. For large video/episode/chapter sources, use `/uploads/multipart` -> `/part-urls` -> PUT file slices to the signed URLs -> `/complete`, then send `sourceUploadId` instead of the media file in the creator create/update request. Keep each PUT's ETag. JSON arrays/objects inside multipart are serialized as JSON strings. Do not send an API bearer token to a presigned storage URL. Song streaming upload currently sends the `audio` file directly; do not assume it supports `sourceUploadId`.

Show the status the server actually returns: drafts, pending review, scheduled, active, rejected or archived. Live title/media/cover changes may appear in `pendingRevision` while the original remains live; text edits may apply immediately. Auto-approved/trusted content can become active immediately. Creator routes retain moderation details that public routes remove. Uploads and artist applications can be temporarily closed by settings; surface the server message.

## Scope and verification limits

- This is the completed documentation/collection package for **existing API work**, not a claim that every planned Figma feature or the native apps are complete.
- Artist Recent Activity and account-level platform sources remain absent. Artist payout requests/methods, admin create-artist, real gateways, subscriptions and other deferred product decisions are not supplied by this package. Read-only artist balance/payout history APIs already exist.
- Browser Web Push uses browser subscriptions and VAPID; it does **not** provide native APNs/FCM device-token registration. Socket.IO and notification history can be integrated now.
- Phone/email accounts with the same number are separate accounts. Phone accounts cannot add an email through the existing password-confirmed change-email flow. Hide unsupported actions appropriately.
- Real SMS receipt, complete KYC/email/provider flows, hidden-tab push and physical iOS/Android acceptance still need end-to-end checks with approved test fixtures. Legal content is user-pending. No production payment readiness is claimed.
- Local backend/schema fixes and frontend lint/hydration fixes were built and tested, but were not deployed in this packaging task. Public runtime routes match all 448 exported operations. The bundled OpenAPI has corrected documentation that may be newer than the server's Swagger UI; use the bundled file for this handoff. SSH deployment-marker verification was attempted but credentials were rejected; no server settings were changed.
- Cloud Postman was not published or synced. Import the supplied files directly; cloud publication is unnecessary for using this ZIP.

## App acceptance checklist

Test on both iOS and Android: token refresh and remembered login; email/phone signup and onboarding/skip; maintenance and expiry errors; search/empty/partial failures; HLS/quality/prefetch/play counts/progress/likes; playlist/library actions; size/colour checkout and ticket tiers; dummy Pay/Cancel, timeout/retry/idempotency, free tickets and hold expiry; wallet history/rewards; reviews/wishlist; notification reconnect/deep links; offline download renew/sync/remove; creator draft/upload/review/revision/preview/delete where that app supports creators. Use your own fixtures and remove them afterward. Do not reuse example IDs as real content.

## Files and validation

- `API_CHANGES_FOR_APPS.md`: complete breaking/behavior/new-endpoint migration guide and release history.
- `postman/BeatX-Mobile.postman_collection.json`: mobile-focused requests and examples.
- `postman/BeatX-RoleBased.postman_collection.json`: full API reference, including admin/internal operations.
- `postman/BeatX-Test.postman_environment.json`: blank credentials/tokens and configurable IDs.
- `postman/BeatX-SafeSmoke.postman_collection.json`: six safe public requests.
- `openapi/BeatX.openapi.json`: source-derived OpenAPI snapshot with corrected auth/search/update/upload schemas.
- `verification/`: actual checks, publication/deployment status and collection contract coverage.
- `SHA256SUMS.json`: file hashes for checking archive contents.

Saved Postman responses are illustrative contract/schema examples, not snapshots of real customer records. Some dynamic content/analytics objects remain intentionally open schemas; use the migration guide and the returned fields rather than treating generic objects as empty responses. The collection verifier checks method/path coverage, roles, bodies, parameters, variables, migration contracts and compiled DTO fixtures; it does not certify every live mutation.
