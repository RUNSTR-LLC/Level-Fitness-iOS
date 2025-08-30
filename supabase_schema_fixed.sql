-- Level Fitness Production Database Schema - FIXED VERSION
-- Run this in your Supabase SQL Editor

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
    bitcoin_address TEXT, -- CoinOS wallet address
    lightning_wallet_id TEXT, -- CoinOS wallet ID
    subscription_tier TEXT DEFAULT 'free', -- 'free', 'member', 'captain'
    subscription_expires_at TIMESTAMPTZ,
    is_captain BOOLEAN DEFAULT false,
    captain_subscription_expires TIMESTAMPTZ,
    captain_team_id UUID, -- Will add constraint after teams table exists
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
    team_wallet_id UUID, -- Will add constraint after lightning_wallets table exists
    team_wallet_balance INTEGER DEFAULT 0, -- Cached team wallet balance in satoshis
    image_url TEXT,
    invite_code TEXT UNIQUE DEFAULT generate_random_uuid()::TEXT,
    is_public BOOLEAN DEFAULT true,
    subscription_tier TEXT DEFAULT 'free', -- 'free', 'premium'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add the foreign key constraint for profiles.captain_team_id now that teams exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'profiles_captain_team_id_fkey') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_captain_team_id_fkey 
            FOREIGN KEY (captain_team_id) REFERENCES teams(id);
    END IF;
END $$;

-- Team members junction table
CREATE TABLE IF NOT EXISTS team_members (
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member', -- 'member', 'captain', 'moderator'
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (team_id, user_id)
);

-- Workouts table
CREATE TABLE IF NOT EXISTS workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL, -- 'running', 'cycling', 'swimming', etc.
    duration INTEGER NOT NULL, -- seconds
    distance DECIMAL, -- meters
    calories INTEGER,
    heart_rate INTEGER,
    elevation_gain DECIMAL, -- meters
    average_speed DECIMAL, -- m/s
    max_speed DECIMAL, -- m/s
    source TEXT NOT NULL, -- 'healthkit', 'strava', 'garmin', etc.
    external_id TEXT, -- ID from external source
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    raw_data JSONB, -- Original data from source
    points_earned INTEGER DEFAULT 0,
    reward_amount INTEGER DEFAULT 0, -- satoshis
    verified BOOLEAN DEFAULT false,
    verification_data JSONB -- Anti-cheat verification
);

-- ========================================
-- COMPETITIONS & CHALLENGES
-- ========================================

-- Events (virtual competitions)
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL, -- 'marathon', 'speed_challenge', 'elevation_goal', etc.
    target_value DECIMAL NOT NULL, -- target distance, time, etc.
    unit TEXT NOT NULL, -- 'meters', 'seconds', 'calories'
    entry_fee INTEGER DEFAULT 0, -- satoshis
    prize_pool INTEGER DEFAULT 0, -- satoshis
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    max_participants INTEGER,
    participant_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'upcoming', -- 'upcoming', 'active', 'completed', 'cancelled'
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
    prize_earned INTEGER DEFAULT 0, -- satoshis
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (event_id, user_id)
);

-- Event registrations (separate from participants for registration tracking)
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
    type TEXT NOT NULL, -- 'distance', 'duration', 'frequency', 'streak'
    target_value DECIMAL NOT NULL,
    unit TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    prize_pool INTEGER DEFAULT 0, -- satoshis
    status TEXT DEFAULT 'active', -- 'active', 'completed', 'cancelled'
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

-- P2P Challenges (user-to-user direct challenges)
CREATE TABLE IF NOT EXISTS p2p_challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    challenger_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    challenged_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL, -- '5k_race', 'weekly_miles', 'daily_run'
    target_value DECIMAL, -- 5 (for 5K), 50 (for 50 miles)
    end_date TIMESTAMPTZ NOT NULL,
    stake_amount INTEGER NOT NULL DEFAULT 0, -- satoshis per person
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

-- ========================================
-- BITCOIN & TRANSACTIONS
-- ========================================

