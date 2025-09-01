-- ========================================
-- EXIT FEE SYSTEM - PHASE 1 MIGRATION
-- ========================================
-- This migration adds the exit fee system infrastructure:
-- 1. Adds left_at timestamp to team_members
-- 2. Creates exit_fee_payments table for payment tracking  
-- 3. Creates team_switch_operations table for atomic switches
-- 4. Adds unique constraint for single active team membership
-- 5. Creates supporting indexes and functions

-- ========================================
-- STEP 1: ALTER EXISTING TABLES
-- ========================================

-- Add left_at timestamp to team_members table
ALTER TABLE team_members 
ADD COLUMN IF NOT EXISTS left_at TIMESTAMPTZ;

-- Add exit fee specific columns to track exit reasons
ALTER TABLE team_members
ADD COLUMN IF NOT EXISTS exit_fee_paid BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS exit_fee_payment_id UUID;

-- ========================================
-- STEP 2: CREATE EXIT FEE TABLES
-- ========================================

-- Exit fee payments table with comprehensive state tracking
CREATE TABLE IF NOT EXISTS exit_fee_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_intent_id TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(16), 'hex'),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    from_team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    to_team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    amount INTEGER NOT NULL DEFAULT 2000,
    lightning_address TEXT NOT NULL DEFAULT 'RUNSTR@coinos.io',
    payment_hash TEXT,
    invoice_text TEXT,
    payment_status TEXT NOT NULL DEFAULT 'initiated',
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    error_message TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours',
    
    -- Ensure valid payment status
    CONSTRAINT exit_fee_payments_status_check CHECK (
        payment_status IN (
            'initiated', 'invoice_created', 'payment_sent', 
            'payment_confirmed', 'team_change_complete', 
            'failed', 'compensated', 'expired'
        )
    ),
    
    -- Ensure amount is exactly 2000 sats for now (hardcoded)
    CONSTRAINT exit_fee_payments_amount_check CHECK (amount = 2000),
    
    -- Ensure Lightning address is RUNSTR@coinos.io
    CONSTRAINT exit_fee_payments_address_check CHECK (lightning_address = 'RUNSTR@coinos.io')
);

-- Team switch operations for atomic switching
CREATE TABLE IF NOT EXISTS team_switch_operations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    from_team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    to_team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    exit_fee_payment_id UUID REFERENCES exit_fee_payments(id) ON DELETE CASCADE,
    operation_type TEXT NOT NULL DEFAULT 'switch', -- 'switch', 'leave'
    status TEXT NOT NULL DEFAULT 'pending',
    error_message TEXT,
    rollback_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    -- Ensure valid operation status
    CONSTRAINT team_switch_operations_status_check CHECK (
        status IN ('pending', 'processing', 'completed', 'failed', 'rolled_back')
    ),
    
    -- Ensure valid operation type
    CONSTRAINT team_switch_operations_type_check CHECK (
        operation_type IN ('switch', 'leave')
    ),
    
    -- For leave operations, to_team_id should be NULL
    CONSTRAINT team_switch_operations_leave_check CHECK (
        (operation_type = 'leave' AND to_team_id IS NULL) OR 
        (operation_type = 'switch' AND to_team_id IS NOT NULL)
    )
);

-- ========================================
-- STEP 3: CREATE SINGLE TEAM CONSTRAINT
-- ========================================

-- Create unique index to enforce single active team membership per user
-- This allows historical team memberships (with left_at set) but only one active membership
CREATE UNIQUE INDEX IF NOT EXISTS unique_active_team_membership 
ON team_members(user_id) 
WHERE left_at IS NULL;

-- ========================================
-- STEP 4: CREATE SUPPORTING INDEXES
-- ========================================

