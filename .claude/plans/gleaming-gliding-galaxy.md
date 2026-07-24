# Plan: Implement Per-Vote De-duplication for Accuracy Voting

## Context
The ZimTracker TODO.md lists "Per-user vote de-dupe" as a deferred item with the note: "Anyone can currently vote repeatedly on the same zone with no de-dupe. Needs a per-user vote record (e.g. `zones/{id}/votes/{uid}`) to make the signal trustworthy."

Currently, the app stores only aggregate vote counts (`accurateVotes` and `inaccurateVotes`) on each `GridZone` document. This allows users to vote multiple times on the same zone, skewing the accuracy percentage.

This implementation will add per-user vote tracking to prevent duplicate voting while maintaining the existing aggregate counts for backward compatibility and performance.

## Approach
We'll implement a hybrid solution that:
1. Keeps the existing `accurateVotes` and `inaccurateVotes` fields on `GridZone` for efficient querying
2. Adds a `votes` subcollection under each zone: `zones/{zoneId}/votes/{userId}`
3. Uses Firestore transactions to ensure consistency when updating both the vote document and aggregate counts
4. Allows users to change their vote (which updates the aggregate counts appropriately)

## Changes Required

### 1. lib/repositories/grid_repository.dart
Replace the `voteZoneAccuracy` method with a transactional implementation that:
- Checks for existing user vote in the votes subcollection
- If vote exists: updates it and adjusts aggregate counts accordingly
- If vote doesn't exist: creates new vote document and increments appropriate counter
- Handles vote changes (e.g., from accurate to inaccurate)

### 2. No changes needed to:
- `lib/models/grid_zone.dart` - Keep existing fields for backward compatibility
- `lib/viewmodels/home_view_model.dart` - Already calls `voteZoneAccuracy`
- `lib/screens/home_screen.dart` - Already calls `voteZoneAccuracy` via viewmodel
- `lib/services/user_service.dart` - Provides `uid` getter for current user ID

## Implementation Details

### Data Structure
```
zones/{zoneId}
  - accurateVotes: number
  - inaccurateVotes: number
  - ... other fields
  votes/{subcollection}
  {userId}
    - vote: boolean (true = accurate, false = inaccurate)
    - timestamp: Timestamp
```

### Transaction Logic
1. Start transaction
2. Read user's vote document: `zones/{zoneId}/votes/{userId}`
3. Read current zone document to get current counts
4. Case analysis:
   - No existing vote:
     * Create vote document with user's choice
     * Increment corresponding aggregate field
   - Existing vote same as new vote:
     * Do nothing (prevent duplicate counting)
   - Existing vote different from new vote:
     * Update vote document
     * Decrement old vote counter
     * Increment new vote counter
5. Commit transaction

## Files to Modify
1. `lib/repositories/grid_repository.dart` - Replace `voteZoneAccuracy` method

## Testing Approach
1. Verify that voting multiple times in succession doesn't increase counts beyond 1
2. Verify that changing a vote updates counts correctly (decrement old, increment new)
3. Verify that the accuracy percentage updates correctly in the UI
4. Test edge cases: network issues, offline scenarios (transaction should fail safely)
5. Ensure existing functionality remains intact (loading zones, displaying percentages, etc.)

## Dependencies
- Uses existing `UserService.uid` to get current user ID
- Requires Firebase Firestore rules to allow read/write to votes subcollection (assumes existing rules permit authenticated users to vote)

## Estimated Effort
Small-Medium: Requires careful transaction handling but builds on existing patterns in the codebase (transactions are used elsewhere in Firestore operations).