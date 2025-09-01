# Issue #2: Kind 1301 Workout Sync from Relays

## Overview
Implement a "Nostr Workout Records" sync button that fetches kind 1301 workout events from Nostr relays and merges them with HealthKit data for team competitions, with clear source indicators and duplicate detection.

## User Story
As a RunstrRewards user with a Nostr identity, I want to sync my workout records published to Nostr relays so that these workouts count towards team competitions alongside my HealthKit workouts.

## Technical Requirements

### 1. Workout Sync UI Integration
- **File**: `RunstrRewards/Features/Workouts/WorkoutSyncView.swift`
- Add "Nostr Workout Records" button below HealthKit sync
- Show sync status and last sync timestamp
- Display workout count from Nostr vs HealthKit
- Add manual refresh capability

### 2. NostrWorkoutService Implementation
- **File**: `RunstrRewards/Services/NostrWorkoutService.swift`  
- Port from `RUNSTR/RUNSTR IOS/Core/Services/Nostr/NostrWorkoutService.swift`
- Fetch kind 1301 events from user's pubkey
- Parse workout data from event content
- Validate workout event structure
- Handle relay connection errors gracefully

### 3. Relay Configuration
- **Default Relays**: Use reliable public relays
  - `wss://relay.damus.io`
  - `wss://nos.lol` 
  - `wss://relay.snort.social`
  - `wss://relay.primal.net`
- Implement fallback relay logic
- Connection timeout and retry handling

### 4. Workout Data Merging
- **File**: `RunstrRewards/Services/WorkoutDataService.swift`
- Merge Nostr workouts with HealthKit data
- Implement duplicate detection based on:
  - Overlapping start/end times (±15 minutes tolerance)
  - Similar activity type and duration
  - Distance correlation (if available)
- Prioritize HealthKit data for duplicates

### 5. Workout Source Indicators
- **File**: `RunstrRewards/Features/Profile/ProfileWorkoutHistoryView.swift`
- Add visual indicators for workout source:
  - HealthKit: Apple Health icon
  - Nostr: Nostr/lightning icon 
  - Manual: User input icon
- Update workout list cells to show source
- Add filtering by source option

## Implementation Steps

### Phase 1: Service Layer
1. [ ] Create `NostrWorkoutService.swift`
2. [ ] Implement relay connection management  
3. [ ] Add kind 1301 event parsing logic
4. [ ] Implement workout validation methods

### Phase 2: Data Integration
1. [ ] Update `WorkoutDataService` for Nostr integration
2. [ ] Implement duplicate detection algorithm
3. [ ] Add workout source tracking
4. [ ] Update workout storage logic

### Phase 3: UI Implementation  
1. [ ] Add Nostr sync button to `WorkoutSyncView`
2. [ ] Update workout history to show sources
3. [ ] Implement sync status indicators
4. [ ] Add error handling and user feedback

### Phase 4: Background Sync
1. [ ] Add Nostr sync to background tasks
2. [ ] Implement incremental sync (since last fetch)
3. [ ] Handle network connectivity issues
4. [ ] Add sync scheduling logic

## Workout Event Parsing

### Kind 1301 Event Structure
```json
{
  "kind": 1301,
  "content": "{\"type\":\"running\",\"start_time\":1640995200,\"end_time\":1640999800,\"duration\":3600,\"distance\":5000,\"pace\":720,\"calories\":400,\"heart_rate_avg\":150}",
  "tags": [
    ["t", "workout"],
    ["activity", "running"]
  ]
}
```

### Required Fields Validation
- `type`: Activity type (running, cycling, walking)
- `start_time`: Unix timestamp  
- `duration`: Workout duration in seconds
- `distance`: Distance in meters
- Optional: `calories`, `heart_rate_avg`, `pace`

## Duplicate Detection Logic

### Time-based Detection
```swift
func isLikelyDuplicate(_ nostrWorkout: Workout, _ healthKitWorkout: Workout) -> Bool {
    let timeDifference = abs(nostrWorkout.startTime.timeIntervalSince(healthKitWorkout.startTime))
    let durationDifference = abs(nostrWorkout.duration - healthKitWorkout.duration)
    
    return timeDifference < 900 && // 15 minutes
           durationDifference < 300 && // 5 minutes  
           nostrWorkout.activityType == healthKitWorkout.activityType
}
```

## UI/UX Considerations

### Sync Button States
- **Idle**: "Sync Nostr Workouts" 
- **Syncing**: "Syncing..." with spinner
- **Success**: "✓ Synced 12 workouts"
- **Error**: "⚠ Sync failed - Tap to retry"

### Workout List Indicators
- Add small icons next to workout entries
- Use consistent iconography across app
- Consider color coding (subtle, accessible)

## Error Handling

### Common Scenarios
- No internet connection
- Relay unreachable
- Invalid event format
- Missing user keys
- Rate limiting

### User Feedback
- Toast notifications for sync status
- Detailed error messages in settings
- Automatic retry with backoff
- Manual refresh option always available

## Database Integration

### Workout Storage
- Store Nostr workouts in same table as HealthKit
- Add `source` field: `healthkit`, `nostr`, `manual`
- Add `nostr_event_id` for traceability
- Add `relay_url` for source tracking

```sql
-- Add to workouts table
ALTER TABLE workouts 
ADD COLUMN source TEXT DEFAULT 'healthkit' CHECK (source IN ('healthkit', 'nostr', 'manual')),
ADD COLUMN nostr_event_id TEXT,
ADD COLUMN relay_url TEXT;

-- Index for source filtering
CREATE INDEX idx_workouts_source ON workouts(source);
```

## Performance Considerations
- Cache parsed workouts locally
- Implement incremental sync (only new events)
- Use connection pooling for relays
- Background processing for large syncs
- Pagination for large workout histories

## Success Criteria
- [ ] Users can sync kind 1301 events from Nostr relays
- [ ] Nostr workouts appear in workout history with indicators
- [ ] Duplicate detection prevents double-counting
- [ ] Nostr workouts count towards team competitions  
- [ ] Sync works reliably with network issues
- [ ] Performance remains good with large datasets

## Files to Create/Modify

### New Files
- `RunstrRewards/Services/NostrWorkoutService.swift`
- `RunstrRewards/Models/WorkoutSource.swift`

### Modified Files  
- `RunstrRewards/Features/Workouts/WorkoutSyncView.swift`
- `RunstrRewards/Services/WorkoutDataService.swift`
- `RunstrRewards/Features/Profile/ProfileWorkoutHistoryView.swift`
- `RunstrRewards/Services/BackgroundTaskManager.swift`
- `supabase_schema.sql`

## Reference Implementation
See `RUNSTR/RUNSTR IOS/Core/Services/Nostr/NostrWorkoutService.swift` for event parsing and relay communication patterns.

## Dependencies  
- Requires Issue #1 (Nostr Authentication) to be completed
- Requires Issue #4 (Nostr Service Layer) for relay management

## Priority: High
Core functionality for Nostr integration value proposition.

## Estimated Effort: 4-5 days
Complex due to relay handling, parsing, and integration requirements.