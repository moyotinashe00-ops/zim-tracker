# Implementation Plan - Utility Tools & Emergency Features

This plan introduces high-utility features designed to help users manage their electricity budget and survive outages more effectively.

## Proposed Features

### 1. ZESA Tariff Calculator
- **The Problem**: ZESA uses a "stepped" pricing model where the price per unit increases as you buy more in a month.
- **The Solution**: A calculator that tells you exactly how many units you will get for your money (USD/ZWG) or how much a specific number of units will cost.
- **Persistence**: Remembers your "last purchase date" to reset the monthly steps.

### 2. Emergency Outage Torch
- **The Problem**: Power often goes out suddenly, leaving users in total darkness.
- **The Solution**: A prominent, high-contrast toggle on the **Home Screen** to instantly turn on the phone's flashlight.
- **Safety**: Includes an "SOS" strobe mode for emergencies.

### 3. "Power-Back" Auto-Report
- **The Problem**: Community maps rely on manual reports, but users often forget to report when power *returns*.
- **The Solution**: A smart background listener that detects when your phone starts charging. If you are in an "OFF" zone, the app will ask: *"Is the power back? Help your neighbors by confirming!"*

### 4. Solar ROI Estimator
- **The Solution**: A simple tool to help users understand the cost-benefit of switching to solar, tailored to the current load shedding stages.

## Proposed Changes

### Dependencies
#### [MODIFY] [pubspec.yaml](file:///C:/Users/TINASHE/Documents/StudioProjects/zim_tracker/pubspec.yaml)
- Add `torch_light`: For flashlight control.
- Add `battery_plus`: To detect charging state for the "Power-Back" feature.

### UI & Logic
#### [NEW] [screens/tools_screen.dart](file:///C:/Users/TINASHE/Documents/StudioProjects/zim_tracker/lib/screens/tools_screen.dart)
- Dashboard for the **Tariff Calculator** and **Solar Estimator**.

#### [MODIFY] [screens/home_screen.dart](file:///C:/Users/TINASHE/Documents/StudioProjects/zim_tracker/lib/screens/home_screen.dart)
- Add a large, glowing **Torch Toggle** button.
- Integrate the **Charging Detector** logic.

#### [MODIFY] [screens/main_layout.dart](file:///C:/Users/TINASHE/Documents/StudioProjects/zim_tracker/lib/screens/main_layout.dart)
- Add a "Tools" tab to the Bottom Navigation Bar.

## User Review Required

> [!IMPORTANT]
> The **Flashlight** feature requires camera permissions on Android/iOS. I will add the necessary configurations to your `AndroidManifest.xml` and `Info.plist`.

## Verification Plan

### Manual Verification
- Test the Tariff Calculator with different amounts to ensure steps (0-50, 51-200, etc.) are calculated correctly.
- Test the Torch Toggle on a physical device (or verify log output in emulator).
- Simulate "Charging" state in the emulator to trigger the "Power-Back" dialog.
