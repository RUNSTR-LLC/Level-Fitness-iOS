# Issue #1: Nostr Authentication System

## Overview
Implement Nostr login as an alternative authentication method alongside Apple Sign-In, allowing users to create new Nostr accounts or import existing ones with secure in-app key storage.

## User Story
As a RunstrRewards user, I want to authenticate using my Nostr identity so that I can sync my workout data from Nostr relays and publish workouts to the decentralized network.

## Technical Requirements

### 1. Authentication UI Updates
- **File**: `RunstrRewards/Features/Authentication/AuthenticationViewController.swift` (create if needed)
- Add "Sign in with Nostr" button below Apple Sign-In
- Implement key import flow (nsec entry)  
- Implement new key generation flow
- Add Nostr profile setup (name, picture, about)

### 2. NostrKeyManager Implementation  
- **File**: `RunstrRewards/Services/NostrKeyManager.swift`
- Port from `RUNSTR/RUNSTR IOS/Core/Services/Nostr/NostrKeyManager.swift`
- Secure Keychain storage for private keys
- Key generation using NostrSDK
- Key validation and format conversion (nsec/hex)

### 3. Integration with Existing Auth Flow
- **File**: `RunstrRewards/Services/SupabaseService.swift`
- Modify to support Nostr authentication alongside Apple
- Create Supabase user records for Nostr users
- Link npub to user profiles
- Handle session management for Nostr users

### 4. User Profile Updates
- **File**: `RunstrRewards/Models/UserProfile.swift`
- Add `nostrPublicKey` field (npub)
- Add `authMethod` enum: `.apple`, `.nostr`
- Update profile sync logic

### 5. Dependencies
- Add `NostrSDK` to project via SPM
- Update `Package.swift` or Xcode project dependencies

## Implementation Steps

### Phase 1: Core Infrastructure
1. [ ] Add NostrSDK dependency to project
2. [ ] Create `NostrKeyManager.swift` service
3. [ ] Implement secure key storage in Keychain
4. [ ] Add key generation and validation methods

### Phase 2: Authentication UI
1. [ ] Design Nostr login UI components
2. [ ] Create key import/generation flows
3. [ ] Add Nostr profile setup screen
4. [ ] Implement error handling and validation

### Phase 3: Backend Integration
1. [ ] Update `UserProfile` model for Nostr fields
2. [ ] Modify Supabase auth flow for Nostr users
3. [ ] Implement user creation/linking logic
4. [ ] Add session persistence for Nostr auth

### Phase 4: Testing & Polish
1. [ ] Unit tests for key management
2. [ ] Integration tests for auth flow
3. [ ] UI/UX testing and refinement
4. [ ] Security audit of key storage

## Database Schema Changes

```sql
-- Add to user_profiles table
ALTER TABLE user_profiles 
ADD COLUMN nostr_public_key TEXT UNIQUE,
ADD COLUMN auth_method TEXT DEFAULT 'apple' CHECK (auth_method IN ('apple', 'nostr'));

-- Index for Nostr lookups
CREATE INDEX idx_user_profiles_nostr_pubkey ON user_profiles(nostr_public_key);
```

## Security Considerations
- Private keys must never leave device or be transmitted
- Use iOS Keychain with appropriate access controls
- Validate key formats before storage
- Implement key backup/recovery warnings
- Add biometric protection for key access

## Success Criteria
- [ ] Users can create new Nostr accounts in-app
- [ ] Users can import existing Nostr keys (nsec format)
- [ ] Keys stored securely in iOS Keychain
- [ ] Nostr users can access all app features
- [ ] Profile data syncs between local and Supabase
- [ ] Authentication persists across app launches

## Files to Create/Modify

### New Files
- `RunstrRewards/Services/NostrKeyManager.swift`
- `RunstrRewards/Features/Authentication/NostrLoginViewController.swift`
- `RunstrRewards/Features/Authentication/NostrProfileSetupViewController.swift`

### Modified Files
- `RunstrRewards/Services/SupabaseService.swift`
- `RunstrRewards/Services/AuthDataService.swift`
- `RunstrRewards/Models/UserProfile.swift`
- `RunstrRewards/Features/Authentication/AuthenticationViewController.swift`
- `supabase_schema.sql`

## Reference Implementation
See `RUNSTR/RUNSTR IOS/Core/Services/Nostr/NostrKeyManager.swift` for key management patterns and security best practices.

## Priority: High
This is foundational for all other Nostr features and should be implemented first.

## Estimated Effort: 3-4 days
Complex due to security requirements and auth flow integration.