-- Lightning wallets (supports both user and team wallets)
CREATE TABLE IF NOT EXISTS lightning_wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE, -- NULL for team wallets
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE, -- NULL for user wallets
    wallet_type TEXT NOT NULL DEFAULT 'user', -- 'user', 'team'
    provider TEXT NOT NULL DEFAULT 'coinos', -- 'coinos', 'lnbits', 'strike'
    wallet_id TEXT NOT NULL, -- Provider's wallet ID
    address TEXT NOT NULL, -- Lightning address or username
    balance INTEGER DEFAULT 0, -- satoshis
    credentials_encrypted TEXT, -- Encrypted provider credentials
    status TEXT DEFAULT 'active', -- 'active', 'inactive', 'error'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints to ensure exactly one of user_id or team_id is set
    CONSTRAINT lightning_wallets_owner_check CHECK (
        (user_id IS NOT NULL AND team_id IS NULL AND wallet_type = 'user') OR 
        (user_id IS NULL AND team_id IS NOT NULL AND wallet_type = 'team')
    ),
    
    -- Unique constraints
    CONSTRAINT lightning_wallets_user_unique UNIQUE (user_id) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT lightning_wallets_team_unique UNIQUE (team_id) DEFERRABLE INITIALLY DEFERRED
);

-- Now add the team_wallet_id constraint to teams table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'teams_team_wallet_fk') THEN
        ALTER TABLE teams ADD CONSTRAINT teams_team_wallet_fk 
            FOREIGN KEY (team_wallet_id) REFERENCES lightning_wallets(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Transactions table (for Bitcoin rewards and payments)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE, -- NULL for team wallet transactions
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE, -- NULL for user transactions
    wallet_id UUID REFERENCES lightning_wallets(id) ON DELETE SET NULL,
    from_wallet_id UUID REFERENCES lightning_wallets(id) ON DELETE SET NULL, -- Source wallet for transfers
    to_wallet_id UUID REFERENCES lightning_wallets(id) ON DELETE SET NULL, -- Destination wallet for transfers
    type TEXT NOT NULL, -- 'workout_reward', 'team_reward', 'team_funding', 'competition_prize', 'team_transfer', 'welcome_bonus', 'withdrawal', 'payment'
    amount INTEGER NOT NULL, -- satoshis
    usd_amount DECIMAL, -- USD equivalent at time of transaction
    description TEXT,
    status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'cancelled'
    transaction_hash TEXT, -- Lightning payment hash
    preimage TEXT, -- Lightning preimage (proof of payment)
    invoice_data JSONB, -- Full invoice/payment data
    metadata JSONB, -- Additional transaction data (team_id, competition_id, etc.)
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prize distributions table (for team reward distributions)
CREATE TABLE IF NOT EXISTS prize_distributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE NOT NULL,
    event_id UUID REFERENCES events(id) ON DELETE SET NULL,
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL, -- Captain who created the distribution
    total_prize INTEGER NOT NULL, -- Total amount in satoshis
    distribution_method TEXT NOT NULL, -- 'equal', 'performance', 'custom', 'hybrid', 'top_performers'
    status TEXT DEFAULT 'draft', -- 'draft', 'pending', 'approved', 'executing', 'completed', 'failed', 'cancelled'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    executed_at TIMESTAMPTZ
);

-- Prize distribution recipients (individual allocations)
CREATE TABLE IF NOT EXISTS prize_recipients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    distribution_id UUID REFERENCES prize_distributions(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    allocation INTEGER NOT NULL, -- Amount in satoshis
    percentage DECIMAL NOT NULL, -- Percentage of total prize
    reason TEXT, -- Reason for this allocation amount
    performance_data JSONB, -- Performance metrics that justified the allocation
    payout_status TEXT DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    payout_date TIMESTAMPTZ,
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- SOCIAL & MESSAGING
-- ========================================

-- Team chat messages
CREATE TABLE IF NOT EXISTS team_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    message_type TEXT DEFAULT 'text', -- 'text', 'workout', 'achievement', 'system'
    metadata JSONB, -- Additional message data (workout info, etc.)
    edited BOOLEAN DEFAULT false,
    edited_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User streaks and achievements
CREATE TABLE IF NOT EXISTS user_streaks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    streak_type TEXT NOT NULL, -- 'daily_workout', 'weekly_goal', 'monthly_distance'
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

-- Team subscriptions junction table
CREATE TABLE IF NOT EXISTS team_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE NOT NULL,
    product_id TEXT NOT NULL, -- com.runstrrewards.team.monthly
    transaction_id TEXT UNIQUE NOT NULL,
    original_transaction_id TEXT,
    purchase_date TIMESTAMPTZ NOT NULL,
    expiration_date TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'active', -- 'active', 'cancelled', 'expired', 'pending'
    auto_renewing BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, team_id)
);

