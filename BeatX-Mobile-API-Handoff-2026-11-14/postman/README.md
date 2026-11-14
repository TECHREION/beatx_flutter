# BeatX API handoff files

Import the mobile or full role-based collection and the test environment. Read `MOBILE_APP_HANDOFF.md` and `API_CHANGES_FOR_APPS.md` from the handoff ZIP/root documentation first. Enter your own test credentials, IDs and device ID; none are included.

API base: `https://fahimstack.tech/beatx-api/api/v1`. Set `platform` to `android` or `ios`; set `activeRole` for shared routes. Login and refresh responses update the selected role's environment tokens. Creator/admin requests use their respective role tokens. Phone OTP and provider login require real user/provider interaction.

The full collection has one request for each of the 448 source HTTP operations; mobile has 295. Multiple callback verbs are one gateway capability, not separate app features. The mobile collection excludes admin-only/internal endpoints. Optional query and form fields are disabled until needed. Complete your own resource variables before sending requests.

Use a new `idempotencyKey` per checkout/redemption attempt and reuse it on retries. A pre-request script creates a UUID if the key is empty; clear it yourself before a different attempt. Do not send API authorization to presigned storage URLs. Choose local files for enabled binary form fields; serialize multipart arrays/objects as JSON strings.

**Do not bulk-run the full/mobile collection.** It includes destructive writes, purchases, OTP sends and stream GETs that record plays. Only `BeatX-SafeSmoke.postman_collection.json` is a safe public runner:

```sh
newman run BeatX-SafeSmoke.postman_collection.json
```

The SafeSmoke collection tests provider visibility, genres, suggestions with a synthetic query, trending search, public availability and payment config. It does not test SMS/provider delivery, real payments or native-app acceptance.

Saved responses are illustrative contract examples; they are not live captures or usable IDs/payment links. The accompanying OpenAPI contains the source schemas. Some dynamic objects are intentionally open. `CONTRACT_VERIFICATION.json` records structural/DTO checks, and `LIVE_SMOKE_VERIFICATION.json` records the safe public run.

For maintainers, regenerate after building the backend:

```sh
npm run build
npm run docs:export
npm run docs:postman
npm run docs:verify
```

The export scans metadata without starting the API, DB, workers or providers. Copy the verified canonical files into the frontend `postman/` directory and rebuild the ZIP. `postman:sync` only uploads the existing JSON; it does not regenerate it. Cloud publication/deployment must be recorded separately.
