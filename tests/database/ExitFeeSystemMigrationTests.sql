-- ========================================
-- EXIT FEE SYSTEM MIGRATION TESTS
-- ========================================
-- These tests validate the exit fee system database migration
-- Run these after applying 001_exit_fee_system.sql

-- ========================================
-- TEST SETUP
-- ========================================

-- Create test function to track results
CREATE OR REPLACE FUNCTION run_exit_fee_migration_tests()
RETURNS TABLE(
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    test_count INTEGER := 0;
    pass_count INTEGER := 0;
    fail_count INTEGER := 0;
    temp_user_id UUID;
    temp_team_id_1 UUID;
    temp_team_id_2 UUID;
    temp_payment_id UUID;
    temp_switch_id UUID;
    active_team_count INTEGER;
    payment_record exit_fee_payments%ROWTYPE;
BEGIN
    -- Initialize test tracking
    RAISE NOTICE '🧪 STARTING EXIT FEE SYSTEM MIGRATION TESTS';
    RAISE NOTICE '================================================';
    
    -- ========================================
    -- TEST 1: Table Creation
    -- ========================================
    test_count := test_count + 1;
    
    BEGIN
        -- Check if tables exist with expected columns
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'exit_fee_payments'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'team_switch_operations' 
        ) AND EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'team_members' AND column_name = 'left_at'
        ) THEN
            pass_count := pass_count + 1;
            RETURN QUERY SELECT 
                'Table Creation'::TEXT,
                'PASS'::TEXT,
                'All required tables and columns created successfully'::TEXT;
        ELSE
            fail_count := fail_count + 1;
            RETURN QUERY SELECT 
                'Table Creation'::TEXT,
                'FAIL'::TEXT,
                'Missing required tables or columns'::TEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        fail_count := fail_count + 1;
        RETURN QUERY SELECT 
            'Table Creation'::TEXT,
            'FAIL'::TEXT,
            format('Error: %s', SQLERRM)::TEXT;
    END;
    
    -- ========================================
    -- TEST 2: Index Creation
    -- ========================================
    test_count := test_count + 1;
    
    BEGIN
        -- Check critical indexes exist
        IF EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'unique_active_team_membership'
        ) AND EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'idx_exit_fee_payments_user_id'
        ) THEN
            pass_count := pass_count + 1;
            RETURN QUERY SELECT 
                'Index Creation'::TEXT,
                'PASS'::TEXT,
                'Critical indexes created successfully'::TEXT;
        ELSE
            fail_count := fail_count + 1;
            RETURN QUERY SELECT 
                'Index Creation'::TEXT,
                'FAIL'::TEXT,
                'Missing critical indexes'::TEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        fail_count := fail_count + 1;
        RETURN QUERY SELECT 
            'Index Creation'::TEXT,
            'FAIL'::TEXT,
            format('Error: %s', SQLERRM)::TEXT;
    END;
    
    -- ========================================
    -- TEST 3: Helper Functions
    -- ========================================
    test_count := test_count + 1;
    
    BEGIN
        -- Test helper functions exist and work
        PERFORM get_user_active_team(gen_random_uuid());
        PERFORM can_user_join_team(gen_random_uuid());
        PERFORM validate_exit_fee_payment('test_intent_id');
        
        pass_count := pass_count + 1;
        RETURN QUERY SELECT 
            'Helper Functions'::TEXT,
            'PASS'::TEXT,
            'All helper functions created and callable'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        fail_count := fail_count + 1;
        RETURN QUERY SELECT 
            'Helper Functions'::TEXT,
            'FAIL'::TEXT,
            format('Error: %s', SQLERRM)::TEXT;
    END;
    
    -- ========================================
    -- SETUP TEST DATA
    -- ========================================
    
    -- Create test user (reuse existing if possible)
    SELECT id INTO temp_user_id FROM profiles LIMIT 1;
    IF temp_user_id IS NULL THEN
        temp_user_id := gen_random_uuid();
        INSERT INTO profiles (id, username, full_name, email) 
        VALUES (temp_user_id, 'test_exit_fee_user', 'Test User', 'test@example.com');
    END IF;
    
    -- Create test teams
    temp_team_id_1 := gen_random_uuid();
    temp_team_id_2 := gen_random_uuid();
    
    INSERT INTO teams (id, name, description, captain_id, is_public) VALUES
    (temp_team_id_1, 'Exit Fee Test Team 1', 'Test team for exit fee system', temp_user_id, true),
    (temp_team_id_2, 'Exit Fee Test Team 2', 'Second test team for switching', temp_user_id, true);
    
    -- ========================================
    -- TEST 4: Single Team Membership Constraint
    -- ========================================
    test_count := test_count + 1;
    
    BEGIN
        -- First join should succeed
        INSERT INTO team_members (team_id, user_id, role) 
        VALUES (temp_team_id_1, temp_user_id, 'member');
        
        -- Second join should fail due to unique constraint
        BEGIN
            INSERT INTO team_members (team_id, user_id, role) 
            VALUES (temp_team_id_2, temp_user_id, 'member');
            
            -- If we get here, constraint failed
            fail_count := fail_count + 1;
            RETURN QUERY SELECT 
                'Single Team Constraint'::TEXT,
                'FAIL'::TEXT,
                'Unique constraint did not prevent multiple team memberships'::TEXT;
                
        EXCEPTION WHEN unique_violation THEN
            -- This is expected - constraint working correctly
            pass_count := pass_count + 1;
            RETURN QUERY SELECT 
                'Single Team Constraint'::TEXT,
                'PASS'::TEXT,
                'Unique constraint successfully prevents multiple active team memberships'::TEXT;
        END;
        
    EXCEPTION WHEN OTHERS THEN
        fail_count := fail_count + 1;
        RETURN QUERY SELECT 
            'Single Team Constraint'::TEXT,
            'FAIL'::TEXT,
            format('Unexpected error: %s', SQLERRM)::TEXT;
    END;
    
    -- ========================================
    -- TEST 5: Exit Fee Payment Creation
    -- ========================================
    test_count := test_count + 1;
    
    BEGIN
        -- Create exit fee payment record
        INSERT INTO exit_fee_payments (
            user_id, from_team_id, amount, payment_status
        ) VALUES (
            temp_user_id, temp_team_id_1, 2000, 'initiated'
        ) RETURNING id INTO temp_payment_id;
        
        -- Verify record created with correct defaults
        SELECT * INTO payment_record FROM exit_fee_payments WHERE id = temp_payment_id;
        
        IF payment_record.amount = 2000 
           AND payment_record.lightning_address = 'RUNSTR@coinos.io'
           AND payment_record.payment_status = 'initiated'
           AND payment_record.payment_intent_id IS NOT NULL THEN
            pass_count := pass_count + 1;
            RETURN QUERY SELECT 
                'Exit Fee Payment Creation'::TEXT,
                'PASS'::TEXT,
                'Exit fee payment record created with correct defaults'::TEXT;
        ELSE
            fail_count := fail_count + 1;
            RETURN QUERY SELECT 
                'Exit Fee Payment Creation'::TEXT,
                'FAIL'::TEXT,
                'Exit fee payment record has incorrect values'::TEXT;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        fail_count := fail_count + 1;
        RETURN QUERY SELECT 
            'Exit Fee Payment Creation'::TEXT,
            'FAIL'::TEXT,
            format('Error: %s', SQLERRM)::TEXT;
    END;
    
    -- ========================================
    -- TEST 6: Team Switch Operation Creation
    -- ========================================
    test_count := test_count + 1;
    
    BEGIN
        -- Create team switch operation
        INSERT INTO team_switch_operations (
            user_id, from_team_id, to_team_id, exit_fee_payment_id, operation_type
        ) VALUES (
            temp_user_id, temp_team_id_1, temp_team_id_2, temp_payment_id, 'switch'
        ) RETURNING id INTO temp_switch_id;
        
        -- Verify created successfully
        IF temp_switch_id IS NOT NULL THEN
            pass_count := pass_count + 1;
            RETURN QUERY SELECT 
                'Team Switch Operation'::TEXT,
                'PASS'::TEXT,
                'Team switch operation created successfully'::TEXT;
        ELSE
            fail_count := fail_count + 1;
            RETURN QUERY SELECT 
                'Team Switch Operation'::TEXT,
                'FAIL'::TEXT,
                'Failed to create team switch operation'::TEXT;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        fail_count := fail_count + 1;
        RETURN QUERY SELECT 
            'Team Switch Operation'::TEXT,
            'FAIL'::TEXT,
            format('Error: %s', SQLERRM)::TEXT;
    END;
    
    -- ========================================
    -- TEST 7: Soft Delete Team Leave
    -- ========================================
    test_count := test_count + 1;
    
    BEGIN
        -- Update team membership to simulate leaving with exit fee
        UPDATE team_members 
        SET left_at = NOW(), 
            exit_fee_paid = true,
            exit_fee_payment_id = temp_payment_id
        WHERE user_id = temp_user_id AND team_id = temp_team_id_1;
        
        -- Check user can now join another team (constraint allows after soft delete)
        SELECT COUNT(*) INTO active_team_count 
        FROM team_members 
        WHERE user_id = temp_user_id AND left_at IS NULL;
        
        IF active_team_count = 0 THEN
            pass_count := pass_count + 1;
            RETURN QUERY SELECT 
                'Soft Delete Team Leave'::TEXT,
                'PASS'::TEXT,
                'User successfully left team, no active memberships remaining'::TEXT;
        ELSE
            fail_count := fail_count + 1;
            RETURN QUERY SELECT 
                'Soft Delete Team Leave'::TEXT,
                'FAIL'::TEXT,
                format('User still has %s active team memberships after leaving', active_team_count)::TEXT;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        fail_count := fail_count + 1;
        RETURN QUERY SELECT 
            'Soft Delete Team Leave'::TEXT,
            'FAIL'::TEXT,
            format('Error: %s', SQLERRM)::TEXT;
    END;
    
    -- ========================================
    -- TEST 8: Team Joining After Leave
    -- ========================================
    test_count := test_count + 1;
    
    BEGIN
        -- Now user should be able to join new team
        INSERT INTO team_members (team_id, user_id, role) 
        VALUES (temp_team_id_2, temp_user_id, 'member');
        
        -- Check active team count is now 1
        SELECT COUNT(*) INTO active_team_count 
        FROM team_members 
        WHERE user_id = temp_user_id AND left_at IS NULL;
        
        IF active_team_count = 1 THEN
            pass_count := pass_count + 1;
            RETURN QUERY SELECT 
                'Team Joining After Leave'::TEXT,
                'PASS'::TEXT,
                'User successfully joined new team after leaving previous team'::TEXT;
        ELSE
            fail_count := fail_count + 1;
            RETURN QUERY SELECT 
                'Team Joining After Leave'::TEXT,
                'FAIL'::TEXT,
                format('Unexpected active team count: %s', active_team_count)::TEXT;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        fail_count := fail_count + 1;
        RETURN QUERY SELECT 
            'Team Joining After Leave'::TEXT,
            'FAIL'::TEXT,
            format('Error: %s', SQLERRM)::TEXT;
    END;
    
    -- ========================================
    -- TEST 9: Analytics Views
    -- ========================================
    test_count := test_count + 1;
    
    BEGIN
        -- Test analytics views work
        PERFORM * FROM exit_fee_analytics LIMIT 1;
        PERFORM * FROM team_switching_analytics LIMIT 1;
        PERFORM * FROM team_membership_violations;
        
        pass_count := pass_count + 1;
        RETURN QUERY SELECT 
            'Analytics Views'::TEXT,
            'PASS'::TEXT,
            'All analytics views are queryable'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        fail_count := fail_count + 1;
        RETURN QUERY SELECT 
            'Analytics Views'::TEXT,
            'FAIL'::TEXT,
            format('Error: %s', SQLERRM)::TEXT;
    END;
    
    -- ========================================
    -- TEST 10: Constraint Validation
    -- ========================================
    test_count := test_count + 1;
    
    BEGIN
        -- Test amount constraint (must be 2000)
        BEGIN
            INSERT INTO exit_fee_payments (user_id, amount) 
            VALUES (temp_user_id, 1500);
            
            fail_count := fail_count + 1;
            RETURN QUERY SELECT 
                'Constraint Validation'::TEXT,
                'FAIL'::TEXT,
                'Amount constraint failed to prevent incorrect exit fee amount'::TEXT;
                
        EXCEPTION WHEN check_violation THEN
            -- Expected - constraint working
            pass_count := pass_count + 1;
            RETURN QUERY SELECT 
                'Constraint Validation'::TEXT,
                'PASS'::TEXT,
                'Amount constraint successfully enforces 2000 sats exit fee'::TEXT;
        END;
        
    EXCEPTION WHEN OTHERS THEN
        fail_count := fail_count + 1;
        RETURN QUERY SELECT 
            'Constraint Validation'::TEXT,
            'FAIL'::TEXT,
            format('Unexpected error: %s', SQLERRM)::TEXT;
    END;
    
    -- ========================================
    -- CLEANUP TEST DATA
    -- ========================================
    
    -- Clean up test data
    DELETE FROM team_members WHERE user_id = temp_user_id;
    DELETE FROM team_switch_operations WHERE user_id = temp_user_id;
    DELETE FROM exit_fee_payments WHERE user_id = temp_user_id;
    DELETE FROM teams WHERE id IN (temp_team_id_1, temp_team_id_2);
    -- Note: Don't delete test user profile as it might be used elsewhere
    
    -- ========================================
    -- FINAL RESULTS
    -- ========================================
    
    RAISE NOTICE '';
    RAISE NOTICE '================================================';
    RAISE NOTICE '🧪 EXIT FEE SYSTEM MIGRATION TEST RESULTS';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Total Tests: %', test_count;
    RAISE NOTICE 'Passed: % (%.1f%%)', pass_count, (pass_count::DECIMAL / test_count * 100);
    RAISE NOTICE 'Failed: % (%.1f%%)', fail_count, (fail_count::DECIMAL / test_count * 100);
    RAISE NOTICE '================================================';
    
    IF fail_count = 0 THEN
        RAISE NOTICE '✅ ALL TESTS PASSED - Migration completed successfully!';
    ELSE
        RAISE NOTICE '❌ SOME TESTS FAILED - Review results above';
    END IF;
    
    -- Return final summary
    RETURN QUERY SELECT 
        'FINAL RESULTS'::TEXT,
        CASE WHEN fail_count = 0 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        format('Tests: %s, Passed: %s, Failed: %s', test_count, pass_count, fail_count)::TEXT;
        
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- RUN THE TESTS
-- ========================================

