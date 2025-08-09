-- WeTwo App Database Schema
-- Created for Supabase PostgreSQL

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================================
-- PROFILES TABLE
-- ========================================
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    zodiac_sign TEXT NOT NULL,
    birth_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- ========================================
-- PARTNERSHIPS TABLE
-- ========================================
CREATE TABLE partnerships (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    partner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    connection_code TEXT UNIQUE NOT NULL,
    status TEXT DEFAULT 'connected' CHECK (status IN ('pending', 'connected', 'disconnected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique partnerships
    UNIQUE(user_id, partner_id)
);

-- Enable Row Level Security
ALTER TABLE partnerships ENABLE ROW LEVEL SECURITY;

-- RLS Policies for partnerships
CREATE POLICY "Users can view their partnerships" ON partnerships
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() = partner_id);

CREATE POLICY "Users can create partnerships" ON partnerships
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their partnerships" ON partnerships
    FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = partner_id);

CREATE POLICY "Users can delete their partnerships" ON partnerships
    FOR DELETE USING (auth.uid() = user_id OR auth.uid() = partner_id);

-- ========================================
-- MEMORIES TABLE
-- ========================================
CREATE TABLE memories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    partner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    mood_level INTEGER NOT NULL CHECK (mood_level >= 1 AND mood_level <= 5),
    tags TEXT[] DEFAULT '{}',
    is_shared BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;

-- RLS Policies for memories
CREATE POLICY "Users can view their own memories" ON memories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view shared memories from partners" ON memories
    FOR SELECT USING (
        is_shared = true AND (
            auth.uid() = partner_id OR 
            EXISTS (
                SELECT 1 FROM partnerships 
                WHERE (user_id = auth.uid() AND partner_id = memories.user_id) 
                   OR (partner_id = auth.uid() AND user_id = memories.user_id)
            )
        )
    );

CREATE POLICY "Users can create their own memories" ON memories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own memories" ON memories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can update shared memories from partners" ON memories
    FOR UPDATE USING (
        is_shared = true AND (
            auth.uid() = partner_id OR 
            EXISTS (
                SELECT 1 FROM partnerships 
                WHERE (user_id = auth.uid() AND partner_id = memories.user_id) 
                   OR (partner_id = auth.uid() AND user_id = memories.user_id)
            )
        )
    );

CREATE POLICY "Users can delete their own memories" ON memories
    FOR DELETE USING (auth.uid() = user_id);

-- ========================================
-- MOOD ENTRIES TABLE (for daily mood tracking)
-- ========================================
CREATE TABLE mood_entries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    mood_level INTEGER NOT NULL CHECK (mood_level >= 1 AND mood_level <= 5),
    event_label TEXT,
    location TEXT,
    photo_data BYTEA,
    insight TEXT,
    love_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure one mood entry per user per day
    UNIQUE(user_id, date)
);

-- Enable Row Level Security
ALTER TABLE mood_entries ENABLE ROW LEVEL SECURITY;

-- RLS Policies for mood_entries
CREATE POLICY "Users can view their own mood entries" ON mood_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view partner mood entries" ON mood_entries
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM partnerships 
            WHERE (user_id = auth.uid() AND partner_id = mood_entries.user_id) 
               OR (partner_id = auth.uid() AND user_id = mood_entries.user_id)
        )
    );

CREATE POLICY "Users can create their own mood entries" ON mood_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own mood entries" ON mood_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own mood entries" ON mood_entries
    FOR DELETE USING (auth.uid() = user_id);

-- ========================================
-- SUBSCRIPTIONS TABLE (for premium features)
-- ========================================
CREATE TABLE subscriptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    plan_type TEXT NOT NULL CHECK (plan_type IN ('free', 'premium', 'premium_plus')),
    status TEXT NOT NULL CHECK (status IN ('active', 'cancelled', 'expired')),
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for subscriptions
CREATE POLICY "Users can view their own subscription" ON subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own subscription" ON subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own subscription" ON subscriptions
    FOR UPDATE USING (auth.uid() = user_id);

-- ========================================
-- USAGE TRACKING TABLE (for freemium limits)
-- ========================================
CREATE TABLE usage_tracking (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    insights_used INTEGER DEFAULT 0,
    photos_uploaded INTEGER DEFAULT 0,
    memories_created INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure one tracking entry per user per day
    UNIQUE(user_id, date)
);

-- Enable Row Level Security
ALTER TABLE usage_tracking ENABLE ROW LEVEL SECURITY;

