# Daftar Uji — Game Utuh

Status: **SAPU-SAPU SUNGAI sekarang punya cerita utuh dari pembuka sampai kesimpulan**,
papan instruksi tiap bab, nama pemain, dan layar MISI SELESAI.

Jalankan seperti biasa (**F5**) — scene utamanya menu.

```
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

---

## Peta alur

```
   pertama kali main
          │
          ▼
   ┌─────────────┐
   │ SIAPA NAMAMU│   ← kotak nama, sekali seumur simpanan
   └──────┬──────┘
          ▼
   ┌──────────────┐
   │  MENU UTAMA  │◄──────────────────────────────────┐
   │  "Hai, ...!" │                                   │
   └──────┬───────┘                                   │
   ┌──────┼───────┬──────────┬─────────┐              │
   ▼      ▼       ▼          ▼         ▼              │
Lanjut  Mulai   Pilih    Pengaturan  Kredit           │
        Baru     Bab                                  │
   └──────┴───────┘                                   │
          │                                           │
          ▼   ── rantai masuk bab ──                  │
   ┌─────────────┐   ┌──────────────┐   ┌────────┐    │
   │  CUTSCENE   │──▶│    PAPAN     │──▶│  BAB   │    │
   │  (sekali)   │   │  INSTRUKSI   │   │        │    │
   └─────────────┘   └──────────────┘   └───┬────┘    │
                                            │         │
                              menang ───────┴─ kalah  │
                                 │               │    │
                                 ▼               ▼    │
                        ┌────────────────┐  layar hasil
                        │  MISI SELESAI  │       │    │
                        │  bintang·skor  │       └────┤
                        │ rekor·terbuka  │            │
                        └───────┬────────┘            │
                                ▼                     │
                          bab berikutnya              │
                                                      │
   Bab 3 tamat ─▶ MISI SELESAI ─▶ "SUNGAI LANCAR"     │
                                        │             │
                                        ▼             │
                              CUTSCENE PENUTUP ───────┘
```

Esc kapan saja di dalam bab → **menu jeda** (lanjutkan / **papan instruksi** / ulangi /
pilih bab / menu utama).

---

## Sudah diuji otomatis — tidak perlu diulang

**Nama pemain**
- Pemain baru disambut kotak nama, bukan menu penuh
- Spasi di ujung dipangkas; nama dibatasi 14 huruf
- Nama masuk ke naskah cutscene ("Namaku Akyas.")
- Nama bertahan setelah game ditutup dan dibuka lagi
- Sapaan punya cadangan "Wader" — tidak pernah ada "Hai, !"

**Mulai baru**
- Menghapus progres, skor, dan jejak cerita — **tapi nama dan volume dipertahankan**

**Rantai cerita → papan instruksi → peta**
- Ketiga langkahnya berurutan dan masing-masing hilang sendiri setelah dilewati
- Melewati cutscene (Esc) tetap dihitung sudah ditonton
- Papan instruksi ketiga bab lengkap: tujuan, kontrol, bahaya, dan cara mengatasinya
- Cutscene penutup 6 panel dan berakhir menyebut sungai sungguhan

**MISI SELESAI**
- Bintang naik bertahap: 900→1, 1500→2, 2000→3 (Bab 1)
- "REKOR BARU" hanya muncul saat skornya benar-benar melewati rekor lama
- Lencana rencana sempurna, rekor, dan bab yang terbuka semuanya tampil

**Yang lama, masih lulus**
- Progres tersimpan dan terbaca lagi; gerbang bab terkunci; menu jeda; Esc di layar hasil
- Kesepuluh scene dimuat tanpa error

---

## A. Kesan pertama (paling penting — minta orang yang belum pernah lihat)

- [ ] Kotak nama di awal terasa menyambut, atau menghalangi?
- [ ] "Hai, [nama]!" di menu terasa personal, atau berlebihan?
- [ ] Cutscene pembuka: **berapa panel sampai Anda ingin melewatinya?** (catat jujur)
- [ ] Teks mengetiknya kecepatannya pas?
- [ ] Panel pertama menjelaskan siapa Anda dan kenapa harus peduli?

## B. Papan instruksi

- [ ] Setelah membacanya, Anda tahu harus apa **tanpa** mencoba dulu?
- [ ] Tiga kolom (gerak / bahaya / cara) kebacaan atau kepadatan?
- [ ] Ada yang masih membingungkan setelah membacanya? (**tulis yang mana**)
- [ ] Buka lagi dari menu jeda di tengah main — rondenya benar-benar tidak hilang?
- [ ] Papan Bab 3 menjelaskan aturan AMAN/DERAS dengan cukup jelas?

## C. MISI SELESAI

- [ ] Skor berhitung naik + bintang menyala satu-satu: terasa sebagai hadiah?
- [ ] Atau justru terlalu lama menunggu sebelum bisa lanjut?
- [ ] Tiga bintang terasa mungkin diraih, atau mustahil?
- [ ] Sungai bersih yang kelihatan di belakang panel — membantu, atau ramai?

## D. Alur cerita

- [ ] Empat babak cerita terasa nyambung jadi satu?
- [ ] Kesimpulan di penutup terasa **didapat dari main**, atau ditempel di akhir?
- [ ] Bagian mana yang paling mengena? Bagian mana yang datar?

## E. Rantai penuh (main dari nol)

- [ ] Mulai baru, lalu tamatkan ketiga bab berturut-turut
- [ ] Berapa lama satu playthrough penuh sekarang? (**catat menitnya**)
- [ ] Cutscene tidak muncul lagi saat mengulang bab yang sama?

---

## Berkas simpanan

`user://sapusapusungai.cfg` — ConfigFile, bisa dibuka pakai Notepad. Sekarang berisi
nama pemain dan daftar babak cerita yang sudah ditonton.

| Sistem | Lokasi |
|---|---|
| Windows | `%APPDATA%\Godot\app_userdata\sapusapusungai\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/sapusapusungai/` |
| Android | folder privat aplikasi |

Menghapus berkas ini = pemain baru, lengkap dengan kotak nama dan cerita dari awal.

---

## Belum ada — sengaja

- **Sprite asli.** Semua masih Kenney CC0 + Polygon2D. Kredit dicantumkan di menu.
- **Audio final.** Semua bunyi masih sintetis buatan sendiri.
- **Ilustrasi cutscene.** Panelnya dirakit dari warna air, jumlah ikan, dan kepadatan
  sampah — bukan gambar tangan. Nadanya sudah benar, detailnya menyusul.
- **Kontrol sentuh Android.** Mode pointer sudah ada di `player_fish.gd`, tapi belum ada
  joystick layar maupun tombol dash/jeda di layar.
- **Pengaturan lain** (resolusi, layar penuh, ganti tombol) belum ada.
- **Suara narator.** Cerita masih teks.