-- Notification tokens for push notifications
CREATE TABLE IF NOT EXISTS notification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    device_token TEXT NOT NULL,
    platform TEXT NOT NULL, -- 'ios', 'android', 'web'
    app_version TEXT,
    device_model TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, device_token)
);

-- Notification inbox for persistent notification storage
CREATE TABLE IF NOT EXISTS notification_inbox (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'challenge_request', 'event_invite', 'result_announcement', etc.
    title TEXT NOT NULL,
    body TEXT,
    action_type VARCHAR(50), -- 'accept_challenge', 'join_event', 'view_details'
    action_data JSONB, -- Flexible data for different action types
    from_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    read BOOLEAN DEFAULT false,
    acted_on BOOLEAN DEFAULT false, -- Did user take action (accept/decline/join)
    action_taken VARCHAR(50), -- 'accepted', 'declined', 'joined', etc.
    expires_at TIMESTAMPTZ, -- For time-sensitive notifications
    created_at TIMESTAMPTZ DEFAULT NOW(),
    acted_at TIMESTAMPTZ
);

-- Workout sync queue (for offline support)
CREATE TABLE IF NOT EXISTS workout_sync_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    workout_data JSONB NOT NULL, -- Full workout object
    priority INTEGER DEFAULT 100,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 5,
    status TEXT DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    last_attempt TIMESTAMPTZ,
    error_message TEXT,
    queued_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Team Leagues (one monthly league per team)
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

-- Add challenge-specific fields to events table
ALTER TABLE events ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES teams(id);
ALTER TABLE events ADD COLUMN IF NOT EXISTS event_subtype VARCHAR(20) DEFAULT 'standard';
ALTER TABLE events ADD COLUMN IF NOT EXISTS is_challenge BOOLEAN DEFAULT false;
ALTER TABLE events ADD COLUMN IF NOT EXISTS challenger_id UUID REFERENCES profiles(id);
ALTER TABLE events ADD COLUMN IF NOT EXISTS challenged_user_ids UUID[];
ALTER TABLE events ADD COLUMN IF NOT EXISTS challenge_status VARCHAR(20) DEFAULT 'pending';
ALTER TABLE events ADD COLUMN IF NOT EXISTS team_arbitration_fee INTEGER DEFAULT 10;
ALTER TABLE events ADD COLUMN IF NOT EXISTS challenge_message TEXT;

-- Extended event participants table with progress tracking
ALTER TABLE event_participants 
ADD COLUMN IF NOT EXISTS progress_history JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS last_progress_update TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS qualification_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'qualified', 'in_progress', 'not_qualified'
ADD COLUMN IF NOT EXISTS auto_entered BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS criteria_matched JSONB DEFAULT '[]'; -- Which criteria rules were matched

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================

-- Core indexes
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_subscription_tier ON profiles(subscription_tier);

CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_workouts_started_at ON workouts(started_at);
CREATE INDEX IF NOT EXISTS idx_workouts_type ON workouts(type);
CREATE INDEX IF NOT EXISTS idx_workouts_source ON workouts(source);
CREATE INDEX IF NOT EXISTS idx_workouts_verified ON workouts(verified);

CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON team_members(team_id);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);

CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_events_end_date ON events(end_date);

CREATE INDEX IF NOT EXISTS idx_lightning_wallets_user_id ON lightning_wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_lightning_wallets_team_id ON lightning_wallets(team_id);
CREATE INDEX IF NOT EXISTS idx_team_messages_team_id ON team_messages(team_id);
CREATE INDEX IF NOT EXISTS idx_team_messages_created_at ON team_messages(created_at);

-- Team subscription indexes
CREATE INDEX IF NOT EXISTS idx_team_subscriptions_user_id ON team_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_team_subscriptions_team_id ON team_subscriptions(team_id);
CREATE INDEX IF NOT EXISTS idx_team_subscriptions_status ON team_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_team_subscriptions_transaction_id ON team_subscriptions(transaction_id);

