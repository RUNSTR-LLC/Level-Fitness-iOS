-- RunstrRewards Complete Database Schema - CORRECTED VERSION
-- Copy and paste this ENTIRE script into your Supabase SQL Editor

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================
-- CORE TABLES
-- ========================================

-- Users profile table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    full_name TEXT,
    email TEXT,
    avatar_url TEXT,
    total_workouts INTEGER DEFAULT 0,
    total_distance DECIMAL DEFAULT 0,
    total_earnings DECIMAL DEFAULT 0,
    bitcoin_address TEXT,
    lightning_wallet_id TEXT,
    subscription_tier TEXT DEFAULT 'free',
    subscription_expires_at TIMESTAMPTZ,
    is_captain BOOLEAN DEFAULT false,
    captain_subscription_expires TIMESTAMPTZ,
    captain_team_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Teams table
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    captain_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    member_count INTEGER DEFAULT 0,
    max_members INTEGER DEFAULT 50,
    total_earnings DECIMAL DEFAULT 0,
    team_wallet_id UUID,
    team_wallet_balance INTEGER DEFAULT 0,
    image_url TEXT,
    invite_code TEXT UNIQUE DEFAULT generate_random_uuid()::TEXT,
    is_public BOOLEAN DEFAULT true,
    subscription_tier TEXT DEFAULT 'free',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Team members junction table
CREATE TABLE IF NOT EXISTS team_members (
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (team_id, user_id)
);

-- Team invitations (from your updated schema)
CREATE TABLE IF NOT EXISTS team_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE NOT NULL,
    invite_code TEXT NOT NULL UNIQUE,
    created_by UUID REFERENCES profiles(id) NOT NULL,
    expires_at TIMESTAMPTZ,
    used_count INTEGER DEFAULT 0,
    max_uses INTEGER DEFAULT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workouts table
CREATE TABLE IF NOT EXISTS workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL,
    duration INTEGER NOT NULL,
    distance DECIMAL,
    calories INTEGER,
    heart_rate INTEGER,
    elevation_gain DECIMAL,
    average_speed DECIMAL,
    max_speed DECIMAL,
    source TEXT NOT NULL,
    external_id TEXT,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    raw_data JSONB,
    points_earned INTEGER DEFAULT 0,
    reward_amount INTEGER DEFAULT 0,
    verified BOOLEAN DEFAULT false,
    verification_data JSONB
);

-- Events (virtual competitions)
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    target_value DECIMAL NOT NULL,
    unit TEXT NOT NULL,
    entry_fee INTEGER DEFAULT 0,
    prize_pool INTEGER DEFAULT 0,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    max_participants INTEGER,
    participant_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'upcoming',
    image_url TEXT,
    rules JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Event participants
CREATE TABLE IF NOT EXISTS event_participants (
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    progress DECIMAL DEFAULT 0,
    position INTEGER,
    completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    entry_paid BOOLEAN DEFAULT false,
    prize_earned INTEGER DEFAULT 0,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (event_id, user_id)
);

-- Event registrations
CREATE TABLE IF NOT EXISTS event_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    registered_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    status TEXT DEFAULT 'active' NOT NULL CHECK (status IN ('active', 'cancelled', 'withdrawn')),
    UNIQUE (event_id, user_id)
);

-- Team challenges
CREATE TABLE IF NOT EXISTS challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    target_value DECIMAL NOT NULL,
    unit TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    prize_pool INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Challenge participants
CREATE TABLE IF NOT EXISTS challenge_participants (
    challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    progress DECIMAL DEFAULT 0,
    completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (challenge_id, user_id)
);

-- P2P Challenges
CREATE TABLE IF NOT EXISTS p2p_challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    challenger_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    challenged_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL,
    target_value DECIMAL,
    end_date TIMESTAMPTZ NOT NULL,
    stake_amount INTEGER NOT NULL DEFAULT 0,
    challenger_paid BOOLEAN DEFAULT false,
    challenged_paid BOOLEAN DEFAULT false,
    winner_id UUID REFERENCES profiles(id),
    challenger_result DECIMAL,
    challenged_result DECIMAL,
    payout_completed BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),
    challenge_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Lightning wallets (supports both user and team wallets)
