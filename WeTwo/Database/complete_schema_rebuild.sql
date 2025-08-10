-- Complete Schema Rebuild for WeTwo App
-- Run this in your Supabase SQL Editor after dropping all existing tables

-- 1. Create profiles table with all required columns
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    zodiac_sign TEXT NOT NULL,
    birth_date DATE NOT NULL,
    profile_photo_url TEXT,
    relationship_status TEXT,
    has_children TEXT,
    children_count TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create memories table
CREATE TABLE memories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    partner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    photo_data TEXT,
    location TEXT,
    mood_level TEXT NOT NULL,
    tags TEXT,
    is_shared TEXT DEFAULT 'false',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create partnerships table
CREATE TABLE partnerships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    partner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    connection_code TEXT NOT NULL,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create love_messages table
CREATE TABLE love_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Enable Row Level Security on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE partnerships ENABLE ROW LEVEL SECURITY;
ALTER TABLE love_messages ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS Policies for profiles
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view partner profiles" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM partnerships 
            WHERE (user_id = auth.uid() AND partner_id = profiles.id) 
               OR (partner_id = auth.uid() AND user_id = profiles.id)
        )
    );

-- 7. Create RLS Policies for memories
CREATE POLICY "Users can view their own memories" ON memories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own memories" ON memories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own memories" ON memories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view shared memories" ON memories
    FOR SELECT USING (
        is_shared = 'true' AND (
            user_id = auth.uid() OR 
            partner_id = auth.uid() OR
            EXISTS (
                SELECT 1 FROM partnerships 
                WHERE (user_id = auth.uid() AND partner_id = memories.user_id) 
                   OR (partner_id = auth.uid() AND user_id = memories.user_id)
            )
        )
    );

-- 8. Create RLS Policies for partnerships
CREATE POLICY "Users can view their partnerships" ON partnerships
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() = partner_id);

CREATE POLICY "Users can insert partnerships" ON partnerships
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their partnerships" ON partnerships
    FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = partner_id);

-- 9. Create RLS Policies for love_messages
CREATE POLICY "Users can view messages they sent or received" ON love_messages
    FOR SELECT USING (
        (auth.uid() = sender_id OR auth.uid() = receiver_id) AND
        EXISTS (
            SELECT 1 FROM partnerships 
            WHERE (user_id = auth.uid() AND partner_id = CASE 
                WHEN auth.uid() = sender_id THEN receiver_id 
                ELSE sender_id 
            END) OR (partner_id = auth.uid() AND user_id = CASE 
                WHEN auth.uid() = sender_id THEN receiver_id 
                ELSE sender_id 
            END)
        )
    );

CREATE POLICY "Users can send messages" ON love_messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM partnerships 
            WHERE (user_id = auth.uid() AND partner_id = receiver_id) 
               OR (partner_id = auth.uid() AND user_id = receiver_id)
        )
    );

CREATE POLICY "Users can update messages they received" ON love_messages
    FOR UPDATE USING (
        auth.uid() = receiver_id AND
        EXISTS (
            SELECT 1 FROM partnerships 
            WHERE (user_id = auth.uid() AND partner_id = sender_id) 
               OR (partner_id = auth.uid() AND user_id = sender_id)
        )
    );

-- 10. Create indexes for better performance
CREATE INDEX idx_memories_user_id ON memories(user_id);
CREATE INDEX idx_memories_date ON memories(date DESC);
CREATE INDEX idx_partnerships_user_id ON partnerships(user_id);
CREATE INDEX idx_partnerships_partner_id ON partnerships(partner_id);
CREATE INDEX idx_love_messages_sender_id ON love_messages(sender_id);
CREATE INDEX idx_love_messages_receiver_id ON love_messages(receiver_id);
CREATE INDEX idx_love_messages_timestamp ON love_messages(timestamp DESC);

-- 11. Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 12. Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_memories_updated_at BEFORE UPDATE ON memories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_partnerships_updated_at BEFORE UPDATE ON partnerships
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_love_messages_updated_at BEFORE UPDATE ON love_messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 13. Add comments for documentation
COMMENT ON TABLE profiles IS 'User profiles with relationship information';
COMMENT ON TABLE memories IS 'User memories and shared moments';
COMMENT ON TABLE partnerships IS 'Partner connections between users';
COMMENT ON TABLE love_messages IS 'Love messages between partners';

COMMENT ON COLUMN profiles.relationship_status IS 'Current relationship status of the user';
COMMENT ON COLUMN profiles.has_children IS 'Whether the user has children (stored as text)';
COMMENT ON COLUMN profiles.children_count IS 'Number of children the user has (stored as text)';
COMMENT ON COLUMN profiles.profile_photo_url IS 'URL to the user profile photo stored in Supabase Storage';
