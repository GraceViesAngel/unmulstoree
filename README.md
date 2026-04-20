# <h1 align="center">UNMUL STORE</h1>

---

### Nama Kelompok : (Constellation)
### Anggota :
- TAUFIK RAMADHANI (2409116001)
- Grace Vies Angel (2409116005)
- AHMAD SEPRIZA (2409116025)
- Najmi Hafizh Mauludan Zain (2409116028)  
### Kelas : A'2024

---

## Deskripsi Aplikasi

Unmul Store merupakan platform resmi Universitas Mulawarman yang menyediakan berbagai kebutuhan mahasiswa seperti merchandise, produk kampus, serta penyewaan toga. Selama ini, proses pemesanan masih dilakukan secara manual, baik dengan datang langsung ke lokasi maupun melalui komunikasi terpisah, sehingga sering menimbulkan kendala seperti informasi produk yang kurang jelas, pencatatan pesanan yang tidak rapi, serta proses yang kurang efisien.

Berdasarkan permasalahan tersebut, kami mengembangkan aplikasi Unmul Store sebagai solusi untuk membantu merapikan dan mempermudah seluruh proses pemesanan dalam satu sistem. Melalui aplikasi ini, pengguna dapat melihat produk, menambahkan ke keranjang, melakukan checkout, serta mengetahui status pesanan secara langsung.

Selain itu, aplikasi ini juga mendukung pengelolaan sistem oleh admin dan super admin, sehingga proses pengelolaan produk, pesanan, dan data menjadi lebih terstruktur. Dengan adanya aplikasi ini, kami berharap layanan di Unmul Store menjadi lebih efisien, mudah digunakan, dan dapat diakses kapan saja.

---

## Fitur Aplikasi

Berikut merupakan fitur utama yang terdapat dalam aplikasi Unmul Store:

| Fitur | Deskripsi |
|------|----------|
| Login & Register | Digunakan untuk autentikasi pengguna sebelum masuk ke aplikasi |
| Home / Dashboard | Menampilkan halaman utama aplikasi |
| Katalog Produk | Menampilkan daftar produk dan detail produk |
| Keranjang | Menyimpan produk yang akan dibeli |
| Checkout | Proses pemesanan produk |
| Status Pesanan | Menampilkan status pesanan pengguna |
| Profil Pengguna | Menampilkan dan mengelola data pengguna |
| Admin Panel | Mengelola produk dan pesanan | 

---

## Struktur Project


Struktur project digunakan untuk menyusun kode aplikasi agar rapi dan mudah dipahami. Setiap susunan memiliki fungsi masing-masing sehingga tidak tercampur dan lebih mudah saat dikembangkan.

### Folder

- **lib**  
  Folder ini merupakan bagian paling penting dalam project, karena seluruh kode utama aplikasi ada di sini. Dari fitur, tampilan, dan logika aplikasi kami buat di dalam folder ini.

- **assets**  
  Digunakan untuk menyimpan gambar, icon, atau file pendukung lainnya. Folder ini, mengatur file gambar dengan lebih rapi dan mudah digunakan di berbagai halaman.

- **test**  
  Folder ini biasanya digunakan untuk pengujian aplikasi. Walaupun tidak selalu digunakan secara maksimal, folder ini tetap disediakan oleh Flutter untuk memastikan aplikasi bisa diuji dengan baik.

- **pubspec.yaml**  
  File ini digunakan untuk mengatur library (dependency) yang dipakai dalam project, serta mendaftarkan assets seperti gambar agar bisa digunakan di dalam aplikasi.


---

### Struktur Features

- **auth** → login, register, dan autentikasi  
- **home** → halaman utama aplikasi  
- **product** → daftar dan detail produk  
- **cart** → keranjang belanja  
- **order** → checkout dan status pesanan  
- **profile** → data pengguna  
- **admin** → pengelolaan produk dan pesanan  
- **superadmin** → pengelolaan sistem secara keseluruhan  

---

## Widget yang Digunakan

Dalam pengembangan aplikasi ini, kami menggunakan beberapa widget utama dari Flutter untuk membangun tampilan dan interaksi pengguna.

| Widget | Fungsi |
|--------|--------|
| StatelessWidget | Digunakan untuk halaman yang tidak berubah |
| StatefulWidget | Digunakan untuk halaman yang memiliki interaksi atau perubahan data |
| Scaffold | Struktur dasar halaman seperti appbar dan body |
| SafeArea | Menyesuaikan tampilan agar tidak tertutup oleh sistem (notch, dll) |
| AppBar | Menampilkan bagian header aplikasi |
| Column & Row | Mengatur susunan tampilan secara vertikal dan horizontal |
| Stack | Menumpuk beberapa widget dalam satu area |
| Container | Mengatur ukuran, warna, dan tampilan komponen |
| Padding & Margin | Memberi jarak antar elemen agar tidak terlalu rapat |
| Text | Menampilkan teks |
| Image | Menampilkan gambar dari assets atau network |
| Icon | Menampilkan ikon |
| TextField | Input data dari pengguna |
| ElevatedButton | Tombol untuk aksi utama |
| GestureDetector / InkWell | Mendeteksi interaksi seperti klik atau tap |
| ListView | Menampilkan data dalam bentuk list (scroll) |
| GridView | Menampilkan data dalam bentuk grid |
| Card | Membungkus tampilan agar terlihat lebih rapi |
| Navigator | Digunakan untuk berpindah antar halaman |
| FutureBuilder / StreamBuilder | Menampilkan data dari proses async (misalnya dari database) |

---

## Alur Aplikasi

### Alur Pengguna (User)

1. Pengguna membuka aplikasi  
2. Login atau melakukan registrasi  
3. Masuk ke halaman utama  
4. Melihat produk yang tersedia  
5. Menambahkan produk ke keranjang  
6. Melakukan checkout  
7. Melihat status pesanan  
8. Selesai  

---

### Alur Admin

1. Admin login ke dalam sistem  
2. Masuk ke halaman dashboard admin  
3. Mengelola data produk (tambah, edit, hapus)  
4. Melihat dan mengelola pesanan pengguna  
5. Memperbarui status pesanan (diproses, selesai, dll)  
6. Menyimpan perubahan data  
7. Selesai  

---

### Alur Super Admin

1. Super admin login ke dalam sistem  
2. Masuk ke halaman dashboard super admin  
3. Mengelola data sistem secara keseluruhan  
4. Mengatur data admin dan pengguna  
5. Mengontrol data produk dan pesanan  
6. Melakukan pengaturan tambahan jika diperlukan  
7. Selesai  


---

## Logika Sistem

Logika sistem digunakan untuk mengatur bagaimana data diproses dan bagaimana fitur dalam aplikasi berjalan. Bagian ini memastikan setiap aksi pengguna, seperti login, memilih produk, hingga melakukan pemesanan, dapat berjalan sesuai alur.

Setiap fitur memiliki logika masing-masing, misalnya:
- **auth** → mengatur login dan validasi pengguna  
- **product** → menampilkan data produk  
- **cart** → menyimpan produk sementara  
- **order** → memproses checkout dan status pesanan  

Aplikasi ini juga terhubung dengan Supabase, sehingga data seperti produk, pengguna, dan pesanan dapat disimpan dan diambil secara langsung dari database.

---

## Kesimpulan

Aplikasi Unmul Store dibuat untuk membantu proses pemesanan yang sebelumnya dilakukan secara manual menjadi lebih terstruktur dan efisien. Dengan adanya aplikasi ini, pengguna dapat melakukan pemesanan dengan lebih mudah, serta pengelolaan data menjadi lebih rapi dan terorganisir.

---