CREATE TABLE IF NOT EXISTS lightning_wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    wallet_type TEXT NOT NULL DEFAULT 'user',
    provider TEXT NOT NULL DEFAULT 'coinos',
    wallet_id TEXT NOT NULL,
    address TEXT NOT NULL,
    balance INTEGER DEFAULT 0,
    credentials_encrypted TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT lightning_wallets_owner_check CHECK (
        (user_id IS NOT NULL AND team_id IS NULL AND wallet_type = 'user') OR 
        (user_id IS NULL AND team_id IS NOT NULL AND wallet_type = 'team')
    ),
    
    CONSTRAINT lightning_wallets_user_unique UNIQUE (user_id) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT lightning_wallets_team_unique UNIQUE (team_id) DEFERRABLE INITIALLY DEFERRED
);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES lightning_wallets(id) ON DELETE SET NULL,
    from_wallet_id UUID REFERENCES lightning_wallets(id) ON DELETE SET NULL,
    to_wallet_id UUID REFERENCES lightning_wallets(id) ON DELETE SET NULL,
    type TEXT NOT NULL,
    amount INTEGER NOT NULL,
    usd_amount DECIMAL,
    description TEXT,
    status TEXT DEFAULT 'pending',
    transaction_hash TEXT,
    preimage TEXT,
    invoice_data JSONB,
    metadata JSONB,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prize distributions table
CREATE TABLE IF NOT EXISTS prize_distributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE NOT NULL,
    event_id UUID REFERENCES events(id) ON DELETE SET NULL,
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    total_prize INTEGER NOT NULL,
    distribution_method TEXT NOT NULL,
    status TEXT DEFAULT 'draft',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    executed_at TIMESTAMPTZ
);

-- Prize distribution recipients
CREATE TABLE IF NOT EXISTS prize_recipients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    distribution_id UUID REFERENCES prize_distributions(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    allocation INTEGER NOT NULL,
    percentage DECIMAL NOT NULL,
    reason TEXT,
    performance_data JSONB,
    payout_status TEXT DEFAULT 'pending',
    payout_date TIMESTAMPTZ,
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Team chat messages
CREATE TABLE IF NOT EXISTS team_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    message_type TEXT DEFAULT 'text',
    metadata JSONB,
    edited BOOLEAN DEFAULT false,
    edited_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User streaks and achievements
CREATE TABLE IF NOT EXISTS user_streaks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    streak_type TEXT NOT NULL,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_activity_date DATE,
    target_value DECIMAL,
    unit TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, streak_type)
);

-- Team subscriptions
CREATE TABLE IF NOT EXISTS team_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE NOT NULL,
    product_id TEXT NOT NULL,
    transaction_id TEXT UNIQUE NOT NULL,
    original_transaction_id TEXT,
    purchase_date TIMESTAMPTZ NOT NULL,
    expiration_date TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'active',
    auto_renewing BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, team_id)
);

-- Notification tokens
CREATE TABLE IF NOT EXISTS notification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    device_token TEXT NOT NULL,
    platform TEXT NOT NULL,
    app_version TEXT,
    device_model TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, device_token)
);

-- Notification inbox
CREATE TABLE IF NOT EXISTS notification_inbox (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    action_type VARCHAR(50),
    action_data JSONB,
    from_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    read BOOLEAN DEFAULT false,
    acted_on BOOLEAN DEFAULT false,
    action_taken VARCHAR(50),
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    acted_at TIMESTAMPTZ
);

-- Workout sync queue
CREATE TABLE IF NOT EXISTS workout_sync_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    workout_data JSONB NOT NULL,
    priority INTEGER DEFAULT 100,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 5,
    status TEXT DEFAULT 'pending',
    last_attempt TIMESTAMPTZ,
    error_message TEXT,
    queued_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Team Leagues
CREATE TABLE IF NOT EXISTS team_leagues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'monthly_distance',
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    payout_percentages INTEGER[] NOT NULL DEFAULT '{100}',
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Add foreign key constraints after all tables exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'profiles_captain_team_id_fkey') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_captain_team_id_fkey 
            FOREIGN KEY (captain_team_id) REFERENCES teams(id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'teams_team_wallet_fk') THEN
        ALTER TABLE teams ADD CONSTRAINT teams_team_wallet_fk 
            FOREIGN KEY (team_wallet_id) REFERENCES lightning_wallets(id) ON DELETE SET NULL;
    END IF;
