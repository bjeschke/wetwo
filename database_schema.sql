-- =====================================================
-- WeTwo Backend Database Schema
-- For Railway PostgreSQL Database
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgcrypto for password hashing
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- USERS TABLE
-- =====================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    birth_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE,
    verification_token VARCHAR(255),
    reset_token VARCHAR(255),
    reset_token_expires TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- PROFILES TABLE
-- =====================================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    zodiac_sign VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    profile_photo_url TEXT,
    relationship_status VARCHAR(100),
    has_children VARCHAR(10), -- 'true' or 'false'
    children_count VARCHAR(10),
    push_token TEXT,
    apple_user_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- PARTNERSHIPS TABLE
-- =====================================================
CREATE TABLE partnerships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    partner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    connection_code VARCHAR(6) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'pending', 'disconnected'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, partner_id)
);

-- =====================================================
-- MEMORIES TABLE
-- =====================================================
CREATE TABLE memories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    partner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    date DATE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    photo_data TEXT, -- Base64 encoded or URL
    location VARCHAR(255),
    mood_level VARCHAR(10) NOT NULL, -- '1', '2', '3', '4', '5'
    tags TEXT, -- Comma-separated tags
    is_shared VARCHAR(10) DEFAULT 'false', -- 'true' or 'false'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- MOOD_ENTRIES TABLE
-- =====================================================
CREATE TABLE mood_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    mood_level INTEGER NOT NULL CHECK (mood_level >= 1 AND mood_level <= 5),
    event_label VARCHAR(255),
    location VARCHAR(255),
    photo_data TEXT, -- Base64 encoded
    insight TEXT,
    love_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date) -- One mood entry per user per day
);

-- =====================================================
-- LOVE_MESSAGES TABLE
-- =====================================================
CREATE TABLE love_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'memory', 'love_message', 'mood', 'partner'
    data JSONB, -- Additional data for the notification
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STORAGE FILES TABLE
-- =====================================================
CREATE TABLE storage_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_url TEXT NOT NULL, -- Full URL to the file in Cloudflare R2
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_type VARCHAR(50) NOT NULL, -- 'profile_photo', 'memory_photo', 'mood_photo'
    bucket_name VARCHAR(100) NOT NULL, -- 'profile-photos', 'memory-photos', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- CLOUDFLARE R2 CONFIGURATION
-- =====================================================
-- Configuration table for storage buckets
CREATE TABLE storage_buckets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bucket_name VARCHAR(100) UNIQUE NOT NULL,
    bucket_url TEXT NOT NULL,
    region VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert the profile-photos bucket configuration
INSERT INTO storage_buckets (bucket_name, bucket_url, region) VALUES
('profile-photos', 'https://fa151e87de0b5708a9317ae0e5be1cd6.r2.cloudflarestorage.com/profile-photos', 'auto');

-- =====================================================
-- USER_SESSIONS TABLE
-- =====================================================
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    refresh_token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Profiles indexes
CREATE INDEX idx_profiles_user_id ON profiles(id);
CREATE INDEX idx_profiles_apple_user_id ON profiles(apple_user_id);

-- Partnerships indexes
CREATE INDEX idx_partnerships_user_id ON partnerships(user_id);
CREATE INDEX idx_partnerships_partner_id ON partnerships(partner_id);
CREATE INDEX idx_partnerships_connection_code ON partnerships(connection_code);
CREATE INDEX idx_partnerships_status ON partnerships(status);

-- Memories indexes
CREATE INDEX idx_memories_user_id ON memories(user_id);
CREATE INDEX idx_memories_partner_id ON memories(partner_id);
CREATE INDEX idx_memories_date ON memories(date);
CREATE INDEX idx_memories_created_at ON memories(created_at);
CREATE INDEX idx_memories_is_shared ON memories(is_shared);

-- Mood entries indexes
CREATE INDEX idx_mood_entries_user_id ON mood_entries(user_id);
CREATE INDEX idx_mood_entries_date ON mood_entries(date);
CREATE INDEX idx_mood_entries_created_at ON mood_entries(created_at);

-- Love messages indexes
CREATE INDEX idx_love_messages_sender_id ON love_messages(sender_id);
CREATE INDEX idx_love_messages_receiver_id ON love_messages(receiver_id);
CREATE INDEX idx_love_messages_timestamp ON love_messages(timestamp);
CREATE INDEX idx_love_messages_is_read ON love_messages(is_read);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_sent_at ON notifications(sent_at);