-- Prize distribution indexes
CREATE INDEX IF NOT EXISTS idx_prize_distributions_team_id ON prize_distributions(team_id);
CREATE INDEX IF NOT EXISTS idx_prize_distributions_status ON prize_distributions(status);
CREATE INDEX IF NOT EXISTS idx_prize_distributions_created_at ON prize_distributions(created_at);
CREATE INDEX IF NOT EXISTS idx_prize_recipients_distribution_id ON prize_recipients(distribution_id);
CREATE INDEX IF NOT EXISTS idx_prize_recipients_user_id ON prize_recipients(user_id);
CREATE INDEX IF NOT EXISTS idx_prize_recipients_payout_status ON prize_recipients(payout_status);

-- Notification token indexes
CREATE INDEX IF NOT EXISTS idx_notification_tokens_user_id ON notification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_tokens_device_token ON notification_tokens(device_token);
CREATE INDEX IF NOT EXISTS idx_notification_tokens_platform ON notification_tokens(platform);
CREATE INDEX IF NOT EXISTS idx_notification_tokens_active ON notification_tokens(is_active);

-- Notification inbox indexes
CREATE INDEX IF NOT EXISTS idx_notification_inbox_user_unread ON notification_inbox(user_id, read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_inbox_user_recent ON notification_inbox(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_inbox_team ON notification_inbox(team_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_inbox_type ON notification_inbox(type);

-- Sync queue indexes
CREATE INDEX IF NOT EXISTS idx_workout_sync_queue_user_id ON workout_sync_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sync_queue_status ON workout_sync_queue(status);
CREATE INDEX IF NOT EXISTS idx_workout_sync_queue_priority ON workout_sync_queue(priority DESC);

-- Team league indexes
CREATE INDEX IF NOT EXISTS idx_team_leagues_team_id ON team_leagues(team_id);
CREATE INDEX IF NOT EXISTS idx_team_leagues_status ON team_leagues(status);
CREATE INDEX IF NOT EXISTS idx_team_leagues_dates ON team_leagues(start_date, end_date);

-- Create unique constraint: only one active league per team
CREATE UNIQUE INDEX IF NOT EXISTS idx_team_active_league 
ON team_leagues(team_id) 
WHERE status = 'active';

-- Add indexes for challenge queries
CREATE INDEX IF NOT EXISTS idx_events_team_id ON events(team_id) WHERE team_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_events_is_challenge ON events(is_challenge) WHERE is_challenge = true;
CREATE INDEX IF NOT EXISTS idx_events_challenger ON events(challenger_id) WHERE challenger_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_events_challenge_status ON events(challenge_status) WHERE is_challenge = true;

-- Team wallet specific indexes
CREATE INDEX IF NOT EXISTS idx_lightning_wallets_team_id_filtered ON lightning_wallets(team_id) WHERE team_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lightning_wallets_wallet_type ON lightning_wallets(wallet_type);
CREATE INDEX IF NOT EXISTS idx_teams_team_wallet_id ON teams(team_wallet_id) WHERE team_wallet_id IS NOT NULL;

-- Transaction indexes for team wallet operations
CREATE INDEX IF NOT EXISTS idx_transactions_team_id ON transactions(team_id) WHERE team_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_from_wallet ON transactions(from_wallet_id) WHERE from_wallet_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_to_wallet ON transactions(to_wallet_id) WHERE to_wallet_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_team_wallet_type ON transactions(type) WHERE type IN ('team_funding', 'team_reward', 'team_transfer', 'competition_prize');

-- ========================================
-- VIEWS FOR COMPLEX QUERIES
-- ========================================

-- Weekly leaderboard view
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

-- Monthly leaderboard view
CREATE OR REPLACE VIEW monthly_leaderboard AS
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
    AND w.started_at >= DATE_TRUNC('month', NOW())
    AND w.verified = true
GROUP BY p.id, p.username, p.full_name, p.avatar_url
ORDER BY total_points DESC;

-- Team leaderboard view
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

-- User statistics view  
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    p.id as user_id,
    p.username,
    p.total_workouts,
    p.total_distance,
    p.total_earnings,
    lw.balance as current_balance,
    COUNT(tm.team_id) as team_count,
    (SELECT COUNT(*) FROM user_streaks us WHERE us.user_id = p.id AND us.current_streak > 0) as active_streaks,
    COALESCE(recent.recent_workout_count, 0) as recent_workouts_7d,
    COALESCE(recent.recent_points, 0) as recent_points_7d
FROM profiles p
LEFT JOIN lightning_wallets lw ON p.id = lw.user_id
LEFT JOIN team_members tm ON p.id = tm.user_id
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) as recent_workout_count,
        SUM(points_earned) as recent_points
    FROM workouts 
    WHERE started_at >= NOW() - INTERVAL '7 days'
    GROUP BY user_id
) recent ON p.id = recent.user_id
GROUP BY p.id, p.username, p.total_workouts, p.total_distance, p.total_earnings, 
         lw.balance, recent.recent_workout_count, recent.recent_points;

-- ========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ========================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
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
-- PROFILES POLICIES
-- ========================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Anyone can view basic profile information (for leaderboards, teams, etc.)
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
    FOR SELECT USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile (handled by trigger)
CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- ========================================
-- TEAMS POLICIES
-- ========================================

DROP POLICY IF EXISTS "Public teams are viewable by everyone" ON teams;
DROP POLICY IF EXISTS "Captains can update their teams" ON teams;
DROP POLICY IF EXISTS "Authenticated users can create teams" ON teams;

-- Anyone can view public teams
CREATE POLICY "Public teams are viewable by everyone" ON teams
    FOR SELECT USING (is_public = true OR EXISTS (
        SELECT 1 FROM team_members WHERE team_id = teams.id AND user_id = auth.uid()
    ));

-- Captains can update their teams
CREATE POLICY "Captains can update their teams" ON teams
    FOR UPDATE USING (auth.uid() = captain_id);

-- Authenticated users can create teams
CREATE POLICY "Authenticated users can create teams" ON teams
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = captain_id);

