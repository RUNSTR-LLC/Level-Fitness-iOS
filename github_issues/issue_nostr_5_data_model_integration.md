# Issue #5: Data Model & Integration Updates

## Overview
Update the core data models and services to support Nostr workouts, including adding Nostr-specific metadata to the Workout model, updating competition logic to accept Nostr workouts, and implementing proper validation for decentralized workout data.

## User Story
As a RunstrRewards user with Nostr workouts, I want these workouts to count towards team competitions with the same reliability as HealthKit workouts, while maintaining data integrity and proper source attribution.

## Technical Requirements

### 1. Workout Model Updates
- **File**: `RunstrRewards/Models/Workout.swift` (if exists) or core workout model
- Add Nostr-specific metadata fields
- Support multiple data sources in same model
- Maintain backward compatibility with existing workouts
- Add validation for Nostr workout data

### 2. WorkoutDataService Integration  
- **File**: `RunstrRewards/Services/WorkoutDataService.swift`
- Update to handle multiple workout sources
- Implement source-aware duplicate detection
- Add Nostr workout validation logic
- Update sync and storage mechanisms

### 3. Competition Logic Updates
- **File**: `RunstrRewards/Services/EventCriteriaEngine.swift`
- Ensure Nostr workouts count towards competitions
- Add source-based validation rules
- Implement anti-cheat measures for Nostr data
- Update scoring calculations to handle all sources

### 4. Database Schema Updates
- **File**: `supabase_schema.sql`
- Add Nostr metadata columns to workouts table
- Create indexes for efficient Nostr workout queries
- Add constraints for data integrity
- Migration scripts for existing data

## Implementation Steps

### Phase 1: Data Model Foundation
1. [ ] Define `WorkoutSource` enum with all source types
2. [ ] Update core workout model with Nostr fields
3. [ ] Add validation methods for Nostr workout data
4. [ ] Create migration strategy for existing workouts

### Phase 2: Service Integration
1. [ ] Update `WorkoutDataService` for multi-source support
2. [ ] Implement source-aware duplicate detection
3. [ ] Add Nostr workout validation pipeline
4. [ ] Update storage and retrieval methods

### Phase 3: Competition Compatibility  
1. [ ] Ensure `EventCriteriaEngine` accepts Nostr workouts
2. [ ] Add source-based anti-cheat validation
3. [ ] Update leaderboard calculations
4. [ ] Test competition scoring with mixed sources

### Phase 4: Database Migration
1. [ ] Create migration scripts for schema updates
2. [ ] Add proper indexes for performance
3. [ ] Implement data integrity constraints
4. [ ] Test migration with existing data

## Data Model Updates

### WorkoutSource Enum
```swift
enum WorkoutSource: String, CaseIterable, Codable {
    case healthKit = "healthkit"
    case nostr = "nostr" 
    case manual = "manual"
    case strava = "strava" // Future integration
    case garmin = "garmin" // Future integration
    
    var displayName: String {
        switch self {
        case .healthKit: return "Apple Health"
        case .nostr: return "Nostr"
        case .manual: return "Manual Entry"
        case .strava: return "Strava"
        case .garmin: return "Garmin"
        }
    }
    
    var icon: String {
        switch self {
        case .healthKit: return "heart.fill"
        case .nostr: return "bolt.fill"
        case .manual: return "pencil"
        case .strava: return "s.circle.fill" 
        case .garmin: return "g.circle.fill"
        }
    }
}
```

### Updated Workout Model
```swift
struct Workout: Codable, Identifiable {
    let id: UUID
    let activityType: ActivityType
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let distance: Double
    let calories: Double?
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let elevationGain: Double?
    let elevationLoss: Double?
    let steps: Int?
    
    // Source information
    let source: WorkoutSource
    let sourceId: String // Original ID from source system
    
    // HealthKit specific
    let healthKitId: String?
    
    // Nostr specific
    let nostrEventId: String?
    let nostrPubkey: String?
    let nostrRelayUrl: String?
    let nostrSignature: String?
    
    // Validation and integrity
    let isVerified: Bool
    let verificationScore: Double // 0.0 to 1.0 confidence
    let lastValidated: Date?
    
    // Metadata
    let createdAt: Date
    let updatedAt: Date
    let syncedAt: Date?
}
```

