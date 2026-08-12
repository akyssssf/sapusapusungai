# Daftar Uji — Game Utuh

Status: **SAPU-SAPU SUNGAI sekarang sudah jadi game utuh**, bukan kumpulan scene.
Alurnya: menu utama → pilih bab → main → hasil → kembali, dengan progres yang tersimpan.

Jalankan seperti biasa (**F5**) — scene utamanya sekarang menu, bukan Kali Brantas.

```
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

---

## Peta alur

```
                    ┌──────────────┐
                    │  MENU UTAMA  │◄──────────────┐
                    └──────┬───────┘               │
             ┌─────────────┼─────────────┐         │
             ▼             ▼             ▼         │
        Pengaturan     Kredit      ┌──────────┐    │
                                   │PILIH BAB │    │
                                   └────┬─────┘    │
                    ┌───────────────────┼──────────┴────┐
                    ▼                   ▼               ▼
              Bab 1 Brantas      Bab 2 Ciliwung   Bab 3 Jeroan
                    │                   │               │
          menang ───┴─── kalah   menang ┴ kalah/banjir  │ selesai
                    │                   │               │
                    └──► bab berikutnya │               ▼
                                        │        "SUNGAI LANCAR"
                                        ▼               │
                                 "EKOSISTEM KOLAPS"     └──► MENU
```

Esc kapan saja di dalam bab → **menu jeda** (lanjutkan / ulangi / pilih bab / menu utama).

---

## Sudah diuji otomatis — tidak perlu diulang

- Progres tersimpan ke `user://sapusapusungai.cfg` dan **terbaca lagi setelah dimuat ulang**
  (bab tamat, skor terbaik tiap bab, volume musik & efek)
- Pemain baru: Bab 1 terbuka, Bab 2 dan 3 terkunci
- Bab 1 tamat → Bab 2 terbuka, Bab 3 masih terkunci; kartu terkunci **tidak bisa diklik**
- Tombol "Lanjutkan" menunjuk bab pertama yang belum tamat, dan disembunyikan untuk pemain baru
- Kartu bab dibangun dari `GameState.CHAPTERS` (3 kartu, judul & status benar)
- Menu pengaturan membaca nilai dari berkas simpanan; penggeser volume mengubah desibel
- Menu jeda: **Esc membuka dan menutup**, permainan benar-benar berhenti saat dijeda,
  tombolnya tetap bisa difokus, musik tetap jalan
- Bab tamat mencatat skor terbaik (1500 → 2750) dan membuka bab berikutnya
- Ketujuh scene (3 peta + 4 layar) dimuat tanpa error
- **Esc di layar hasil** (menang maupun kalah) kembali ke pilih bab, dan menu jeda
  benar-benar tidak ikut terbuka di sana
- **Bab 3 sekarang memberi skor**: 500 + bonus cepat sampai 500 tiap sumbatan

---

## A. Alur menu

- [ ] Menu utama muncul saat game dijalankan, bukan langsung masuk sungai?
- [ ] Latar sungai bergeraknya (berkas cahaya, debu air, gelembung) enak dilihat?
- [ ] Redup-terang antar layar terasa mulus, atau terlalu lambat/cepat?
- [ ] Esc di panel Pengaturan/Kredit kembali ke menu utama?
- [ ] Tombol KELUAR benar-benar menutup aplikasi?

## B. Pilih bab

- [ ] Status tiap kartu terbaca jelas (SELESAI + skor / BELUM SELESAI / TERKUNCI)?
- [ ] Kartu terkunci jelas kenapa terkuncinya?
- [ ] Navigasi panah kiri/kanan terasa enak, atau lebih suka pakai tetikus saja?
- [ ] Fokus awal langsung di bab yang belum tamat — membantu?

## C. Menu jeda

- [ ] Esc di tengah permainan langsung membuka jeda?
- [ ] Keempat tombolnya bekerja: lanjutkan, ulangi bab, pilih bab, menu utama?
- [ ] Setelah "ulangi bab", babnya benar-benar mulai dari nol?
- [ ] Esc **tidak** membuka jeda di layar hasil (menang/kalah)?

## D. Progres & penyimpanan

- [ ] Tamatkan Bab 1, tutup game, buka lagi — Bab 2 masih terbuka?
- [ ] Skor terbaik tiap bab tersimpan dan naik hanya kalau lebih tinggi?
- [ ] "Skor terbaik keseluruhan" di menu utama = jumlah ketiga bab?
      (**Bab 3 dulu selalu menyumbang 0 — sekarang seharusnya ikut terhitung**)
- [ ] Pengaturan → "Hapus semua progres" minta konfirmasi dua kali, lalu benar-benar bersih?
- [ ] Volume musik/efek tersimpan setelah game ditutup dan dibuka lagi?

## E. Rantai cerita penuh (main dari nol)

- [ ] Hapus progres, lalu mainkan sampai tamat ketiga bab berturut-turut
- [ ] Setiap transisi antar bab terasa nyambung, atau ada yang membingungkan?
- [ ] Layar "EKOSISTEM KOLAPS" (Bab 2) dan "SUNGAI LANCAR" (Bab 3) terasa berlawanan
      nadanya — sesuai maksudnya?
- [ ] Berapa lama satu playthrough penuh? (**tolong catat menitnya**)

---

## Berkas simpanan

Tersimpan di `user://sapusapusungai.cfg` — format ConfigFile, bisa dibuka pakai Notepad:

| Sistem | Lokasi |
|---|---|
| Windows | `%APPDATA%\Godot\app_userdata\sapusapusungai\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/sapusapusungai/` |
| Android | folder privat aplikasi |

Menghapus berkas ini = pemain baru. Berguna saat menguji alur dari nol.

---

## Tentang gerbang progres

Sebelumnya ada peringatan "`bypass_progress_gate` wajib dimatikan sebelum build".
**Peringatan itu sudah tidak berlaku.**

Sekarang pintu yang sesungguhnya ada di layar pilih bab — kartu bab terkunci bahkan tidak
bisa diklik, dan pemain tidak punya jalan lain masuk ke peta. Pemeriksaan di dalam tiap
peta tinggal jadi jaring pengaman untuk saat scene peta dijalankan LANGSUNG dari editor
(F6), jadi `bypass_progress_gate` boleh dibiarkan menyala tanpa membocorkan apa pun.

---

## Belum ada — sengaja

- **Sprite asli.** Semua masih Kenney CC0 + Polygon2D. Kredit sudah dicantumkan di menu.
- **Audio final.** Semua bunyi masih sintetis buatan sendiri.
- **Kontrol sentuh Android.** Mode pointer sudah ada di `player_fish.gd`, tapi belum ada
  joystick layar maupun tombol dash/jeda di layar.
- **Pengaturan lain** (resolusi, layar penuh, ganti tombol) belum ada.