END $$;

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================

CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_subscription_tier ON profiles(subscription_tier);

CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_workouts_started_at ON workouts(started_at);
CREATE INDEX IF NOT EXISTS idx_workouts_type ON workouts(type);
CREATE INDEX IF NOT EXISTS idx_workouts_source ON workouts(source);
CREATE INDEX IF NOT EXISTS idx_workouts_verified ON workouts(verified);

CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON team_members(team_id);

CREATE INDEX IF NOT EXISTS idx_team_invitations_team_id ON team_invitations(team_id);
CREATE INDEX IF NOT EXISTS idx_team_invitations_code ON team_invitations(invite_code);
CREATE INDEX IF NOT EXISTS idx_team_invitations_active ON team_invitations(is_active);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_team_id ON transactions(team_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);

CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_events_end_date ON events(end_date);

CREATE INDEX IF NOT EXISTS idx_lightning_wallets_user_id ON lightning_wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_lightning_wallets_team_id ON lightning_wallets(team_id);
CREATE INDEX IF NOT EXISTS idx_lightning_wallets_wallet_type ON lightning_wallets(wallet_type);

CREATE INDEX IF NOT EXISTS idx_team_messages_team_id ON team_messages(team_id);
CREATE INDEX IF NOT EXISTS idx_team_messages_created_at ON team_messages(created_at);

CREATE INDEX IF NOT EXISTS idx_team_subscriptions_user_id ON team_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_team_subscriptions_team_id ON team_subscriptions(team_id);
CREATE INDEX IF NOT EXISTS idx_team_subscriptions_status ON team_subscriptions(status);

CREATE INDEX IF NOT EXISTS idx_prize_distributions_team_id ON prize_distributions(team_id);
CREATE INDEX IF NOT EXISTS idx_prize_distributions_status ON prize_distributions(status);
CREATE INDEX IF NOT EXISTS idx_prize_recipients_distribution_id ON prize_recipients(distribution_id);
CREATE INDEX IF NOT EXISTS idx_prize_recipients_user_id ON prize_recipients(user_id);

CREATE INDEX IF NOT EXISTS idx_notification_tokens_user_id ON notification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_tokens_device_token ON notification_tokens(device_token);

