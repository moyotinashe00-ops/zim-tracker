# Volt: AI Resilience & Dependency Upgrade Walkthrough

The **Volt Intelligence** layer has been hardened to handle "Not Found" and "Quota Exceeded" errors gracefully. By upgrading dependencies and implementing a tiered fallback strategy, the app now ensures continuous operation even when specific AI models are unavailable.

## Resilience Breakthroughs

### 1. Tiered Model Hierarchy
- **Primary Intelligence**: Still prioritizes the high-speed `gemini-3.5-flash`.
- **Automatic Descension**: If a 3.5 series model is reported as "Not Found" or "Not Supported" on your current API endpoint, the system automatically descends to the production-stable **Gemini 1.5 Flash** series.
- **Ultra-Lite Safety Net**: As a final measure, it can switch to `gemini-1.5-flash-8b` to ensure baseline intelligence is always available.

### 2. Smart Error Detection & Key Rotation
- **429/Quota Logic**: When a rate limit is detected, the app rotates across your multiple API keys first.
- **404/Availability Logic**: When a model itself is unavailable, the app skips that tier and moves to the next stable model in the hierarchy.
- **Unified Resilience Wrapper**: All AI operations are now wrapped in `_executeWithResilience`, which manages the entire retry-rotate-fallback loop automatically.

### 3. Dependency Upgrade
- **Stability**: Upgraded `google_generative_ai` to `^0.4.7` to ensure correct model mapping and compatibility with 2026-era API endpoints.

## Verification Results
- **Model Fallback**: Confirmed in logs that the app now successfully bypasses the missing 3.5-flash-lite model and engages the 1.5-flash fallback.
- **Map Intelligence**: Strategic summaries and live sweeps are now fully functional and resilient to model availability issues.
