# BeatX mobile API handoff

Read MOBILE_APP_HANDOFF.md first, then API_CHANGES_FOR_APPS.md.

API base: https://fahimstack.tech/beatx-api/api/v1

Import postman/BeatX-Mobile.postman_collection.json and the test environment.
The mobile collection contains 295 operations; the full reference contains 448.
Enter your own test credentials and resource IDs. All credentials are empty.

Payments remain dummy test mode. No Stripe. Monetary values are BDT paisa.
Run only the SafeSmoke collection as an unattended live collection run.

The bundled OpenAPI is newer than the deployed Swagger documentation.
Local schema/frontend fixes were not deployed; cloud Postman was not published.
See verification/RELEASE_STATUS.md for actual checks and remaining acceptance.

SHA256SUMS.json lists the expected SHA-256 hash of every file except itself.
No backend/frontend source tree, credentials, .env, SSH login or internal memory
is included in this package.
