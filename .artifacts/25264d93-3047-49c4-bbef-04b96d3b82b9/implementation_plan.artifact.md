# Volt: Atlas - National Grid Map Implementation Plan

This plan introduces a high-fidelity map feature called **Atlas**, allowing users to visualize the real-time power status across all grid nodes in Zimbabwe.

## User Review Required

> [!IMPORTANT]
> The map will use OpenStreetMap tiles via `flutter_map`. This requires an active internet connection to load tiles.
> Markers will be color-coded: **Neon Green** (Grid Active) and **Neon Red** (Load Shedding).

## Proposed Changes

### 1. Data Layer Enhancements
- **[MODIFY] [grid_repository.dart](file:///C:/Users/TINASHE/Documents/StudioProjects/zim_tracker/lib/repositories/grid_repository.dart)**:
    - Add `Stream<List<GridZone>> getAllZones()` to fetch all available grid nodes.
- **[MODIFY] [home_view_model.dart](file:///C:/Users/TINASHE/Documents/StudioProjects/zim_tracker/lib/viewmodels/home_view_model.dart)**:
    - Expose the `allZonesStream` for map consumption.

### 2. New Screen: Volt Atlas
- **[NEW] [atlas_screen.dart](file:///C:/Users/TINASHE/Documents/StudioProjects/zim_tracker/lib/screens/atlas_screen.dart)**:
    - Implement a full-screen interactive map using `flutter_map`.
    - Plot custom "Volt" markers for every grid zone.
    - Add an "Info Overlay" that appears when a marker is tapped, showing current status and time until restoration/cut.
    - Implement a "Locate Me" button to zoom into the user's current area.

### 3. UI Integration
- **[MODIFY] [main_layout.dart](file:///C:/Users/TINASHE/Documents/StudioProjects/zim_tracker/lib/screens/main_layout.dart)**:
    - Add "ATLAS" as a new tab or replace the "INFO" tab (as Knowledge Base info can be integrated elsewhere).
    - Alternatively, add a prominent "Open Atlas" button to the Dashboard header.
    - *Decision*: We will replace the "INFO" tab in the bottom navigation with "ATLAS" to give it high visibility, moving the Knowledge Base into a sub-menu or a section in the Atlas screen.

### 4. Styling
- Custom Map Theme: Apply a dark/midnight tile filter if possible, or use a high-contrast dark tile set to match the **Volt** aesthetic.

## Verification Plan

### Automated Tests
- Verify `getAllZones` stream emits correctly when data changes in Firestore.

### Manual Verification
- Test map panning and zooming across Zimbabwe.
- Verify marker color correctly reflects the `status` field in Firestore.
- Ensure the Info Overlay displays the correct `GridZone` data upon tapping a marker.