-- ========================================
-- TEAM MEMBERS POLICIES
-- ========================================

DROP POLICY IF EXISTS "Team members can view teammates" ON team_members;
DROP POLICY IF EXISTS "Users can join teams" ON team_members;
DROP POLICY IF EXISTS "Users can leave teams or captains can remove members" ON team_members;

-- Team members can view other team members
CREATE POLICY "Team members can view teammates" ON team_members
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM team_members tm WHERE tm.team_id = team_members.team_id AND tm.user_id = auth.uid()
    ));

-- Users can join teams
CREATE POLICY "Users can join teams" ON team_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can leave teams (or captains can remove members)
CREATE POLICY "Users can leave teams or captains can remove members" ON team_members
    FOR DELETE USING (
        auth.uid() = user_id OR 
        EXISTS (SELECT 1 FROM teams WHERE id = team_members.team_id AND captain_id = auth.uid())
    );

-- ========================================
-- WORKOUTS POLICIES
-- ========================================

DROP POLICY IF EXISTS "Users can view own workouts" ON workouts;
DROP POLICY IF EXISTS "Users can insert own workouts" ON workouts;
DROP POLICY IF EXISTS "Team members can view teammate workouts" ON workouts;

-- Users can view their own workouts
CREATE POLICY "Users can view own workouts" ON workouts
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own workouts
CREATE POLICY "Users can insert own workouts" ON workouts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Team members can view teammate workouts (for leaderboards)
CREATE POLICY "Team members can view teammate workouts" ON workouts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm1
            JOIN team_members tm2 ON tm1.team_id = tm2.team_id
            WHERE tm1.user_id = auth.uid() AND tm2.user_id = workouts.user_id
        )
    );

-- ========================================
-- CHALLENGES POLICIES
-- ========================================

DROP POLICY IF EXISTS "Team members can view team challenges" ON challenges;
DROP POLICY IF EXISTS "Team captains can create challenges" ON challenges;

-- Team members can view team challenges
CREATE POLICY "Team members can view team challenges" ON challenges
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM team_members WHERE team_id = challenges.team_id AND user_id = auth.uid()
    ));

-- Team captains can create challenges
CREATE POLICY "Team captains can create challenges" ON challenges
    FOR INSERT WITH CHECK (EXISTS (
        SELECT 1 FROM teams WHERE id = challenges.team_id AND captain_id = auth.uid()
    ));

