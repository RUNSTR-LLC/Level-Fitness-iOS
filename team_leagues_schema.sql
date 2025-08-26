-- Team Leagues Table Schema for Supabase
-- This creates the team_leagues table to support one monthly league per team
-- Apply this SQL to your Supabase database

CREATE TABLE team_leagues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'monthly_distance',
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    payout_percentages INTEGER[] NOT NULL DEFAULT '{100}', -- Array of payout percentages
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Create unique constraint: only one active league per team
CREATE UNIQUE INDEX idx_team_active_league 
ON team_leagues(team_id) 
WHERE status = 'active';

-- Create indexes for performance
CREATE INDEX idx_team_leagues_team_id ON team_leagues(team_id);
CREATE INDEX idx_team_leagues_status ON team_leagues(status);
CREATE INDEX idx_team_leagues_dates ON team_leagues(start_date, end_date);

-- Add Row Level Security (RLS)
ALTER TABLE team_leagues ENABLE ROW LEVEL SECURITY;

-- Policy: Team members can view their team's leagues
CREATE POLICY "Team members can view team leagues" ON team_leagues
    FOR SELECT USING (
        team_id IN (
            SELECT team_id FROM team_members 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Team captains can create/update their team's leagues
CREATE POLICY "Team captains can manage team leagues" ON team_leagues
    FOR ALL USING (
        team_id IN (
            SELECT id FROM teams 
            WHERE captain_id = auth.uid()
        )
    );

-- Comments for documentation
COMMENT ON TABLE team_leagues IS 'Monthly leagues for teams - each team can have one active league at a time';
COMMENT ON COLUMN team_leagues.payout_percentages IS 'Array of prize distribution percentages, e.g., [70, 20, 10] for top 3 split';
COMMENT ON COLUMN team_leagues.type IS 'League type, currently only monthly_distance supported';
COMMENT ON INDEX idx_team_active_league IS 'Ensures only one active league per team';