## Database Schema Changes

### Updated Workouts Table
```sql
-- Add Nostr and source tracking columns
ALTER TABLE workouts 
ADD COLUMN source TEXT DEFAULT 'healthkit' CHECK (source IN ('healthkit', 'nostr', 'manual', 'strava', 'garmin')),
ADD COLUMN source_id TEXT NOT NULL, -- Original ID from source
ADD COLUMN healthkit_id TEXT,
ADD COLUMN nostr_event_id TEXT,
ADD COLUMN nostr_pubkey TEXT,
ADD COLUMN nostr_relay_url TEXT,
ADD COLUMN nostr_signature TEXT,
ADD COLUMN is_verified BOOLEAN DEFAULT true,
ADD COLUMN verification_score REAL DEFAULT 1.0 CHECK (verification_score >= 0.0 AND verification_score <= 1.0),
ADD COLUMN last_validated TIMESTAMPTZ,
ADD COLUMN synced_at TIMESTAMPTZ DEFAULT now();

-- Create indexes for efficient queries
CREATE INDEX idx_workouts_source ON workouts(source);
CREATE INDEX idx_workouts_source_id ON workouts(source_id);
CREATE INDEX idx_workouts_nostr_event ON workouts(nostr_event_id) WHERE nostr_event_id IS NOT NULL;
CREATE INDEX idx_workouts_nostr_pubkey ON workouts(nostr_pubkey) WHERE nostr_pubkey IS NOT NULL;
CREATE INDEX idx_workouts_verification ON workouts(is_verified, verification_score);

-- Add unique constraint to prevent duplicate imports
CREATE UNIQUE INDEX idx_workouts_source_unique ON workouts(source, source_id, user_id);

-- Migration script for existing data
UPDATE workouts 
SET source = 'healthkit',
    source_id = COALESCE(healthkit_uuid, id::text),
    is_verified = true,
    verification_score = 1.0
WHERE source IS NULL;
```

## Validation Pipeline

### Nostr Workout Validation
```swift
struct NostrWorkoutValidator {
    
    enum ValidationError: Error {
        case invalidEventFormat
        case missingRequiredFields  
        case invalidSignature
        case duplicateEvent
        case timeStampInFuture
        case unreasonableValues
    }
    
    static func validate(_ workout: Workout) -> ValidationResult {
        var score: Double = 1.0
        var issues: [ValidationIssue] = []
        
        // Basic field validation
        if workout.nostrEventId == nil || workout.nostrPubkey == nil {
            issues.append(.missingNostrMetadata)
            score -= 0.3
        }
        
        // Timestamp validation
        if workout.startTime > Date() {
            issues.append(.futureTimestamp)  
            score -= 0.5
        }
        
        // Reasonableness checks
        if workout.duration > 24 * 3600 { // > 24 hours
            issues.append(.unreasonableDuration)
            score -= 0.2
        }
        
        if let pace = workout.averagePace, pace < 120 { // < 2 min/km
            issues.append(.unreasonablePace)
            score -= 0.3
        }
        
        // Heart rate validation
        if let hr = workout.averageHeartRate, hr > 220 || hr < 30 {
            issues.append(.unreasonableHeartRate)
            score -= 0.1
        }
        
        return ValidationResult(
            score: max(0.0, score),
            issues: issues,
            isAccepted: score > 0.5 // Minimum threshold
        )
    }
}
```

### Anti-Cheat Integration

#### Competition Eligibility Rules
```swift
extension EventCriteriaEngine {
    
    func isWorkoutEligibleForCompetition(_ workout: Workout, event: Event) -> Bool {
        // Basic eligibility (time, activity type, etc.)
        guard workout.isBasicallyEligible(for: event) else { return false }
        
        // Source-specific validation
        switch workout.source {
        case .healthKit:
            return true // Always trusted
            
        case .nostr:
            return workout.isVerified && 
                   workout.verificationScore > 0.7 &&
                   workout.hasValidNostrSignature
                   
        case .manual:
            return workout.verificationScore > 0.8 // Higher threshold for manual
            
        case .strava, .garmin:
            return workout.isVerified // Future: additional OAuth validation
        }
    }
    
    private func validateNostrWorkout(_ workout: Workout) -> Bool {
        guard let eventId = workout.nostrEventId,
              let pubkey = workout.nostrPubkey else { return false }
        
        // Additional validation could include:
        // - Verify event still exists on relays
        // - Check event signature
        // - Validate against known user pubkey
        // - Cross-reference with other data sources
        
        return NostrWorkoutValidator.validate(workout).isAccepted
    }
}
```