-- ========================================
-- P2P CHALLENGES POLICIES
-- ========================================

DROP POLICY IF EXISTS "Users can view their P2P challenges" ON p2p_challenges;
DROP POLICY IF EXISTS "Users can create P2P challenges" ON p2p_challenges;
DROP POLICY IF EXISTS "Users can update their P2P challenges" ON p2p_challenges;

-- Users can view P2P challenges they're involved in (challenger or challenged)
CREATE POLICY "Users can view their P2P challenges" ON p2p_challenges
    FOR SELECT USING (
        auth.uid() = challenger_id OR 
        auth.uid() = challenged_id
    );

-- Users can create P2P challenges (as challenger)
CREATE POLICY "Users can create P2P challenges" ON p2p_challenges
    FOR INSERT WITH CHECK (auth.uid() = challenger_id);

-- Users can update P2P challenges they're involved in
CREATE POLICY "Users can update their P2P challenges" ON p2p_challenges
    FOR UPDATE USING (
        auth.uid() = challenger_id OR 
        auth.uid() = challenged_id
    );

-- ========================================
-- EVENTS POLICIES
-- ========================================

DROP POLICY IF EXISTS "Everyone can view active events" ON events;
DROP POLICY IF EXISTS "Users can view challenges they're involved in" ON events;

-- Everyone can view active events
CREATE POLICY "Everyone can view active events" ON events
    FOR SELECT USING (status IN ('upcoming', 'active'));

-- Users can view challenges they're involved in (FIXED - no IF NOT EXISTS)
CREATE POLICY "Users can view challenges they're involved in" ON events
    FOR SELECT USING (
        NOT is_challenge OR 
        auth.uid() = challenger_id OR 
        auth.uid() = ANY(challenged_user_ids) OR
        EXISTS (SELECT 1 FROM team_members WHERE team_id = events.team_id AND user_id = auth.uid())
    );

-- ========================================
-- EVENT REGISTRATIONS POLICIES
-- ========================================

DROP POLICY IF EXISTS "Users can view own event registrations" ON event_registrations;
DROP POLICY IF EXISTS "Users can create own event registrations" ON event_registrations;
DROP POLICY IF EXISTS "Users can update own event registrations" ON event_registrations;

-- Users can view their own registrations
CREATE POLICY "Users can view own event registrations" ON event_registrations
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own registrations
CREATE POLICY "Users can create own event registrations" ON event_registrations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own registration status
CREATE POLICY "Users can update own event registrations" ON event_registrations
    FOR UPDATE USING (auth.uid() = user_id);

-- ========================================
-- LIGHTNING WALLETS POLICIES
-- ========================================

DROP POLICY IF EXISTS "Users can manage own wallet" ON lightning_wallets;
DROP POLICY IF EXISTS "Team captains can manage team wallets" ON lightning_wallets;
DROP POLICY IF EXISTS "Team members can view team wallet balance" ON lightning_wallets;

-- Users can only view and manage their own wallet
CREATE POLICY "Users can manage own wallet" ON lightning_wallets
    FOR ALL USING (auth.uid() = user_id);

-- Team captains can manage team wallets
CREATE POLICY "Team captains can manage team wallets" ON lightning_wallets
    FOR ALL USING (
        wallet_type = 'team' AND EXISTS (
            SELECT 1 FROM teams WHERE id = lightning_wallets.team_id AND captain_id = auth.uid()
        )
    );

-- Team members can view team wallet balance
CREATE POLICY "Team members can view team wallet balance" ON lightning_wallets
    FOR SELECT USING (
        wallet_type = 'team' AND EXISTS (
            SELECT 1 FROM team_members WHERE team_id = lightning_wallets.team_id AND user_id = auth.uid()
        )
    );

-- ========================================
-- TRANSACTIONS POLICIES
-- ========================================

DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Service role can manage transactions" ON transactions;
DROP POLICY IF EXISTS "Team wallet transactions viewable by team members" ON transactions;
DROP POLICY IF EXISTS "Service role can manage team wallet transactions" ON transactions;

-- Users can only view their own transactions
CREATE POLICY "Users can view own transactions" ON transactions
    FOR SELECT USING (auth.uid() = user_id);

