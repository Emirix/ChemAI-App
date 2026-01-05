-- Lütfen bu dosyanın tamamını (Ctrl+A) kopyaladığınızdan emin olun.
-- Eksik karakter kopyalanması hata verebilir.

DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read" ON storage.objects;

-- 1. Yükleme İzni (Upload)
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'lab-attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 2. Güncelleme İzni (Update)
CREATE POLICY "Allow authenticated updates"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'lab-attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Silme İzni (Delete)
CREATE POLICY "Allow authenticated deletes"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'lab-attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. Okuma İzni (Select - Public)
CREATE POLICY "Allow public read"
ON storage.objects FOR SELECT
TO public
USING ( bucket_id = 'lab-attachments' );
