-- Exit Fee Analytics Migration
-- This migration creates views and functions to support exit fee analytics and monitoring
-- Depends on: 001_exit_fee_system.sql

-- ========================================
-- ANALYTICS VIEWS
-- ========================================

-- Daily revenue tracking view
CREATE OR REPLACE VIEW exit_fee_revenue_daily AS
SELECT 
    DATE(completed_at) as date,
    COUNT(*) as payment_count,
    SUM(amount) as total_sats,
    AVG(amount) as avg_payment_amount,
    AVG(EXTRACT(EPOCH FROM (completed_at - created_at))) as avg_duration_seconds,
    MIN(EXTRACT(EPOCH FROM (completed_at - created_at))) as min_duration_seconds,
    MAX(EXTRACT(EPOCH FROM (completed_at - created_at))) as max_duration_seconds
FROM exit_fee_payments
WHERE payment_status = 'team_change_complete'
    AND completed_at IS NOT NULL
GROUP BY DATE(completed_at)
ORDER BY date DESC;

-- Weekly revenue aggregation
CREATE OR REPLACE VIEW exit_fee_revenue_weekly AS
SELECT 
    DATE_TRUNC('week', completed_at) as week_start,
    COUNT(*) as payment_count,
    SUM(amount) as total_sats,
    AVG(amount) as avg_payment_amount,
    AVG(EXTRACT(EPOCH FROM (completed_at - created_at))) as avg_duration_seconds
FROM exit_fee_payments
WHERE payment_status = 'team_change_complete'
    AND completed_at IS NOT NULL
GROUP BY DATE_TRUNC('week', completed_at)
ORDER BY week_start DESC;

-- Monthly revenue aggregation
CREATE OR REPLACE VIEW exit_fee_revenue_monthly AS
SELECT 
    DATE_TRUNC('month', completed_at) as month_start,
    COUNT(*) as payment_count,
    SUM(amount) as total_sats,
    AVG(amount) as avg_payment_amount,
    AVG(EXTRACT(EPOCH FROM (completed_at - created_at))) as avg_duration_seconds
FROM exit_fee_payments
WHERE payment_status = 'team_change_complete'
    AND completed_at IS NOT NULL
GROUP BY DATE_TRUNC('month', completed_at)
ORDER BY month_start DESC;

-- Team switching patterns view
CREATE OR REPLACE VIEW team_switch_patterns AS
SELECT 
    from_team_id,
    to_team_id,
    COUNT(*) as switch_count,
    AVG(amount) as avg_fee,
    AVG(EXTRACT(EPOCH FROM (completed_at - created_at))) as avg_switch_duration,
    MIN(completed_at) as first_switch,
    MAX(completed_at) as latest_switch
FROM exit_fee_payments
WHERE payment_status = 'team_change_complete'
    AND to_team_id IS NOT NULL
    AND from_team_id IS NOT NULL
    AND completed_at IS NOT NULL
GROUP BY from_team_id, to_team_id
ORDER BY switch_count DESC;

-- Team churn analysis (teams losing members)
CREATE OR REPLACE VIEW team_churn_analysis AS
SELECT 
    efp.from_team_id as team_id,
    t.name as team_name,
    COUNT(*) as members_lost,
    SUM(efp.amount) as lost_revenue_potential,
    AVG(EXTRACT(EPOCH FROM (efp.completed_at - efp.created_at))) as avg_exit_duration,
    COUNT(*) FILTER (WHERE efp.to_team_id IS NOT NULL) as switched_to_other_team,
    COUNT(*) FILTER (WHERE efp.to_team_id IS NULL) as left_platform
FROM exit_fee_payments efp
LEFT JOIN teams t ON efp.from_team_id = t.id
WHERE efp.payment_status = 'team_change_complete'
    AND efp.from_team_id IS NOT NULL
    AND efp.completed_at IS NOT NULL
GROUP BY efp.from_team_id, t.name
ORDER BY members_lost DESC;

