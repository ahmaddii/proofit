-- Create the bucket if it doesn't exist (you might have done this via UI already)
insert into storage.buckets (id, name, public)
values ('proof-video', 'proof-video', false)
on conflict (id) do nothing;

-- POLICY 1: Allow Authenticated Users to Upload (INSERT)
-- This allows any authenticated user to upload a file to the 'proof-video' bucket,
-- PROVIDED the file path starts with their User ID.
create policy "Allow authenticated uploads"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'proof-video' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- POLICY 2: Allow Users to View/Download their own files (SELECT)
-- This allows users to download files from 'proof-video' if the path starts with their User ID.
create policy "Allow users to view own video proofs"
on storage.objects for select
to authenticated
using (
  bucket_id = 'proof-video' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- POLICY 3: Allow Users to Update their own files (if needed)
create policy "Allow users to update own video proofs"
on storage.objects for update
to authenticated
using (
  bucket_id = 'proof-video' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- POLICY 4: Allow Users to Delete their own files
create policy "Allow users to delete own video proofs"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'proof-video' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
