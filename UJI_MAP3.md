# Daftar Uji — Map 3 Kali Jeroan Madiun

Status: **sekarang benar-benar puzzle.** Yang menentukan bukan lagi kelincahan, tapi
**urutan** — dan urutan yang benar justru melawan insting pemain.

```
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/maps/map3_jeroan.tscn
```

Kontrol: **WASD / panah** berenang · **Tab** (atau **Q**, atau **klik ikan**) ganti kendali.

---

## Aturan yang mengubah bab ini

Sebelumnya bab ini hambar karena cuma ada **satu cara** menyelesaikannya: bawa ikan A,
parkir, bawa ikan B, tunggu. Tidak ada keputusan yang bisa salah — dan tanpa keputusan
yang bisa salah, tidak ada puzzle.

Sekarang ada satu aturan tambahan, dan cuma satu:

> **Sebuah sumbatan melepas ARUS DERAS kalau tidak ada lagi sumbatan lain yang masih
> tertutup di HILIRNYA.**

Logikanya nyata: air yang dilepas dari hulu akan **ditahan** sumbatan berikutnya di hilir,
jadi cuma menggenang. Tapi air yang dilepas dari hilir tidak ditahan apa pun — seluruh
kolam yang tertahan di belakangnya **menghambur sekaligus**, dan menyeret kedua ikan Anda
ke kiri selama 11 detik.

Dari satu aturan itu, urutan yang benar muncul sendiri:

```
    HILIR (kiri)                                    HULU (kanan)
    ikan lahir di sini                              kerja mulai dari sini
         ●●                                                  │
         │                                                   │
    [Sumbatan  ]        [Sumbatan  ]        [Sumbatan  ]     │
    [  Hilir   ]        [  Tengah  ]        [   Hulu   ]◄────┘  1. dulu
         ▲                    ▲
         │                    └────────────────────────────────  2. lalu
         └─────────────────────────────────────────────────────  3. terakhir
```

**Yang membuatnya jadi teka-teki, bukan jebakan:** tiap sumbatan memasang penanda
sebelum disentuh — **AMAN** (hijau) atau **AWAS - DERAS** (oranye, dengan panah ke arah
air akan lari). Pemain bisa membaca akibatnya sebelum bertindak. Penandanya berpindah
sendiri tiap kali satu sumbatan terbuka.

**Dan yang paling terakhir justru jadi hadiahnya:** saat sumbatan hilir dibuka terakhir,
arusnya tetap menghambur — tapi sudah tidak ada pekerjaan yang bisa dirusaknya. Itu
momen sungai akhirnya jalan.

Menamatkan tanpa sekali pun salah urutan memberi **RENCANA SEMPURNA +600**.

---

## Sudah diuji otomatis — tidak perlu diulang

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
- Ketiga sumbatan masih terjangkau dalam urutan yang benar (jendela 10,5 dtk vs
  kebutuhan terberat 8,2 dtk di Sumbatan Hulu)
- Radius antar sumbatan tidak bertumpuk (444 dan 429 px, ambangnya 400)
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

## C. Yang lama, masih perlu dinilai

- [ ] Satu ikan dekat (**outline kuning**) vs dua ikan (**outline biru + cincin**) jelas?
- [ ] Hanyut 8 px/dtk saat ikan ditinggal: masih terasa, atau sudah tidak berarti?
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
| Radius "dekat sumbatan" | tiap Sumbatan | `push_radius` (200) |
| Lama harus bertahan | tiap Sumbatan | `hold_time` (1,6 / 2,0 / 2,4) |
| Warna penanda ramalan | tiap Sumbatan | `warna_aman` / `warna_deras` |
| Gerbang progres | Map3Jeroan | `requires_map2`, `bypass_progress_gate` |

## Menambah atau menggeser sumbatan

Duplikat salah satu node **Sumbatan** di dalam `Obstacles`, geser posisinya. Wasit
mengurutkan sendiri berdasarkan posisi X dan menghitung ulang siapa yang AMAN dan siapa
yang DERAS. **Tidak ada daftar urutan yang ditulis mati di mana pun** — jawabannya ikut
berubah sendiri.

**Tiga syarat yang perlu dijaga:**
1. Jarak ke sumbatan tetangga harus **lebih besar dari jumlah kedua radiusnya** (dengan
   radius 200, artinya lebih dari 400 px), supaya tidak ada dua cincin terisi sekaligus.
2. `(push_radius - 116) / idle_current_drift` harus **lebih besar dari** waktu tempuh ikan
   kedua ditambah `hold_time`. Angka 116 itu lantai fisik: badan sumbatan 86 + ikan 30.
3. `kekuatan_arus` harus **di bawah** `max_speed` ikan (300), kalau tidak pemain kehilangan
   kendali alih-alih ditantang.

---

## Belum ada — sengaja

- **Latar masih sederhana**: gradasi air + tebing polos + partikel arus.
- **Arus deras belum punya visual sendiri** selain guncangan kamera dan bunyi — partikel
  arus derasnya menyusul.
- Map 3 tidak memakai satu pun script Map 1/2.
