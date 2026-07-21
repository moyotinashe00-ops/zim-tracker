# Volt: 2026 Model Alignment & Stability Plan

This plan updates the **Volt Intelligence** layer to align with the July 2026 Gemini model availability. It removes retired 1.5-series models and implements a more resilient fallback chain using active 3.x generation models.

## User Review Required

> [!IMPORTANT]
> Google has officially retired the **Gemini 1.5** and **2.0** series as of mid-2026. Attempts to call these models now return `404 Not Found`.

> [!NOTE]
> We are transitioning the fallback hierarchy to use the **Gemini 3.x** family, which is currently the stable production standard.

## Proposed Changes

### 1. Model Registry Alignment
- **[MODIFY] [ai_service.dart](file:///C:/Users/TINASHE/Documents/StudioProjects/zim_tracker/lib/services/ai_service.dart)**:
    - Update `_modelTiers` to include only active 2026 models:
        1. `gemini-3.5-flash` (Primary)
        2. `gemini-3.1-pro` (High-Intelligence Fallback)
        3. `gemini-3.1-flash-lite` (Efficiency Fallback)
    - Remove retired `gemini-1.5-flash`, `gemini-1.5-flash-8b`, and the experimental `gemini-3.5-flash-lite`.

### 2. Enhanced 503/429 Mitigation
- Update `_executeWithResilience` to handle the `503 Service Unavailable` error more aggressively by immediately stepping down the model tier, even before rotating API keys, as 503 usually indicates model-specific load rather than account-specific limits.

## Verification Plan

### Manual Verification
- Restart the app and trigger a "National Intelligence Sweep".
- Confirm in logs that the app no longer attempts to call the retired 1.5 models.
- Verify that if `gemini-3.5-flash` returns a 503, the system successfully engages `gemini-3.1-pro`.