-- Team attraction analysis (teams gaining members)
CREATE OR REPLACE VIEW team_attraction_analysis AS
SELECT 
    efp.to_team_id as team_id,
    t.name as team_name,
    COUNT(*) as members_gained,
    AVG(EXTRACT(EPOCH FROM (efp.completed_at - efp.created_at))) as avg_join_duration,
    COUNT(DISTINCT efp.from_team_id) as sources_count
FROM exit_fee_payments efp
LEFT JOIN teams t ON efp.to_team_id = t.id
WHERE efp.payment_status = 'team_change_complete'
    AND efp.to_team_id IS NOT NULL
    AND efp.completed_at IS NOT NULL
GROUP BY efp.to_team_id, t.name
ORDER BY members_gained DESC;

-- Payment success metrics by day
CREATE OR REPLACE VIEW payment_success_metrics AS
SELECT
    DATE(created_at) as date,
    COUNT(*) as total_attempts,
    COUNT(*) FILTER (WHERE payment_status = 'team_change_complete') as successful,
    COUNT(*) FILTER (WHERE payment_status = 'failed') as failed,
    COUNT(*) FILTER (WHERE payment_status = 'expired') as expired,
    COUNT(*) FILTER (WHERE payment_status IN ('initiated', 'invoice_created', 'payment_sent', 'payment_confirmed')) as pending,
    ROUND(
        (COUNT(*) FILTER (WHERE payment_status = 'team_change_complete')::DECIMAL / COUNT(*)) * 100, 
        2
    ) as success_rate_percentage
FROM exit_fee_payments
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Payment performance by hour (for identifying peak times)
CREATE OR REPLACE VIEW payment_hourly_patterns AS
SELECT
    EXTRACT(HOUR FROM created_at) as hour_of_day,
    COUNT(*) as total_attempts,
    COUNT(*) FILTER (WHERE payment_status = 'team_change_complete') as successful,
    AVG(EXTRACT(EPOCH FROM (completed_at - created_at))) 
        FILTER (WHERE payment_status = 'team_change_complete' AND completed_at IS NOT NULL) as avg_duration_seconds,
    ROUND(
        (COUNT(*) FILTER (WHERE payment_status = 'team_change_complete')::DECIMAL / COUNT(*)) * 100, 
        2
    ) as success_rate_percentage
FROM exit_fee_payments
GROUP BY EXTRACT(HOUR FROM created_at)
ORDER BY hour_of_day;

-- User payment behavior analysis
CREATE OR REPLACE VIEW user_payment_behavior AS
SELECT
    user_id,
    COUNT(*) as total_payments,
    COUNT(*) FILTER (WHERE payment_status = 'team_change_complete') as successful_payments,
    COUNT(*) FILTER (WHERE payment_status = 'failed') as failed_payments,
    SUM(amount) FILTER (WHERE payment_status = 'team_change_complete') as total_fees_paid,
    AVG(retry_count) as avg_retry_count,
    MIN(created_at) as first_payment_attempt,
    MAX(created_at) as latest_payment_attempt,
    COUNT(DISTINCT from_team_id) as teams_left,
    COUNT(DISTINCT to_team_id) FILTER (WHERE to_team_id IS NOT NULL) as teams_joined
FROM exit_fee_payments
GROUP BY user_id
ORDER BY total_fees_paid DESC;

-- ========================================
-- MONITORING VIEWS
-- ========================================

-- Stuck payments monitoring (payments over threshold)
CREATE OR REPLACE VIEW stuck_payments AS
SELECT
    id,
    payment_intent_id,
    user_id,
    from_team_id,
    to_team_id,
    payment_status,
    retry_count,
    error_message,
    created_at,
    EXTRACT(EPOCH FROM (NOW() - created_at)) as stuck_duration_seconds,
    expires_at
FROM exit_fee_payments
WHERE payment_status IN ('initiated', 'invoice_created', 'payment_sent', 'payment_confirmed')
    AND created_at < NOW() - INTERVAL '1 hour'
ORDER BY created_at ASC;

