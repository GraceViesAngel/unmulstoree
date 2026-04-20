-- Cara 1: Cari tau kolom apa saja di tabel profiles
SELECT column_name 
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profiles';

-- Cara 2: Cari tau kolom apa saja di tabel profiles dengan tipe data
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;