-- Storage files indexes
CREATE INDEX idx_storage_files_user_id ON storage_files(user_id);
CREATE INDEX idx_storage_files_file_type ON storage_files(file_type);
CREATE INDEX idx_storage_files_bucket_name ON storage_files(bucket_name);

-- Storage buckets indexes
CREATE INDEX idx_storage_buckets_bucket_name ON storage_buckets(bucket_name);
CREATE INDEX idx_storage_buckets_is_active ON storage_buckets(is_active);

-- User sessions indexes
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_partnerships_updated_at BEFORE UPDATE ON partnerships FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_memories_updated_at BEFORE UPDATE ON memories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_mood_entries_updated_at BEFORE UPDATE ON mood_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_love_messages_updated_at BEFORE UPDATE ON love_messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_storage_buckets_updated_at BEFORE UPDATE ON storage_buckets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTIONS FOR BUSINESS LOGIC
-- =====================================================

-- Function to calculate zodiac sign from birth date
CREATE OR REPLACE FUNCTION calculate_zodiac_sign(birth_date DATE)
RETURNS VARCHAR(50) AS $$
BEGIN
    RETURN CASE 
        WHEN EXTRACT(MONTH FROM birth_date) = 1 AND EXTRACT(DAY FROM birth_date) >= 20 OR
             EXTRACT(MONTH FROM birth_date) = 2 AND EXTRACT(DAY FROM birth_date) <= 18 THEN 'Aquarius'
        WHEN EXTRACT(MONTH FROM birth_date) = 2 AND EXTRACT(DAY FROM birth_date) >= 19 OR
             EXTRACT(MONTH FROM birth_date) = 3 AND EXTRACT(DAY FROM birth_date) <= 20 THEN 'Pisces'
        WHEN EXTRACT(MONTH FROM birth_date) = 3 AND EXTRACT(DAY FROM birth_date) >= 21 OR
             EXTRACT(MONTH FROM birth_date) = 4 AND EXTRACT(DAY FROM birth_date) <= 19 THEN 'Aries'
        WHEN EXTRACT(MONTH FROM birth_date) = 4 AND EXTRACT(DAY FROM birth_date) >= 20 OR
             EXTRACT(MONTH FROM birth_date) = 5 AND EXTRACT(DAY FROM birth_date) <= 20 THEN 'Taurus'
        WHEN EXTRACT(MONTH FROM birth_date) = 5 AND EXTRACT(DAY FROM birth_date) >= 21 OR
             EXTRACT(MONTH FROM birth_date) = 6 AND EXTRACT(DAY FROM birth_date) <= 20 THEN 'Gemini'
        WHEN EXTRACT(MONTH FROM birth_date) = 6 AND EXTRACT(DAY FROM birth_date) >= 21 OR
             EXTRACT(MONTH FROM birth_date) = 7 AND EXTRACT(DAY FROM birth_date) <= 22 THEN 'Cancer'
        WHEN EXTRACT(MONTH FROM birth_date) = 7 AND EXTRACT(DAY FROM birth_date) >= 23 OR
             EXTRACT(MONTH FROM birth_date) = 8 AND EXTRACT(DAY FROM birth_date) <= 22 THEN 'Leo'
        WHEN EXTRACT(MONTH FROM birth_date) = 8 AND EXTRACT(DAY FROM birth_date) >= 23 OR
             EXTRACT(MONTH FROM birth_date) = 9 AND EXTRACT(DAY FROM birth_date) <= 22 THEN 'Virgo'
        WHEN EXTRACT(MONTH FROM birth_date) = 9 AND EXTRACT(DAY FROM birth_date) >= 23 OR
             EXTRACT(MONTH FROM birth_date) = 10 AND EXTRACT(DAY FROM birth_date) <= 22 THEN 'Libra'
        WHEN EXTRACT(MONTH FROM birth_date) = 10 AND EXTRACT(DAY FROM birth_date) >= 23 OR
             EXTRACT(MONTH FROM birth_date) = 11 AND EXTRACT(DAY FROM birth_date) <= 21 THEN 'Scorpio'
        WHEN EXTRACT(MONTH FROM birth_date) = 11 AND EXTRACT(DAY FROM birth_date) >= 22 OR
             EXTRACT(MONTH FROM birth_date) = 12 AND EXTRACT(DAY FROM birth_date) <= 21 THEN 'Sagittarius'
        WHEN EXTRACT(MONTH FROM birth_date) = 12 AND EXTRACT(DAY FROM birth_date) >= 22 OR
             EXTRACT(MONTH FROM birth_date) = 1 AND EXTRACT(DAY FROM birth_date) <= 19 THEN 'Capricorn'
        ELSE 'Unknown'
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to generate connection code
CREATE OR REPLACE FUNCTION generate_connection_code()
RETURNS VARCHAR(6) AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result VARCHAR(6) := '';
    i INTEGER;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(chars, floor(random() * length(chars))::integer + 1, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS FOR AUTOMATIC ACTIONS
-- =====================================================

-- Trigger to create profile when user is created
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, name, zodiac_sign, birth_date)
    VALUES (NEW.id, NEW.name, calculate_zodiac_sign(NEW.birth_date), NEW.birth_date);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_user_profile
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_profile();

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for user profiles with partnership info
CREATE VIEW user_profiles_with_partnerships AS
SELECT 
    u.id,
    u.email,
    p.name,
    p.zodiac_sign,
    p.birth_date,
    p.profile_photo_url,
    p.relationship_status,
    p.has_children,
    p.children_count,
    p.push_token,
    p.apple_user_id,
    u.created_at,
    p.updated_at,
    CASE 
        WHEN ps.user_id = u.id THEN ps.partner_id
        WHEN ps.partner_id = u.id THEN ps.user_id
        ELSE NULL
    END as partner_id,
    ps.status as partnership_status,
    ps.connection_code