## Service Updates

### WorkoutDataService Changes
```swift
extension WorkoutDataService {
    
    func syncNostrWorkouts(for user: UserProfile) async throws -> [Workout] {
        guard let nostrService = NostrService.shared else {
            throw WorkoutSyncError.nostrServiceUnavailable
        }
        
        // Fetch from Nostr relays
        let nostrWorkouts = try await nostrService.fetchUserWorkouts(
            pubkey: user.nostrPublicKey,
            since: user.lastNostrSync
        )
        
        // Validate each workout
        let validatedWorkouts = nostrWorkouts.compactMap { workout in
            let validation = NostrWorkoutValidator.validate(workout)
            guard validation.isAccepted else { return nil }
            
            return workout.withValidation(validation)
        }
        
        // Check for duplicates with existing workouts
        let deduplicatedWorkouts = try await removeDuplicates(
            validatedWorkouts,
            against: user.existingWorkouts
        )
        
        // Store in database
        try await store(deduplicatedWorkouts, for: user)
        
        // Update sync timestamp
        user.lastNostrSync = Date()
        try await updateUser(user)
        
        return deduplicatedWorkouts
    }
    
    private func removeDuplicates(_ newWorkouts: [Workout], against existing: [Workout]) async throws -> [Workout] {
        return newWorkouts.filter { newWorkout in
            !existing.contains { existingWorkout in
                areLikelyDuplicates(newWorkout, existingWorkout)
            }
        }
    }
    
    private func areLikelyDuplicates(_ workout1: Workout, _ workout2: Workout) -> Bool {
        let timeDiff = abs(workout1.startTime.timeIntervalSince(workout2.startTime))
        let durationDiff = abs(workout1.duration - workout2.duration)
        let distanceDiff = abs(workout1.distance - workout2.distance)
        
        return workout1.activityType == workout2.activityType &&
               timeDiff < 900 && // 15 minutes
               durationDiff < 300 && // 5 minutes  
               distanceDiff < 500 // 500 meters
    }
}
```

## Testing Strategy

### Unit Tests
- Test workout validation with various Nostr event formats
- Test duplicate detection across sources
- Test competition eligibility with different source types
- Test database migration scripts

### Integration Tests  
- Test end-to-end Nostr workout sync
- Test competition scoring with mixed workout sources
- Test data integrity after migrations
- Test performance with large datasets

## Success Criteria
- [ ] Nostr workouts stored with proper metadata and validation
- [ ] Duplicate detection works across HealthKit and Nostr sources
- [ ] Competition engine accepts verified Nostr workouts
- [ ] Database migration completes successfully for existing data
- [ ] Anti-cheat validation prevents obviously fake workouts
- [ ] Performance remains acceptable with mixed workout sources
- [ ] Data integrity maintained across all operations

## Files to Create/Modify

### New Files
- `RunstrRewards/Models/WorkoutSource.swift`
- `RunstrRewards/Validation/NostrWorkoutValidator.swift`
- `RunstrRewards/Models/ValidationResult.swift`

### Modified Files
- Core workout model file (location TBD)
- `RunstrRewards/Services/WorkoutDataService.swift`
- `RunstrRewards/Services/EventCriteriaEngine.swift`
- `RunstrRewards/Services/LeaderboardTracker.swift`
- `supabase_schema.sql`
- Database migration scripts

## Migration Strategy

### Backwards Compatibility
- All existing workouts default to `source: .healthKit`
- Existing competition logic unchanged for HealthKit workouts
- Gradual rollout of Nostr validation features
- Fallback behaviors for missing Nostr metadata

### Performance Considerations
- Efficient indexes for source-based queries
- Optimized duplicate detection algorithms
- Lazy loading of Nostr metadata when needed
- Cache validation results to avoid repeated checks

## Priority: High
Core integration that enables all other Nostr features to work with competitions.

## Estimated Effort: 4-5 days  
Complex due to data model changes, migration requirements, and integration touchpoints across the entire system.