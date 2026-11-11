# Panduan pasang ciri Lupa Kata Laluan (backend iPANTAU)

Pakej ini menambah dua endpoint awam yang app iPANTAU v2.0 gunakan untuk skrin "Lupa kata laluan".

- `POST /api/auth/lupa-kata-laluan` menghantar kod 6 digit ke emel pengguna.
- `POST /api/auth/reset-kata-laluan` menyemak kod dan menetapkan kata laluan baharu.

## Fail yang berubah

| Fail | Perubahan |
|---|---|
| `controllers/authController.js` | Tambah fungsi `lupaKataLaluan` dan `resetKataLaluan`. Fungsi sedia ada tidak berubah. |
| `routes/auth.js` | Daftar dua laluan awam baharu. |
| `lib/mailer.js` | Fail baharu. Hantar emel melalui API HTTP Brevo. |
| `prisma/schema.prisma` | Model baharu `ResetKataLaluan` dan relasi pada `Pengguna`. |
| `prisma/migrations/20261021040000_add_reset_kata_laluan/` | Migrasi baharu untuk jadual `ResetKataLaluan`. |

Tiada pakej npm baharu. Kod ini guna `fetch` terbina dalam Node 18 dan ke atas.

## Kenapa Brevo dan bukan Gmail SMTP

Render menyekat trafik keluar ke port SMTP (25, 465 dan 587) untuk perkhidmatan web percuma. Nodemailer dengan Gmail SMTP akan tamat masa. Brevo menghantar emel melalui HTTPS, jadi ia berfungsi pada pelan percuma Render. Pelan percuma Brevo membenarkan 300 emel sehari dan tidak memerlukan domain sendiri.

## Langkah pemasangan

1. Salin semua fail dalam pakej ini ke dalam folder `ipantau-backend` dan gantikan fail lama.
2. Daftar akaun di brevo.com. Dalam Senders, tambah emel penghantar (contohnya Gmail anda) dan sahkan melalui pautan dalam emel.
3. Dalam Brevo, buka SMTP & API kemudian API Keys, dan cipta satu API key.
4. Dalam Render, buka servis backend kemudian Environment, dan tambah pemboleh ubah berikut.
   - `BREVO_API_KEY` dengan nilai API key tadi
   - `MAIL_FROM` dengan emel penghantar yang telah disahkan
   - `MAIL_FROM_NAME` dengan nilai `iPANTAU` (pilihan)
5. Jalankan migrasi pada pangkalan data produksi. Dari komputer anda, gunakan `DATABASE_URL` produksi dan jalankan `npx prisma migrate deploy`. Anda juga boleh tukar Build Command di Render kepada `npm install && npx prisma generate && npx prisma migrate deploy`.
6. Commit dan push ke GitLab. Render akan deploy semula.
7. Uji di telefon. Tekan "Lupa kata laluan?", masukkan emel akaun ujian, semak kod dalam emel, kemudian tetapkan kata laluan baharu.

Semasa pembangunan tempatan tanpa `BREVO_API_KEY`, pelayan tidak menghantar emel. Pelayan mencetak kandungan emel termasuk kod dalam konsol, jadi anda masih boleh menguji aliran ini.

## Peraturan keselamatan

- Respons langkah pertama sentiasa sama walaupun emel tidak berdaftar, supaya orang lain tidak boleh meneka akaun yang wujud.
- Pangkalan data hanya menyimpan hash bcrypt kod, bukan kod asal.
- Kod tamat selepas 15 minit dan hanya boleh digunakan sekali.
- Seorang pengguna boleh meminta satu kod setiap 60 saat, dan maksimum 3 kod dalam 15 minit.
- Kod terbatal selepas 5 cubaan salah.
- Akaun admin tidak boleh menggunakan aliran ini, sama seperti log masuk mudah alih.
- Kata laluan baharu mesti sekurang-kurangnya 8 aksara dengan huruf besar, huruf kecil, nombor dan simbol. Pelayan menyemak peraturan ini sendiri.

## Nota

Endpoint `PUT /auth/tukar-kata-laluan` sedia ada masih menerima kata laluan 6 aksara. App v2.0 sudah menguatkuasakan peraturan yang lebih ketat pada skrin Tukar Kata Laluan. Jika anda mahu pelayan juga menolak kata laluan lemah di situ, gunakan semula `PW_RULE` dalam fungsi `tukarKataLaluan`.
