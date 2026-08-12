# Daftar Uji — Map 3 Kali Jeroan Madiun

Status: **puzzle dorong balok (Sokoban).** Dorong balok bambu keluar dari lorong sampai
airnya tembus dari hulu ke mulut sungai.

```
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/maps/map3_jeroan.tscn
```

Kontrol: **WASD / panah** berenang & mendorong · **R** ulangi papan

---

## Papannya

```
  MULUT SUNGAI                                                  HULU
       ▼                                                         ▼
     ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
     │████│    │    │    │    │    │    │    │    │████│  ← tepian (ikan lewat)
     ├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
     │████│    │ ⌂  │████│ ⌂  │████│    │ ⌂  │    │████│  ← kantong balok
     ├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
     │ ◀━ │≈≈≈≈│ ▓k │≈≈≈≈│≈≈≈≈│ ▓B │≈≈≈≈│ ▓k │≈≈≈≈│ ━▶ │  ← LORONG AIR
     ├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
     │████│    │    │████│    │████│    │    │    │████│
     ├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
     │████│    │    │    │    │    │    │    │    │████│
     └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘
      kol0  1    2    3    4    5    6    7    8    9

  ████ batu   ≈ lorong air (gelap)   kosong = tepian (lebih terang)
  ▓k balok kecil (1 ikan)            ▓B balok besar (2 IKAN)
```

**Lorong yang gelap = jalan air. Tepian yang lebih terang = jalan ikan.**
Air cuma mengalir di lorong; ikan bisa berenang di mana saja.

Pemisahan itu bukan hiasan — versi pertama papan ini memakai satu jenis petak untuk
keduanya dan ternyata **mustahil diselesaikan**: begitu balok pertama menyumbat lorong,
ikannya ikut terkurung dan tidak akan pernah bisa mencapai sisi seberang balok mana pun.
Sokoban menuntut pemain bisa berjalan memutari balok, tapi kalau air boleh lewat semua
petak yang bisa dilalui ikan, jalan memutar itu jadi jalan pintas buat airnya juga.

**Balok kolom 5 terjepit batu atas-bawah**, jadi tidak bisa langsung dikeluarkan — harus
digeser menyamping dulu ke kolom 4 yang punya kantong. Itu satu-satunya "aha" yang harus
ditemukan sendiri.

Penyelesaian paling hemat: **4 dorongan.**

## Wader B sekarang NPC

Tidak ada lagi Tab. Kamu cuma memegang **Wader A**; Wader B mengikuti sendiri lewat
tepian, dan merapat otomatis begitu kamu menempel di muka balok besar.

Dia punya pencarian jalur sungguhan (BFS di atas kisi) — berenang lurus tidak cukup di
papan Sokoban, karena ikan yang mengarah lurus akan menempel di sisi balok lalu berhenti
di situ selamanya.

**Dan dia tidak akan pernah mendorong balok yang bukan sedang kamu dorong.** Tanpa aturan
itu dia menggeser apa pun yang kebetulan dilewatinya saat menyusul — dan di Sokoban satu
dorongan tak diniatkan bisa mematikan papan, lalu pemain menyalahkan dirinya sendiri
untuk langkah yang bukan dia yang lakukan.

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
- Airnya ikut maju tiap kali balok minggir
- **Balok kolom 5 tidak bisa langsung dikeluarkan** (terjepit batu atas-bawah), tapi
  bisa digeser ke kolom 4 lalu dinaikkan dari sana
- **Papannya benar-benar bisa diselesaikan** dalam 4 dorongan **tanpa Tab sekali pun**,
  dan babnya berakhir begitu air menyentuh mulut sungai (10/10 petak lorong terairi)
- NPC menyusul pemain menyeberangi papan lewat tepian (sisa 78 px dari tujuan)
- NPC berdiri di seberang pemain, tidak menumpuk di atasnya
- NPC **tidak** mendorong balok yang bukan sedang dibantu (dulu bisa: 5 dorongan, sekarang 4)
- Kedua ikan lahir di tepian, bukan di dalam lorong yang sedang mereka buka
- Papan tergambar DI DEPAN latar (dulu tersembunyi di belakangnya)
- Balok tidak bisa didorong ke mulut sungai (papan tidak bisa dibuat mustahil tanpa sadar)
- Balok tidak bisa didorong ke petak yang sedang ditempati ikan

---

## A. Yang paling ingin saya tahu

Main **tanpa membaca dokumen ini dulu.**

- [ ] **Sekarang jelas titik dorongnya di mana?** (ini pertanyaan utamanya)
- [ ] Muka balok yang menyala + panah: kelihatan, atau terlewat?
- [ ] **Lorong gelap vs tepian terang: kebedaan?** Paham air cuma lewat yang gelap?
- [ ] Wader B yang ikut sendiri: terasa membantu, atau malah menghalangi?
- [ ] Pernah menunggu lama Wader B datang? (dia 12% lebih pelan dari kamu, sengaja)
- [ ] Label "2 IKAN" di balok besar cukup untuk paham harus bawa ikan kedua?
- [ ] Airnya yang maju satu petak: terasa sebagai hadiah tiap dorongan?
- [ ] **Sudah terasa seperti puzzle dorong balok yang Anda bayangkan?**

## B. Kesulitan

- [ ] Balok kolom 5 (yang harus digeser menyamping dulu): ketemu sendiri, atau bikin buntu?
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
	"#........#",
	"#..#.#...#",
	"O=k==B=k=I",
	"#..#.#...#",
	"#........#",
]
```

`#` batu · `.` **tepian** (ikan lewat, air tidak) · `=` **lorong** (air mengalir) ·
`k` balok kecil · `B` balok besar · `I` mulut masuk · `O` mulut keluar

**Syarat papan yang sah:** tiap balok harus punya sisi yang bisa dicapai ikan lewat
tepian, kalau tidak papannya mustahil. Dan lorong tidak boleh punya jalan memutar,
kalau tidak airnya lewat begitu saja.

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
