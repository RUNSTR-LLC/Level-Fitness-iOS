# Issue #3: Workout Publishing UI & Controls

## Overview
Implement user controls for publishing workouts to Nostr with two options: "Post" (kind 1 social summary) and "Save" (kind 1301 structured record), with support for both manual publishing and automatic sync toggle.

## User Story
As a RunstrRewards user, I want to share my workout achievements on Nostr as social posts and also save detailed workout records to the decentralized network for future access and verification.

## Technical Requirements

### 1. Workout Publishing Controls
- **File**: `RunstrRewards/Features/Profile/ProfileWorkoutHistoryView.swift`
- Add publishing buttons to workout detail view/modal
- "Post" button: Publishes kind 1 social summary
- "Save" button: Publishes kind 1301 structured record  
- Show publishing status (pending, success, failed)
- Support bulk selection for multiple workouts

### 2. Workout Detail Publishing Modal
- **File**: `RunstrRewards/Features/Workouts/WorkoutPublishingViewController.swift` (new)
- Modal presented from workout history
- Preview of social post content (editable)
- Privacy settings (public/private)
- Relay selection (default to all)
- Publishing progress indicator

### 3. Auto-Sync Settings
- **File**: `RunstrRewards/Features/Settings/NostrSettingsViewController.swift` (new)
- Toggle for automatic workout publishing
- Separate toggles for kind 1 and kind 1301
- Default relay configuration  
- Publishing privacy preferences
- Sync frequency settings

### 4. Publishing Status Tracking
- **File**: `RunstrRewards/Models/WorkoutPublishStatus.swift` (new)
- Track publishing status per workout
- Store event IDs for published workouts
- Handle partial failures (some relays succeed)
- Retry failed publications

## Implementation Steps

### Phase 1: Core Publishing UI
1. [ ] Create `WorkoutPublishingViewController` modal
2. [ ] Add "Post" and "Save" buttons to workout history
3. [ ] Implement workout content preview
4. [ ] Add publishing progress indicators

### Phase 2: Settings Integration
1. [ ] Create `NostrSettingsViewController`
2. [ ] Add auto-sync toggle controls
3. [ ] Implement relay configuration UI
4. [ ] Add privacy preference controls

### Phase 3: Status Management
1. [ ] Create `WorkoutPublishStatus` model
2. [ ] Implement status tracking in database
3. [ ] Add retry mechanisms for failed posts
4. [ ] Show publishing history in settings

### Phase 4: Bulk Operations
1. [ ] Add multi-select to workout history
2. [ ] Implement bulk publishing operations
3. [ ] Add progress tracking for bulk operations
4. [ ] Handle partial success scenarios

## UI Design Specifications

### Publishing Button States
```swift
enum PublishingState {
    case unpublished    // "Post" / "Save"
    case publishing     // "Publishing..." with spinner  
    case published      // "✓ Posted" / "✓ Saved" (disabled)
    case failed         // "⚠ Failed - Tap to retry"
    case partialSuccess // "⚠ Some relays failed"
}
```

### Social Post Content Format
```
Just completed a 5.2km run! 🏃‍♂️💨

📊 Stats:
⏱ Duration: 28m 45s  
🚀 Pace: 5:32 /km
💪 Calories: 387
❤️ Avg HR: 152 bpm

#running #fitness #nostr #runstrrewards
```

### Workout Detail Modal Layout
- Workout summary at top
- Two prominent buttons: "Post" and "Save"  
- Preview section (expandable)
- Settings gear icon for preferences
- Progress indicator during publishing

## Publishing Logic

### Kind 1 Social Post Creation
```swift
func createSocialPost(for workout: Workout) -> String {
    let emoji = workout.activityType.emoji
    let activity = workout.activityType.displayName
    
    var content = "Just completed a \(workout.distanceFormatted) \(activity)! \(emoji)\n\n📊 Stats:\n"
    content += "⏱ Duration: \(workout.durationFormatted)\n"
    
    if let pace = workout.averagePace {
        content += "🚀 Pace: \(pace.formatted)\n"
    }
    
    if let calories = workout.calories {
        content += "💪 Calories: \(Int(calories))\n"  
    }
    
    if let hr = workout.averageHeartRate {
        content += "❤️ Avg HR: \(Int(hr)) bpm\n"
    }
    
    content += "\n#\(activity.lowercased()) #fitness #nostr #runstrrewards"
    return content
}
```