-- RLS Policies for usage_tracking
CREATE POLICY "Users can view their own usage" ON usage_tracking
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own usage tracking" ON usage_tracking
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own usage tracking" ON usage_tracking
    FOR UPDATE USING (auth.uid() = user_id);

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================
CREATE INDEX idx_memories_user_id ON memories(user_id);
CREATE INDEX idx_memories_partner_id ON memories(partner_id);
CREATE INDEX idx_memories_created_at ON memories(created_at DESC);
CREATE INDEX idx_memories_is_shared ON memories(is_shared);

CREATE INDEX idx_mood_entries_user_id ON mood_entries(user_id);
CREATE INDEX idx_mood_entries_date ON mood_entries(date DESC);

CREATE INDEX idx_partnerships_user_id ON partnerships(user_id);
CREATE INDEX idx_partnerships_partner_id ON partnerships(partner_id);
CREATE INDEX idx_partnerships_connection_code ON partnerships(connection_code);

CREATE INDEX idx_usage_tracking_user_id ON usage_tracking(user_id);
CREATE INDEX idx_usage_tracking_date ON usage_tracking(date);

-- ========================================
-- FUNCTIONS AND TRIGGERS
-- ========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_partnerships_updated_at BEFORE UPDATE ON partnerships
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_memories_updated_at BEFORE UPDATE ON memories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mood_entries_updated_at BEFORE UPDATE ON mood_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usage_tracking_updated_at BEFORE UPDATE ON usage_tracking
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to generate connection codes
CREATE OR REPLACE FUNCTION generate_connection_code()
RETURNS TEXT AS $$
DECLARE
    code TEXT;
    exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a 6-character alphanumeric code
        code := upper(substring(md5(random()::text) from 1 for 6));
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM partnerships WHERE connection_code = code) INTO exists;
        
        -- If code doesn't exist, return it
        IF NOT exists THEN
            RETURN code;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- STORAGE BUCKETS
-- ========================================

-- Create storage bucket for memory photos
INSERT INTO storage.buckets (id, name, public) 
VALUES ('memory-photos', 'memory-photos', true);

-- Storage policies for memory photos
CREATE POLICY "Users can upload their own photos" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'memory-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view photos from their memories" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'memory-photos' AND (
            auth.uid()::text = (storage.foldername(name))[1] OR
            EXISTS (
                SELECT 1 FROM memories m
                JOIN partnerships p ON (p.user_id = auth.uid() AND p.partner_id = m.user_id) 
                                   OR (p.partner_id = auth.uid() AND p.user_id = m.user_id)
                WHERE m.id::text = (storage.foldername(name))[1] AND m.is_shared = true
            )
        )
    );

CREATE POLICY "Users can update their own photos" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'memory-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own photos" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'memory-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ========================================
-- INITIAL DATA
-- ========================================

-- Insert default subscription for new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO subscriptions (user_id, plan_type, status)
    VALUES (NEW.id, 'free', 'active');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ========================================
-- VIEWS FOR COMMON QUERIES
-- ========================================

-- View for user's complete profile with subscription info
CREATE VIEW user_profiles AS
SELECT 
    p.*,
    s.plan_type,
    s.status as subscription_status,
    s.end_date as subscription_end_date
FROM profiles p
LEFT JOIN subscriptions s ON p.id = s.user_id
WHERE s.status = 'active' OR s.status IS NULL;

-- View for shared memories between partners
CREATE VIEW shared_memories AS
SELECT 
    m.*,
    p1.name as user_name,
    p2.name as partner_name
FROM memories m
JOIN partnerships pt ON (pt.user_id = m.user_id AND pt.partner_id = m.partner_id)
   OR (pt.partner_id = m.user_id AND pt.user_id = m.partner_id)
JOIN profiles p1 ON m.user_id = p1.id
JOIN profiles p2 ON m.partner_id = p2.id
WHERE m.is_shared = true;

-- ========================================
-- COMMENTS
-- ========================================
COMMENT ON TABLE profiles IS 'User profiles with zodiac signs and personal info';
COMMENT ON TABLE partnerships IS 'Partner connections between users';
COMMENT ON TABLE memories IS 'Shared and personal memories with photos';
COMMENT ON TABLE mood_entries IS 'Daily mood tracking entries';
COMMENT ON TABLE subscriptions IS 'Premium subscription management';
COMMENT ON TABLE usage_tracking IS 'Freemium usage limits tracking';

COMMENT ON COLUMN memories.mood_level IS '1=very sad, 2=sad, 3=neutral, 4=happy, 5=very happy';
COMMENT ON COLUMN mood_entries.mood_level IS '1=very sad, 2=sad, 3=neutral, 4=happy, 5=very happy';
COMMENT ON COLUMN memories.tags IS 'Array of tags for categorizing memories';
COMMENT ON COLUMN partnerships.connection_code IS '6-character unique code for partner connection'; 