-- Payment errors analysis
CREATE OR REPLACE VIEW payment_errors_analysis AS
SELECT
    payment_status,
    error_message,
    COUNT(*) as occurrence_count,
    AVG(retry_count) as avg_retry_count,
    MIN(created_at) as first_occurrence,
    MAX(created_at) as latest_occurrence
FROM exit_fee_payments
WHERE payment_status = 'failed'
    AND error_message IS NOT NULL
GROUP BY payment_status, error_message
ORDER BY occurrence_count DESC;

-- Real-time monitoring dashboard data
CREATE OR REPLACE VIEW realtime_metrics AS
SELECT
    -- Today's metrics
    COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE) as attempts_today,
    COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE AND payment_status = 'team_change_complete') as successes_today,
    SUM(amount) FILTER (WHERE DATE(created_at) = CURRENT_DATE AND payment_status = 'team_change_complete') as revenue_today,
    
    -- Last 24 hours
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours') as attempts_24h,
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours' AND payment_status = 'team_change_complete') as successes_24h,
    SUM(amount) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours' AND payment_status = 'team_change_complete') as revenue_24h,
    
    -- Current stuck payments
    COUNT(*) FILTER (
        WHERE payment_status IN ('initiated', 'invoice_created', 'payment_sent', 'payment_confirmed')
        AND created_at < NOW() - INTERVAL '1 hour'
    ) as stuck_payments_count,
    
    -- Average processing time today
    AVG(EXTRACT(EPOCH FROM (completed_at - created_at))) FILTER (
        WHERE DATE(created_at) = CURRENT_DATE 
        AND payment_status = 'team_change_complete'
        AND completed_at IS NOT NULL
    ) as avg_processing_time_today
FROM exit_fee_payments;

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Function to get revenue for date range
CREATE OR REPLACE FUNCTION get_exit_fee_revenue(start_date DATE, end_date DATE)
RETURNS TABLE (
    total_amount BIGINT,
    payment_count BIGINT,
    avg_amount NUMERIC,
    success_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        SUM(efp.amount) as total_amount,
        COUNT(*) FILTER (WHERE efp.payment_status = 'team_change_complete') as payment_count,
        AVG(efp.amount) FILTER (WHERE efp.payment_status = 'team_change_complete') as avg_amount,
        (COUNT(*) FILTER (WHERE efp.payment_status = 'team_change_complete')::DECIMAL / 
         COUNT(*)::DECIMAL * 100) as success_rate
    FROM exit_fee_payments efp
    WHERE DATE(efp.created_at) BETWEEN start_date AND end_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get team switching matrix
CREATE OR REPLACE FUNCTION get_team_switch_matrix()
RETURNS TABLE (
    from_team_id UUID,
    from_team_name TEXT,
    to_team_id UUID,
    to_team_name TEXT,
    switch_count BIGINT,
    avg_duration NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        efp.from_team_id,
        t1.name as from_team_name,
        efp.to_team_id,
        t2.name as to_team_name,
        COUNT(*) as switch_count,
        AVG(EXTRACT(EPOCH FROM (efp.completed_at - efp.created_at))) as avg_duration
    FROM exit_fee_payments efp
    LEFT JOIN teams t1 ON efp.from_team_id = t1.id
    LEFT JOIN teams t2 ON efp.to_team_id = t2.id
    WHERE efp.payment_status = 'team_change_complete'
        AND efp.from_team_id IS NOT NULL
        AND efp.to_team_id IS NOT NULL
        AND efp.completed_at IS NOT NULL
    GROUP BY efp.from_team_id, t1.name, efp.to_team_id, t2.name
    ORDER BY switch_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate payment percentiles
CREATE OR REPLACE FUNCTION get_payment_duration_percentiles()
RETURNS TABLE (
    p50_seconds NUMERIC,
    p90_seconds NUMERIC,
    p95_seconds NUMERIC,
    p99_seconds NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (completed_at - created_at))) as p50_seconds,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (completed_at - created_at))) as p90_seconds,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (completed_at - created_at))) as p95_seconds,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (completed_at - created_at))) as p99_seconds
    FROM exit_fee_payments
    WHERE payment_status = 'team_change_complete'
        AND completed_at IS NOT NULL
        AND created_at IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- CLEANUP FUNCTIONS
