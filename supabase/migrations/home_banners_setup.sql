-- 1. Buat tabel home_banners
CREATE TABLE IF NOT EXISTS public.home_banners (
  slot smallint PRIMARY KEY CHECK (slot >= 1 AND slot <= 3),
  image_url text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2. Enable RLS
ALTER TABLE public.home_banners ENABLE ROW LEVEL SECURITY;

-- 3. Policies untuk tabel home_banners
DROP POLICY IF EXISTS "home_banners_select_public" ON public.home_banners;
CREATE POLICY "home_banners_select_public"
ON public.home_banners FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "home_banners_admin_insert" ON public.home_banners;
CREATE POLICY "home_banners_admin_insert"
ON public.home_banners FOR INSERT
TO authenticated
WITH CHECK (public.pab_is_admin());

DROP POLICY IF EXISTS "home_banners_admin_update" ON public.home_banners;
CREATE POLICY "home_banners_admin_update"
ON public.home_banners FOR UPDATE
TO authenticated
USING (public.pab_is_admin())
WITH CHECK (public.pab_is_admin());

DROP POLICY IF EXISTS "home_banners_admin_delete" ON public.home_banners;
CREATE POLICY "home_banners_admin_delete"
ON public.home_banners FOR DELETE
TO authenticated
USING (public.pab_is_admin());

-- 4. Buat bucket banners (abaikan jika sudah ada)
INSERT INTO storage.buckets (id, name, public)
VALUES ('banners', 'banners', true)
ON CONFLICT (id) DO NOTHING;

-- 5. Policies untuk storage bucket banners
DROP POLICY IF EXISTS "banners_public_read" ON storage.objects;
CREATE POLICY "banners_public_read"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'banners');

DROP POLICY IF EXISTS "banners_admin_insert" ON storage.objects;
CREATE POLICY "banners_admin_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'banners' AND public.pab_is_admin());

DROP POLICY IF EXISTS "banners_admin_update" ON storage.objects;
CREATE POLICY "banners_admin_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'banners' AND public.pab_is_admin())
WITH CHECK (bucket_id = 'banners' AND public.pab_is_admin());

DROP POLICY IF EXISTS "banners_admin_delete" ON storage.objects;
CREATE POLICY "banners_admin_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'banners' AND public.pab_is_admin());
