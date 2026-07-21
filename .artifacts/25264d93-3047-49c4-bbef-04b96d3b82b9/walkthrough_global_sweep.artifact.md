# Volt: Global Intelligence Sweep Walkthrough

The application has been transformed from a static city-based tracker into a dynamic, **Global Grid Intelligence** system. You can now track power status at any specific point in Zimbabwe using real-time AI and geocoding.

## Key Breakthroughs

### 🌍 Universal Grid Discovery
- **Search Any Point**: The "Discovery" search now uses the Nominatim geocoder. You can search for specific streets, suburbs, or even remote villages across Zimbabwe.
- **Dynamic Registration**: Selecting a search result automatically registers it as a new "Grid Node" in your personal watchlist and the national database.

### 🛰️ Live Intelligence Sweep
- **AI Inference**: When you search for a new point, Gemini AI performs a "Live Inference" to predict if that coordinate currently has power based on broader regional patterns.
- **National Sync**: The new "Sync Live Intelligence" button on the map (Refresh icon) triggers a nationwide sweep, where AI re-evaluates and updates the status of every registered node in Zimbabwe.

### 📍 Expanded National Spine
- **Major Hubs Added**: The default registry now includes critical grid "Spine" components like the **Warren**, **Marvel**, and **Sherwood** Bulk Supply substations, alongside the major generation plants (Hwange/Kariba).
- **High-Density Mapping**: The map can now support hundreds of pulsing markers across all provinces.

### 🛡️ Admin Recovery Tools
- **Decommission Protocol**: A new "Wipe Registry" feature in the Admin Sync portal allows developers to clear the node database for maintenance or testing.

## How to Test
1. Go to the **PULSE** (Alerts) tab and search for a specific suburb (e.g., "Parklands, Bulawayo").
2. Select the result to add it to your map.
3. Observe the **Atlas** (Map) to see the new node pulsing.
4. Tap the **Refresh** icon in the map header to trigger a "National Intelligence Sweep".
