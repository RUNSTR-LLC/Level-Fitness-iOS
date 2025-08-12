# Supabase Setup Guide for Level Fitness iOS

## 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click "New project"
3. Enter project details:
   - Name: `level-fitness`
   - Database Password: (save this securely)
   - Region: Choose closest to your users
4. Wait for project to provision (~2 minutes)

## 2. Get API Credentials

1. Go to Settings → API
2. Copy these values:
   - Project URL: `https://YOUR_PROJECT_ID.supabase.co`
   - Anon/Public Key: `eyJhbGc...` (long string)
3. Update `SupabaseService.swift` with these values

## 3. Configure Authentication

### Enable Sign in with Apple

1. Go to Authentication → Providers
2. Enable "Apple" provider
3. Add your Bundle ID: `com.levelfitness.ios`
4. Configure Apple Services:
   - Services ID: `com.levelfitness.ios.service`
   - Team ID: (from Apple Developer account)
   - Key ID: (from Apple Developer account)
   - Private Key: (download from Apple Developer)

### Set up Auth Redirect

1. Go to Authentication → URL Configuration
2. Add redirect URL: `com.levelfitness.ios://login-callback`

## 4. Create Database Schema

Run these SQL commands in the SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users profile table (extends Supabase auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    total_workouts INTEGER DEFAULT 0,
    total_distance DECIMAL DEFAULT 0,
    total_earnings DECIMAL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Teams table
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    captain_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    member_count INTEGER DEFAULT 0,
    total_earnings DECIMAL DEFAULT 0,
    image_url TEXT,
    invite_code TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Team members junction table
CREATE TABLE team_members (
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (team_id, user_id)
);

-- Workouts table
CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    duration INTEGER NOT NULL, -- seconds
    distance DECIMAL, -- meters
    calories INTEGER,
    heart_rate INTEGER,
    source TEXT NOT NULL, -- 'healthkit', 'strava', etc
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    raw_data JSONB
);

-- Challenges table
CREATE TABLE challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL, -- 'distance', 'duration', 'frequency'
    target_value DECIMAL NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    prize_pool DECIMAL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Challenge participants
CREATE TABLE challenge_participants (
    challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    progress DECIMAL DEFAULT 0,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (challenge_id, user_id)
);

-- Transactions table (for Bitcoin rewards)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'earning', 'withdrawal', 'bonus'
    amount DECIMAL NOT NULL,
    btc_amount DECIMAL,
    description TEXT,
    status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed'
    transaction_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Leaderboard view
CREATE OR REPLACE VIEW leaderboard AS
SELECT 
    p.id as user_id,
    p.username,
    p.avatar_url,
    COUNT(w.id) as workout_count,
    SUM(w.duration) as total_duration,
    SUM(w.distance) as total_distance,
    p.total_earnings,
    RANK() OVER (ORDER BY p.total_earnings DESC) as rank
FROM profiles p
LEFT JOIN workouts w ON p.id = w.user_id
WHERE w.started_at >= NOW() - INTERVAL '7 days'
GROUP BY p.id, p.username, p.avatar_url, p.total_earnings;

-- Create indexes for performance
CREATE INDEX idx_workouts_user_id ON workouts(user_id);
CREATE INDEX idx_workouts_started_at ON workouts(started_at);
CREATE INDEX idx_team_members_user_id ON team_members(user_id);
CREATE INDEX idx_team_members_team_id ON team_members(team_id);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);

-- Row Level Security (RLS) Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Teams policies
CREATE POLICY "Anyone can view teams" ON teams FOR SELECT USING (true);
CREATE POLICY "Captains can update their teams" ON teams FOR UPDATE USING (auth.uid() = captain_id);
CREATE POLICY "Authenticated users can create teams" ON teams FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Team members policies
CREATE POLICY "Anyone can view team members" ON team_members FOR SELECT USING (true);
CREATE POLICY "Users can join teams" ON team_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can leave teams" ON team_members FOR DELETE USING (auth.uid() = user_id);

-- Workouts policies
CREATE POLICY "Users can view own workouts" ON workouts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own workouts" ON workouts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Team members can view teammate workouts" ON workouts FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM team_members tm1
        JOIN team_members tm2 ON tm1.team_id = tm2.team_id
        WHERE tm1.user_id = auth.uid() AND tm2.user_id = workouts.user_id
    )
);

-- Transactions policies
CREATE POLICY "Users can view own transactions" ON transactions FOR SELECT USING (auth.uid() = user_id);

-- Functions and Triggers

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update team member count
CREATE OR REPLACE FUNCTION update_team_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE teams SET member_count = member_count + 1 WHERE id = NEW.team_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE teams SET member_count = member_count - 1 WHERE id = OLD.team_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER team_member_count_trigger
    AFTER INSERT OR DELETE ON team_members
    FOR EACH ROW EXECUTE FUNCTION update_team_member_count();

-- Update user stats after workout
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE profiles 
    SET 
        total_workouts = total_workouts + 1,
        total_distance = total_distance + COALESCE(NEW.distance, 0),
        updated_at = NOW()
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER workout_stats_trigger
    AFTER INSERT ON workouts
    FOR EACH ROW EXECUTE FUNCTION update_user_stats();
```

## 5. Configure Storage Buckets

1. Go to Storage
2. Create bucket: `avatars`
   - Public bucket: Yes
   - File size limit: 5MB
   - Allowed MIME types: `image/*`
3. Create bucket: `team-images`
   - Public bucket: Yes
   - File size limit: 10MB
   - Allowed MIME types: `image/*`

## 6. Add Supabase SDK to Xcode

1. Open Xcode project
2. File → Add Package Dependencies
3. Enter: `https://github.com/supabase/supabase-swift`
4. Add to target: LevelFitness
5. Import in files: `import Supabase`

## 7. Update SupabaseService.swift

Replace the placeholder values in `SupabaseService.swift`:

```swift
private let supabaseURL = "https://YOUR_PROJECT_ID.supabase.co"
private let supabaseAnonKey = "YOUR_ANON_KEY"
```

## 8. Test the Integration

1. Build and run the app
2. Try Sign in with Apple
3. Check Supabase dashboard → Authentication → Users
4. Verify user appears in the list

## 9. Environment Variables (Production)

For production, use environment variables or a config file:

```swift
// Config.swift (add to .gitignore)
struct Config {
    static let supabaseURL = "YOUR_URL"
    static let supabaseKey = "YOUR_KEY"
}
```

## 10. Real-time Subscriptions

Enable real-time for tables:

1. Go to Database → Replication
2. Enable replication for:
   - teams
   - team_members
   - workouts
   - challenges

## Troubleshooting

### Common Issues

1. **Sign in with Apple not working**
   - Verify Bundle ID matches
   - Check entitlements file
   - Ensure capability is enabled in Xcode

2. **Database queries failing**
   - Check RLS policies
   - Verify user is authenticated
   - Check SQL syntax in Supabase logs

3. **Real-time not updating**
   - Enable replication for table
   - Check WebSocket connection
   - Verify subscription filters

## Next Steps

1. ✅ Supabase project created
2. ✅ Database schema set up
3. ✅ Authentication configured
4. ⏳ Add Supabase SDK to Xcode
5. ⏳ Update service files with credentials
6. ⏳ Test authentication flow
7. ⏳ Implement HealthKit integration
8. ⏳ Build sync engine

## Security Checklist

- [ ] Never commit API keys to git
- [ ] Use environment variables in production
- [ ] Enable RLS on all tables
- [ ] Validate all user inputs
- [ ] Use prepared statements for queries
- [ ] Implement rate limiting
- [ ] Add request signing for sensitive operations