-- Update Love Messages RLS Policies to require partner connection
-- Run this in your Supabase SQL Editor to update existing policies

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view messages they sent or received" ON love_messages;
DROP POLICY IF EXISTS "Users can insert messages they send" ON love_messages;
DROP POLICY IF EXISTS "Users can send messages" ON love_messages;
DROP POLICY IF EXISTS "Users can update messages they received" ON love_messages;

-- Create updated policies that require partner connection
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

CREATE POLICY "Users can insert messages they send" ON love_messages
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

-- Verify the policies were created
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'love_messages' 
AND schemaname = 'public'
ORDER BY policyname;
