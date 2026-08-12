# Daftar Uji — Map 3 Kali Jeroan Madiun

Status: **sekarang benar-benar puzzle.** Yang menentukan bukan lagi kelincahan, tapi
**urutan** — dan urutan yang benar justru melawan insting pemain.

```
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/maps/map3_jeroan.tscn
```

Kontrol: **WASD / panah** berenang · **Tab** (atau **Q**, atau **klik ikan**) ganti kendali.

---

## Yang berubah: dari MENUNGGU jadi MENDORONG

Keluhan sebelumnya tepat — aturan urutan menambah *keputusan*, tapi yang dilakukan
tangan pemain tetap sama: parkir dua ikan, tunggu cincin penuh. Tidak ada yang bergerak.

**Sekarang sumbatannya benar-benar didorong.**

| | |
|---|---|
| **Ikan yang dipegang** | harus terus **berenang menekan** ke arah dorong. Lepas tombol = berhenti mendorong. |
| **Ikan yang ditinggal** | otomatis **mengganjal** — tapi hanya kalau posisinya di sisi **seberang** arah dorong. Salah sisi, dia tidak membantu sama sekali. |

Ganjalan saja (0,8) maupun dorongan saja (maksimal 1,0) sama-sama di bawah ambang 1,6.
Butuh keduanya. "Harus berdua" jadi dipaksakan oleh fisikanya, bukan oleh hitungan.

Dan yang paling terasa: **sumbatannya bergeser di layar selama didorong**, ikut miring,
memercikkan air — lalu **melorot balik** begitu dilepas. Ada bayangan samar di posisi
tujuan supaya pemain tahu sampai mana harus mendorong.

Tiap sumbatan punya arah dorong berbeda, jadi tempat mengganjalnya juga berpindah-pindah.

## Aturan urutan (masih berlaku, di atas mekanik dorong)

> **Sebuah sumbatan melepas ARUS DERAS kalau tidak ada lagi sumbatan lain yang masih
> tertutup di HILIRNYA.**

Air yang dilepas dari hulu ditahan sumbatan berikutnya — aman. Air yang dilepas dari
hilir tidak ditahan apa pun, seluruh kolam menghambur. Urutan benar: **hulu dulu, hilir
terakhir**, melawan insting karena ikan lahir di hilir. Penanda **AMAN** / **AWAS-DERAS**
di tiap sumbatan membuatnya teka-teki, bukan jebakan. Tamat tanpa salah urutan =
**RENCANA SEMPURNA +600**.

## Sudah diuji otomatis — tidak perlu diulang

**Mekanik dorong**
- Satu ikan mendorong sekuatnya: **tidak menggerakkan sama sekali**
- Ganjalan saja: juga tidak menggerakkan
- Ganjal + dorong aktif: bergeser 78 px dan ikut berputar 7,3 derajat
- Berhenti mendorong: melorot balik **bertahap**, bukan hangus total
- Mendorong dari sisi yang salah: tidak menambah kemajuan
- Didorong terus: akhirnya lepas
- Ketiga sumbatan punya ruang untuk mengganjal di sisi seberangnya

**CRASH yang dilaporkan sudah diperbaiki**
- Membuka sumbatan kedua setelah yang pertama benar-benar dihapus Godot: tidak crash lagi
- Daftar sumbatan dibersihkan dari acuan mati

**Aturan urutan**
- Tiga sumbatan diurutkan sendiri dari hilir ke hulu; **hanya satu berpenanda DERAS**
  pada satu waktu, dan penandanya berpindah setelah tiap sumbatan terbuka
- Membuka hilir duluan **melepas arus** dan menghanguskan bonus rencana sempurna
- Membuka hulu duluan **tidak melepas arus** sama sekali
- Sumbatan terakhir tetap melepas arus, **tapi tidak dihitung sebagai kesalahan**, dan
  bonus rencana sempurna tetap diberikan (+1600 total di sumbatan itu)
- Arus mendorong ikan yang berada di **hulu** titik lepasnya; ikan yang sudah lewat
  lubangnya tidak ditarik balik
- Arus mereda sendiri sampai nol — kesalahan urutan itu mahal, bukan permanen
- Arus (190 px/dtk) **lebih lemah** daripada kecepatan renang (300) — pemain melawan
  arus, bukan kehilangan kendali
- Radius dorong antar sumbatan tidak bertumpuk (532 dan 371 px, ambangnya 330)
- Skor: cepat → 1000, lambat → 500, setengah waktu → 750; bar aliran tidak menghitung ganda

---

## A. Apakah sekarang terasa seperti puzzle? (pertanyaan utama)

Main **tanpa membaca dokumen ini dulu**.

- [ ] **Percobaan pertama Anda mulai dari sumbatan yang mana?** (jujur — kalau dari yang
      kiri, itu justru hasil yang saya harapkan)
