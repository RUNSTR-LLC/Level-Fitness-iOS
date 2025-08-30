-- Create Only Missing Tables for RunstrRewards
-- Run this to add the remaining tables

-- ========================================
-- MISSING TABLES CREATION
-- ========================================

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

-- Lightning wallets
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
    )
);

-- Prize distributions
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

-- Prize recipients
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

-- User streaks
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

-- Team leagues
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

-- ========================================
-- ENABLE RLS ON NEW TABLES
-- ========================================

ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE p2p_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE lightning_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE prize_distributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prize_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_inbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_leagues ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sync_queue ENABLE ROW LEVEL SECURITY;

-- ========================================
-- BASIC POLICIES FOR NEW TABLES
-- ========================================

-- Lightning wallets policies
CREATE POLICY "Users can manage own wallet" ON lightning_wallets
    FOR ALL USING (auth.uid() = user_id);

-- Transactions policies (if transactions table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transactions') THEN
        EXECUTE 'CREATE POLICY "Users can view own transactions" ON transactions FOR SELECT USING (auth.uid() = user_id)';
        EXECUTE 'CREATE POLICY "Service role can manage transactions" ON transactions FOR ALL USING (auth.role() = ''service_role'')';
    END IF;
END $$;

-- Notification policies
CREATE POLICY "Users can view their own notifications" ON notification_inbox
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own tokens" ON notification_tokens
    FOR ALL USING (auth.uid() = user_id);

-- P2P Challenges policies
CREATE POLICY "Users can view their P2P challenges" ON p2p_challenges
    FOR SELECT USING (auth.uid() = challenger_id OR auth.uid() = challenged_id);

-- Team leagues policies  
CREATE POLICY "Team members can view team leagues" ON team_leagues
    FOR SELECT USING (
        team_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid())
    );

-- ========================================
-- VERIFICATION
-- ========================================

SELECT 'CREATION COMPLETE' as status, COUNT(*) as new_tables_created
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'event_registrations', 'challenges', 'challenge_participants', 'p2p_challenges',
    'lightning_wallets', 'prize_distributions', 'prize_recipients', 'team_subscriptions',
    'user_streaks', 'notification_inbox', 'team_leagues', 'notification_tokens', 'workout_sync_queue'
);