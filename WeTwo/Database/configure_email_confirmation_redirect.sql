-- Configure Email Confirmation Redirect URLs for WeTwo App
-- Run this in your Supabase SQL Editor

-- Update the auth.users table to set custom email confirmation redirect URLs
-- This will make Supabase send confirmation emails with links that open the WeTwo app

-- First, let's check the current auth configuration
SELECT 
    key,
    value
FROM auth.config 
WHERE key LIKE '%email%' OR key LIKE '%redirect%';

-- Update the email confirmation redirect URL to use the WeTwo app scheme
-- Replace 'wetwo://' with your actual URL scheme if different
UPDATE auth.config 
SET value = 'wetwo://email-confirmation'
WHERE key = 'email_confirmation_redirect_url';

-- If the above doesn't work, we can also set it via the Supabase dashboard:
-- 1. Go to Authentication > Settings
-- 2. Find "Redirect URLs" section
-- 3. Add: wetwo://email-confirmation
-- 4. Save the changes

-- Alternative: Set up a custom email template with the app URL scheme
-- This would require creating a custom email template in Supabase

-- For development/testing, you can also use a web URL that redirects to the app:
-- UPDATE auth.config 
-- SET value = 'https://your-domain.com/email-confirmation'
-- WHERE key = 'email_confirmation_redirect_url';

-- Verify the configuration
SELECT 
    key,
    value
FROM auth.config 
WHERE key = 'email_confirmation_redirect_url';

-- Note: You may need to restart your Supabase project for changes to take effect
-- Also ensure your app's URL scheme is properly configured in Xcode
