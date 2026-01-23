-- Enable RLS on proofs table (if not already enabled)
ALTER TABLE proofs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can INSERT their own proofs
CREATE POLICY "Users can insert their own proofs"
ON proofs
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can SELECT their own proofs
CREATE POLICY "Users can view their own proofs"
ON proofs
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Users can UPDATE their own proofs (only if not locked)
CREATE POLICY "Users can update their own unlocked proofs"
ON proofs
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id AND locked_flag = false)
WITH CHECK (auth.uid() = user_id AND locked_flag = false);

-- Policy: Users can DELETE their own proofs (only if not locked)
CREATE POLICY "Users can delete their own unlocked proofs"
ON proofs
FOR DELETE
TO authenticated
USING (auth.uid() = user_id AND locked_flag = false);

-- Enable RLS on user_profiles table (if not already enabled)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can INSERT their own profile
CREATE POLICY "Users can insert their own profile"
ON user_profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Policy: Users can SELECT their own profile
CREATE POLICY "Users can view their own profile"
ON user_profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Policy: Users can UPDATE their own profile
CREATE POLICY "Users can update their own profile"
ON user_profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- ============================================
-- STORAGE BUCKET POLICIES
-- ============================================

-- Create storage buckets if they don't exist (run this in Supabase Dashboard > Storage)
-- Note: You need to create these buckets manually in the Storage section first

-- Policy for proof-media bucket: Users can upload to their own folder
CREATE POLICY "Users can upload to their own folder in proof-media"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'proof-media' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy for proof-media bucket: Users can read their own files
CREATE POLICY "Users can read their own files in proof-media"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'proof-media' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy for proof-media bucket: Users can delete their own files
CREATE POLICY "Users can delete their own files in proof-media"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'proof-media' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy for proof-audio bucket: Users can upload to their own folder
CREATE POLICY "Users can upload to their own folder in proof-audio"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'proof-audio' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy for proof-audio bucket: Users can read their own files
CREATE POLICY "Users can read their own files in proof-audio"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'proof-audio' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy for proof-audio bucket: Users can delete their own files
CREATE POLICY "Users can delete their own files in proof-audio"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'proof-audio' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
