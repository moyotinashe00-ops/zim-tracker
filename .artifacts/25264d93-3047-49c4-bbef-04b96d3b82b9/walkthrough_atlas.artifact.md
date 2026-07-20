# Volt: Atlas - National Grid Map Walkthrough

The **Volt Atlas** feature provides a full-screen, interactive map of Zimbabwe, allowing users to visualize the real-time status of the national grid.

## Features

### 1. Interactive National Map
- **Live Telemetry**: Every grid node is plotted using its latitude and longitude from Firestore.
- **Color-Coded Status**:
    - **Neon Green**: Power is active in the area.
    - **Neon Red**: Area is currently under load shedding.
- **Midnight Aesthetic**: Uses high-contrast "CartoDB Dark" map tiles to perfectly match the **Volt** design language.

### 2. Zone Inspector
- **Tap to Inspect**: Tapping any marker opens a detailed overlay at the bottom.
- **Real-Time Data**: Shows the specific status (ACTIVE/OFFLINE) and projected restoration/cut times for the selected area.
- **Primary Node Switching**: Users can instantly set an inspected zone as their "Primary Node" directly from the map, which updates their main Dashboard.

### 3. Integrated Navigation
- **Top Tab Priority**: Atlas is now a first-class citizen in the bottom navigation, replacing the static Info tab.

## Technical Implementation
- **Data Flow**: Powered by the `allZonesStream` in `GridRepository`, ensuring that status changes on the map are reflected in near real-time.
- **Map Engine**: Built using `flutter_map` with a custom marker layer for glowing Volt effects.
