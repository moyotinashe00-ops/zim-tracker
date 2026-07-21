# AI Model Alignment & Stability Task List

- [ ] AI Service Alignment
    - [x] Update `_modelTiers` to 2026 standard (3.5 Flash, 3.1 Pro, 3.1 Flash-Lite)
    - [x] Refactor `_executeWithResilience` to handle 503 (Busy) with immediate model step-down
    - [x] Ensure quota rotation remains as a secondary recovery step
- [ ] Verification
    - [ ] Confirm in logs that 1.5/2.0 series are no longer called
    - [ ] Verify 3.1 Pro fallback on 3.5 Flash 503 error