-- System can insert transactions (via service role)
CREATE POLICY "Service role can manage transactions" ON transactions
    FOR ALL USING (auth.role() = 'service_role');

-- Team wallet transactions viewable by team members
CREATE POLICY "Team wallet transactions viewable by team members" ON transactions
    FOR SELECT USING (
        team_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM team_members WHERE team_id = transactions.team_id AND user_id = auth.uid()
        )
    );

-- Service role can manage team wallet transactions
CREATE POLICY "Service role can manage team wallet transactions" ON transactions
    FOR ALL USING (auth.role() = 'service_role' AND team_id IS NOT NULL);

-- ========================================
-- OTHER TABLE POLICIES
-- ========================================

-- Team messages policies
DROP POLICY IF EXISTS "Team members can view team messages" ON team_messages;
DROP POLICY IF EXISTS "Team members can send messages" ON team_messages;

CREATE POLICY "Team members can view team messages" ON team_messages
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM team_members WHERE team_id = team_messages.team_id AND user_id = auth.uid()
    ));

CREATE POLICY "Team members can send messages" ON team_messages
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND EXISTS (
            SELECT 1 FROM team_members WHERE team_id = team_messages.team_id AND user_id = auth.uid()
        )
    );

-- User streaks policies
DROP POLICY IF EXISTS "Users can view own streaks" ON user_streaks;
DROP POLICY IF EXISTS "Service role can manage streaks" ON user_streaks;

CREATE POLICY "Users can view own streaks" ON user_streaks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage streaks" ON user_streaks
    FOR ALL USING (auth.role() = 'service_role');

-- Team subscription policies
DROP POLICY IF EXISTS "Users can view own team subscriptions" ON team_subscriptions;
DROP POLICY IF EXISTS "Service role can manage team subscriptions" ON team_subscriptions;
DROP POLICY IF EXISTS "Users can insert own team subscriptions" ON team_subscriptions;

CREATE POLICY "Users can view own team subscriptions" ON team_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage team subscriptions" ON team_subscriptions
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Users can insert own team subscriptions" ON team_subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Notification policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON notification_inbox;
DROP POLICY IF EXISTS "Users can create their own notifications" ON notification_inbox;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notification_inbox;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON notification_inbox;

CREATE POLICY "Users can view their own notifications" ON notification_inbox
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can create their own notifications" ON notification_inbox
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update their own notifications" ON notification_inbox
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete their own notifications" ON notification_inbox
    FOR DELETE USING (auth.uid()::text = user_id::text);

-- Notification token policies
DROP POLICY IF EXISTS "Users can manage own tokens" ON notification_tokens;

CREATE POLICY "Users can manage own tokens" ON notification_tokens
    FOR ALL USING (auth.uid() = user_id);

-- Workout sync queue policies
DROP POLICY IF EXISTS "Users can manage own sync queue" ON workout_sync_queue;

CREATE POLICY "Users can manage own sync queue" ON workout_sync_queue
    FOR ALL USING (auth.uid() = user_id);

-- Team league policies
DROP POLICY IF EXISTS "Team members can view team leagues" ON team_leagues;
DROP POLICY IF EXISTS "Team captains can manage team leagues" ON team_leagues;

CREATE POLICY "Team members can view team leagues" ON team_leagues
    FOR SELECT USING (
        team_id IN (
            SELECT team_id FROM team_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Team captains can manage team leagues" ON team_leagues
    FOR ALL USING (
        team_id IN (
            SELECT id FROM teams 
            WHERE captain_id = auth.uid()
        )
    );

-- Prize distribution policies
DROP POLICY IF EXISTS "Team members can view prize distributions" ON prize_distributions;
DROP POLICY IF EXISTS "Team captains can manage prize distributions" ON prize_distributions;

CREATE POLICY "Team members can view prize distributions" ON prize_distributions
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM team_members WHERE team_id = prize_distributions.team_id AND user_id = auth.uid()
    ));

CREATE POLICY "Team captains can manage prize distributions" ON prize_distributions
    FOR ALL USING (EXISTS (
        SELECT 1 FROM teams WHERE id = prize_distributions.team_id AND captain_id = auth.uid()
    ));