- [ ] Setelah arusnya menghambur, banner penjelasannya membuat Anda paham **sebabnya**,
      atau cuma terasa dihukum tiba-tiba?
- [ ] Di percobaan kedua, Anda langsung tahu harus mulai dari kanan?
- [ ] Penanda **AMAN / AWAS-DERAS** terbaca sebelum Anda bertindak, atau baru ketahuan
      setelah terlambat?
- [ ] Panah oranye jelas menunjukkan ke mana airnya akan lari?
- [ ] Setelah tahu jawabannya, mengulang bab ini masih menarik (mengejar RENCANA
      SEMPURNA), atau jadi hambar lagi?

## B. Rasa arusnya

- [ ] 190 px/dtk terasa **berat tapi masih bisa dilawan**, atau kendali serasa dirampas?
- [ ] 11 detik terasa pas, atau kelamaan menunggu?
- [ ] Meredanya terasa alami?
- [ ] Sumbatan terakhir yang melepas arus sebagai penutup: terasa sebagai kemenangan?

## C. Rasa mendorong (yang paling saya ingin tahu)

- [ ] **Terasa berat?** Sumbatan yang bergeser tiap kali Anda menekan — cukup memuaskan?
- [ ] Melorot balik saat dilepas: bikin tegang, atau bikin frustrasi?
- [ ] Aturan "ganjal dari sisi seberang" ketemu sendiri, atau harus baca papan dulu?
- [ ] 2,2 detik dorongan penuh per sumbatan: pas, kependekan, atau kepanjangan?
- [ ] Kamera dua ikan saat keduanya berjauhan membantu atau bikin pusing?
- [ ] Berapa lama satu ronde penuh sekarang? (**catat menitnya**)

---

## Tombol setelan Map 3

| Yang mau diubah | Node | Properti |
|---|---|---|
| **Kekuatan arus deras** | Map3Jeroan | `kekuatan_arus` (190) |
| **Lama arus mereda** | Map3Jeroan | `lama_arus` (11 dtk) |
| **Hadiah urutan benar** | Map3Jeroan | `bonus_rencana_sempurna` (600) |
| Hanyut ikan yang ditinggal | FishA / FishB | `idle_current_drift` (8; 0 = mati) |
| Nilai dasar tiap sumbatan | Map3Jeroan | `score_per_obstacle` (500) |
| Bonus cepat maksimum | Map3Jeroan | `max_efficiency_bonus` (500) |
| Lama bonus habis | Map3Jeroan | `bonus_fade_seconds` (24 dtk) |
| **Arah sumbatan didorong** | tiap Sumbatan | `arah_dorong` |
| **Sejauh apa sampai lepas** | tiap Sumbatan | `jarak_lepas` (170 / 150 / 170) |
| **Seberat apa** | tiap Sumbatan | `ambang_gerak` (1,6), `tenaga_ganjal` (0,8), `tenaga_dorong` (1,0) |
| **Cepat didorong / melorot** | tiap Sumbatan | `kecepatan_geser` (78), `kecepatan_lorot` (34) |
| Jarak ikan masih terhitung | tiap Sumbatan | `radius_dorong` (165) |
| Warna penanda ramalan | tiap Sumbatan | `warna_aman` / `warna_deras` |
| Gerbang progres | Map3Jeroan | `requires_map2`, `bypass_progress_gate` |

## Menambah atau menggeser sumbatan

Duplikat salah satu node **Sumbatan** di dalam `Obstacles`, geser posisinya. Wasit
mengurutkan sendiri berdasarkan posisi X dan menghitung ulang siapa yang AMAN dan siapa
yang DERAS. **Tidak ada daftar urutan yang ditulis mati di mana pun** — jawabannya ikut
berubah sendiri.

**Tiga syarat yang perlu dijaga:**
1. Jarak ke sumbatan tetangga harus **lebih besar dari jumlah kedua `radius_dorong`**
   (dengan 165, artinya lebih dari 330 px), supaya satu ikan tidak terhitung di dua
   sumbatan sekaligus.
2. Harus ada **ruang air di sisi seberang `arah_dorong`** untuk ikan mengganjal —
   sekitar 130 px dari titik tengah sumbatan, di dalam air dan bukan di dalam tebing.
   Tanpa ruang itu, sumbatannya mustahil didorong.
3. `kekuatan_arus` harus **di bawah** `max_speed` ikan (300), kalau tidak pemain kehilangan
   kendali alih-alih ditantang.

---

## Belum ada — sengaja

- **Latar masih sederhana**: gradasi air + tebing polos + partikel arus.
- **Arus deras belum punya visual sendiri** selain guncangan kamera dan bunyi — partikel
  arus derasnya menyusul.
- **Sprite sumbatan masih Polygon2D**, bukan gambar bambu sungguhan.
- Map 3 tidak memakai satu pun script Map 1/2.
