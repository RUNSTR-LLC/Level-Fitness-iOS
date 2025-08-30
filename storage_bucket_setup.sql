-- Storage Bucket Setup for RunstrRewards
-- Run this in your Supabase SQL Editor

-- Create profile-images bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('profile-images', 'profile-images', true, 5242880, '{"image/*"}')
ON CONFLICT (id) DO NOTHING;

-- Create team-images bucket if it doesn't exist  
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('team-images', 'team-images', true, 10485760, '{"image/*"}')
ON CONFLICT (id) DO NOTHING;

-- Verify buckets were created
SELECT 
    'STORAGE BUCKETS' as check_type,
    id as bucket_name,
    CASE WHEN public THEN '✅ PUBLIC' ELSE '❌ PRIVATE' END as access_level,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id IN ('profile-images', 'team-images');

-- Check if any buckets exist at all
SELECT 'BUCKET COUNT' as check_type, COUNT(*) as total_buckets FROM storage.buckets;