FROM users u
LEFT JOIN profiles p ON u.id = p.id
LEFT JOIN partnerships ps ON (ps.user_id = u.id OR ps.partner_id = u.id) AND ps.status = 'active';

-- View for shared memories between partners
CREATE VIEW shared_memories AS
SELECT 
    m.*,
    u1.name as user_name,
    u2.name as partner_name
FROM memories m
JOIN users u1 ON m.user_id = u1.id
LEFT JOIN users u2 ON m.partner_id = u2.id
WHERE m.is_shared = 'true';

-- =====================================================
-- SAMPLE DATA (OPTIONAL)
-- =====================================================

-- Insert sample users (passwords are hashed versions of 'password123')
INSERT INTO users (email, password_hash, name, birth_date, email_verified) VALUES
('alice@example.com', crypt('password123', gen_salt('bf')), 'Alice', '1990-05-15', true),
('bob@example.com', crypt('password123', gen_salt('bf')), 'Bob', '1988-12-03', true);

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON TABLE users IS 'Main user accounts with authentication';
COMMENT ON TABLE profiles IS 'User profile information and preferences';
COMMENT ON TABLE partnerships IS 'Connections between users (couples)';
COMMENT ON TABLE memories IS 'User memories and events';
COMMENT ON TABLE mood_entries IS 'Daily mood tracking entries';
COMMENT ON TABLE love_messages IS 'Messages between partners';
COMMENT ON TABLE notifications IS 'Push notifications and alerts';
COMMENT ON TABLE storage_files IS 'File storage metadata';
COMMENT ON TABLE storage_buckets IS 'Cloudflare R2 storage bucket configuration';
COMMENT ON TABLE user_sessions IS 'User authentication sessions';

COMMENT ON COLUMN memories.photo_data IS 'Base64 encoded image data or URL';
COMMENT ON COLUMN mood_entries.photo_data IS 'Base64 encoded image data';
COMMENT ON COLUMN partnerships.connection_code IS '6-character alphanumeric code for partner connection';
COMMENT ON COLUMN profiles.push_token IS 'Firebase/APNS push notification token';
COMMENT ON COLUMN profiles.apple_user_id IS 'Apple Sign-In user identifier';

-- =====================================================
-- GRANTS AND PERMISSIONS (ADJUST FOR YOUR SETUP)
-- =====================================================

-- Grant permissions to your application user
-- Replace 'your_app_user' with your actual database user
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_app_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_app_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO your_app_user;
