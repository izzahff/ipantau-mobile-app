# Reset kata laluan melalui emel (keperluan backend)

App iPANTAU v2.0 kini ada skrin "Lupa kata laluan" yang memanggil dua endpoint baharu. Backend perlu menyediakan kedua-dua endpoint ini sebelum ciri tersebut berfungsi. Sehingga itu, app akan memaparkan mesej "Ciri ini belum tersedia di pelayan." apabila pelayan memulangkan 404.

## Aliran

1. Pengguna memasukkan emel dan menekan "Hantar kod".
2. Backend menjana kod 6 digit, menyimpan hash kod tersebut bersama masa tamat (15 minit), dan menghantar kod ke emel pengguna.
3. Pengguna memasukkan kod dan kata laluan baharu.
4. Backend menyemak kod, menukar kata laluan, dan membatalkan kod itu.

## Endpoint 1 `POST /api/auth/lupa-kata-laluan`

Badan permintaan

```json
{ "email": "ali@majujaya.com.my" }
```

Respons (sentiasa sama, walaupun emel tidak berdaftar, supaya orang lain tidak boleh meneka emel yang wujud)

```json
{ "success": true, "message": "Jika emel berdaftar, kod telah dihantar." }
```

Peraturan

- Jana kod rawak 6 digit dengan `crypto.randomInt(0, 1000000)`, kemudian pad kepada 6 aksara.
- Simpan hash kod (bcrypt), bukan kod asal.
- Tamat tempoh selepas 15 minit.
- Hadkan permintaan, contohnya maksimum 3 permintaan setiap 15 minit bagi setiap emel, dan sekat permintaan berulang dalam 60 saat (app sudah ada kiraan masa 60 saat).
- Permintaan baharu membatalkan kod lama bagi emel yang sama.

## Endpoint 2 `POST /api/auth/reset-kata-laluan`

Badan permintaan

```json
{ "email": "ali@majujaya.com.my", "kod": "482913", "kata_laluan_baru": "Pantau#2026" }
```

Respons berjaya

```json
{ "success": true, "message": "Kata laluan berjaya ditetapkan semula." }
```

Respons gagal (HTTP 400)

```json
{ "success": false, "message": "Kod tidak sah atau telah tamat tempoh." }
```

Peraturan

- Tolak selepas 5 cubaan salah bagi satu kod, dan batalkan kod tersebut.
- Semak semula peraturan kata laluan di pelayan (sekurang-kurangnya 8 aksara, 1 huruf besar, 1 huruf kecil, 1 nombor, 1 simbol). App juga menyemak, tetapi pelayan tidak boleh bergantung pada app.
- Hash kata laluan baharu dengan kaedah yang sama seperti `/auth/tukar-kata-laluan`.
- Tandakan kod sebagai sudah digunakan selepas berjaya.

## Cadangan jadual

```sql
CREATE TABLE reset_kata_laluan (
  id           SERIAL PRIMARY KEY,
  pengguna_id  INTEGER NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
  kod_hash     TEXT NOT NULL,
  tamat_pada   TIMESTAMPTZ NOT NULL,
  cubaan       INTEGER NOT NULL DEFAULT 0,
  digunakan    BOOLEAN NOT NULL DEFAULT FALSE,
  dicipta_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Nama jadual `pengguna` dan lajur mengikut andaian. Sila sesuaikan dengan skema sebenar.

## Contoh kod Express

Contoh ini menganggap Express, `pg` (PostgreSQL), `bcrypt` dan `nodemailer`. Sesuaikan `db`, nama lajur dan konfigurasi SMTP dengan projek backend sebenar.

```js
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const nodemailer = require('nodemailer');

const mailer = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT || 587),
  auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
});

const GENERIC = { success: true, message: 'Jika emel berdaftar, kod telah dihantar.' };
const PW_RULE = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$/;

router.post('/auth/lupa-kata-laluan', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const { rows } = await db.query('SELECT id, nama FROM pengguna WHERE email = $1', [email]);
  if (!rows.length) return res.json(GENERIC);
  const user = rows[0];

  const recent = await db.query(
    "SELECT 1 FROM reset_kata_laluan WHERE pengguna_id = $1 AND dicipta_pada > NOW() - INTERVAL '60 seconds'",
    [user.id],
  );
  if (recent.rows.length) return res.json(GENERIC);

  const kod = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
  await db.query('UPDATE reset_kata_laluan SET digunakan = TRUE WHERE pengguna_id = $1 AND digunakan = FALSE', [user.id]);
  await db.query(
    "INSERT INTO reset_kata_laluan (pengguna_id, kod_hash, tamat_pada) VALUES ($1, $2, NOW() + INTERVAL '15 minutes')",
    [user.id, await bcrypt.hash(kod, 10)],
  );

  await mailer.sendMail({
    from: process.env.SMTP_FROM,
    to: email,
    subject: 'Kod tetapan semula kata laluan iPANTAU',
    text: `Salam ${user.nama},\n\nKod anda ialah ${kod}. Kod ini sah selama 15 minit.\n\nJika anda tidak meminta kod ini, abaikan emel ini.`,
  });
  return res.json(GENERIC);
});

router.post('/auth/reset-kata-laluan', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const kod = String(req.body.kod || '').trim();
  const baru = String(req.body.kata_laluan_baru || '');
  const fail = () => res.status(400).json({ success: false, message: 'Kod tidak sah atau telah tamat tempoh.' });

  if (!PW_RULE.test(baru)) {
    return res.status(400).json({ success: false, message: 'Kata laluan baharu tidak memenuhi syarat.' });
  }

  const { rows } = await db.query(
    `SELECT r.id, r.kod_hash, r.cubaan, p.id AS pengguna_id
       FROM reset_kata_laluan r JOIN pengguna p ON p.id = r.pengguna_id
      WHERE p.email = $1 AND r.digunakan = FALSE AND r.tamat_pada > NOW()
      ORDER BY r.dicipta_pada DESC LIMIT 1`,
    [email],
  );
  if (!rows.length) return fail();
  const r = rows[0];

  if (r.cubaan >= 5 || !(await bcrypt.compare(kod, r.kod_hash))) {
    await db.query('UPDATE reset_kata_laluan SET cubaan = cubaan + 1, digunakan = (cubaan + 1 >= 5) WHERE id = $1', [r.id]);
    return fail();
  }

  await db.query('UPDATE pengguna SET kata_laluan = $1 WHERE id = $2', [await bcrypt.hash(baru, 10), r.pengguna_id]);
  await db.query('UPDATE reset_kata_laluan SET digunakan = TRUE WHERE id = $1', [r.id]);
  return res.json({ success: true, message: 'Kata laluan berjaya ditetapkan semula.' });
});
```

## Pemboleh ubah persekitaran (Render)

`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`. Untuk Gmail, gunakan App Password, bukan kata laluan akaun biasa.
