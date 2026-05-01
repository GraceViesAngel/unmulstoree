# Unmul Store

> **Jenis Proyek:** Aplikasi E-Commerce & Penyewaan Barang
> **Tech Stack:** Flutter (Frontend & Web), Supabase (Backend & DB)

---

## 📋 Daftar Isi

1. [Gambaran Umum](#1-gambaran-umum)
2. [Teknologi & Dependensi](#2-teknologi--dependensi)
3. [Struktur Direktori](#3-struktur-direktori)
4. [Arsitektur Aplikasi](#4-arsitektur-aplikasi)
5. [Design System](#5-design-system)
6. [Model Data](#6-model-data)
7. [Repository & Logika](#7-repository--logika)
8. [Fitur & Tampilan](#8-fitur--tampilan)
   - [8.1 Modul Autentikasi](#81-modul-autentikasi)
   - [8.2 Modul Beranda & Produk](#82-modul-beranda--produk)
   - [8.3 Modul Pemesanan & Keranjang](#83-modul-pemesanan--keranjang)
   - [8.4 Modul Admin & Superadmin](#84-modul-admin--superadmin)
9. [Widget Reusable](#9-widget-reusable)
10. [Alur Navigasi](#10-alur-navigasi)
11. [Validasi Form](#11-validasi-form)
12. [Penanganan Error & Dialog](#12-penanganan-error--dialog)
13. [Daftar Widget yang Digunakan](#13-daftar-widget-yang-digunakan)

---

## 👥 **Profil Anggota**

**Kelompok A6**

| **Nama** | **NIM** | **Kelas** | **GitHub Username** |
|-----------|----------|------------|----------------------|
| Taufik Ramadhani | 2409116001 | Sistem Informasi A '24 | [![GitHub](https://img.shields.io/badge/-superamarr-black?logo=github&style=flat-square)](https://github.com/superamarr) |
| Grace Vies Angel | 2409116005 | Sistem Informasi A '24 | [![GitHub](https://img.shields.io/badge/-Farris636-black?logo=github&style=flat-square)](https://github.com/Farris636) |
| Ahmad Sepriza | 2409116025 | Sistem Informasi A '24 | [![GitHub](https://img.shields.io/badge/-gfarlz-black?logo=github&style=flat-square)](https://github.com/gfarlz) |
| Najmi Hafizh Mauludan Zain | 2409116028 | Sistem Informasi A '24 | [![GitHub](https://img.shields.io/badge/-NajmiHafizh-black?logo=github&style=flat-square)](https://github.com/NajmiHafizh) |

---

## 1. Gambaran Umum

**Unmul Store** adalah sebuah platform aplikasi E-Commerce berbasis Flutter yang melayani sivitas akademika Universitas Mulawarman. Aplikasi ini tidak hanya melayani **pembelanjaan konvensional** (beli putus), melainkan juga melayani **penyewaan barang** (rental) dengan fitur pelacakan deposit dan denda keterlambatan.

Aplikasi menggunakan skema *Role-Based Access Control* (RBAC) yang membagi pengguna menjadi:
- **User:** Pelanggan biasa yang melakukan transaksi beli dan sewa.
- **Admin:** Pengurus pesanan yang memverifikasi pembayaran dan pengiriman barang.
- **Superadmin:** Pemegang kendali utama manajemen produk, admin, dan aturan denda sistem.

---

## 2. Teknologi & Dependensi

### Framework & Backend
- **Flutter SDK** (Target Web/Mobile)
- **Supabase** (PostgreSQL Database, Authentication, Row Level Security)

### Package / Dependensi Utama

| Package | Fungsi |
|---|---|
| `supabase_flutter` | SDK resmi untuk interaksi dengan backend database/auth |
| `go_router` | Tata kelola routing, navigasi halaman, dan proteksi/guard route |
| `google_fonts` | Tipografi aplikasi mengikuti standar Google Fonts |
| `flutter_dotenv` | Mengatur variabel environment secara lokal untuk keamanan |

---

## 3. Struktur Direktori

Aplikasi ini menggunakan pola *Feature-Driven / Clean Architecture* sederhana agar kode termodular dengan rapi.

```
unmulstoree/
│
├── lib/
│   ├── main.dart                    # Entry point aplikasi
│   │
│   ├── core/                        # Inti aplikasi
│   │   ├── theme/                   # Tema (Warna, Tipografi)
│   │   └── routing/                 # Konfigurasi GoRouter
│   │
│   ├── features/                    # Modul-modul fitur
│   │   ├── auth/                    # Login, Register, Lupa Password
│   │   ├── home/                    # Tampilan beranda pelanggan
│   │   ├── product/                 # Tampilan dan sheet detil produk
│   │   ├── order/                   # Keranjang, Pesanan, Histori Transaksi
│   │   ├── profile/                 # Kelola akun pelanggan
│   │   └── admin/                   # Modul dashboard admin dan superadmin
│   │
│   └── shared/
│       └── widgets/                 # Kumpulan widget UI yang dapat digunakan ulang
│
├── pubspec.yaml                     # Konfigurasi dependensi
└── DOCUMENTATION.md                 # Dokumentasi proyek
```

---

## 4. Arsitektur Aplikasi

Pola yang digunakan berfokus pada **Pemisahan Logika (Separation of Concerns)**, menggunakan lapisan antarmuka (Presentation) dan pengelolaan data (Domain/Data).

```
┌─────────────────────────────────────────────────────┐
│                 View (Screens)                      │
│   Home Screen ─ Cart Screen ─ Admin Dashboard       │
└─────────────────┬───────────────────────────────────┘
                  │  Memanggil Fungsi Asinkron / Menerima Data
                  ▼
┌─────────────────────────────────────────────────────┐
│            Repositories (Domain/Data)               │
│   CartRepository │ SuperAdminRepository │ dsb.      │
└─────────────────┬───────────────────────────────────┘
                  │  Query CRUD API
                  ▼
┌─────────────────────────────────────────────────────┐
│                 Backend (Supabase)                  │
│       Tabel: profiles, products, cart_items...      │
└─────────────────────────────────────────────────────┘
```

1. **View:** Menggunakan `StatefulWidget` untuk membangun UI dan sering menggunakan `setState` untuk memutakhirkan perubahan ringan, dan memanggil fungsi repo saat memuat atau menyimpan data.
2. **Repository:** Membungkus kueri Supabase `.from('tabel')` sehingga widget tidak melakukan kontak langsung dengan bahasa kueri *database*. Hal ini melindungi arsitektur.

---

## 5. Design System

Semua warna tema utama distandarkan dalam kelas `AppTheme` di dalam folder `core/theme/`.

### Palet Warna & Tipografi

Menggunakan paduan warna harmonis untuk menunjang pengalaman e-commerce yang bersih:

| Penggunaan | Warna / Keterangan |
|---|---|
| **Warna Utama (Primary)** | Hijau kebiruan/warna khas kampus (*AppTheme.primaryColor*) yang digunakan untuk tombol utama dan Badge. |
| **Aksen Bahaya (Danger)**| Merah untuk hapus item, logout, error, dan indikator telat bayar. |
| **Warna Netral**| Putih (`#FFFFFF`) untuk latar kartu, Abu-abu (`#F1F5F9` / `#64748B`) untuk kotak isian, teks penjelas. |
| **Font Dasar** | `GoogleFonts.poppins` digunakan konsisten untuk judul tebal dan isi teks agar berkesan modern. |

---

## 6. Model Data

Di dalam folder `data/models`, terdapat representasi data tabel PostgreSQL ke dalam format Class Dart.

### Contoh: `CartItemModel`

Modifikasi khusus ditambahkan pada keranjang untuk menampung fitur "Sewa".
```dart
class CartItemModel {
  final String id;
  final String productId;
  final int quantity;
  final bool isRental;        // TRUE jika item ini disewa, bukan dibeli putus
  final productData;          // Detail produk (Nama, Harga, Gambar)
}
```

### Relasi
- **Users / Profiles:** Memiliki kolom `role` (user, admin, superadmin)
- **Orders:** Memiliki flag `is_rental`, merekam catatan harga per item + *Deposit*

---

## 7. Repository & Logika

Setiap fitur memiliki fungsi Repository, misalnya `SuperAdminRepository`:

| Method | Penjelasan Logika |
|---|---|
| `getGlobalSettings()` | Mengambil nilai `default_deposit` dan `late_fee_per_day` dari profil global |
| `deleteProduct(id)` | Menghapus rententan *foreign key* produk pada `cart_items` dan `order_items` yang terkait sebelum menghapus produk seutuhnya. |
| `updateUserRole(id)`| Mengangkat atau menurunkan hak admin tanpa mencederai autentikasi dasar Supabase Auth. |

---

## 8. Fitur & Tampilan

Berikut detail fitur spesifik dari tiap modul utama dan *mockup* layar.

### 8.1 Modul Autentikasi (`lib/features/auth`)

Fitur otentikasi komprehensif bagi segala keperluan portal masuk kampus Store.

| Identifikasi Layar | Komponen / Widget Penting | Tampilan |
| :--- | :--- | :--- |
| **Welcome / Splash** | Transisi logo, Deteksi Session awal | *[Gambar Welcome]* |
| **Login & Register** | TextField kustom berseni, Validasi Panjang, Regex Email | <img width="325" height="701" alt="image" src="https://github.com/user-attachments/assets/f769977c-dab3-412b-9739-0c81d91c00b6" /> |
| **Forgot Password** | Kirim Reset Link ke Email User | <img width="319" height="695" alt="image" src="https://github.com/user-attachments/assets/8b98b9be-599b-49ce-97fe-0aaa7de87dd8" /> |

### 8.2 Modul Beranda & Produk (`lib/features/home` & `product`)

| Identifikasi Layar | Komponen / Widget Penting | Tampilan |
| :--- | :--- | :--- |
| **Beranda Layar Utama** | `CarouselSlider` promo Banner, `GridView` untuk etalase katalog, Kategori badge | <img width="318" height="698" alt="image" src="https://github.com/user-attachments/assets/f54c9eec-9336-41dc-a601-5c7804de8087" /> |
| **Detail Produk & Sheet** | Gambar penuh `SliverAppBar`, Pilihan variasi dengan tombol aksi (Beli / Sewa) -> Membuka `BottomSheet` ringkasan. | <img width="320" height="699" alt="image" src="https://github.com/user-attachments/assets/98d6bfc9-76e9-4848-84b9-78d7df5593ff" /> |

### 8.3 Modul Pemesanan & Keranjang (`lib/features/order`)

Mekanisme checkout dengan sistem sewa yang menuntut pendataan tambahan (Lama Hari + Uang Jaminan).

| Identifikasi Layar | Komponen / Widget Penting | Tampilan |
| :--- | :--- | :--- |
| **Keranjang Belanja** | List panjang, hitungan Subtotal harga (jika sewa + Rp.50.000 deposit x Jumlah) | <img width="319" height="695" alt="image" src="https://github.com/user-attachments/assets/4a301c02-a1a5-43d0-b94a-9d354078f458" /> |
| **Checkout/Pembayaran** | *ListTile* form Alamat Wajib, Rincian Kalkulasi Harga Ongkir Cepat / Reguler | <img width="324" height="695" alt="image" src="https://github.com/user-attachments/assets/eb8458f8-3beb-46d4-aa1b-9ca0ebdb543e" /> |
| **Status Pesanan**| Tampilan historis jejak resi status pesanan (*Diproses*, *Dikirim* dsb) dengan `Badge` | <img width="313" height="694" alt="image" src="https://github.com/user-attachments/assets/ae0eb0a6-4da0-4079-a4c3-15c2ff6fd9c3" /> |

### 8.4 Modul Admin & Superadmin (`lib/features/admin`)

Khusus untuk peran istimewa. Mengelola verifikasi pengguna.

| Identifikasi Layar | Komponen / Widget Penting | Tampilan |
| :--- | :--- | :--- |
| **Panel Pesanan (Admin)** | `TabBarView` memuat status antrian "Masuk", "Sedang Dikirim", "Selesai" | <img width="319" height="697" alt="image" src="https://github.com/user-attachments/assets/544580ae-8cd5-4221-926c-749d948b9be9" /> |
| **Monitor Denda (Admin)** | List keterlambatan pengguna. Tombol memotong deposit denda | *[Gambar Denda]* |
| **Kelola Sistem (Sp-Admin)** | Edit nilai dasar denda harian (Rp 20.000) per aplikasi seluruh sistem | |
| **Kelola Admin & Produk** | Menghapus akses `role`. **Optimistic UI Update** untuk percepat loading render. | <img width="319" height="698" alt="image" src="https://github.com/user-attachments/assets/81486335-1e0b-453d-9002-d266d3f34161" /> <img width="320" height="691" alt="image" src="https://github.com/user-attachments/assets/b47373b8-028c-4187-bee2-25bfc95a2b6f" /> |

---

## 9. Widget Reusable

Untuk menjaga konsistensi tampilan antar modul.

- **`CustomTextField`** : Input elegan dengan border radius membulat, bayangan, abu-abu pelan dan ikon dukungan `prefixIcon`.
- **`PrimaryButton`** : Tombol dasar tebal berisikan `bool isLoading` (mengganti tulisan dengan pusaran animasi loading saat jaringan lama).
- **`ConfirmActionSheet`** : Dialog khusus meminta penegasan pembatalan atau hapus sebelum merusak data.

---

## 10. Alur Navigasi

Routing berpusat di `main.dart` dan `core/routing` menggunakan rute dinamis layaknya web.

Alur Khasnya:
`Welcome -> Login -> (Otorisasi Sukses) -> Penentuan Role`
- Profil = **Superadmin** -> `SuperadminMainScreen()`
- Profil = **Admin** -> `AdminDashboardScreen()`
- Profil = **User** -> `MainLayoutScreen()` (Dengan Bottom Navigation untuk akses Home dan Cart)

Jika status *session* putus di tengah jalan, router memukul paksa layar kembali ke Welcome Screen.

---

## 11. Validasi Form

Beberapa validasi utama di Aplikasi:
| Layar/Input | Aturan Validasi |
|---|---|
| **Register** | Email wajib berformat Valid (`@`). Password min. 6 huruf. |
| **Checkout** | Menolak checkout bila Alamat/No HP di database belum lengkap. |
| **Tambah Admin** | Menolak email kosong, nama kosong, deteksi email duplikat di Log Supabase. |
| **Sewa Item** | Kuantitas tidak boleh 0. Durasi hari Default 3 Hari diset otomatis jika sewa. |

---

## 12. Penanganan Error & Dialog

Pesan kegagalan disajikan ramah dan informatif menggunakan `ScaffoldMessenger.of(context).showSnackBar()`.

- **Hapus Admin:** Muncul `ConfirmActionSheet` ("Apakah yakin menghapus hak admin ini?").
- **Hapus Produk:** Jika terbentur sistem DB riwayat order, modul `SuperAdminRepository` menangani *silent clear* terlebih dahulu sebelum melempar dialog "Berhasil".
- **Error Jaringan:** Dipecah khusus. Jika error auth di Supabase adalah "rate limit", dimunculkan pesan *"Terlalu banyak permintaan. Tunggu sebentar"*.

---

## 13. Daftar Widget yang Digunakan

| Kategori | Widget yg Dipakai | Kegunaan dalam Proyek |
|---|---|---|
| **Struktural** | `Scaffold`, `AppBar`, `Column`, `Row`, `Expanded` | Rangka utama setiap halaman (*screens*) |
| **Input Elemen** | `TextFormField`, `TextEditingController` | Memungkinkan ketikan dan modifikasi pada Register/Tambah Produk |
| **Tombol** | `FloatingActionButton`, `ElevatedButton`, `TextButton`, `IconButton` | Sebagai pelatuk interaksi `onPressed` submit data navigasi |
| **Daftar & Scroll**| `ListView.builder`, `SingleChildScrollView`, `SliverAppBar`, `GridView` | Membentuk etalase grid produk maupun list riwayat tanpa *overflow* layar |
| **Penegasan (UI)**| `ClipRRect`, `Card`, `Container`, `Divider` | Pembentuk pembatas bayangan box untuk kartu produk / daftar isi |
| **Dialoging** | `AlertDialog`, `SnackBar`, `BottomSheet` | Memunculkan interupsi layar layaknya tambah varian barang / konfirmasi |
| **Sistem State** | `setState`, `FutureBuilder`, `StatefulWidget` | Mengikat siklus data *real-time* Supabase (contoh memuat Admin Profile) |
