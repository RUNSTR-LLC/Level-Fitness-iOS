-- Fix for the "verified" column error
-- Run this after the main schema to fix the views

-- First, let's add the verified column to workouts if it doesn't exist
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT false;

-- Now recreate the views with the correct column reference
CREATE OR REPLACE VIEW weekly_leaderboard AS
SELECT 
    p.id as user_id,
    p.username,
    p.full_name,
    p.avatar_url,
    COUNT(w.id) as workout_count,
    SUM(w.duration) as total_duration,
    SUM(COALESCE(w.distance, 0)) as total_distance,
    SUM(COALESCE(w.calories, 0)) as total_calories,
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