-- ========================================

-- Function to archive old exit fee records (for data retention)
CREATE OR REPLACE FUNCTION archive_old_exit_fees(archive_days INTEGER DEFAULT 365)
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
BEGIN
    -- Move old records to archive table (create if doesn't exist)
    CREATE TABLE IF NOT EXISTS exit_fee_payments_archive (LIKE exit_fee_payments INCLUDING ALL);
    
    -- Insert old records into archive
    INSERT INTO exit_fee_payments_archive 
    SELECT * FROM exit_fee_payments
    WHERE created_at < NOW() - (archive_days || ' days')::INTERVAL
        AND payment_status IN ('team_change_complete', 'failed', 'expired');
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    
    -- Delete archived records from main table
    DELETE FROM exit_fee_payments
    WHERE created_at < NOW() - (archive_days || ' days')::INTERVAL
        AND payment_status IN ('team_change_complete', 'failed', 'expired');
    
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- GRANT PERMISSIONS
-- ========================================

-- Grant read access to analytics views
GRANT SELECT ON exit_fee_revenue_daily TO authenticated;
GRANT SELECT ON exit_fee_revenue_weekly TO authenticated;
GRANT SELECT ON exit_fee_revenue_monthly TO authenticated;
GRANT SELECT ON team_switch_patterns TO authenticated;
GRANT SELECT ON payment_success_metrics TO authenticated;
GRANT SELECT ON payment_hourly_patterns TO authenticated;
GRANT SELECT ON realtime_metrics TO authenticated;

-- Restrict sensitive views to service role only
GRANT SELECT ON user_payment_behavior TO service_role;
GRANT SELECT ON stuck_payments TO service_role;
GRANT SELECT ON payment_errors_analysis TO service_role;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_exit_fee_revenue(DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_team_switch_matrix() TO authenticated;
GRANT EXECUTE ON FUNCTION get_payment_duration_percentiles() TO authenticated;
GRANT EXECUTE ON FUNCTION archive_old_exit_fees(INTEGER) TO service_role;

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================

-- Additional indexes for analytics performance
CREATE INDEX IF NOT EXISTS idx_exit_fee_payments_completed_at_status 
    ON exit_fee_payments(completed_at, payment_status) 
    WHERE completed_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_exit_fee_payments_created_date 
    ON exit_fee_payments(DATE(created_at));

CREATE INDEX IF NOT EXISTS idx_exit_fee_payments_hour 
    ON exit_fee_payments(EXTRACT(HOUR FROM created_at));

CREATE INDEX IF NOT EXISTS idx_exit_fee_payments_team_switch 
    ON exit_fee_payments(from_team_id, to_team_id, payment_status)
    WHERE from_team_id IS NOT NULL AND to_team_id IS NOT NULL;

-- ========================================
-- COMMENTS FOR DOCUMENTATION
-- ========================================

COMMENT ON VIEW exit_fee_revenue_daily IS 'Daily exit fee revenue aggregation with payment metrics';
COMMENT ON VIEW team_switch_patterns IS 'Analysis of team-to-team switching patterns';
COMMENT ON VIEW payment_success_metrics IS 'Daily payment success rate and failure analysis';
COMMENT ON VIEW stuck_payments IS 'Monitor payments that exceed processing thresholds';
COMMENT ON VIEW realtime_metrics IS 'Real-time dashboard metrics for operations monitoring';

COMMENT ON FUNCTION get_exit_fee_revenue(DATE, DATE) IS 'Calculate revenue metrics for specified date range';
COMMENT ON FUNCTION get_team_switch_matrix() IS 'Generate team switching matrix with names and metrics';
COMMENT ON FUNCTION archive_old_exit_fees(INTEGER) IS 'Archive old exit fee records for data retention';