-- Execute the test suite
SELECT * FROM run_exit_fee_migration_tests();

-- ========================================
-- ADDITIONAL VALIDATION QUERIES
-- ========================================

-- Check for any constraint violations
SELECT 'Constraint Violations Check' as test_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status,
       format('%s users with multiple active team memberships', COUNT(*)) as details
FROM team_membership_violations;

-- Verify all required indexes exist
SELECT 'Required Indexes Check' as test_name,
       CASE WHEN COUNT(*) >= 8 THEN 'PASS' ELSE 'FAIL' END as status,
       format('%s exit fee system indexes found (expected: >= 8)', COUNT(*)) as details
FROM pg_indexes 
WHERE indexname LIKE '%exit_fee%' OR indexname LIKE '%team_switch%' OR indexname = 'unique_active_team_membership';

-- Check RLS policies are enabled
SELECT 'RLS Policies Check' as test_name,
       CASE WHEN COUNT(*) >= 2 THEN 'PASS' ELSE 'FAIL' END as status,
       format('%s tables have RLS enabled (expected: >= 2)', COUNT(*)) as details
FROM information_schema.tables t
JOIN pg_class c ON c.relname = t.table_name
WHERE table_name IN ('exit_fee_payments', 'team_switch_operations')
  AND c.relrowsecurity = true;

-- Performance check - ensure indexes are being used
EXPLAIN (FORMAT TEXT) 
SELECT * FROM exit_fee_payments WHERE user_id = gen_random_uuid();

EXPLAIN (FORMAT TEXT)
SELECT * FROM team_members WHERE user_id = gen_random_uuid() AND left_at IS NULL;