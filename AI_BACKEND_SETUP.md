# Volt AI backend \u2014 setup & deploy

This moves all Gemini calls off the Flutter client and into Firebase Cloud
Functions, so the API key never ships inside the app.

## 0. Revoke the old keys (if you haven't already)

Google AI Studio \u2192 API keys \u2192 delete both keys that were in the old
`ai_service.dart`. They were committed to a public GitHub repo, so treat
them as burned regardless of anything else below.

## 1. Get a fresh Gemini API key

https://aistudio.google.com/apikey \u2192 create a new key. Copy it, you'll
paste it once into Secret Manager in step 4 and nowhere else.

## 2. Install the Firebase CLI (if you don't have it)

```cmd
npm install -g firebase-tools
firebase login
```

## 3. Install function dependencies

```cmd
cd functions
npm install
cd ..
```

## 4. Store the key in Secret Manager (NOT in code, NOT in .env committed to git)

```cmd
firebase functions:secrets:set GEMINI_API_KEY
```

Paste the new key when prompted. This stores it in Google Secret Manager,
scoped to your `zim-tracker-bce22` project. Only the deployed function can
read it at runtime.

## 5. Deploy the functions

```cmd
firebase deploy --only functions
```

This deploys 5 callable functions: `parseZetdcNotice`, `getGridForecast`,
`getMapIntelligenceSummary`, `performNationalIntelligenceSweep`,
`inferStatusForCoordinate`.

## 6. Update the Flutter app

```cmd
flutter pub get
```

`ai_service.dart` has already been rewritten to call these functions via
`cloud_functions` instead of talking to Gemini directly \u2014 no changes
needed in `home_view_model.dart` or `admin_sync_screen.dart`, the method
signatures are identical.

## What changed vs. the old design

- The old service held 2 hardcoded API keys and rotated between them on
  quota errors. The new one holds 1 key, stored server-side, with the same
  3-tier model fallback (`gemini-3.5-flash` \u2192 `gemini-3.1-pro` \u2192
  `gemini-3.1-flash-lite`) on 503/quota/not-found errors.
- Every function calls `requireAuth()` first \u2014 only signed-in users
  (which is already mandatory to reach any screen in this app) can trigger
  a Gemini call. This also stops a leaked/scraped endpoint from being used
  to burn your quota anonymously.
- If you want a hard cap on cost, consider adding Firebase App Check on
  top of this later \u2014 happy to wire that in when you're ready.