### Kind 1301 Structured Data
- Use exact format from `RUNSTR/RUNSTR IOS/Core/Models/NostrModels.swift`
- Include all available workout metrics
- Validate required fields before publishing
- Add source metadata for traceability

## Auto-Sync Implementation

### Settings Storage
```swift
struct NostrPublishingSettings {
    var autoPublishSocialPosts: Bool = false
    var autoPublishWorkoutRecords: Bool = false  
    var publishPrivacy: PublishPrivacy = .public
    var selectedRelays: [String] = NostrRelay.defaultRelays
    var syncFrequency: SyncFrequency = .immediate
}
```

### Background Publishing
- Integrate with `BackgroundTaskManager`
- Queue workouts for publishing when network available
- Handle rate limiting from relays
- Respect user preferences for auto-sync

## Database Schema

### Publishing Status Tracking
```sql
-- New table for workout publishing status
CREATE TABLE workout_publish_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID REFERENCES workouts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    kind INTEGER NOT NULL, -- 1 or 1301
    status TEXT NOT NULL CHECK (status IN ('pending', 'publishing', 'published', 'failed', 'partial')),
    event_id TEXT, -- Nostr event ID if published
    published_relays TEXT[], -- Array of successful relay URLs
    failed_relays TEXT[], -- Array of failed relay URLs  
    error_message TEXT,
    attempted_at TIMESTAMPTZ,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_workout_publish_status_workout ON workout_publish_status(workout_id);
CREATE INDEX idx_workout_publish_status_user ON workout_publish_status(user_id);
CREATE INDEX idx_workout_publish_status_status ON workout_publish_status(status);
```

## Error Handling

### Common Publishing Errors
- Network connectivity issues
- Relay rate limiting  
- Invalid event format
- Missing user keys
- Relay connection timeout

### User Experience
- Clear error messages with suggested actions
- Automatic retry with exponential backoff
- Manual retry buttons for failed posts
- Offline queue for when network unavailable

## Privacy Considerations

### Content Filtering
- Allow users to edit social post content
- Option to exclude sensitive data (location, HR)
- Privacy toggle per workout
- Bulk privacy settings

### Data Control
- Users can delete published events (if relay supports)
- Clear indication of what data is shared
- Option to use private relays only
- Granular control over shared metrics

## Success Criteria
- [ ] Users can publish workouts as social posts (kind 1)
- [ ] Users can save structured workout records (kind 1301)
- [ ] Auto-sync works reliably in background
- [ ] Publishing status clearly indicated in UI
- [ ] Failed publications can be retried
- [ ] Bulk publishing operations work smoothly
- [ ] Settings provide adequate privacy control

## Files to Create/Modify

### New Files
- `RunstrRewards/Features/Workouts/WorkoutPublishingViewController.swift`
- `RunstrRewards/Features/Settings/NostrSettingsViewController.swift`
- `RunstrRewards/Models/WorkoutPublishStatus.swift`
- `RunstrRewards/Models/NostrPublishingSettings.swift`

### Modified Files
- `RunstrRewards/Features/Profile/ProfileWorkoutHistoryView.swift`
- `RunstrRewards/Services/WorkoutDataService.swift`
- `RunstrRewards/Services/BackgroundTaskManager.swift`
- `RunstrRewards/Features/Settings/SettingsViewController.swift`
- `supabase_schema.sql`

## Reference Implementation  
See `RUNSTR/RUNSTR IOS/Core/Services/Nostr/NostrEventPublisher.swift` for publishing patterns and content formatting.

## Dependencies
- Requires Issue #1 (Nostr Authentication) 
- Requires Issue #4 (Nostr Service Layer)
- Works alongside Issue #2 (Workout Sync)

## Priority: Medium-High
Key user-facing feature that provides immediate value.

## Estimated Effort: 3-4 days
Moderate complexity due to UI requirements and status management.