-- Prize recipient policies
DROP POLICY IF EXISTS "Users can view own prize allocations" ON prize_recipients;

CREATE POLICY "Users can view own prize allocations" ON prize_recipients
    FOR SELECT USING (auth.uid() = user_id);

-- ========================================
-- FUNCTIONS AND TRIGGERS
-- ========================================

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create user profile
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

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update team member count when members join/leave
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

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS team_member_count_trigger ON team_members;

CREATE TRIGGER team_member_count_trigger
    AFTER INSERT OR DELETE ON team_members
    FOR EACH ROW EXECUTE FUNCTION update_team_member_count();

-- Update user stats after workout sync
CREATE OR REPLACE FUNCTION update_user_stats_from_workout()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE profiles 
        SET 
            total_workouts = total_workouts + 1,
            total_distance = total_distance + COALESCE(NEW.distance, 0),
            updated_at = NOW()
        WHERE id = NEW.user_id;
        
        -- Update user streaks
        INSERT INTO user_streaks (user_id, streak_type, current_streak, last_activity_date, target_value, unit)
        VALUES (NEW.user_id, 'daily_workout', 1, CURRENT_DATE, 1, 'workout')
        ON CONFLICT (user_id, streak_type) DO UPDATE SET
            current_streak = CASE 
                WHEN user_streaks.last_activity_date = CURRENT_DATE THEN user_streaks.current_streak
                WHEN user_streaks.last_activity_date = CURRENT_DATE - INTERVAL '1 day' THEN user_streaks.current_streak + 1
                ELSE 1
            END,
            longest_streak = GREATEST(user_streaks.longest_streak, 
                CASE 
                    WHEN user_streaks.last_activity_date = CURRENT_DATE THEN user_streaks.current_streak
                    WHEN user_streaks.last_activity_date = CURRENT_DATE - INTERVAL '1 day' THEN user_streaks.current_streak + 1
                    ELSE 1
                END
            ),
            last_activity_date = CURRENT_DATE,
            updated_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS workout_stats_trigger ON workouts;

CREATE TRIGGER workout_stats_trigger
    AFTER INSERT ON workouts
    FOR EACH ROW EXECUTE FUNCTION update_user_stats_from_workout();

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_lightning_wallets_updated_at ON lightning_wallets;
CREATE TRIGGER update_lightning_wallets_updated_at
    BEFORE UPDATE ON lightning_wallets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_streaks_updated_at ON user_streaks;
CREATE TRIGGER update_user_streaks_updated_at
    BEFORE UPDATE ON user_streaks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- INITIAL DATA SETUP
-- ========================================

-- Create sample public teams for testing
INSERT INTO teams (name, description, captain_id, is_public, created_at) VALUES
    ('Level Fitness Beginners', 'Welcome to Level Fitness! Perfect for getting started with your fitness journey.', NULL, true, NOW()),
    ('Daily Grinders', 'For those who work out every single day. Join us for accountability and motivation!', NULL, true, NOW()),
    ('Weekend Warriors', 'Maximize your weekend workouts. Perfect for busy professionals.', NULL, true, NOW()),
    ('Distance Runners', 'Long distance running community. Share routes, tips, and achievements.', NULL, true, NOW()),
    ('Strength Squad', 'All about lifting, bodyweight training and building strength.', NULL, true, NOW())
ON CONFLICT (name) DO NOTHING;

-- Create sample events
INSERT INTO events (name, description, type, target_value, unit, entry_fee, prize_pool, start_date, end_date, status) VALUES
    ('September Marathon Challenge', 'Complete a marathon distance (42.2km) throughout September', 'marathon', 42200, 'meters', 1000, 50000, '2024-09-01 00:00:00+00', '2024-09-30 23:59:59+00', 'upcoming'),
    ('Fall Fitness Kickoff', 'Work out 20 times in September to earn rewards', 'frequency', 20, 'workouts', 500, 25000, '2024-09-01 00:00:00+00', '2024-09-30 23:59:59+00', 'upcoming'),
    ('10K Speed Challenge', 'Complete a 10K run as fast as possible', 'speed_challenge', 10000, 'meters', 2000, 100000, '2024-10-01 00:00:00+00', '2024-10-31 23:59:59+00', 'upcoming')
ON CONFLICT (name) DO NOTHING;