# Volt: Redesign Walkthrough

The application has been completely rewritten to the **Volt Grid Intelligence** design. This overhaul introduces a premium, data-driven aesthetic and a robust architecture.

## Key Changes

### 1. Volt Design System
- **Theme**: Moved to `VoltTheme` (Deep Obsidian & Cyber Blue).
- **Typography**: Integrated `Roboto Mono` for data displays to give an industrial, high-tech feel.
- **Glassmorphism**: UI components now use a custom `glassDecoration` for a modern, layered look.

### 2. Architecture Upgrade
- **Provider Pattern**: Implemented `MultiProvider` in `main.dart` for state management.
- **Repositories**: Created `GridRepository` to handle data logic outside of UI classes.
- **ViewModels**: Added `HomeViewModel` to manage screen state reactively.

### 3. Screen Redesigns
- **Dashboard**: Features real-time `GridPulseWidget` and AI-driven forecasts.
- **Chronos Timeline**: A cleaner, data-centric view of planned outages.
- **Utility Hub**: Integrated hardware status (Torch/Battery) with a ZESA token calculator.
- **Pulse Center**: Real-time grid event logging with color-coded severity.
- **Knowledge Base**: Structured breakdown of load-shedding stages and community protocols.
- **Access Portal**: A high-security aesthetic for the authentication flow.

## Visual & Functional Improvements
- **Grid Pulse**: An animated wave visualization representing national grid health.
- **Deep Linking**: Quick Actions on the Dashboard now navigate directly to relevant tabs (Chronos, Reporting).
- **Interactive Pulse**: Real-time toggling of grid node subscriptions with immediate Firestore persistence.
- **Resource Hub**: Technical resources and emergency contacts wired to external system handlers (Tel/Web).
- **Outage Reporting**: A unified grid failure logging system with community verification protocols.
- **Access Management**: Secure sign-out and account management flows.
- **Hardware Integration**: Real-time battery monitoring and torch control within the Utility Hub.

## Cleanup
- Removed legacy `AppTheme` and all associated standard Material styles.
- Standardized all UI components to use `VoltTheme` glassmorphism and data typography.
