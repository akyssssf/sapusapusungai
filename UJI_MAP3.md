# Daftar Uji — Map 3 Kali Jeroan Madiun

Status: **puzzle dorong balok (Sokoban).** Dorong balok bambu keluar dari lorong sampai
airnya tembus dari hulu ke mulut sungai.

```
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/maps/map3_jeroan.tscn
```

Kontrol: **WASD / panah** berenang & mendorong · **Tab** ganti ikan · **R** ulangi papan

---

## Papannya

```
   MULUT SUNGAI                                                    HULU
   (air harus sampai sini)                              (air masuk dari sini)
        │                                                          │
        ▼                                                          ▼
      ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
      │████│████│    │████│████│    │████│████│████│████│
      ├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
      │████│████│    │████│████│    │████│    │    │████│
      ├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
      │ ◀━ │    │    │ ▓k │    │ ▓B │    │ ▓k │    │ ━▶ │  ← lorong air
      ├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
      │████│████│    │████│████│    │████│    │    │████│
      ├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
      │████│████│    │████│████│    │████│████│████│████│
      └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘
       kol0  1    2    3    4    5    6    7    8    9

   ████ batu     ▓k balok kecil (1 ikan)     ▓B balok besar (2 IKAN)
```

**Lorong tengah satu-satunya jalan air.** Kantong di atas dan bawah buntu — itulah
tempat membuang balok.

**Kolom 3 sengaja tidak punya kantong** (atas dan bawahnya batu). Balok di situ tidak
bisa langsung dikeluarkan; harus digeser menyamping dulu ke kolom 2, baru dikeluarkan.
Itu satu-satunya "aha" yang harus ditemukan sendiri.

Penyelesaian paling hemat: **4 dorongan.**

---

## Kenapa dibangun ulang (lagi)

Dua versi sebelumnya menyuruh pemain **menahan** sesuatu — menahan posisi, lalu menahan
tombol. Dua-duanya bukan puzzle, karena tidak ada yang perlu dipindahkan ke tempat yang
benar dan tidak ada langkah yang bisa salah secara permanen.

Sokoban punya keduanya: tiap dorongan mengubah papan, dan sebagian dorongan tidak bisa
dibatalkan.

### Jawaban atas "ga tau titiknya di mana"

Itu keluhan yang paling penting, dan sepenuhnya salah rancangan sebelumnya — ada tiga
aturan tak terlihat sekaligus (radius 165 px, sisi seberang, arah tekan) dan tidak satu
pun digambar di layar.

| Sekarang | |
|---|---|
| **Semuanya di atas petak** | Kisi terlihat. Tidak ada lagi radius tak terlihat. |
| **Balok bermuka rata** | Ikan menempel di muka yang jelas, tidak meluncur menyusuri lengkungan. |
| **Muka yang bisa didorong MENYALA** | Lengkap dengan panah arahnya, begitu ikan berada di tempat yang benar. Kuning = kurang ikan, biru = sudah cukup. |
| **Balok besar berlabel "2 IKAN"** | Harfiah, bukan isyarat halus. Isyarat visual saja bikin pemain menyimpulkan "baloknya macet". |
| **Airnya maju satu petak** | Tiap kali jalannya terbuka. Umpan balik langsung bahwa dorongan barusan berguna. |

---

## Sudah diuji otomatis — tidak perlu diulang

- Papan terbaca benar dari denah teks (10×5), mulut masuk & keluar ketemu
- Tiga balok terpasang, satu di antaranya balok besar
- **Balok besar TIDAK bergerak dengan satu ikan**; bergerak dengan dua
- Balok kecil bergerak dengan satu ikan, dan petak asalnya jadi kosong
- Airnya ikut maju tiap kali balok minggir (6 → 8 petak setelah dorongan pertama)
- **Kolom 3 tidak bisa langsung dikeluarkan ke atas**, tapi bisa digeser ke kolom 2
  lalu dikeluarkan dari sana
- **Papannya benar-benar bisa diselesaikan** dalam 4 dorongan, dan babnya berakhir
  begitu air menyentuh mulut sungai
- Balok tidak bisa didorong ke mulut sungai (papan tidak bisa dibuat mustahil tanpa sadar)
- Balok tidak bisa didorong ke petak yang sedang ditempati ikan

---

## A. Yang paling ingin saya tahu

Main **tanpa membaca dokumen ini dulu.**

- [ ] **Sekarang jelas titik dorongnya di mana?** (ini pertanyaan utamanya)
- [ ] Muka balok yang menyala + panah: kelihatan, atau terlewat?
- [ ] Label "2 IKAN" di balok besar cukup untuk paham harus bawa ikan kedua?
- [ ] Airnya yang maju satu petak: terasa sebagai hadiah tiap dorongan?
- [ ] **Sudah terasa seperti puzzle dorong balok yang Anda bayangkan?**

## B. Kesulitan

- [ ] Balok kolom 3 (yang harus digeser menyamping dulu): ketemu sendiri, atau bikin buntu?
- [ ] Pernah membuat papan jadi mustahil? Kalau ya, **R** kelihatan sebagai jalan keluar?
- [ ] 4 dorongan terasa terlalu sedikit? (papannya bisa dibuat lebih besar)
- [ ] Berapa lama satu ronde? (**catat menitnya**)

## C. Rasa

- [ ] 0,3 detik menekan sebelum balok pindah: pas, atau terasa lambat?
- [ ] Balok yang meluncur 0,22 detik + sedikit gepeng: terasa berat?
- [ ] Kamera dua ikan masih enak dengan papan sebesar ini?

---

## Mengubah papannya

Seluruh papan ada di **satu konstanta teks** di `scripts/map3_manager.gd`:

```gdscript
const PETA := [
	"##.##.####",
	"##.##.#..#",
	"O..k.B.k.I",
	"##.##.#..#",
	"##.##.####",
]
```

`#` batu · `.` air bisa lewat · `k` balok kecil · `B` balok besar ·
`I` mulut masuk · `O` mulut keluar

Ubah gambarnya, papannya ikut berubah — batu, tabrakan, balok, dan aliran airnya
dibangun sendiri saat scene dibuka. **Jangan lupa memperbarui `DORONGAN_OPTIMAL`**
kalau denahnya diubah, karena angka itu yang dipakai menghitung bonus.

Ukuran papan boleh berapa saja asal semua barisnya sama panjang.

## Tombol setelan lain

| Yang mau diubah | Properti di Map3Jeroan |
|---|---|
| Besar petak | `lebar_petak` (140) |
| Lama menekan sebelum balok pindah | `waktu_dorong` (0,3 dtk) |
| Lama balok meluncur | `lama_geser` (0,22 dtk) |
| Skor tiap petak air baru | `skor_per_petak_air` (40) |
| Skor selesai & bonus hemat | `skor_selesai` (1000), `bonus_langkah` (800) |
| Denda tiap dorongan berlebih | `denda_per_langkah` (100) |

---

## Belum ada — sengaja

- **Sprite balok masih Polygon2D** bergaris, bukan gambar ikatan bambu sungguhan.
- **Batu masih kotak polos** — belum ada tekstur tebing.
- **Belum ada undo satu langkah**; yang ada baru ulang seluruh papan (R).
- **Baru satu papan.** Kalau mekaniknya sudah terasa benar, menambah papan kedua tinggal
  menambah satu denah teks lagi.
