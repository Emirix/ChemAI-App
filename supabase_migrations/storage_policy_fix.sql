-- NOT: Lutfen once Supabase Panelinden 'Storage' menusune gidip
-- 'lab-attachments' adinda PUBLIC bir bucket olusturun.

-- Mevcut politikalari temizle (hata verirse onemsemeyin)
drop policy if exists "Allow authenticated uploads" on storage.objects;
drop policy if exists "Allow authenticated updates" on storage.objects;
drop policy if exists "Allow authenticated deletes" on storage.objects;
drop policy if exists "Allow public read" on storage.objects;

-- 1. Yukleme Izni (Upload)
-- Kullanicilarin kendi klasorlerine (user_id) yukleme yapmasina izin verir
create policy "Allow authenticated uploads"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'lab-attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 2. Guncelleme Izni (Update)
create policy "Allow authenticated updates"
on storage.objects for update
to authenticated
using (
  bucket_id = 'lab-attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Silme Izni (Delete)
create policy "Allow authenticated deletes"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'lab-attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. Okuma Izni (Select - Public)
-- Herkesin dosyalari okumasina izin verir (Public bucket oldugu icin)
create policy "Allow public read"
on storage.objects for select
to public
using ( bucket_id = 'lab-attachments' );
