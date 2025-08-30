-- Fix missing columns in workouts table
-- Run this to add all missing columns and fix the views

-- Add missing columns to workouts table
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT false;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS points_earned INTEGER DEFAULT 0;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS reward_amount INTEGER DEFAULT 0;

-- Recreate views with proper column handling
CREATE OR REPLACE VIEW weekly_leaderboard AS
SELECT 
    p.id as user_id,
    p.username,
    p.full_name,
    p.avatar_url,
    COUNT(w.id) as workout_count,
    SUM(COALESCE(w.duration, 0)) as total_duration,
    SUM(COALESCE(w.distance, 0)) as total_distance,
    SUM(COALESCE(w.calories, 0)) as total_calories,
    SUM(COALESCE(w.points_earned, 0)) as total_points,
    SUM(COALESCE(w.reward_amount, 0)) as total_rewards,
    RANK() OVER (ORDER BY SUM(COALESCE(w.points_earned, 0)) DESC) as rank
FROM profiles p
LEFT JOIN workouts w ON p.id = w.user_id 
    AND w.started_at >= NOW() - INTERVAL '7 days'
    AND COALESCE(w.verified, false) = true
GROUP BY p.id, p.username, p.full_name, p.avatar_url
ORDER BY total_points DESC;

CREATE OR REPLACE VIEW team_leaderboard AS
SELECT 
    t.id as team_id,
    t.name as team_name,
    t.member_count,
    COUNT(w.id) as total_workouts,
    SUM(COALESCE(w.duration, 0)) as total_duration,
    SUM(COALESCE(w.distance, 0)) as total_distance,
    SUM(COALESCE(w.points_earned, 0)) as total_points,
    SUM(COALESCE(w.reward_amount, 0)) as total_rewards,
    RANK() OVER (ORDER BY SUM(COALESCE(w.points_earned, 0)) DESC) as rank
FROM teams t
LEFT JOIN team_members tm ON t.id = tm.team_id
LEFT JOIN workouts w ON tm.user_id = w.user_id 
    AND w.started_at >= NOW() - INTERVAL '7 days'
    AND COALESCE(w.verified, false) = true
GROUP BY t.id, t.name, t.member_count
ORDER BY total_points DESC;