-- Exit fee payments indexes
CREATE INDEX IF NOT EXISTS idx_exit_fee_payments_user_id ON exit_fee_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_exit_fee_payments_status ON exit_fee_payments(payment_status);
CREATE INDEX IF NOT EXISTS idx_exit_fee_payments_intent_id ON exit_fee_payments(payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_exit_fee_payments_payment_hash ON exit_fee_payments(payment_hash) 
    WHERE payment_hash IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_exit_fee_payments_created_at ON exit_fee_payments(created_at);
CREATE INDEX IF NOT EXISTS idx_exit_fee_payments_expires_at ON exit_fee_payments(expires_at);

-- Team switch operations indexes
CREATE INDEX IF NOT EXISTS idx_team_switch_operations_user_id ON team_switch_operations(user_id);
CREATE INDEX IF NOT EXISTS idx_team_switch_operations_status ON team_switch_operations(status);
CREATE INDEX IF NOT EXISTS idx_team_switch_operations_payment_id ON team_switch_operations(exit_fee_payment_id);
CREATE INDEX IF NOT EXISTS idx_team_switch_operations_created_at ON team_switch_operations(created_at);

-- Enhanced team_members indexes
CREATE INDEX IF NOT EXISTS idx_team_members_left_at ON team_members(left_at);
CREATE INDEX IF NOT EXISTS idx_team_members_active ON team_members(user_id, team_id) 
    WHERE left_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_team_members_exit_fee_payment ON team_members(exit_fee_payment_id) 
    WHERE exit_fee_payment_id IS NOT NULL;

-- ========================================
-- STEP 5: ROW LEVEL SECURITY POLICIES
-- ========================================

-- Enable RLS on new tables
ALTER TABLE exit_fee_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_switch_operations ENABLE ROW LEVEL SECURITY;

-- Exit fee payments policies
CREATE POLICY "Users can view own exit fee payments" ON exit_fee_payments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own exit fee payments" ON exit_fee_payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role can manage exit fee payments" ON exit_fee_payments
    FOR ALL USING (auth.role() = 'service_role');

-- Team switch operations policies  
CREATE POLICY "Users can view own team switch operations" ON team_switch_operations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage team switch operations" ON team_switch_operations
    FOR ALL USING (auth.role() = 'service_role');

-- ========================================
-- STEP 6: HELPER FUNCTIONS
-- ========================================

-- Function to get user's active team (if any)
CREATE OR REPLACE FUNCTION get_user_active_team(p_user_id UUID)
RETURNS TABLE(team_id UUID, team_name TEXT, role TEXT, joined_at TIMESTAMPTZ) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tm.team_id,
        t.name as team_name,
        tm.role,
        tm.joined_at
    FROM team_members tm
    INNER JOIN teams t ON tm.team_id = t.id
    WHERE tm.user_id = p_user_id 
      AND tm.left_at IS NULL
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can join a team (not already on one)
CREATE OR REPLACE FUNCTION can_user_join_team(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    active_team_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO active_team_count
    FROM team_members
    WHERE user_id = p_user_id 
      AND left_at IS NULL;
      
    RETURN active_team_count = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate exit fee payment before team changes
CREATE OR REPLACE FUNCTION validate_exit_fee_payment(p_payment_intent_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    payment_record exit_fee_payments%ROWTYPE;
BEGIN
    SELECT * INTO payment_record
    FROM exit_fee_payments
    WHERE payment_intent_id = p_payment_intent_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Payment must be confirmed to allow team changes
    RETURN payment_record.payment_status = 'payment_confirmed';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to expire old payment intents
CREATE OR REPLACE FUNCTION expire_old_exit_fee_payments()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE exit_fee_payments 
    SET payment_status = 'expired',
        updated_at = NOW()
    WHERE payment_status IN ('initiated', 'invoice_created', 'payment_sent')
      AND expires_at < NOW();
      
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 7: ENHANCED TRIGGERS
-- ========================================

-- Update team_members trigger to handle exit fee tracking
CREATE OR REPLACE FUNCTION enhanced_update_team_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- User joining team
        UPDATE teams SET member_count = member_count + 1 WHERE id = NEW.team_id;
        
        -- Log team join activity
        INSERT INTO transactions (
            user_id, team_id, type, amount, description, status, created_at
        ) VALUES (
            NEW.user_id, NEW.team_id, 'team_join', 0, 
            'User joined team', 'completed', NOW()
        );
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' AND OLD.left_at IS NULL AND NEW.left_at IS NOT NULL THEN
        -- User leaving team (left_at changed from NULL to timestamp)
        UPDATE teams SET member_count = member_count - 1 WHERE id = OLD.team_id;
        
        -- Log team exit activity with exit fee reference
        INSERT INTO transactions (
            user_id, team_id, type, amount, description, status, 
            metadata, created_at
        ) VALUES (
            OLD.user_id, OLD.team_id, 'team_exit', 
            CASE WHEN NEW.exit_fee_paid THEN 2000 ELSE 0 END,
            'User left team' || CASE WHEN NEW.exit_fee_paid THEN ' (exit fee paid)' ELSE '' END,
            'completed',
            jsonb_build_object(
                'exit_fee_paid', NEW.exit_fee_paid,
                'exit_fee_payment_id', NEW.exit_fee_payment_id
            ),
            NOW()
        );
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Hard delete (should be rare, prefer soft delete with left_at)
        UPDATE teams SET member_count = member_count - 1 WHERE id = OLD.team_id;
        RETURN OLD;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Replace existing team member count trigger
DROP TRIGGER IF EXISTS team_member_count_trigger ON team_members;
CREATE TRIGGER enhanced_team_member_count_trigger
    AFTER INSERT OR UPDATE OR DELETE ON team_members
    FOR EACH ROW EXECUTE FUNCTION enhanced_update_team_member_count();

-- Update timestamps trigger for new tables
DROP TRIGGER IF EXISTS update_exit_fee_payments_updated_at ON exit_fee_payments;
CREATE TRIGGER update_exit_fee_payments_updated_at
    BEFORE UPDATE ON exit_fee_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_team_switch_operations_updated_at ON team_switch_operations;
CREATE TRIGGER update_team_switch_operations_updated_at
    BEFORE UPDATE ON team_switch_operations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- STEP 8: VALIDATION VIEWS
-- ========================================

-- View to check single team membership constraint
CREATE OR REPLACE VIEW team_membership_violations AS
SELECT 
    user_id,
    COUNT(*) as active_team_count,
    array_agg(team_id) as team_ids
FROM team_members 
WHERE left_at IS NULL
GROUP BY user_id
HAVING COUNT(*) > 1;

-- View for exit fee payment analytics
CREATE OR REPLACE VIEW exit_fee_analytics AS
SELECT 
    DATE_TRUNC('day', created_at) as payment_date,
    payment_status,
    COUNT(*) as payment_count,
    SUM(amount) as total_amount,
    AVG(retry_count) as avg_retries,
    COUNT(CASE WHEN payment_status = 'team_change_complete' THEN 1 END) as successful_exits
FROM exit_fee_payments
GROUP BY DATE_TRUNC('day', created_at), payment_status
ORDER BY payment_date DESC, payment_status;

-- View for team switching patterns
CREATE OR REPLACE VIEW team_switching_analytics AS
SELECT 
    DATE_TRUNC('week', created_at) as week,
    operation_type,
    status,
    COUNT(*) as operation_count,
    COUNT(DISTINCT user_id) as unique_users,
    AVG(EXTRACT(EPOCH FROM (completed_at - created_at))/60) as avg_completion_time_minutes
FROM team_switch_operations
GROUP BY DATE_TRUNC('week', created_at), operation_type, status
ORDER BY week DESC, operation_type, status;

-- ========================================
-- STEP 9: VALIDATION QUERIES
-- ========================================

-- Test single team membership constraint
DO $$
DECLARE
    violation_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO violation_count FROM team_membership_violations;
    
    IF violation_count > 0 THEN
        RAISE NOTICE 'WARNING: Found % users with multiple active team memberships', violation_count;
        RAISE NOTICE 'These will need to be resolved before enforcing exit fees';
    ELSE
        RAISE NOTICE 'SUCCESS: All users have at most one active team membership';
    END IF;
END;
$$;

-- ========================================
-- STEP 10: CLEANUP SCHEDULE
-- ========================================

-- Function to be called periodically to clean up expired payments
CREATE OR REPLACE FUNCTION cleanup_exit_fee_system()
RETURNS TEXT AS $$
DECLARE
    expired_payments INTEGER;
    old_operations INTEGER;
    result TEXT;
BEGIN
    -- Expire old payment intents
    expired_payments := expire_old_exit_fee_payments();
    
    -- Clean up old failed operations (older than 7 days)
    UPDATE team_switch_operations 
    SET status = 'failed'
    WHERE status = 'pending' 
      AND created_at < NOW() - INTERVAL '7 days';
    
    GET DIAGNOSTICS old_operations = ROW_COUNT;
    
    result := format('Cleaned up %s expired payments and %s old operations', 
                    expired_payments, old_operations);
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- MIGRATION COMPLETE
-- ========================================

-- Log successful migration
INSERT INTO transactions (
    type, amount, description, status, metadata, created_at
) VALUES (
    'system_migration', 0, 'Exit fee system database migration completed',
    'completed', 
    jsonb_build_object(
        'migration_version', '001',
        'migration_name', 'exit_fee_system',
        'tables_created', ARRAY['exit_fee_payments', 'team_switch_operations'],
        'constraints_added', ARRAY['unique_active_team_membership'],
        'functions_created', ARRAY['get_user_active_team', 'can_user_join_team', 'validate_exit_fee_payment']
    ),
    NOW()
);

-- Final success message
DO $$
BEGIN
    RAISE NOTICE '✅ EXIT FEE SYSTEM MIGRATION COMPLETED SUCCESSFULLY';
    RAISE NOTICE '📊 Tables created: exit_fee_payments, team_switch_operations';
    RAISE NOTICE '🔒 Constraint added: unique_active_team_membership';
    RAISE NOTICE '⚡ Functions created: 4 helper functions';
    RAISE NOTICE '🔍 Views created: 3 analytics views';
    RAISE NOTICE '🛡️ RLS policies: 4 security policies';
    RAISE NOTICE '📈 Indexes created: 12 performance indexes';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Run validation queries to check data integrity';
    RAISE NOTICE '2. Test exit fee payment flow';
    RAISE NOTICE '3. Implement ExitFeeManager service';
END;
$$;