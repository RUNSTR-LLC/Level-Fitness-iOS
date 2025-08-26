-- Fix Duplicate Teams Migration
-- This migration adds constraints to prevent duplicate team creation and ensures usernames are properly populated

-- 1. Add unique constraint to prevent captains from creating multiple teams
-- Note: This will fail if there are already duplicate teams for the same captain
-- In that case, you'll need to manually clean up duplicates first

-- Check for existing duplicates before adding constraint
DO $$
BEGIN
    -- Check if there are any captains with multiple teams
    IF EXISTS (
        SELECT captain_id 
        FROM teams 
        WHERE captain_id IS NOT NULL 
        GROUP BY captain_id 
        HAVING COUNT(*) > 1
    ) THEN
        RAISE NOTICE 'WARNING: Found captains with multiple teams. Please clean up duplicates before adding unique constraint.';
        
        -- Show the duplicate captains
        RAISE NOTICE 'Duplicate captains:';
        FOR rec IN 
            SELECT captain_id, COUNT(*) as team_count
            FROM teams 
            WHERE captain_id IS NOT NULL 
            GROUP BY captain_id 
            HAVING COUNT(*) > 1
        LOOP
            RAISE NOTICE 'Captain % has % teams', rec.captain_id, rec.team_count;
        END LOOP;
    ELSE
        -- No duplicates found, safe to add constraint
        ALTER TABLE teams ADD CONSTRAINT unique_captain_team UNIQUE (captain_id);
        RAISE NOTICE 'Added unique constraint for captain teams successfully.';
    END IF;
END $$;

-- 2. Ensure all profiles have proper usernames
-- Update profiles that don't have usernames by extracting from email
UPDATE profiles 
SET username = SPLIT_PART(email, '@', 1),
    full_name = SPLIT_PART(email, '@', 1),
    updated_at = NOW()
WHERE (username IS NULL OR username = '') 
  AND email IS NOT NULL 
  AND email != '';

-- 3. Add indexes for better performance on username lookups
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_teams_captain_id ON teams(captain_id);

-- 4. Add a function to automatically set username from email for new users
CREATE OR REPLACE FUNCTION set_default_username()
RETURNS TRIGGER AS $$
BEGIN
    -- If username is not provided but email is available, extract username from email
    IF (NEW.username IS NULL OR NEW.username = '') AND NEW.email IS NOT NULL AND NEW.email != '' THEN
        NEW.username := SPLIT_PART(NEW.email, '@', 1);
        NEW.full_name := COALESCE(NEW.full_name, NEW.username);
    END IF;
    
    -- Set updated_at timestamp
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically set username for new profiles
DROP TRIGGER IF EXISTS trigger_set_default_username ON profiles;
CREATE TRIGGER trigger_set_default_username
    BEFORE INSERT OR UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION set_default_username();

-- Log the migration completion
INSERT INTO migrations_log (migration_name, applied_at, description) 
VALUES (
    'fix_duplicate_teams_and_usernames', 
    NOW(), 
    'Added unique constraint for captain teams and improved username handling'
)
ON CONFLICT (migration_name) DO NOTHING;

-- Create migrations_log table if it doesn't exist
CREATE TABLE IF NOT EXISTS migrations_log (
    migration_name TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    description TEXT
);