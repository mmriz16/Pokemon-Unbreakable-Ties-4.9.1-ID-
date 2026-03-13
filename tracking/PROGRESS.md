# Progress

## Done
- Audit sumber teks runtime selesai.
- Repo kerja lokal di folder `Pokemon Unbreakable Ties 4.9.1 (ID)` dibuat.
- Remote GitHub ditambahkan.
- Translasi awal `Data/Scripts/016_UI` dipindahkan ke repo kerja.
- Translasi awal PBS/deskripsi dipindahkan ke repo kerja.
- Compile awal beberapa file `.dat` dipindahkan ke repo kerja.
- Script rebuild `english.dat` dibuat.
- `Data/english.dat` versi Indonesia berhasil dibangun di folder `ID`.
- Verifikasi sample berhasil: nama species tetap asli, sedangkan kinds/entries/deskripsi terjemah ke Indonesia.
- Script resumable untuk rebuild `messages.dat` dibuat.
- `Data/messages.dat` versi Indonesia berhasil dibangun di folder `ID`.
- Verifikasi sample `messages.dat` berhasil: type text, move descriptions, ability descriptions, trainer types, dan map/common messages sudah terbaca dari file hasil rebuild.
- Proofreading pass runtime pertama diterapkan langsung ke `english.dat` dan `messages.dat` untuk istilah yang paling terlihat salah, terutama `types` dan `trainer types`.
- Proofreading pass kedua diterapkan untuk trainer classes yang masih kaku dan string UI Pokedex yang sempat merusak path asset (`Graphics/Pictures`).
- Cleanup UI pass diterapkan ke `Party`, `Summary`, `Bag`, `Save`, `PC`, `Pokemon Storage`, `Move Relearner`, `Mystery Gift`, `Text Entry`, dan `Hall of Fame` untuk menghapus sisa path asset yang salah serta string `Pokedex/Pokemon` yang rusak encoding.
- Proofreading pass battle diterapkan ke runtime data untuk memperhalus kalimat yang paling sering muncul, misalnya status/stat down, pemblokiran jurus, serangan yang dihindari, dan beberapa pesan efek ability/item.
- Proofreading pass battle kedua diterapkan untuk effectiveness, flee text, miss text, dan beberapa pesan status/ability yang sangat sering tampil saat turn berjalan.
- Proofreading pass battle ketiga diterapkan untuk status ailment text dan beberapa kalimat flavour yang masih kaku, termasuk paralysis cure, drowsy/levitate text, dan beberapa deskripsi karakter yang sempat masih bercampur Spanyol.
- Cleanup pass item/overworld diterapkan ke `messages.dat` untuk memulihkan path asset runtime (`Graphics/Pictures/...`), merapikan prompt mail/item/editor, dan membersihkan beberapa string story/profile yang masih bercampur Spanyol atau terlalu literal.
- Cleanup pass save/shop/storage diterapkan ke `messages.dat` untuk merapikan prompt save, PC/mail wording, Summer Mart text, dan beberapa label editor yang masih memakai kata `gerakan` atau frasa hasil translasi literal.

## Next
- Verifikasi `messages.dat` langsung di game.
- Audit `CommonEvents.rxdata` dan `Map*.rxdata` per urutan story.
- Rapikan istilah UI dan trainer class yang masih kaku.
- Mulai translasi `011_Battle`, `012_Overworld`, `013_Items`, dan `999_Main`.
- Putuskan apakah `english.dat` hasil rebuild akan dipakai langsung atau dijadikan baseline lalu diproofread dulu.

## Blockers
- Tidak ada akses Notion API/connector di environment ini.
- `english.dat` Indonesia lama tidak ditemukan di folder sumber saat ini, jadi rebuild dilakukan dari file Inggris yang ada sekarang.
- Hasil translasi mesin masih perlu proofreading, terutama trainer types, ribbon text, dan battle descriptions.
- Hasil translasi mesin untuk `messages.dat` masih perlu proofreading lanjutan, terutama event/story text dan prompt editor yang jarang muncul.

## Working Rules
- Nama Pokemon, item, move, ability tetap pakai istilah asli kecuali diputuskan lain.
- Deskripsi dan UI diterjemahkan ke Bahasa Indonesia.
- Setiap perubahan runtime harus punya backup.
