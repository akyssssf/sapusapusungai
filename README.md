# SAPU-SAPU SUNGAI

> Bersihkan sungainya. Jaga penghuninya.

Game 2D bertema sungai-sungai Indonesia, dibuat dengan **Godot 4.7** untuk
**GEMASTIK XIX 2026 — Divisi Pengembangan Aplikasi Permainan**.

Kamu adalah seekor ikan wader. Tiga sungai sungguhan, tiga masalah yang berbeda —
dan satu kesimpulan yang cuma bisa didapat dengan memainkan ketiganya.

---

## Tiga bab, tiga jenis permainan

| Bab | Sungai | Mainnya |
|---|---|---|
| **1** | Kali Brantas, Jawa Timur | Aksi makan-dimakan. Mulai dari sampah kecil, tumbuh, lalu hadapi Induk Sapu-Sapu. |
| **2** | Sungai Ciliwung, Jakarta | Sampahnya lebih padat — dan sekarang ada ikan lokal yang **bukan makanan**. |
| **3** | Kali Jeroan, Madiun | Puzzle dorong balok. Singkirkan sumbatan bambu supaya airnya bisa tembus lagi. |

Bab 2 punya ambang tersembunyi yang tidak pernah ditampilkan sebagai angka. Kalau
terlalu banyak ikan lokal termakan, airnya menggelap, nada musiknya turun, dan sungai
yang **sudah kamu bersihkan** tetap berakhir banjir. Itu bukan bug — itu isi pesannya.

---

## Menjalankannya

Butuh **Godot 4.7** atau lebih baru. Tidak ada dependensi lain.

```bash
godot --path .
```

Atau buka foldernya lewat Godot Project Manager, lalu tekan **F5**.

### Kontrol

| Tombol | Fungsi |
|---|---|
| `W A S D` / panah | berenang (dan mendorong balok di Bab 3) |
| `Spasi` / `Shift` | dash — Bab 1 & 2 |
| `R` | ulangi papan — Bab 3 |
| `Esc` | menu jeda (ada **Papan Instruksi** di dalamnya) |

Lupa aturannya di tengah main? Buka **Papan Instruksi** dari menu jeda — rondemu tidak
hilang.

---

## Isinya

- **Nama pemain** ditanya di awal, lalu dipakai di menu dan **di dalam naskah ceritanya**
- **Lima babak cerita**: pembuka, dua jembatan antar bab, ending banjir, dan penutup
- **Papan instruksi tiap bab**: tujuan, kontrol, apa yang berbahaya, cara mengatasinya
- **Layar MISI SELESAI** dengan bintang, skor berhitung naik, rekor, dan bab yang terbuka
- **Progres tersimpan** ke `user://sapusapusungai.cfg` — format ConfigFile, bisa dibuka
  pakai Notepad

Alur lengkapnya:

```
kotak nama → menu utama → [cutscene → papan instruksi → bab] → MISI SELESAI → bab berikutnya
```

---

## Susunan berkas

```
scenes/
  maps/        tiga peta bab
  entities/    ikan, sampah, sapu-sapu, bos, balok dorong
  ui/          menu, pilih bab, cutscene, papan instruksi, HUD, layar hasil
scripts/
  autoload/    GameState (progres & simpanan), AudioManager, SceneRouter
  story.gd     SELURUH naskah cerita dan isi papan instruksi, dalam satu berkas
assets/        audio sintetis buatan sendiri
kenney_fish-pack_2/   sprite ikan & lingkungan (CC0)
```

Beberapa keputusan yang sengaja:

- **Naskah dikumpulkan di `scripts/story.gd`.** Naskah adalah bagian yang paling sering
  diubah, jadi harus jadi yang paling gampang ditemukan.
- **Papan Bab 3 ditulis sebagai gambar teks.** Batu, tabrakan, balok, dan aliran airnya
  dibangun sendiri dari denah itu — ubah gambarnya, papannya ikut berubah.
- **Semua perpindahan scene lewat `SceneRouter`,** supaya alamat scene tidak tersebar dan
  tiap perpindahan dapat redup-terang yang sama.

---

## Catatan pengembangan

Tiap bab punya daftar uji sendiri, lengkap dengan hal-hal yang **sudah diverifikasi
otomatis** lewat Godot headless dan hal-hal yang masih butuh dinilai manusia:

- [`UJI_GAME.md`](UJI_GAME.md) — alur game utuh
- [`UJI_MAP1.md`](UJI_MAP1.md) · [`UJI_MAP2.md`](UJI_MAP2.md) · [`UJI_MAP3.md`](UJI_MAP3.md)

---

## Aset & lisensi

- **Sprite**: [Kenney Fish Pack 2](https://kenney.nl/assets/fish-pack) — **CC0**, bebas
  dipakai. Sampah, sapu-sapu, dan balok bambu masih `Polygon2D` buatan sendiri.
- **Audio**: seluruhnya sintetis, dibuat sendiri untuk proyek ini.
- Kredit lengkap juga dicantumkan di dalam game, lewat menu **KREDIT**.

## Yang belum ada

- Sprite asli untuk sampah, sapu-sapu, dan bos (masih `Polygon2D`)
- Ilustrasi cutscene (panelnya dirakit dari warna air, jumlah ikan, dan kepadatan sampah)
- Kontrol sentuh Android — mode pointer sudah ada, joystick layarnya belum
- Pengaturan resolusi, layar penuh, dan ganti tombol
