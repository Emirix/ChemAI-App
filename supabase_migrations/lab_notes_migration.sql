-- Create experiments table
CREATE TABLE IF NOT EXISTS experiments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'failed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create lab_notes table
CREATE TABLE IF NOT EXISTS lab_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id UUID NOT NULL REFERENCES experiments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    note_type TEXT DEFAULT 'observation' CHECK (note_type IN ('observation', 'success', 'issue', 'unexpected')),
    attachments JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_experiments_user_id ON experiments(user_id);
CREATE INDEX IF NOT EXISTS idx_experiments_created_at ON experiments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lab_notes_experiment_id ON lab_notes(experiment_id);
CREATE INDEX IF NOT EXISTS idx_lab_notes_user_id ON lab_notes(user_id);
CREATE INDEX IF NOT EXISTS idx_lab_notes_created_at ON lab_notes(created_at DESC);

-- Enable RLS
ALTER TABLE experiments ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_notes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for experiments
CREATE POLICY "Users can view their own experiments"
    ON experiments FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own experiments"
    ON experiments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own experiments"
    ON experiments FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own experiments"
    ON experiments FOR DELETE
    USING (auth.uid() = user_id);

-- RLS Policies for lab_notes
CREATE POLICY "Users can view their own lab notes"
    ON lab_notes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own lab notes"
    ON lab_notes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own lab notes"
    ON lab_notes FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own lab notes"
    ON lab_notes FOR DELETE
    USING (auth.uid() = user_id);