CREATE INDEX IF NOT EXISTS idx_notification_inbox_user_id ON notification_inbox(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_inbox_unread ON notification_inbox(user_id, read, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_workout_sync_queue_user_id ON workout_sync_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sync_queue_status ON workout_sync_queue(status);

CREATE INDEX IF NOT EXISTS idx_team_leagues_team_id ON team_leagues(team_id);
CREATE INDEX IF NOT EXISTS idx_team_leagues_status ON team_leagues(status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_team_active_league 
ON team_leagues(team_id) 
WHERE status = 'active';

-- ========================================
-- VIEWS FOR LEADERBOARDS
-- ========================================

CREATE OR REPLACE VIEW weekly_leaderboard AS
SELECT 
    p.id as user_id,
    p.username,
    p.full_name,
    p.avatar_url,
    COUNT(w.id) as workout_count,
    SUM(w.duration) as total_duration,
    SUM(COALESCE(w.distance, 0)) as total_distance,
    SUM(w.calories) as total_calories,
    SUM(w.points_earned) as total_points,
    SUM(w.reward_amount) as total_rewards,
    RANK() OVER (ORDER BY SUM(w.points_earned) DESC) as rank
FROM profiles p
LEFT JOIN workouts w ON p.id = w.user_id 
    AND w.started_at >= NOW() - INTERVAL '7 days'
    AND w.verified = true
GROUP BY p.id, p.username, p.full_name, p.avatar_url
ORDER BY total_points DESC;

CREATE OR REPLACE VIEW team_leaderboard AS
SELECT 
    t.id as team_id,
    t.name as team_name,
    t.member_count,
    COUNT(w.id) as total_workouts,
    SUM(w.duration) as total_duration,
    SUM(COALESCE(w.distance, 0)) as total_distance,
    SUM(w.points_earned) as total_points,
    SUM(w.reward_amount) as total_rewards,
    RANK() OVER (ORDER BY SUM(w.points_earned) DESC) as rank
FROM teams t
LEFT JOIN team_members tm ON t.id = tm.team_id
LEFT JOIN workouts w ON tm.user_id = w.user_id 
    AND w.started_at >= NOW() - INTERVAL '7 days'
    AND w.verified = true
GROUP BY t.id, t.name, t.member_count
ORDER BY total_points DESC;

-- ========================================
-- ROW LEVEL SECURITY SETUP
-- ========================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE p2p_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE lightning_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prize_distributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prize_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_inbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sync_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_leagues ENABLE ROW LEVEL SECURITY;

-- ========================================
-- BASIC POLICIES (ESSENTIAL ONLY)
-- ========================================

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Teams policies
DROP POLICY IF EXISTS "Public teams are viewable by everyone" ON teams;
DROP POLICY IF EXISTS "Captains can update their teams" ON teams;
DROP POLICY IF EXISTS "Authenticated users can create teams" ON teams;

CREATE POLICY "Public teams are viewable by everyone" ON teams
    FOR SELECT USING (is_public = true OR EXISTS (
        SELECT 1 FROM team_members WHERE team_id = teams.id AND user_id = auth.uid()
    ));

CREATE POLICY "Captains can update their teams" ON teams
    FOR UPDATE USING (auth.uid() = captain_id);

CREATE POLICY "Authenticated users can create teams" ON teams
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = captain_id);

-- Team invitations policies
DROP POLICY IF EXISTS "Anyone can view active team invitations" ON team_invitations;
DROP POLICY IF EXISTS "Team captains can create invitations" ON team_invitations;
DROP POLICY IF EXISTS "Team captains can update team invitations" ON team_invitations;

CREATE POLICY "Anyone can view active team invitations" ON team_invitations
    FOR SELECT USING (is_active = true);

CREATE POLICY "Team captains can create invitations" ON team_invitations
    FOR INSERT WITH CHECK (
        auth.uid() = created_by AND
        EXISTS (SELECT 1 FROM teams WHERE id = team_invitations.team_id AND captain_id = auth.uid())
    );

CREATE POLICY "Team captains can update team invitations" ON team_invitations
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM teams WHERE id = team_invitations.team_id AND captain_id = auth.uid())
    );

-- Workouts policies
DROP POLICY IF EXISTS "Users can view own workouts" ON workouts;
DROP POLICY IF EXISTS "Users can insert own workouts" ON workouts;

CREATE POLICY "Users can view own workouts" ON workouts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workouts" ON workouts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Lightning wallets policies
DROP POLICY IF EXISTS "Users can manage own wallet" ON lightning_wallets;
DROP POLICY IF EXISTS "Team captains can manage team wallets" ON lightning_wallets;

CREATE POLICY "Users can manage own wallet" ON lightning_wallets
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Team captains can manage team wallets" ON lightning_wallets
    FOR ALL USING (
        wallet_type = 'team' AND EXISTS (
            SELECT 1 FROM teams WHERE id = lightning_wallets.team_id AND captain_id = auth.uid()
        )
    );

-- Transactions policies
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Service role can manage transactions" ON transactions;

CREATE POLICY "Users can view own transactions" ON transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage transactions" ON transactions
    FOR ALL USING (auth.role() = 'service_role');

-- Other essential policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON notification_inbox;
CREATE POLICY "Users can view their own notifications" ON notification_inbox
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own tokens" ON notification_tokens;
CREATE POLICY "Users can manage own tokens" ON notification_tokens
    FOR ALL USING (auth.uid() = user_id);

-- ========================================
-- ESSENTIAL FUNCTIONS AND TRIGGERS
-- ========================================

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, full_name, email, avatar_url)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'full_name',
        NEW.email,
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update team member count
CREATE OR REPLACE FUNCTION update_team_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE teams SET member_count = member_count + 1 WHERE id = NEW.team_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE teams SET member_count = member_count - 1 WHERE id = OLD.team_id;
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS team_member_count_trigger ON team_members;
CREATE TRIGGER team_member_count_trigger
    AFTER INSERT OR DELETE ON team_members
    FOR EACH ROW EXECUTE FUNCTION update_team_member_count();